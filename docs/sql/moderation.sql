-- Blocking + reporting.
--
-- IMPORTANT: this file DOCUMENTS WHAT IS ALREADY DEPLOYED. These tables and functions
-- existed on the live database but had no record anywhere in this repo, which meant
-- `docs/sql/` — the supposed source of truth — was lying, and a fresh environment
-- rebuilt from it would silently lack moderation. Anyone planning social work would
-- also have duplicated it. Captured here from the live definitions.
--
-- Why it matters beyond tidiness: App Store Guideline 1.2 requires a way to block
-- abusive users and report objectionable content for any app with user-to-user
-- content. The SERVER side of that is already done. The gap is client UI — nothing in
-- the app calls block_user or report_content today.

create table if not exists public.blocks (
  user_id    text not null references public.app_users(apple_user_id) on delete cascade,
  blocked_id text not null references public.app_users(apple_user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, blocked_id)
);

create table if not exists public.content_reports (
  id          bigint generated always as identity primary key,
  reporter_id text not null,
  postcard_id bigint,
  reason      text not null default 'objectionable',
  message     text,               -- snapshot of the reported text at report time
  created_at  timestamptz not null default now(),
  handled     boolean not null default false
);
-- NOTE: content_reports deliberately has NO foreign key on reporter_id. Reports must
-- outlive the accounts involved, so a moderation record survives account deletion.

-- Block someone: record it, and sever the existing relationship both ways.
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

-- Report a postcard. Snapshots the message so the evidence survives deletion.
create or replace function report_content(p_user text, p_postcard bigint, p_reason text)
returns jsonb language plpgsql security definer as $$
declare v_msg text;
begin
  select message into v_msg from public.postcards where id = p_postcard;
  insert into public.content_reports(reporter_id, postcard_id, reason, message)
    values (p_user, p_postcard, coalesce(p_reason, 'objectionable'), v_msg);
  return jsonb_build_object('ok', true);
end $$;

grant execute on function block_user(text, text)            to anon, authenticated;
grant execute on function report_content(text, bigint, text) to anon, authenticated;

notify pgrst, 'reload schema';

-- ---------------------------------------------------------------------------
-- LEGACY: public.delete_user(p_user)
--
-- A second account-deletion function that predates docs/sql/account.sql. It is
-- SUPERSEDED by delete_account and should not be called.
--
-- Its explicit deletes from friendships / postcards / blocks are redundant — every one
-- of those columns is already ON DELETE CASCADE from app_users (verified against the
-- live schema). It also never touches app_feedback, which has no FK, so it ORPHANS
-- feedback rows carrying the deleted user's id. delete_account disassociates them
-- instead. Left in place rather than dropped, in case something still calls it.
-- ---------------------------------------------------------------------------
