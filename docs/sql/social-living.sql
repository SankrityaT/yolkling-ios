-- Living Friends tab: waves, visits, gifts. All RPCs SECURITY DEFINER; tables not
-- directly client-selectable. Idempotent (if not exists / or replace).
create table if not exists public.waves (
  id bigint generated always as identity primary key,
  from_id text not null references public.app_users(apple_user_id) on delete cascade,
  to_id   text not null references public.app_users(apple_user_id) on delete cascade,
  created_at timestamptz not null default now(),
  seen_at timestamptz,
  check (from_id <> to_id)
);
create index if not exists waves_to_unseen on public.waves(to_id, seen_at);

create or replace function send_wave(p_from text, p_to text)
returns jsonb language plpgsql security definer as $$
begin
  if not exists (select 1 from public.friendships where user_id = p_from and friend_id = p_to) then
    return jsonb_build_object('ok', false, 'reason', 'not_friends');
  end if;
  delete from public.waves where from_id = p_from and to_id = p_to and seen_at is null;
  insert into public.waves(from_id, to_id) values (p_from, p_to);
  return jsonb_build_object('ok', true);
end; $$;

create or replace function get_waves(p_user text)
returns jsonb language plpgsql security definer as $$
declare v jsonb;
begin
  select coalesce(jsonb_agg(jsonb_build_object('from_id', w.from_id, 'name', rs.name,
           'created_at', w.created_at) order by w.created_at desc), '[]'::jsonb)
    into v
  from public.waves w
  left join public.room_snapshots rs on rs.user_id = w.from_id
  where w.to_id = p_user and w.seen_at is null;
  update public.waves set seen_at = now() where to_id = p_user and seen_at is null;
  return v;
end; $$;

create table if not exists public.visits (
  id bigint generated always as identity primary key,
  visitor_id text not null references public.app_users(apple_user_id) on delete cascade,
  owner_id   text not null references public.app_users(apple_user_id) on delete cascade,
  created_at timestamptz not null default now(),
  check (visitor_id <> owner_id)
);
create index if not exists visits_owner on public.visits(owner_id, created_at);

create or replace function log_visit(p_visitor text, p_owner text)
returns void language plpgsql security definer as $$
begin
  if exists (select 1 from public.visits where visitor_id = p_visitor and owner_id = p_owner
             and created_at >= date_trunc('day', now())) then
    return;
  end if;
  insert into public.visits(visitor_id, owner_id) values (p_visitor, p_owner);
end; $$;

create or replace function get_recent_visits(p_user text)
returns jsonb language sql security definer as $$
  select coalesce(jsonb_agg(j order by j->>'created_at' desc), '[]'::jsonb) from (
    select distinct on (v.visitor_id)
      jsonb_build_object('visitor_id', v.visitor_id, 'name', rs.name, 'created_at', v.created_at) as j
    from public.visits v
    left join public.room_snapshots rs on rs.user_id = v.visitor_id
    where v.owner_id = p_user and v.created_at >= now() - interval '7 days'
    order by v.visitor_id, v.created_at desc
  ) t;
$$;

create table if not exists public.gifts (
  id bigint generated always as identity primary key,
  from_id text not null references public.app_users(apple_user_id) on delete cascade,
  to_id   text not null references public.app_users(apple_user_id) on delete cascade,
  amount int not null,
  created_at timestamptz not null default now()
);
create index if not exists gifts_from on public.gifts(from_id, created_at);

create or replace function gift_yolks(p_from text, p_to text, p_amount int)
returns jsonb language plpgsql security definer as $$
declare v_today int; v_balance int;
begin
  if p_amount not in (10,20,50) then return jsonb_build_object('ok', false, 'reason', 'bad_amount'); end if;
  if not exists (select 1 from public.friendships where user_id = p_from and friend_id = p_to) then
    return jsonb_build_object('ok', false, 'reason', 'not_friends');
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
end; $$;

grant execute on function send_wave(text, text)         to anon, authenticated;
grant execute on function get_waves(text)               to anon, authenticated;
grant execute on function log_visit(text, text)         to anon, authenticated;
grant execute on function get_recent_visits(text)       to anon, authenticated;
grant execute on function gift_yolks(text, text, int)   to anon, authenticated;

notify pgrst, 'reload schema';
