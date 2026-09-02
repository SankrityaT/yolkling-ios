-- Yolkling: in-app feedback. Kept separate from the landing page's `feedback`
-- (contact form). A write-only channel from the app: RLS-locked so the anon key
-- can only INSERT through the SECURITY DEFINER function, never read.

create table if not exists public.app_feedback (
  id          bigint generated always as identity primary key,
  user_id     text,
  kind        text not null default 'other',   -- idea | bug | love | other
  message     text not null,
  app_version text,
  created_at  timestamptz not null default now()
);

alter table public.app_feedback enable row level security;  -- no policies: only the function writes

create or replace function submit_feedback(p_user text, p_kind text, p_message text, p_version text default null)
returns jsonb language plpgsql security definer as $$
begin
  -- Identity guard: writes a feedback row attributed to p_user, so an unguarded actor is impersonation.
  perform public.assert_caller(p_user);

  if length(coalesce(trim(p_message), '')) < 1 then
    return jsonb_build_object('ok', false, 'reason', 'empty');
  end if;
  insert into public.app_feedback(user_id, kind, message, app_version)
  values (nullif(p_user, ''), coalesce(nullif(p_kind, ''), 'other'), left(p_message, 4000), p_version);
  return jsonb_build_object('ok', true);
end $$;

grant execute on function submit_feedback(text, text, text, text) to anon, authenticated;
notify pgrst, 'reload schema';
