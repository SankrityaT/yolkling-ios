-- Yolkling: server wallet (#11) — make the wallet durable + cross-device, keyed to
-- the Apple id. The server is the system of record once a player signs in; offline /
-- signed-out play stays fully local. Reuses app_users.coins + inventory (rewards.sql)
-- and ensure_app_user (social.sql). Last-write-wins on coins, union on inventory, so
-- a player's stuff follows them and never silently shrinks.
--
-- Note: this is state-sync, not an anti-cheat ledger. For a free, no-IAP earned
-- economy that's the right tradeoff; a validated grant/spend ledger can replace
-- push_wallet later without touching the client contract.

-- Current server view of a player's wallet.
create or replace function wallet_state(p_user text)
returns jsonb language sql security definer as $$
  select jsonb_build_object(
    'coins', coalesce((select coins from public.app_users where apple_user_id = p_user), 0),
    'owned', coalesce((select jsonb_agg(item_id) from public.inventory where user_id = p_user), '[]'::jsonb)
  );
$$;

-- Push the local wallet up; merge inventory (union) + adopt the coin balance; return
-- the reconciled authoritative state for the client to adopt.
create or replace function push_wallet(p_user text, p_coins int, p_owned jsonb)
returns jsonb language plpgsql security definer as $$
begin
  perform ensure_app_user(p_user);
  update public.app_users set coins = greatest(0, p_coins) where apple_user_id = p_user;
  insert into public.inventory(user_id, item_id, source)
    select p_user, x.value, 'sync'
    from jsonb_array_elements_text(coalesce(p_owned, '[]'::jsonb)) as x(value)
    on conflict (user_id, item_id) do nothing;
  return wallet_state(p_user);
end $$;

grant execute on function wallet_state(text)            to anon, authenticated;
grant execute on function push_wallet(text, int, jsonb) to anon, authenticated;

notify pgrst, 'reload schema';
