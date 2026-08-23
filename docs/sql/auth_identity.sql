-- Verified identity for backend calls.
--
-- THE VULNERABILITY THIS CLOSES
--
-- Every SECURITY DEFINER function took the caller's id as a plain text parameter
-- (`p_user`), and the client authenticated with the anon key, which ships inside the app
-- binary and can be pulled out of an IPA in about a minute. The database therefore had no
-- way to know who was calling: the identity was simply asserted by whoever sent the
-- request. Demonstrated on the live project by calling wallet_state with another user's
-- id and reading their inventory back, using nothing but the public key.
--
-- The ids were not secret either. get_friends returns `user_id` for every friend and
-- get_drift hands out strangers' ids by design, so ordinary use of the app supplies a
-- steady stream of valid targets. That made 30 functions reachable as anybody:
-- push_wallet to alter someone's inventory, send_postcard to post as them, respond_trade
-- to accept on their behalf, and delete_account to irreversibly destroy their creature.
--
-- THE FIX
--
-- The client now trades its Apple identity token for a real Supabase session and sends
-- that user's JWT. `auth.uid()` is therefore trustworthy, and these helpers turn it into
-- the Apple user id every table is already keyed on, so no data has to be re-keyed.
--
-- Any client-side check would have been irrelevant here: the attack never used our
-- client. Only the server can fix this.

-- The Apple `sub` for the current caller, or null when the request is not authenticated.
--
-- Resolved through auth.identities rather than a column we maintain, so it cannot drift
-- out of sync with the actual session.
create or replace function public.current_apple_user()
returns text
language sql
stable
security definer
set search_path = public, auth
as $$
  select i.provider_id
    from auth.identities i
   where i.user_id = auth.uid()
     and i.provider = 'apple'
   limit 1;
$$;

-- Assert the caller really is who they claim to be.
--
-- Raises rather than returning false: every caller of this is about to read or write
-- somebody's data, and a guard that can be ignored by not checking its result is not a
-- guard. An exception cannot be accidentally dropped.
create or replace function public.assert_caller(p_user text)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_caller text;
begin
  v_caller := public.current_apple_user();

  if v_caller is null then
    raise exception 'not authenticated'
      using hint = 'sign in with apple, this endpoint needs a user session';
  end if;

  if v_caller is distinct from p_user then
    -- Deliberately does not echo either id back. An error message that confirms
    -- whether a guessed id exists is an enumeration oracle.
    raise exception 'not your account';
  end if;
end $$;

grant execute on function public.current_apple_user() to anon, authenticated;
grant execute on function public.assert_caller(text)  to anon, authenticated;

notify pgrst, 'reload schema';
