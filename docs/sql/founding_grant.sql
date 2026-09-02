-- Yolkling: founding-species grant (limited edition, grant-only).
-- Extends redeem_code so a founder code grants one founding species, and a
-- referral grants one to BOTH parties. Recorded in inventory (never 'purchase').
-- Additive + idempotent. See docs/species/founding.md.

-- Grant a founding species into inventory (one-time per user+species).
create or replace function grant_founding(p_user text, p_species text, p_source text)
returns void language plpgsql security definer as $$
begin
  insert into public.inventory(user_id, item_id, source)
  values (p_user, p_species, p_source)
  on conflict (user_id, item_id) do nothing;
end $$;

-- The founding species a user owns (client reveals any it has not seen yet).
create or replace function my_founding(p_user text)
returns text[] language sql security definer stable as $$
  select coalesce(array_agg(item_id order by granted_at), '{}')
  from public.inventory
  where user_id = p_user and item_id like 'founding-%';
$$;

-- Redeem: founder code -> early-bird bonus + 1 founding; referral -> bonus to
-- both sides + a founding to BOTH (warmwelcome to the friend, the og to the
-- referrer). One redeem per user.
create or replace function redeem_code(p_code text, p_user text)
returns jsonb language plpgsql security definer as $$
declare
  v_referrer text; v_bonus int := 0; v_kind text; v_founding text;
  v_pool text[] := array[
    'founding-goldenhour','founding-first light','founding-daybreak no. 001',
    'founding-pearl','founding-moonstone','founding-rose quartz','founding-opaline',
    'founding-aurora','founding-dusklight','founding-seafoam','founding-honeyfeather',
    'founding-haloglow','founding-starling no. 002','founding-the og'];
begin
  -- Identity guard. Without it this definition is an unguarded twin of the
  -- enforced one in auth_enforce.sql, and re-running this file silently
  -- reopens the hole it closed. Injected so every file is safe to re-run and
  -- safe to apply in any order on a fresh database.
  perform public.assert_caller(p_user);

  if exists (select 1 from public.redemptions where redeemed_by = p_user) then
    return jsonb_build_object('ok', false, 'reason', 'already_redeemed');
  end if;

  if exists (select 1 from public.waitlist where referral_code = p_code and claimed_by is null) then
    update public.waitlist set claimed_by = p_user, claimed_at = now() where referral_code = p_code;
    v_bonus := 250; v_kind := 'early_bird';
    v_founding := v_pool[1 + (abs(hashtext(p_user)) % array_length(v_pool, 1))];
    perform grant_founding(p_user, v_founding, 'waitlist');
  elsif exists (select 1 from public.app_users where referral_code = p_code and apple_user_id <> p_user) then
    select apple_user_id into v_referrer from public.app_users where referral_code = p_code;
    update public.app_users set referred_by = p_code where apple_user_id = p_user and referred_by is null;
    update public.app_users set coins = coins + 100 where apple_user_id = v_referrer;
    v_bonus := 100; v_kind := 'referral';
    v_founding := 'founding-warmwelcome';
    perform grant_founding(p_user, v_founding, 'referral');
    perform grant_founding(v_referrer, 'founding-the og', 'referral');
  else
    return jsonb_build_object('ok', false, 'reason', 'invalid_or_used');
  end if;

  update public.app_users set coins = coins + v_bonus where apple_user_id = p_user;
  insert into public.redemptions(code, redeemed_by) values (p_code, p_user);
  return jsonb_build_object('ok', true, 'kind', v_kind, 'bonus', v_bonus, 'founding', v_founding);
end $$;

grant execute on function my_founding(text) to anon, authenticated;
notify pgrst, 'reload schema';
