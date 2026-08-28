-- The wander actually happens while you're away.
--
-- Until now it did not, and CLAIMS.md said so plainly: the drift rolled on app open, so
-- "while you were away" was true from the player's side but there was no background job.
-- The creature walking home (WanderHomeView) made the moment visible, but it still only
-- happened because you opened the app. This is what makes it a fact rather than a framing.
--
-- WHY IT IS GATED ON SELF-CARE, which is the good part.
--
-- The creature only goes out if you have been looking after yourself. Care for yourself →
-- your creature has a good day → it comes home with something. That is this app's whole
-- thesis expressed as a mechanic instead of a slogan, and it means the wander is EARNED
-- rather than a daily allowance that arrives whether or not you showed up.
--
-- It also cannot be farmed. The gate reads `lastCareDate` out of the backed-up player
-- state, which only moves on a real check-in or grow-by-living claim, at most once a day,
-- server-side. There is nothing to grind.
--
-- WHO IS ELIGIBLE. Signed-in players only, because `player_state` is keyed on the Apple id
-- and a signed-out player has no server-side record of having cared for themselves. They
-- keep the old behaviour (the roll happens on open), which is not a downgrade — it is
-- exactly what they have today.
--
-- Requires: pg_cron. Enable it once in the Supabase dashboard under Database → Extensions.

create extension if not exists pg_cron;

-- How recently you must have cared for yourself to earn a wander. Two days rather than one
-- so a single missed evening does not stop the creature going out — the whole app refuses
-- to punish a gap, and a wander that vanishes the moment you slip would be a streak
-- mechanic wearing a friendlier coat.
create or replace function drift_care_window() returns interval language sql immutable as $$
  select interval '2 days';
$$;

-- Roll one night's wanders for everyone who earned one.
--
-- Writes into the SAME `drifts` table the client already reads, with the same unique
-- (user_id, day) constraint, so a server roll and a client roll cannot both land — whoever
-- gets there first owns the day. That is why this needs no coordination with the app.
-- The daily ceiling, enforced by the schema rather than by hope.
--
-- This comment block used to claim `drifts` already had a unique (user_id, day)
-- constraint. It did not: the primary key is (user_id, target_id, day), so the same
-- player could hold several drifts on one day as long as the targets differed. Two
-- consequences, both silent:
--
--   1. `roll_nightly_drifts` failed OUTRIGHT. Its `on conflict (user_id, day)` had no
--      matching constraint to bind to, which is an error, not a no-op — so the nightly
--      job would have thrown at 04:00 every night and produced nothing, while cron.job
--      still showed it scheduled and active.
--   2. The "whoever gets there first owns the day" guarantee between the client roll and
--      the server roll did not hold, because nothing stopped both from landing.
--
-- One wander a day is a design invariant (see the daily-ceilings section in the plan),
-- so it belongs in the schema. Added as a unique INDEX rather than by altering the
-- primary key, which would need the existing key dropped and rebuilt for no gain.
create unique index if not exists drifts_one_per_day on public.drifts (user_id, day);

create or replace function roll_nightly_drifts()
returns int language plpgsql security definer as $$
declare v_count int := 0;
begin
  with eligible as (
    select ps.user_id
      from public.player_state ps
     where
       -- Cared for themselves recently. `lastCareDate` is written by the client's own
       -- care path and backed up; a missing or unparseable value simply means not
       -- eligible, which is the safe direction to fail.
       (ps.state ->> 'lastCareDate') is not null
       and (ps.state ->> 'lastCareDate')::timestamptz > now() - drift_care_window()
       -- Has not already wandered today, from either side.
       and not exists (
         select 1 from public.drifts d
          where d.user_id = ps.user_id and d.day = current_date
       )
  ),
  targets as (
    -- One public room each, excluding themselves, their friends, and anyone either party
    -- has blocked. Same rules as `get_drift`; a stranger you have blocked must not become
    -- a stranger your creature visits.
    select e.user_id,
           (select rs.user_id
              from public.room_snapshots rs
             where rs.is_public
               and rs.user_id <> e.user_id
               and not exists (select 1 from public.friendships f
                                where f.user_id = e.user_id and f.friend_id = rs.user_id)
               and not exists (select 1 from public.blocks b
                                where (b.user_id = e.user_id and b.blocked_id = rs.user_id)
                                   or (b.user_id = rs.user_id and b.blocked_id = e.user_id))
             order by random()
             limit 1) as target_id
      from eligible e
  )
  insert into public.drifts(user_id, target_id, day)
  select t.user_id, t.target_id, current_date
    from targets t
   where t.target_id is not null
  on conflict (user_id, day) do nothing;

  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- 04:00 UTC. Deliberately not midnight: the point is for it to have already happened by
-- the time anyone opens the app in the morning, and a job that fires exactly at a date
-- boundary races the `current_date` it depends on.
select cron.schedule(
  'yolkling-nightly-drift',
  '0 4 * * *',
  $$ select public.roll_nightly_drifts(); $$
);

grant execute on function roll_nightly_drifts() to service_role;
grant execute on function drift_care_window()   to anon, authenticated;

notify pgrst, 'reload schema';
