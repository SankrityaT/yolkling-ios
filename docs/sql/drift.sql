-- Drift: your yolkling wanders into a stranger's room.
--
-- WHY THIS EXISTS. The friend-visit system is a CLOSED loop: it needs you to have the
-- app, your friend to have the app, and the two of you connected. On launch day nobody
-- has friends here, so the core mechanic is inert until density builds — a cold-start
-- trap. Drift makes the mechanic work at a user base of two.
--
-- Deliberately NOT a feed, a profile system, or a follow graph. Once a day your creature
-- lands somewhere, you may leave one composed note, and that's it.

-- ---------------------------------------------------------------------------
-- 1. Rooms opt IN to being visited by strangers.
--
-- default false is load-bearing: retroactively exposing every room that has ever been
-- published is a privacy change you cannot make silently. Existing rooms stay private
-- until their owner opts in.
-- ---------------------------------------------------------------------------
alter table public.room_snapshots
  add column if not exists is_public boolean not null default false;

create index if not exists room_snapshots_public on public.room_snapshots(is_public) where is_public;

-- ---------------------------------------------------------------------------
-- 2. The vocabulary lives SERVER-SIDE.
--
-- The client composes postcards by selection rather than free text, which keeps the app
-- out of scope for App Store Guideline 1.2. But a client-side allowlist is not a
-- guarantee — anyone holding the anon key can call the RPC directly. This table is what
-- actually enforces it. Seeded from Core/Social/PostcardVocabulary.swift by script so
-- the two cannot drift apart.
-- ---------------------------------------------------------------------------
create table if not exists public.postcard_phrases (
  token    text primary key,
  text     text not null,
  category text not null
);

-- ---------------------------------------------------------------------------
-- 3. Where you've drifted. One landing per person per day.
-- ---------------------------------------------------------------------------
create table if not exists public.drifts (
  user_id   text not null references public.app_users(apple_user_id) on delete cascade,
  target_id text not null references public.app_users(apple_user_id) on delete cascade,
  day       date not null default current_date,
  primary key (user_id, target_id, day),
  check (user_id <> target_id)
);

-- ---------------------------------------------------------------------------
-- 4. Candidate rooms to drift into.
--
-- Excludes yourself, existing friends (they have the richer friend flow), anyone
-- blocked in EITHER direction, and anyone you already drifted to today.
-- order by random() is fine at this scale; revisit past ~100k public rooms.
-- ---------------------------------------------------------------------------
create or replace function get_drift(p_user text)
returns jsonb language plpgsql security definer as $$
declare v_rows jsonb;
begin
  perform ensure_app_user(p_user);
  select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) into v_rows from (
    select rs.user_id, rs.name, rs.snapshot
    from public.room_snapshots rs
    where rs.is_public
      and rs.user_id <> p_user
      and not exists (select 1 from public.friendships f
                       where f.user_id = p_user and f.friend_id = rs.user_id)
      and not exists (select 1 from public.blocks b
                       where (b.user_id = p_user   and b.blocked_id = rs.user_id)
                          or (b.user_id = rs.user_id and b.blocked_id = p_user))
      and not exists (select 1 from public.drifts d
                       where d.user_id = p_user and d.target_id = rs.user_id and d.day = current_date)
    order by random()
    limit 3
  ) x;
  return v_rows;
end $$;

-- Record that a drift happened. Capped at 3 landings a day so it stays a small ritual.
create or replace function log_drift(p_user text, p_target text)
returns jsonb language plpgsql security definer as $$
declare v_today int;
begin
  if p_user = p_target then
    return jsonb_build_object('ok', false, 'reason', 'thats_you');
  end if;
  select count(*) into v_today from public.drifts where user_id = p_user and day = current_date;
  if v_today >= 3 then
    return jsonb_build_object('ok', false, 'reason', 'drifted_enough');
  end if;
  insert into public.drifts(user_id, target_id) values (p_user, p_target)
    on conflict do nothing;
  return jsonb_build_object('ok', true);
end $$;

-- ---------------------------------------------------------------------------
-- 5. Postcards by TOKEN, validated server-side.
--
-- Supersedes send_postcard(p_message text), which accepted arbitrary text.
-- Strangers earn no Yolks and get one postcard a day: kindness to a stranger should be
-- worth doing for its own sake, and paying for it would just create a farming loop.
-- ---------------------------------------------------------------------------
create or replace function send_postcard_v2(p_from text, p_to text, p_token text)
returns jsonb language plpgsql security definer as $$
declare
  v_text     text;
  v_friend   boolean;
  v_reward   int := 0;
  v_today    int;
begin
  select text into v_text from public.postcard_phrases where token = p_token;
  if v_text is null then
    return jsonb_build_object('ok', false, 'reason', 'invalid_token');
  end if;

  if exists (select 1 from public.blocks
              where (user_id = p_to   and blocked_id = p_from)
                 or (user_id = p_from and blocked_id = p_to)) then
    return jsonb_build_object('ok', false, 'reason', 'blocked');
  end if;

  v_friend := exists (select 1 from public.friendships
                       where user_id = p_from and friend_id = p_to);

  if v_friend then
    -- Existing friend behaviour: a small reward, server-capped at 2 a day.
    select count(*) into v_today from public.postcards
      where from_id = p_from and reward > 0 and created_at::date = current_date;
    if v_today < 2 then v_reward := 5; end if;
  else
    -- Stranger: must have drifted there today, one postcard only, no reward.
    if not exists (select 1 from public.drifts
                    where user_id = p_from and target_id = p_to and day = current_date) then
      return jsonb_build_object('ok', false, 'reason', 'not_drifted');
    end if;
    if exists (select 1 from public.postcards
                where from_id = p_from and to_id = p_to and created_at::date = current_date) then
      return jsonb_build_object('ok', false, 'reason', 'already_sent');
    end if;
  end if;

  insert into public.postcards(from_id, to_id, message, reward)
    values (p_from, p_to, v_text, v_reward);

  if v_reward > 0 then
    update public.app_users set coins = coins + v_reward where apple_user_id = p_from;
  end if;

  return jsonb_build_object('ok', true, 'reward', v_reward);
end $$;

grant execute on function get_drift(text)                       to anon, authenticated;
grant execute on function log_drift(text, text)                 to anon, authenticated;
grant execute on function send_postcard_v2(text, text, text)    to anon, authenticated;

notify pgrst, 'reload schema';
insert into public.postcard_phrases(token, text, category) values
  ('w1', 'thinking of you', 'warmth'),
  ('w2', 'your room looks so cozy', 'warmth'),
  ('w3', 'glad you''re around', 'warmth'),
  ('w4', 'just came by to say hi', 'warmth'),
  ('w5', 'you crossed my mind today', 'warmth'),
  ('w6', 'sending a little sunshine', 'warmth'),
  ('w7', 'it''s nicer here with you in it', 'warmth'),
  ('w8', 'hope someone''s been kind to you', 'warmth'),
  ('w9', 'no reason, just wanted to wave', 'warmth'),
  ('w10', 'saved you a warm spot', 'warmth'),
  ('c1', 'you''ve got this', 'cheer'),
  ('c2', 'proud of you today', 'cheer'),
  ('c3', 'one small thing at a time', 'cheer'),
  ('c4', 'that was brave', 'cheer'),
  ('c5', 'look how far you''ve come', 'cheer'),
  ('c6', 'cheering from over here', 'cheer'),
  ('c7', 'you did the hard part already', 'cheer'),
  ('c8', 'keep going, gently', 'cheer'),
  ('c9', 'today counts too', 'cheer'),
  ('c10', 'worth it, promise', 'cheer'),
  ('m1', 'hope your day is gentle', 'comfort'),
  ('m2', 'rest is allowed', 'comfort'),
  ('m3', 'it''s okay to go slow', 'comfort'),
  ('m4', 'drink some water, love', 'comfort'),
  ('m5', 'the hard bit passes', 'comfort'),
  ('m6', 'you don''t have to do it all', 'comfort'),
  ('m7', 'go outside for a minute', 'comfort'),
  ('m8', 'sleep well tonight', 'comfort'),
  ('m9', 'nothing to fix, just breathe', 'comfort'),
  ('m10', 'put the phone down, it''ll keep', 'comfort'),
  ('s1', 'my yolk tracked mud in your room, sorry', 'silly'),
  ('s2', 'yours has excellent taste in hats', 'silly'),
  ('s3', 'we napped. it was productive.', 'silly'),
  ('s4', 'borrowed a snack. no regrets.', 'silly'),
  ('s5', 'your yolk is showing off again', 'silly'),
  ('s6', 'wobbled all the way here', 'silly'),
  ('s7', 'ten out of ten room, would visit again', 'silly'),
  ('s8', 'rolled over. that''s the whole update.', 'silly'),
  ('s9', 'came for the vibes, stayed too long', 'silly'),
  ('s10', 'left a tiny mess as a gift', 'silly')
on conflict (token) do update set text = excluded.text, category = excluded.category;
notify pgrst, 'reload schema';

-- ---------------------------------------------------------------------------
-- 6. publish_room gains an opt-in flag.
--
-- Overload rather than replace: the 3-arg form is kept so an older build in the wild
-- keeps working, and it preserves whatever is_public already is (COALESCE on the
-- existing row) instead of silently un-publishing a room on every sync.
-- ---------------------------------------------------------------------------
create or replace function publish_room(p_user text, p_name text, p_snapshot jsonb, p_public boolean)
returns void language plpgsql security definer as $$
begin
  perform ensure_app_user(p_user);
  insert into public.room_snapshots(user_id, name, snapshot, is_public, updated_at)
    values (p_user, p_name, coalesce(p_snapshot, '{}'::jsonb), coalesce(p_public, false), now())
  on conflict (user_id) do update
    set name = excluded.name, snapshot = excluded.snapshot,
        is_public = coalesce(p_public, public.room_snapshots.is_public), updated_at = now();
end $$;

grant execute on function publish_room(text, text, jsonb, boolean) to anon, authenticated;

notify pgrst, 'reload schema';

-- ---------------------------------------------------------------------------
-- 7. Letting strangers wave and gift.
--
-- One helper decides who may reach whom, so the rule lives in a single place rather
-- than being re-derived (differently, eventually) in each function. It also adds a
-- BLOCK CHECK that neither send_wave nor gift_yolks previously had — harmless while
-- everything required friendship, load-bearing the moment strangers can reach you.
-- ---------------------------------------------------------------------------
create or replace function can_reach(p_from text, p_to text)
returns text language plpgsql security definer as $$
begin
  if p_from = p_to then return 'self'; end if;
  if exists (select 1 from public.blocks
              where (user_id = p_to   and blocked_id = p_from)
                 or (user_id = p_from and blocked_id = p_to)) then
    return 'blocked';
  end if;
  if exists (select 1 from public.friendships
              where user_id = p_from and friend_id = p_to) then
    return 'friend';
  end if;
  if exists (select 1 from public.drifts
              where user_id = p_from and target_id = p_to and day = current_date) then
    return 'drifted';
  end if;
  return 'no';
end $$;

create or replace function send_wave(p_from text, p_to text)
returns jsonb language plpgsql security definer as $$
declare v_rel text; v_today int;
begin
  v_rel := can_reach(p_from, p_to);
  if v_rel in ('self','blocked') then return jsonb_build_object('ok', false, 'reason', v_rel); end if;
  if v_rel = 'no' then return jsonb_build_object('ok', false, 'reason', 'not_friends'); end if;

  if v_rel = 'drifted' then
    -- A wave carries no payload, so the only abuse vector is volume. Cap it.
    select count(*) into v_today from public.waves w
      where w.from_id = p_from and w.created_at >= date_trunc('day', now())
        and not exists (select 1 from public.friendships f
                         where f.user_id = p_from and f.friend_id = w.to_id);
    if v_today >= 3 then return jsonb_build_object('ok', false, 'reason', 'wave_cap'); end if;
  end if;

  delete from public.waves where from_id = p_from and to_id = p_to and seen_at is null;
  insert into public.waves(from_id, to_id) values (p_from, p_to);
  return jsonb_build_object('ok', true);
end $$;

create or replace function gift_yolks(p_from text, p_to text, p_amount integer)
returns jsonb language plpgsql security definer as $$
declare v_today int; v_balance int; v_rel text; v_stranger_today int;
begin
  v_rel := can_reach(p_from, p_to);
  if v_rel in ('self','blocked') then return jsonb_build_object('ok', false, 'reason', v_rel); end if;
  if v_rel = 'no' then return jsonb_build_object('ok', false, 'reason', 'not_friends'); end if;

  if v_rel = 'drifted' then
    -- Strangers: one small gift a day, fixed amount. The SENDER pays (as below), so an
    -- alt-account farm is net-negative rather than profitable — which is the whole
    -- reason gifting to strangers is safe to allow at all.
    if p_amount <> 10 then return jsonb_build_object('ok', false, 'reason', 'stranger_amount'); end if;
    select count(*) into v_stranger_today from public.gifts g
      where g.from_id = p_from and g.created_at >= date_trunc('day', now())
        and not exists (select 1 from public.friendships f
                         where f.user_id = p_from and f.friend_id = g.to_id);
    if v_stranger_today >= 1 then return jsonb_build_object('ok', false, 'reason', 'stranger_gift_cap'); end if;
  elsif p_amount not in (10,20,50) then
    return jsonb_build_object('ok', false, 'reason', 'bad_amount');
  end if;

  select coalesce(sum(amount),0) into v_today from public.gifts
    where from_id = p_from and created_at >= date_trunc('day', now());
  if v_today + p_amount > 100 then return jsonb_build_object('ok', false, 'reason', 'daily_cap'); end if;

  select coins into v_balance from public.app_users where apple_user_id = p_from for update;
  if coalesce(v_balance,0) < p_amount then return jsonb_build_object('ok', false, 'reason', 'insufficient'); end if;

  update public.app_users set coins = coins - p_amount where apple_user_id = p_from;
  update public.app_users set coins = coins + p_amount where apple_user_id = p_to;
  insert into public.gifts(from_id, to_id, amount) values (p_from, p_to, p_amount);

  select coins into v_balance from public.app_users where apple_user_id = p_from;
  return jsonb_build_object('ok', true, 'coins', v_balance);
end $$;

grant execute on function can_reach(text, text)            to anon, authenticated;
grant execute on function send_wave(text, text)            to anon, authenticated;
grant execute on function gift_yolks(text, text, integer)  to anon, authenticated;

notify pgrst, 'reload schema';
