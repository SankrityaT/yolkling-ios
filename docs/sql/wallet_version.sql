-- ---------------------------------------------------------------------------
-- Wallet versioning: spending has to sync.
--
-- push_wallet took `greatest(coins, p_coins)`, so a purchase could never lower the
-- stored balance, and the client then adopted the server's higher number on the next
-- launch. Every purchase was refunded on relaunch: the shop was free, and a player's
-- real balance was whatever they had at their richest.
--
-- The `greatest` was not arbitrary -- gift_yolks credits coins server-side, and a blind
-- overwrite from a stale client destroyed a gift that had just landed. So the fix is not
-- "trust the client", it is "know whose number is newer": a version that both sides bump,
-- where the higher version wins. The client bumps on every local wallet change; gift_yolks
-- bumps when it credits. Coins move in both directions again, and a gift still survives.
--
-- Safe to run on a live database, and safe to re-run. The old 3-argument push_wallet is
-- left in place so app versions already in the wild keep working.
-- ---------------------------------------------------------------------------

alter table public.app_users
  add column if not exists wallet_version bigint not null default 0;

create or replace function wallet_state_v2(p_user text)
returns jsonb language sql security definer as $$
  select jsonb_build_object(
    'coins',   coalesce((select coins          from public.app_users where apple_user_id = p_user), 0),
    'version', coalesce((select wallet_version from public.app_users where apple_user_id = p_user), 0),
    'owned',   coalesce((select jsonb_agg(item_id) from public.inventory where user_id = p_user), '[]'::jsonb)
  );
$$;

create or replace function push_wallet_v2(p_user text, p_coins int, p_owned jsonb, p_version bigint)
returns jsonb language plpgsql security definer as $$
declare v_version bigint;
begin
  -- Identity guard, as in every other write: this sets a balance for p_user.
  perform public.assert_caller(p_user);
  perform ensure_app_user(p_user);

  -- `for update` so two devices pushing at once cannot both read the old version and
  -- decide they are the newer one.
  select wallet_version into v_version
    from public.app_users where apple_user_id = p_user for update;

  -- Strictly newer wins, in EITHER direction. An equal version means the same lineage
  -- (nothing changed since the client last read), so the server's number stands.
  if p_version > coalesce(v_version, 0) then
    update public.app_users
       set coins = greatest(0, p_coins), wallet_version = p_version
     where apple_user_id = p_user;
  end if;

  -- Inventory is add-only and unversioned: an item you own is a fact, and the server is
  -- never the reason one disappears.
  insert into public.inventory(user_id, item_id, source)
    select p_user, x.value, 'sync'
      from jsonb_array_elements_text(coalesce(p_owned, '[]'::jsonb)) as x(value)
    on conflict (user_id, item_id) do nothing;

  return wallet_state_v2(p_user);
end $$;

-- gift_yolks writes coins behind the client's back, so it has to bump the version too, or
-- the next push from either device would look newer and undo the gift. Copied verbatim
-- from social-living.sql (same amounts, same daily cap, same guards); the ONLY change is
-- `wallet_version = wallet_version + 1` on both updates.
create or replace function gift_yolks(p_from text, p_to text, p_amount int)
returns jsonb language plpgsql security definer as $$
declare v_today int; v_balance int;
begin
  perform public.assert_caller(p_from);

  if p_amount not in (10,20,50) then return jsonb_build_object('ok', false, 'reason', 'bad_amount'); end if;
  if not exists (select 1 from public.friendships where user_id = p_from and friend_id = p_to) then
    return jsonb_build_object('ok', false, 'reason', 'not_friends');
  end if;
  select coalesce(sum(amount),0) into v_today from public.gifts
    where from_id = p_from and created_at >= date_trunc('day', now());
  if v_today + p_amount > 100 then return jsonb_build_object('ok', false, 'reason', 'daily_cap'); end if;
  select coins into v_balance from public.app_users where apple_user_id = p_from for update;
  if coalesce(v_balance,0) < p_amount then return jsonb_build_object('ok', false, 'reason', 'insufficient'); end if;
  update public.app_users set coins = coins - p_amount, wallet_version = wallet_version + 1
    where apple_user_id = p_from;
  update public.app_users set coins = coins + p_amount, wallet_version = wallet_version + 1
    where apple_user_id = p_to;
  insert into public.gifts(from_id, to_id, amount) values (p_from, p_to, p_amount);
  select coins into v_balance from public.app_users where apple_user_id = p_from;
  return jsonb_build_object('ok', true, 'coins', v_balance);
end; $$;

grant execute on function wallet_state_v2(text)                    to anon, authenticated;
grant execute on function push_wallet_v2(text, int, jsonb, bigint) to anon, authenticated;
grant execute on function gift_yolks(text, text, int)              to anon, authenticated;

notify pgrst, 'reload schema';
