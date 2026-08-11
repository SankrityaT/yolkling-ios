-- Yolkling: social layer (#17) — friends, room snapshots (pet houses), postcards.
-- Additive + defensive. Run in the yolkling Supabase project SQL editor (or via the
-- Management API query endpoint with a PAT). Reuses public.app_users + its
-- referral_code as the shareable FRIEND CODE (no separate code system needed).
--
-- Auth model matches the rest of the app: tables are RLS-locked and the anon key
-- can ONLY reach them through these SECURITY DEFINER functions, keyed by the app's
-- backendUserID (Apple id once signed in, else the stable install id), stored in
-- app_users.apple_user_id as text. No global directory; you only see your friends.

-- Defensive: make sure a user row exists (mirrors ensure_user from referrals).
create or replace function ensure_app_user(p_user text)
returns text language plpgsql security definer as $$
declare v_code text;
begin
  insert into public.app_users(apple_user_id) values (p_user)
    on conflict (apple_user_id) do nothing;
  select referral_code into v_code from public.app_users where apple_user_id = p_user;
  return v_code;
end $$;

-- 1) Friendships: stored in BOTH directions for simple reads. Instant + mutual when
--    a code is redeemed (no request/accept dance in v1; a code is consent enough).
create table if not exists public.friendships (
  user_id    text not null references public.app_users(apple_user_id) on delete cascade,
  friend_id  text not null references public.app_users(apple_user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id <> friend_id)
);
create index if not exists idx_friendships_user on public.friendships(user_id);

-- 2) Room snapshots: the publishable look of your creature + room, so a friend can
--    VISIT (see your pet house). Opaque jsonb the client encodes/decodes; the server
--    never interprets it. name is denormalized for friend lists + postcard senders.
create table if not exists public.room_snapshots (
  user_id    text primary key references public.app_users(apple_user_id) on delete cascade,
  name       text,
  snapshot   jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- 3) Postcards / kind notes. The SENDER may earn a small reward (the warm-glow
--    faucet, see docs/REWARDS.md): server-enforced cap so it can't be farmed.
create table if not exists public.postcards (
  id         bigint generated always as identity primary key,
  from_id    text not null references public.app_users(apple_user_id) on delete cascade,
  to_id      text not null references public.app_users(apple_user_id) on delete cascade,
  message    text not null,
  reward     integer not null default 0,        -- Yolks credited to the SENDER (0 = none)
  created_at timestamptz not null default now(),
  read_at    timestamptz
);
create index if not exists idx_postcards_to on public.postcards(to_id, created_at desc);

-- 4) add_friend: redeem a friend's code (their referral_code) to become mutual
--    friends. Idempotent. Returns the friend's id + name.
create or replace function add_friend(p_user text, p_code text)
returns jsonb language plpgsql security definer as $$
declare v_friend text; v_name text;
begin
  perform ensure_app_user(p_user);
  select apple_user_id into v_friend from public.app_users
    where referral_code = upper(trim(p_code));
  if v_friend is null then
    return jsonb_build_object('ok', false, 'reason', 'invalid_code');
  end if;
  if v_friend = p_user then
    return jsonb_build_object('ok', false, 'reason', 'thats_you');
  end if;
  insert into public.friendships(user_id, friend_id) values (p_user, v_friend)
    on conflict do nothing;
  insert into public.friendships(user_id, friend_id) values (v_friend, p_user)
    on conflict do nothing;
  select name into v_name from public.room_snapshots where user_id = v_friend;
  return jsonb_build_object('ok', true, 'friend_id', v_friend, 'name', v_name);
end $$;

-- 5) get_friends: your friends + each one's published room snapshot.
create or replace function get_friends(p_user text)
returns jsonb language sql security definer as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'user_id', f.friend_id,
    'name',    rs.name,
    'snapshot', rs.snapshot,
    'updated_at', rs.updated_at
  ) order by rs.updated_at desc nulls last), '[]'::jsonb)
  from public.friendships f
  left join public.room_snapshots rs on rs.user_id = f.friend_id
  where f.user_id = p_user
    and not exists (
      select 1 from public.blocks b
      where (b.user_id = p_user and b.blocked_id = f.friend_id)
         or (b.user_id = f.friend_id and b.blocked_id = p_user));
$$;

-- 6) publish_room: upsert your own snapshot (called when your look/room changes).
create or replace function publish_room(p_user text, p_name text, p_snapshot jsonb)
returns void language plpgsql security definer as $$
begin
  perform ensure_app_user(p_user);
  insert into public.room_snapshots(user_id, name, snapshot, updated_at)
    values (p_user, p_name, coalesce(p_snapshot, '{}'::jsonb), now())
  on conflict (user_id) do update
    set name = excluded.name, snapshot = excluded.snapshot, updated_at = now();
end $$;

-- 7) send_postcard: a kind note to a friend. Sender-only reward, hard-capped server
--    side: at most 2 rewarded notes/day total, and at most 1 rewarded per friend/day.
create or replace function send_postcard(p_from text, p_to text, p_message text)
returns jsonb language plpgsql security definer as $$
declare v_reward int := 0; v_daily int; v_friend_today int; v_msg text;
begin
  if not exists (select 1 from public.friendships where user_id = p_from and friend_id = p_to) then
    return jsonb_build_object('ok', false, 'reason', 'not_friends');
  end if;
  v_msg := left(coalesce(trim(p_message), ''), 280);
  if length(v_msg) = 0 then
    return jsonb_build_object('ok', false, 'reason', 'empty');
  end if;

  select count(*) into v_daily from public.postcards
    where from_id = p_from and reward > 0 and created_at::date = current_date;
  select count(*) into v_friend_today from public.postcards
    where from_id = p_from and to_id = p_to and reward > 0 and created_at::date = current_date;
  if v_daily < 2 and v_friend_today = 0 then
    v_reward := 5;                      -- small on purpose; the kindness is the point
  end if;

  insert into public.postcards(from_id, to_id, message, reward)
    values (p_from, p_to, v_msg, v_reward);
  return jsonb_build_object('ok', true, 'reward', v_reward);
end $$;

-- 8) get_postcards: your inbox (received), newest first, with sender name.
create or replace function get_postcards(p_user text)
returns jsonb language sql security definer as $$
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
  limit 50;
$$;

-- 9) mark_postcards_read: flip unread → read for a user's inbox.
create or replace function mark_postcards_read(p_user text)
returns void language sql security definer as $$
  update public.postcards set read_at = now() where to_id = p_user and read_at is null;
$$;

-- 10) RLS: lock the tables; reach them only through the functions above.
alter table public.friendships    enable row level security;
alter table public.room_snapshots enable row level security;
alter table public.postcards      enable row level security;
-- (no policies = no direct anon access; SECURITY DEFINER functions bypass RLS)

grant execute on function ensure_app_user(text)              to anon, authenticated;
grant execute on function add_friend(text, text)             to anon, authenticated;
grant execute on function get_friends(text)                  to anon, authenticated;
grant execute on function publish_room(text, text, jsonb)    to anon, authenticated;
grant execute on function send_postcard(text, text, text)    to anon, authenticated;
grant execute on function get_postcards(text)                to anon, authenticated;
grant execute on function mark_postcards_read(text)          to anon, authenticated;

notify pgrst, 'reload schema';
