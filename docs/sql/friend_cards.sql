-- What your friends have found.
--
-- `get_friends` returned a room snapshot per friend, which is enough to stand in their
-- room and enough to render them, but not enough to know what they COLLECT. Now that cards
-- exist that is the missing half: you cannot want what someone has if you cannot see what
-- they have, and trading only means something once you can.
--
-- WHAT IS DELIBERATELY NOT RETURNED HERE.
--
-- The bond card's finish comes from `trust`, and trust is the most personal number in this
-- app: it is a reading of how someone has been treating themselves, it decays when they
-- stop, and it moves at most once a day. Publishing "trust 34%" to their friends would
-- turn a private thing into a scoreboard, and the app would deserve everything it got.
--
-- So friends see the MATERIAL and never the number. The finish is beautiful and it says
-- "they have been showing up", which is the whole compliment; the percentage is nobody's
-- business. Same for the care stats — days, focus minutes, streak. None of them cross.
--
-- `trust_band` is the one derived value that does, and only because it is already public
-- in another form: it is the same five-way split that produces the line under the creature
-- in their room ("warming up to you", "your companion"), which friends can already read.
-- Returning the band rather than the value means a friend's card can wear the right
-- laminate without anyone learning a figure about them.

-- Which species a player has found, from their backed-up state.
--
-- Reads `player_state` rather than adding a column, because the Dex already lives in the
-- creature snapshot and a second copy would be a second thing to keep in step.
create or replace function friend_collection(p_user text)
returns jsonb language sql security definer stable as $$
  select coalesce(ps.state -> 'discoveredSpeciesIDs', '[]'::jsonb)
    from public.player_state ps
   where ps.user_id = p_user;
$$;

-- The five-way trust band, matching TrustStage. Never the raw number.
create or replace function trust_band(p_trust double precision)
returns text language sql immutable as $$
  select case
    when p_trust is null  then 'stranger'
    when p_trust < 0.2    then 'stranger'
    when p_trust < 0.45   then 'warming'
    when p_trust < 0.7    then 'friend'
    when p_trust < 0.9    then 'companion'
    else 'devoted'
  end;
$$;

-- Friends, their rooms, AND their collections.
--
-- Replaces the version in social.sql. Kept as a separate file rather than edited in place
-- for the same reason `is_tradeable` moved: re-running the older file to pick up an
-- unrelated change would silently drop the new columns, and a missing field is a much
-- quieter failure than a missing function.
create or replace function get_friends(p_user text)
returns jsonb language sql security definer as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'user_id',    f.friend_id,
    'name',       rs.name,
    'snapshot',   rs.snapshot,
    'updated_at', rs.updated_at,
    'found',      public.friend_collection(f.friend_id),
    'trust_band', public.trust_band((ps.state ->> 'trust')::double precision)
  ) order by rs.updated_at desc nulls last), '[]'::jsonb)
  from public.friendships f
  left join public.room_snapshots rs on rs.user_id = f.friend_id
  left join public.player_state   ps on ps.user_id = f.friend_id
  where f.user_id = p_user;
$$;

grant execute on function friend_collection(text)            to anon, authenticated;
grant execute on function trust_band(double precision)       to anon, authenticated;
grant execute on function get_friends(text)                  to anon, authenticated;

notify pgrst, 'reload schema';
