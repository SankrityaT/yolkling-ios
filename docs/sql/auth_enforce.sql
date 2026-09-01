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

-- Returns the {found, state, updated_at} ENVELOPE the client parses, not the raw state.
-- This returned the bare jsonb, so SupabaseClient.pullPlayerState's `obj["found"] == true`
-- guard never passed and the function returned nil UNCONDITIONALLY — cloud restore was
-- dead app-wide, and any caller treating nil as "no backup" would happily overwrite a
-- real one. Applied live 2026-09-01.
create or replace function public.pull_player_state(p_user text)
returns jsonb language plpgsql stable security definer
set search_path = public as $$
declare v_user text := public.me(); v_state jsonb; v_at timestamptz;
begin
  select state, updated_at into v_state, v_at
    from public.player_state where user_id = v_user;
  if v_state is null then
    return jsonb_build_object('found', false);
  end if;
  return jsonb_build_object('found', true, 'state', v_state, 'updated_at', v_at);
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

-- ---------------------------------------------------------------------------
-- Economy identity, applied live 2026-09-01.
--
-- These three executed for an UNAUTHENTICATED caller holding only the shipped
-- anon key, because the sender/proposer was whatever the client said. Verified
-- against production before and after: gift_yolks returned {"ok":false,
-- "reason":"not_friends"} for a spoofed sender (i.e. it ran, and only failed a
-- business check), and now returns "not authenticated".
--
-- gift_yolks was the live money hole: friend ids are handed out by get_friends,
-- so anyone could drain 100 Yolks a day from each of their friends into their
-- own balance. The p_from / p_to parameters are kept for wire compatibility and
-- the sender is now always public.me().
-- ---------------------------------------------------------------------------

create or replace function public.gift_yolks(p_from text, p_to text, p_amount integer)
returns jsonb language plpgsql security definer
set search_path = public as $$
declare v_from text := public.me();
        v_today int; v_balance int; v_rel text; v_stranger_today int;
begin
  v_rel := can_reach(v_from, p_to);
  if v_rel in ('self','blocked') then return jsonb_build_object('ok', false, 'reason', v_rel); end if;
  if v_rel = 'no' then return jsonb_build_object('ok', false, 'reason', 'not_friends'); end if;
  if v_rel = 'drifted' then
    if p_amount <> 10 then return jsonb_build_object('ok', false, 'reason', 'stranger_amount'); end if;
    select count(*) into v_stranger_today from public.gifts g
      where g.from_id = v_from and g.created_at >= date_trunc('day', now())
        and not exists (select 1 from public.friendships f
                         where f.user_id = v_from and f.friend_id = g.to_id);
    if v_stranger_today >= 1 then return jsonb_build_object('ok', false, 'reason', 'stranger_gift_cap'); end if;
  elsif p_amount not in (10,20,50) then
    return jsonb_build_object('ok', false, 'reason', 'bad_amount');
  end if;
  select coalesce(sum(amount),0) into v_today from public.gifts
    where from_id = v_from and created_at >= date_trunc('day', now());
  if v_today + p_amount > 100 then return jsonb_build_object('ok', false, 'reason', 'daily_cap'); end if;
  select coins into v_balance from public.app_users where apple_user_id = v_from for update;
  if coalesce(v_balance,0) < p_amount then return jsonb_build_object('ok', false, 'reason', 'insufficient'); end if;
  update public.app_users set coins = coins - p_amount where apple_user_id = v_from;
  update public.app_users set coins = coins + p_amount where apple_user_id = p_to;
  insert into public.gifts(from_id, to_id, amount) values (v_from, p_to, p_amount);
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.send_wave(p_from text, p_to text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_from text := public.me(); v_rel text; v_today int;
begin
  v_rel := can_reach(v_from, p_to);
  if v_rel in ('self','blocked') then return jsonb_build_object('ok', false, 'reason', v_rel); end if;
  if v_rel = 'no' then return jsonb_build_object('ok', false, 'reason', 'not_friends'); end if;
  if v_rel = 'drifted' then
    select count(*) into v_today from public.waves w
      where w.from_id = v_from and w.created_at >= date_trunc('day', now())
        and not exists (select 1 from public.friendships f
                         where f.user_id = v_from and f.friend_id = w.to_id);
    if v_today >= 3 then return jsonb_build_object('ok', false, 'reason', 'wave_cap'); end if;
  end if;
  insert into public.waves(from_id, to_id) values (v_from, p_to);
  return jsonb_build_object('ok', true);
end $$;

-- propose_trade: the proposer is the signed-in user. See trading.sql for the body;
-- the live definition differs only in taking the identity from me().

notify pgrst, 'reload schema';


-- ---------------------------------------------------------------------------
-- publish_room (4-arg): returns a result, and enforces identity.
--
-- It returned void, so the client could not tell success from failure at all —
-- and a client checking for {ok} reads every call as a failure, which makes
-- "open my door" impossible and drift/wander permanently unreachable. It was
-- also unguarded: p_user was taken on trust. Applied live 2026-09-01.
-- ---------------------------------------------------------------------------
drop function if exists public.publish_room(text, text, jsonb, boolean);
create or replace function public.publish_room(p_user text, p_name text, p_snapshot jsonb, p_public boolean)
returns jsonb language plpgsql security definer
set search_path = public as $$
declare v_user text := public.me();
begin
  insert into public.room_snapshots(user_id, name, snapshot, is_public, updated_at)
    values (v_user, p_name, coalesce(p_snapshot, '{}'::jsonb), p_public, now())
  on conflict (user_id) do update
    set name = excluded.name, snapshot = excluded.snapshot,
        is_public = excluded.is_public, updated_at = now();
  return jsonb_build_object('ok', true);
end $$;

notify pgrst, 'reload schema';
