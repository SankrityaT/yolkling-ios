-- Trading: swap a cosmetic you have for one you don't.
--
-- WHY IT'S SAFE HERE, which is not obvious. Cosmetic ownership is a SET, not a count —
-- you either own a hat or you don't, and a second copy is worth nothing. So there is no
-- stockpiling, and funnelling items through alt accounts gains you items you could have
-- bought anyway. The only genuinely scarce things are the grant-only seasonal items, and
-- an alt can't get those either without having been there while the season ran. Trading
-- moves scarce items around; it cannot manufacture them.
--
-- WHAT'S DELIBERATELY EXCLUDED:
--   * Founding species. Those are granted for bringing someone in — personal, and
--     trading them would turn a thank-you into a commodity.
--   * Strangers. Offers only travel between friends, which removes the entire class of
--     "random stranger sends a deceptive offer".
--   * Gifts. Every trade is a SWAP; nothing moves one-way. A one-way transfer would be
--     the one shape that lets an alt farm seasonal items.

create table if not exists public.trade_offers (
  id         bigint generated always as identity primary key,
  from_id    text not null references public.app_users(apple_user_id) on delete cascade,
  to_id      text not null references public.app_users(apple_user_id) on delete cascade,
  offer_item text not null,
  want_item  text not null,
  status     text not null default 'pending',   -- pending | accepted | declined | cancelled | expired
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '3 days',
  check (from_id <> to_id),
  check (offer_item <> want_item)
);

create index if not exists trade_offers_to   on public.trade_offers(to_id, status);
create index if not exists trade_offers_from on public.trade_offers(from_id, status);

-- `is_tradeable` is DEFINED IN tradeable_items.sql, not here.
--
-- It used to live here as `p_item not like 'founding-%'`, and that blocklist was the
-- bug: `inventory` also holds colour swatches, room themes and decor, so everything
-- except founding species was tradeable by default — including the colour of your
-- creature's face. See tradeable_items.sql for the full reasoning.
--
-- The definition was moved rather than fixed in place on purpose. Left here as a
-- `create or replace`, re-running this file to pick up any other change would silently
-- reinstate the blocklist and reopen the hole. Apply tradeable_items.sql after this one.

create or replace function propose_trade(p_from text, p_to text, p_offer text, p_want text)
returns jsonb language plpgsql security definer as $$
declare v_pending int;
begin
  if p_from = p_to then return jsonb_build_object('ok', false, 'reason', 'thats_you'); end if;
  if p_offer = p_want then return jsonb_build_object('ok', false, 'reason', 'same_item'); end if;

  if not is_tradeable(p_offer) or not is_tradeable(p_want) then
    return jsonb_build_object('ok', false, 'reason', 'not_tradeable');
  end if;

  -- Friends only. A stranger offer is a scam surface with no upside.
  if not exists (select 1 from public.friendships
                  where user_id = p_from and friend_id = p_to) then
    return jsonb_build_object('ok', false, 'reason', 'not_friends');
  end if;

  if exists (select 1 from public.blocks
              where (user_id = p_to and blocked_id = p_from)
                 or (user_id = p_from and blocked_id = p_to)) then
    return jsonb_build_object('ok', false, 'reason', 'blocked');
  end if;

  -- Both sides must actually hold their half, right now.
  if not exists (select 1 from public.inventory where user_id = p_from and item_id = p_offer) then
    return jsonb_build_object('ok', false, 'reason', 'you_dont_own_that');
  end if;
  if not exists (select 1 from public.inventory where user_id = p_to and item_id = p_want) then
    return jsonb_build_object('ok', false, 'reason', 'they_dont_own_that');
  end if;
  -- No point trading for something you already have.
  if exists (select 1 from public.inventory where user_id = p_from and item_id = p_want) then
    return jsonb_build_object('ok', false, 'reason', 'already_have');
  end if;

  select count(*) into v_pending from public.trade_offers
    where from_id = p_from and status = 'pending' and expires_at > now();
  if v_pending >= 5 then
    return jsonb_build_object('ok', false, 'reason', 'too_many_pending');
  end if;

  if exists (select 1 from public.trade_offers
              where from_id = p_from and to_id = p_to and offer_item = p_offer
                and want_item = p_want and status = 'pending' and expires_at > now()) then
    return jsonb_build_object('ok', false, 'reason', 'already_offered');
  end if;

  insert into public.trade_offers(from_id, to_id, offer_item, want_item)
    values (p_from, p_to, p_offer, p_want);
  return jsonb_build_object('ok', true);
end $$;

-- Accept or decline. The swap is one statement per side inside the function, so a
-- failure part-way can't leave one person holding both halves.
create or replace function respond_trade(p_user text, p_trade bigint, p_accept boolean)
returns jsonb language plpgsql security definer as $$
declare t record;
begin
  select * into t from public.trade_offers where id = p_trade for update;
  if t is null then return jsonb_build_object('ok', false, 'reason', 'gone'); end if;
  if t.to_id <> p_user then return jsonb_build_object('ok', false, 'reason', 'not_yours'); end if;
  if t.status <> 'pending' then return jsonb_build_object('ok', false, 'reason', 'already_'||t.status); end if;
  if t.expires_at <= now() then
    update public.trade_offers set status = 'expired' where id = p_trade;
    return jsonb_build_object('ok', false, 'reason', 'expired');
  end if;

  if not p_accept then
    update public.trade_offers set status = 'declined' where id = p_trade;
    return jsonb_build_object('ok', true, 'accepted', false);
  end if;

  -- Re-check TRADEABILITY at accept time, not only at propose time. What may be traded
  -- is a rule that changes (see tradeable_items.sql, which turned a blocklist into an
  -- allowlist), and an offer made under the old rule is still sitting here `pending`.
  -- Letting one land would move a colour swatch or a room theme out of inventory while
  -- Player.colorHex / Player.roomThemeID kept rendering it — a divergence nothing can
  -- repair.
  if not is_tradeable(t.offer_item) or not is_tradeable(t.want_item) then
    update public.trade_offers set status = 'expired' where id = p_trade;
    return jsonb_build_object('ok', false, 'reason', 'not_tradeable');
  end if;

  -- Re-check ownership at ACCEPT time. Either side may have traded their half away
  -- since the offer was made, and an offer is a promise about a moment, not forever.
  if not exists (select 1 from public.inventory where user_id = t.from_id and item_id = t.offer_item)
     or not exists (select 1 from public.inventory where user_id = t.to_id and item_id = t.want_item) then
    update public.trade_offers set status = 'expired' where id = p_trade;
    return jsonb_build_object('ok', false, 'reason', 'no_longer_held');
  end if;

  -- Swap.
  delete from public.inventory where user_id = t.from_id and item_id = t.offer_item;
  delete from public.inventory where user_id = t.to_id   and item_id = t.want_item;
  insert into public.inventory(user_id, item_id, source)
    values (t.from_id, t.want_item, 'trade'), (t.to_id, t.offer_item, 'trade')
    on conflict (user_id, item_id) do nothing;

  update public.trade_offers set status = 'accepted' where id = p_trade;

  -- Any other pending offer involving either item is now unfulfillable.
  update public.trade_offers set status = 'expired'
   where status = 'pending'
     and ((from_id = t.from_id and offer_item = t.offer_item)
       or (from_id = t.to_id   and offer_item = t.want_item));

  return jsonb_build_object('ok', true, 'accepted', true,
                            'got', t.offer_item, 'gave', t.want_item);
end $$;

create or replace function my_trades(p_user text)
returns jsonb language plpgsql security definer as $$
declare v jsonb;
begin
  select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) into v from (
    select o.id, o.from_id, o.to_id, o.offer_item, o.want_item, o.status, o.expires_at,
           (o.to_id = p_user) as incoming,
           -- app_users has no name column; the display name lives on the published room.
           coalesce(rs.name, 'a friend') as other_name
    from public.trade_offers o
    left join public.room_snapshots rs
      on rs.user_id = case when o.to_id = p_user then o.from_id else o.to_id end
    where (o.from_id = p_user or o.to_id = p_user)
      and o.status = 'pending' and o.expires_at > now()
    order by o.created_at desc
  ) x;
  return v;
end $$;

grant execute on function is_tradeable(text)                          to anon, authenticated;
grant execute on function propose_trade(text, text, text, text)       to anon, authenticated;
grant execute on function respond_trade(text, bigint, boolean)        to anon, authenticated;
grant execute on function my_trades(text)                             to anon, authenticated;

notify pgrst, 'reload schema';

-- What the two of you could actually swap.
--
-- Without this the UI would be a guessing game: you'd offer something they already have,
-- or ask for something they don't own, and only find out when the server said no. This
-- returns each side's tradeable items that the OTHER side lacks — i.e. exactly the set
-- of offers that can succeed.
create or replace function tradeable_between(p_user text, p_other text)
returns jsonb language plpgsql security definer as $$
declare v_mine jsonb; v_theirs jsonb;
begin
  select coalesce(jsonb_agg(item_id), '[]'::jsonb) into v_mine
    from public.inventory i
   where i.user_id = p_user
     and is_tradeable(i.item_id)
     and not exists (select 1 from public.inventory j
                      where j.user_id = p_other and j.item_id = i.item_id);

  select coalesce(jsonb_agg(item_id), '[]'::jsonb) into v_theirs
    from public.inventory i
   where i.user_id = p_other
     and is_tradeable(i.item_id)
     and not exists (select 1 from public.inventory j
                      where j.user_id = p_user and j.item_id = i.item_id);

  return jsonb_build_object('mine', v_mine, 'theirs', v_theirs);
end $$;

grant execute on function tradeable_between(text, text) to anon, authenticated;

notify pgrst, 'reload schema';
