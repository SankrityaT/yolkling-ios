-- Yolkling: rewards + referrals migration
-- Run in the yolkling Supabase project SQL editor. Additive + defensive.
-- Adjust types/keys to your actual `waitlist` table and your Sign in with Apple
-- auth setup (see the RLS note at the bottom). Bonus amounts are placeholders to confirm.

-- 1) Short code generator, e.g. YOLK-7K2P
create or replace function gen_yolk_code() returns text language sql volatile as $$
  select 'YOLK-' || upper(substr(md5(gen_random_uuid()::text), 1, 5));
$$;

-- 2) Waitlist: referral code + early-bird flag + claim tracking
alter table public.waitlist add column if not exists referral_code text unique;
alter table public.waitlist add column if not exists is_early boolean not null default true;  -- everyone pre-launch counts as early
alter table public.waitlist add column if not exists claimed_by text;          -- apple user id that claimed it
alter table public.waitlist add column if not exists claimed_at timestamptz;

update public.waitlist set referral_code = gen_yolk_code() where referral_code is null;

create or replace function waitlist_set_code() returns trigger language plpgsql as $$
begin
  if new.referral_code is null then new.referral_code := gen_yolk_code(); end if;
  return new;
end $$;
drop trigger if exists trg_waitlist_code on public.waitlist;
create trigger trg_waitlist_code before insert on public.waitlist
  for each row execute function waitlist_set_code();

-- 3) App users (keyed by Sign in with Apple stable id)
create table if not exists public.app_users (
  apple_user_id text primary key,
  referral_code text unique not null default gen_yolk_code(),  -- theirs to share
  referred_by   text references public.app_users(referral_code),
  coins         integer not null default 100,                  -- welcome grant
  created_at    timestamptz not null default now()
);

-- 4) Inventory (owned cosmetics)
create table if not exists public.inventory (
  id         bigint generated always as identity primary key,
  user_id    text not null references public.app_users(apple_user_id) on delete cascade,
  item_id    text not null,
  source     text not null default 'purchase',   -- waitlist | referral | purchase | gift
  granted_at timestamptz not null default now(),
  unique (user_id, item_id)
);

-- 5) Redemptions: at most one code redeemed per user
create table if not exists public.redemptions (
  code        text not null,
  redeemed_by text not null references public.app_users(apple_user_id) on delete cascade,
  redeemed_at timestamptz not null default now(),
  primary key (redeemed_by)
);

-- 6) Redeem: a founder (waitlist) code grants the early-bird bonus;
--    another user's referral code credits both sides. One redeem per user.
create or replace function redeem_code(p_code text, p_user text)
returns jsonb language plpgsql security definer as $$
declare v_referrer text; v_bonus int := 0; v_kind text;
begin
  -- Identity guard. redeem_code credits coins to p_user, so a spoofed p_user redeems
  -- into any account. This file is applied AFTER founding_grant.sql and re-creates the
  -- function, so the guard has to exist in both copies or a full deploy reopens the hole.
  perform public.assert_caller(p_user);

  if exists (select 1 from public.redemptions where redeemed_by = p_user) then
    return jsonb_build_object('ok', false, 'reason', 'already_redeemed');
  end if;

  if exists (select 1 from public.waitlist where referral_code = p_code and claimed_by is null) then
    update public.waitlist set claimed_by = p_user, claimed_at = now() where referral_code = p_code;
    v_bonus := 250; v_kind := 'early_bird';                    -- TUNE: early-bird bonus
  elsif exists (select 1 from public.app_users where referral_code = p_code and apple_user_id <> p_user) then
    select apple_user_id into v_referrer from public.app_users where referral_code = p_code;
    update public.app_users set referred_by = p_code where apple_user_id = p_user and referred_by is null;
    update public.app_users set coins = coins + 100 where apple_user_id = v_referrer;   -- TUNE: referrer reward
    v_bonus := 100; v_kind := 'referral';                      -- TUNE: new-user referral bonus
  else
    return jsonb_build_object('ok', false, 'reason', 'invalid_or_used');
  end if;

  update public.app_users set coins = coins + v_bonus where apple_user_id = p_user;
  insert into public.redemptions(code, redeemed_by) values (p_code, p_user);
  return jsonb_build_object('ok', true, 'kind', v_kind, 'bonus', v_bonus);
end $$;

-- 7) RLS
alter table public.app_users   enable row level security;
alter table public.inventory   enable row level security;
alter table public.redemptions enable row level security;

-- NOTE on auth keying: if you connect Sign in with Apple via Supabase Auth's Apple provider,
-- auth.uid() is a Supabase UUID, not the raw Apple id. Either (a) key app_users on that UUID
-- instead of apple_user_id text, or (b) store the mapping and call redeem_code from a trusted
-- edge function with the service role. The policies below assume option (a)-style equality;
-- adjust to your setup.
-- create policy has no "if not exists", so re-running this file errors with 42710 and
-- aborts everything below it. Dropping first makes the file re-runnable, which the
-- README promises of every file here.
drop policy if exists "own user row"  on public.app_users;
drop policy if exists "own inventory" on public.inventory;
create policy "own user row"  on public.app_users  for select using (auth.uid()::text = apple_user_id);
create policy "own inventory" on public.inventory  for select using (auth.uid()::text = user_id);
