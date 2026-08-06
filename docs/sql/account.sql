-- Account deletion.
--
-- App Store Guideline 5.1.1(v) requires any app that lets you CREATE an account to let
-- you delete it from inside the app. Yolkling has Sign in with Apple plus a server-side
-- social graph, so this is mandatory — its absence is a rejection, not a nice-to-have.
--
-- Almost everything cascades: inventory, redemptions, friendships, room_snapshots,
-- postcards, waves, visits and gifts all reference
-- app_users(apple_user_id) ON DELETE CASCADE, so removing the app_users row clears them.
--
-- The one exception is app_feedback, which carries a bare `user_id text` with no FK.
-- That row is DISASSOCIATED rather than dropped: the feedback itself is useful product
-- signal and contains no account data once the id is gone, which satisfies the
-- "delete my account and its data" requirement without destroying the signal.

create or replace function delete_account(p_user text)
returns jsonb language plpgsql security definer as $$
declare
  v_existed boolean;
begin
  select exists(select 1 from public.app_users where apple_user_id = p_user) into v_existed;

  -- Disassociate feedback (no FK, so it would otherwise be orphaned WITH the user id).
  update public.app_feedback set user_id = null where user_id = p_user;

  -- Everything else cascades from here.
  delete from public.app_users where apple_user_id = p_user;

  return jsonb_build_object('ok', true, 'existed', v_existed);
end $$;

grant execute on function delete_account(text) to anon, authenticated;

notify pgrst, 'reload schema';
