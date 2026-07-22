-- Yolkling: moderation + account deletion. Required for App Store review:
--   * Guideline 1.2  — user-generated content (postcards) needs block + report.
--   * Guideline 5.1.1(v) — an app with accounts must let users delete the account.
-- Additive + defensive. Run in the yolkling Supabase project SQL editor (or via the
-- Management API query endpoint with a PAT). Same auth model as social.sql: tables
-- are RLS-locked and the anon key can ONLY reach them through these SECURITY DEFINER
-- functions, keyed by the app's backendUserID (apple_user_id text).

-- 1) Blocks: a one-way record that hides content both ways at read time. Stored
--    per (blocker, blocked). We also drop any existing friendship immediately.
create table if not exists public.blocks (
  user_id    text not null references public.app_users(apple_user_id) on delete cascade,
  blocked_id text not null references public.app_users(apple_user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, blocked_id),
  check (user_id <> blocked_id)
);
create index if not exists idx_blocks_user on public.blocks(user_id);
alter table public.blocks enable row level security;

-- 2) Reports: an objectionable-content queue for review. Content-bearing so a human
--    (you) can act within 24h as the guideline requires.
create table if not exists public.content_reports (
  id          bigint generated always as identity primary key,
  reporter_id text not null,
  postcard_id bigint,
  reason      text,
  message     text,
  created_at  timestamptz not null default now(),
  handled     boolean not null default false
);
alter table public.content_reports enable row level security;

-- block_user: record the block, remove the mutual friendship, and delete any
-- postcards already exchanged in either direction so they vanish from both inboxes.
create or replace function block_user(p_user text, p_blocked text)
returns jsonb language plpgsql security definer as $$
begin
  if p_user = p_blocked then
    return jsonb_build_object('ok', false, 'reason', 'cannot block yourself');
  end if;
  insert into public.blocks(user_id, blocked_id) values (p_user, p_blocked)
    on conflict do nothing;
  delete from public.friendships
    where (user_id = p_user and friend_id = p_blocked)
       or (user_id = p_blocked and friend_id = p_user);
  delete from public.postcards
    where (from_id = p_blocked and to_id = p_user)
       or (from_id = p_user and to_id = p_blocked);
  return jsonb_build_object('ok', true);
end $$;

-- report_content: file a report for review. Captures the postcard text so it can be
-- assessed even if the sender later deletes it.
create or replace function report_content(p_user text, p_postcard bigint, p_reason text)
returns jsonb language plpgsql security definer as $$
declare v_msg text;
begin
  select message into v_msg from public.postcards where id = p_postcard;
  insert into public.content_reports(reporter_id, postcard_id, reason, message)
    values (p_user, p_postcard, coalesce(p_reason, 'objectionable'), v_msg);
  return jsonb_build_object('ok', true);
end $$;

-- delete_user: permanently erase the account and everything tied to it. The
-- app_users row cascades to friendships / room_snapshots / postcards / inventory /
-- redemptions / blocks via their ON DELETE CASCADE FKs; we also clear the reverse
-- direction rows that reference this user as a friend/recipient/blocked party.
create or replace function delete_user(p_user text)
returns jsonb language plpgsql security definer as $$
begin
  delete from public.friendships where friend_id = p_user;
  delete from public.postcards   where to_id = p_user or from_id = p_user;
  delete from public.blocks      where blocked_id = p_user or user_id = p_user;
  -- app_users delete cascades the rest (room_snapshots, inventory, redemptions, ...)
  delete from public.app_users where apple_user_id = p_user;
  return jsonb_build_object('ok', true);
end $$;

grant execute on function block_user(text, text)          to anon, authenticated;
grant execute on function report_content(text, bigint, text) to anon, authenticated;
grant execute on function delete_user(text)               to anon, authenticated;

-- Note: get_friends / get_postcards should additionally filter out rows where a
-- block exists in either direction. Add to those SELECTs in social.sql when
-- convenient (the block_user delete above already clears current content):
--   and not exists (select 1 from public.blocks b
--        where (b.user_id = p_user and b.blocked_id = f.friend_id)
--           or (b.user_id = f.friend_id and b.blocked_id = p_user))
