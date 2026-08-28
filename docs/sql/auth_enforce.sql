-- Enforce verified identity on the functions that can do real harm.
--
-- Depends on docs/sql/auth_identity.sql. Apply that first.
--
-- Each function keeps its signature so no client change is needed, but the `p_user`
-- parameter is now IGNORED and the caller is taken from the session instead. That is
-- deliberate: a guard that compares p_user against the real caller still leaves the
-- parameter looking meaningful, and the next person to add a function will copy the
-- pattern and forget the comparison. Ignoring it entirely removes the footgun.
--
-- `me()` raises when there is no session, so an unauthenticated call fails closed rather
-- than silently operating on nothing.

create or replace function public.me()
returns text
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v text;
begin
  v := public.current_apple_user();
  if v is null then
    raise exception 'not authenticated'
      using hint = 'this endpoint needs a signed-in session';
  end if;
  return v;
end $$;

grant execute on function public.me() to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Destructive. This one mattered most: anybody holding a friend's id could end
-- that friend's creature, and "it can't truly die" is the app's core promise.
-- ---------------------------------------------------------------------------
create or replace function public.delete_account(p_user text)
returns jsonb language plpgsql security definer
set search_path = public as $$
declare
  v_user text := public.me();
  v_existed boolean;
begin
  select exists(select 1 from public.app_users where apple_user_id = v_user) into v_existed;
  update public.app_feedback set user_id = null where user_id = v_user;
  delete from public.app_users where apple_user_id = v_user;
  return jsonb_build_object('ok', true, 'existed', v_existed);
end $$;

-- ---------------------------------------------------------------------------
-- Wallet: read and write.
-- ---------------------------------------------------------------------------
create or replace function public.wallet_state(p_user text)
returns jsonb language plpgsql stable security definer
set search_path = public as $$
declare v_user text := public.me();
begin
  return jsonb_build_object(
    'coins', coalesce((select coins from public.app_users where apple_user_id = v_user), 0),
    'owned', coalesce((select jsonb_agg(item_id) from public.inventory where user_id = v_user), '[]'::jsonb)
  );
end $$;

create or replace function public.push_wallet(p_user text, p_coins integer, p_owned jsonb)
returns jsonb language plpgsql security definer
set search_path = public as $$
declare v_user text := public.me();
begin
  perform ensure_app_user(v_user);
  update public.app_users
     set coins = greatest(coins, greatest(0, p_coins))
   where apple_user_id = v_user;
  insert into public.inventory(user_id, item_id, source)
    select v_user, x.value, 'sync'
    from jsonb_array_elements_text(coalesce(p_owned, '[]'::jsonb)) as x(value)
    on conflict (user_id, item_id) do nothing;
  return public.wallet_state(v_user);
end $$;

-- ---------------------------------------------------------------------------
-- The creature backup itself.
-- ---------------------------------------------------------------------------
create or replace function public.push_player_state(p_user text, p_state jsonb, p_version text)
returns jsonb language plpgsql security definer
set search_path = public as $$
declare v_user text := public.me();
begin
  perform ensure_app_user(v_user);
  insert into public.player_state(user_id, state, app_version, updated_at)
    values (v_user, coalesce(p_state, '{}'::jsonb), p_version, now())
  on conflict (user_id) do update
    set state = excluded.state, app_version = excluded.app_version, updated_at = now();
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.pull_player_state(p_user text)
returns jsonb language plpgsql stable security definer
set search_path = public as $$
declare v_user text := public.me();
begin
  return coalesce((select state from public.player_state where user_id = v_user), 'null'::jsonb);
end $$;

notify pgrst, 'reload schema';

-- ---------------------------------------------------------------------------
-- The `language sql` functions, converted to plpgsql so the guard can run first.
--
-- A SQL-language function has no place to put a statement before its query, so each
-- becomes a plpgsql wrapper around the identical query. Bodies are otherwise unchanged.
--
-- NOT guarded, deliberately: `friend_collection(p_user)`. get_friends calls it with a
-- FRIEND's id, not the caller's, so a guard here would break the friends list for
-- everyone. It exposes only the species list of somebody you are already friends with,
-- which get_friends is entitled to show, and it is unreachable with a stranger's id
-- because reaching it requires a friendship row.
-- ---------------------------------------------------------------------------

create or replace function public.get_friends(p_user text)
returns jsonb language plpgsql security definer
set search_path = public as $$
begin
  perform public.assert_caller(p_user);
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'user_id',    f.friend_id,
      'name',       rs.name,
      'snapshot',   rs.snapshot,
      'updated_at', rs.updated_at,
      'found',      public.friend_collection(f.friend_id),
      'trust_band', public.trust_band((ps.state ->> 'trust')::double precision)
    ) order by rs.updated_at desc nulls last), '[]'::jsonb)
    from public.friendships f
    left join public.room_snapshots rs on rs.user_id = f.friend_id
    left join public.player_state   ps on ps.user_id = f.friend_id
    where f.user_id = p_user
  );
end $$;

create or replace function public.get_postcards(p_user text)
returns jsonb language plpgsql security definer
set search_path = public as $$
begin
  perform public.assert_caller(p_user);
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', p.id,
      'from_id', p.from_id,
      'from_name', rs.name,
      'message', p.message,
      'created_at', p.created_at,
      'read', (p.read_at is not null)
    ) order by p.created_at desc), '[]'::jsonb)
    from public.postcards p
    left join public.room_snapshots rs on rs.user_id = p.from_id
    where p.to_id = p_user
      and not exists (
        select 1 from public.blocks b
        where (b.user_id = p_user and b.blocked_id = p.from_id)
           or (b.user_id = p.from_id and b.blocked_id = p_user))
    limit 50
  );
end $$;

create or replace function public.get_recent_visits(p_user text)
returns jsonb language plpgsql security definer
set search_path = public as $$
begin
  perform public.assert_caller(p_user);
  return (
    select coalesce(jsonb_agg(j order by j->>'created_at' desc), '[]'::jsonb) from (
      select distinct on (v.visitor_id)
        jsonb_build_object('visitor_id', v.visitor_id, 'name', rs.name, 'created_at', v.created_at) as j
      from public.visits v
      left join public.room_snapshots rs on rs.user_id = v.visitor_id
      where v.owner_id = p_user and v.created_at >= now() - interval '7 days'
      order by v.visitor_id, v.created_at desc
    ) t
  );
end $$;

create or replace function public.mark_postcards_read(p_user text)
returns void language plpgsql security definer
set search_path = public as $$
begin
  perform public.assert_caller(p_user);
  update public.postcards set read_at = now() where to_id = p_user and read_at is null;
end $$;

create or replace function public.my_founding(p_user text)
returns text[] language plpgsql stable security definer
set search_path = public as $$
begin
  perform public.assert_caller(p_user);
  return (
    select coalesce(array_agg(item_id order by granted_at), '{}')
    from public.inventory
    where user_id = p_user and item_id like 'founding-%'
  );
end $$;

-- Single-line body, so the injector could not find a newline after BEGIN.
create or replace function public.ensure_user(p_user text)
returns text language plpgsql security definer
set search_path = public as $$
declare v_code text;
begin
  perform public.assert_caller(p_user);
  insert into public.app_users (apple_user_id) values (p_user) on conflict (apple_user_id) do nothing;
  select referral_code into v_code from public.app_users where apple_user_id = p_user;
  return v_code;
end $$;

notify pgrst, 'reload schema';
