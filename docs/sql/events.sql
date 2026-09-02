-- Seasons: a time-boxed window during which a species set is in bloom.
--
-- WHY THIS EXISTS. Nothing in the app currently gives anyone a reason to subscribe
-- TODAY. A supporter glow and a Yolks stipend are "nice, eventually" — there's no clock.
-- A season is the only honest urgency available to an app that refuses guilt mechanics:
-- you can MISS a season, but nothing is ever taken from you (docs/MONETIZATION.md,
-- "honest scarcity" — limited must be real, time-bound and clearly explained).
--
-- The art ships INSIDE the app binary; only the window and the grants live here. That's
-- the constraint, stated plainly: all content is compiled-in Swift rendered by large
-- switch statements, so a season cannot introduce new artwork without a release. What it
-- CAN do is open and close on a server date — which is enough to run a live season
-- during judging without shipping a build.

create table if not exists public.events (
  id                   text primary key,          -- 'spring-bloom-2026'
  kind                 text not null,             -- species_set | cosmetic_drop | room_theme
  payload_id           text not null,             -- an id the client already compiles in
  title                text not null,
  blurb                text not null default '',
  starts_at            timestamptz not null,
  ends_at              timestamptz not null,
  requires_entitlement text,                      -- null = free | 'plus'
  grant_on_join        text[] not null default '{}',
  check (ends_at > starts_at)
);

create index if not exists events_window on public.events(starts_at, ends_at);

-- Who has joined what, so a grant is handed out exactly once.
create table if not exists public.event_joins (
  user_id  text not null references public.app_users(apple_user_id) on delete cascade,
  event_id text not null references public.events(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (user_id, event_id)
);

-- Everything running right now, with whether this player has joined it.
create or replace function active_events(p_user text)
returns jsonb language plpgsql security definer as $$
declare v jsonb;
begin
  select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) into v from (
    select e.id, e.kind, e.payload_id, e.title, e.blurb,
           e.starts_at, e.ends_at, e.requires_entitlement,
           exists(select 1 from public.event_joins j
                   where j.user_id = p_user and j.event_id = e.id) as joined
    from public.events e
    where now() >= e.starts_at and now() < e.ends_at
    order by e.ends_at
  ) x;
  return v;
end $$;

-- Join a running season. Reuses the grant_founding / inventory pattern verbatim: an
-- insert-on-conflict into inventory, so a grant is idempotent and a double-tap is free.
create or replace function join_event(p_user text, p_event text)
returns jsonb language plpgsql security definer as $$
declare v_grants text[]; v_ok boolean;
begin
  -- Identity guard. join_event writes rows into public.inventory, so a spoofed
  -- p_user mints season cosmetics into somebody else's account. The only
  -- definition lives here, so this file is the only place that can enforce it.
  perform public.assert_caller(p_user);

  perform ensure_app_user(p_user);

  select true, grant_on_join into v_ok, v_grants
    from public.events
   where id = p_event and now() >= starts_at and now() < ends_at;

  if v_ok is not true then
    return jsonb_build_object('ok', false, 'reason', 'not_running');
  end if;

  insert into public.event_joins(user_id, event_id) values (p_user, p_event)
    on conflict do nothing;

  if array_length(v_grants, 1) is not null then
    insert into public.inventory(user_id, item_id, source)
      select p_user, g, 'event' from unnest(v_grants) g
      on conflict (user_id, item_id) do nothing;
  end if;

  return jsonb_build_object('ok', true, 'granted', coalesce(v_grants, '{}'));
end $$;

grant execute on function active_events(text)       to anon, authenticated;
grant execute on function join_event(text, text)    to anon, authenticated;

notify pgrst, 'reload schema';
