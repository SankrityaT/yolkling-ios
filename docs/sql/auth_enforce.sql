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
