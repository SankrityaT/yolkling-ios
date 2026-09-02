-- Cloud backup: "it can't truly die".
--
-- The landing page has promised this on the Plus tier since launch, and it wasn't built.
-- Rather than delete the claim, make it true — it's the one Plus perk with real stakes
-- behind it. Everything else you buy is expression; this is the thing that means a lost
-- phone doesn't cost you a creature you've raised for months.
--
-- Partial backup already existed and is deliberately NOT duplicated here:
--   coins + owned items  → app_users.coins + inventory  (push_wallet / wallet_state)
--   room snapshot        → room_snapshots               (publish_room)
--   founding species     → inventory                    (my_founding)
-- What was missing is the creature ITSELF — who it is, and everything it has lived
-- through. That's what this stores.
--
-- Keyed on the Sign in with Apple id. An anonymous InstallID is deliberately NOT good
-- enough: it's UserDefaults-backed and dies with the app, so backing up to it would be
-- a promise that quietly fails exactly when it's needed.

create table if not exists public.player_state (
  user_id     text primary key references public.app_users(apple_user_id) on delete cascade,
  state       jsonb not null,
  app_version text,
  updated_at  timestamptz not null default now()
);

-- Save. Last write wins, which is correct here: one person, their own devices, and the
-- alternative (merging two divergent creature states) has no sensible answer.
create or replace function push_player_state(p_user text, p_state jsonb, p_version text)
returns jsonb language plpgsql security definer as $$
begin
  -- Identity guard. Without it this definition is an unguarded twin of the
  -- enforced one in auth_enforce.sql, and re-running this file silently
  -- reopens the hole it closed. Injected so every file is safe to re-run and
  -- safe to apply in any order on a fresh database.
  perform public.assert_caller(p_user);

  perform ensure_app_user(p_user);
  insert into public.player_state(user_id, state, app_version, updated_at)
    values (p_user, coalesce(p_state, '{}'::jsonb), p_version, now())
  on conflict (user_id) do update
    set state = excluded.state, app_version = excluded.app_version, updated_at = now();
  return jsonb_build_object('ok', true);
end $$;

-- Restore. Returns null state when there's nothing saved, so a first-time signer-in is
-- distinguishable from a restore that found nothing — the client must NOT overwrite a
-- live creature with an empty one.
create or replace function pull_player_state(p_user text)
returns jsonb language plpgsql security definer as $$
declare v_state jsonb; v_at timestamptz;
begin
  -- Identity guard. Without it this definition is an unguarded twin of the
  -- enforced one in auth_enforce.sql, and re-running this file silently
  -- reopens the hole it closed. Injected so every file is safe to re-run and
  -- safe to apply in any order on a fresh database.
  perform public.assert_caller(p_user);

  select state, updated_at into v_state, v_at
    from public.player_state where user_id = p_user;
  if v_state is null then
    return jsonb_build_object('found', false);
  end if;
  return jsonb_build_object('found', true, 'state', v_state, 'updated_at', v_at);
end $$;

grant execute on function push_player_state(text, jsonb, text) to anon, authenticated;
grant execute on function pull_player_state(text)              to anon, authenticated;

notify pgrst, 'reload schema';
