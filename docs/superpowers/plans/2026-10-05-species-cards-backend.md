# Species Cards Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the server its own record of which species each player holds, and let players earn new species by walking, with every random roll made on the server, so that species trading (plan 4) has something trustworthy to trade.

**Architecture:** Five new tables (`species_catalog`, `species_cards`, `dex_seen`, `card_imports`, `eggs`, `step_days`) and six new `security definer` functions that take the caller from the session via `public.me()`. A one-time import turns each player's existing on-device discoveries into server cards; after that, cards only come from server rolls. Every change is additive and is proven on a throwaway local Postgres before it reaches production.

**Tech Stack:** PostgreSQL 15+ (Supabase), plpgsql, a local PostgreSQL 16 test harness (`initdb`, `pg_ctl`, `psql` from Homebrew), Python 3 for the catalog generator, Swift Testing for the catalog export.

**Spec:** `docs/superpowers/plans/2026-10-05-yolkling-1.1-index.md` (plan 2 and "Production safety"), mockups `IncubatorPreview.swift`, `HatchPreview.swift`, `RareFormPreview.swift` on local branch `design/1.1-mockups`.

## Global Constraints

- Production project `vlucekvrdxvpkvbizabz`. Additive only: no `drop`, no column removal, no `create or replace` of any function that exists today.
- Every new function: `security definer`, `set search_path = public`, caller from `public.me()`, no `p_user` parameter, `grant execute ... to authenticated`, `revoke ... from anon` where Postgres granted it by default.
- Every new table: row level security enabled with no policies, and `revoke all ... from anon, authenticated`. Only the functions read or write them.
- Eggs: tiers 2, 5 and 10 km; 1,300 steps per km; at most 3 incubating at once; at most 40,000 counted steps per player per day.
- Hatch odds by tier (cumulative cut points on a uniform roll in [0,1)):
  - 2 km: common below 0.80, rare below 0.98, epic otherwise, never legendary.
  - 5 km: common below 0.60, rare below 0.90, epic below 0.99, legendary otherwise.
  - 10 km: common below 0.35, rare below 0.75, epic below 0.95, legendary otherwise.
- Rare form ("gilded"): independent chance of 1 in 64 on every hatch.
- Founding species are never rolled and never imported.
- No secret (access token, database password, service role key) is printed, pasted or committed.

## Review Focus

- **The phone sends a step total that went down** (Health data edited, a new day mid-sync): expect no change and no error, because only increases count.
- **The same import sent twice at once** (two devices, or a retry racing the first call): expect exactly one import and no duplicate cards.
- **A player with no `app_users` row calls a function** (signed in with Apple but never synced): expect a clean `{"ok": false, "reason": "no_account"}`, not a foreign key error.
- **Hatching another player's egg by id:** expect `not_yours`, and nothing created.
- **A rarity with no active species** (for example, every legendary marked inactive): expect the roll to fall back to the next rarity down, never an empty card.

Each of these has a test in the task that owns the code.

---

## File Structure

- Create: `tools/sqltest/run.sh`: builds a throwaway Postgres, applies the schema in order, runs the tests, tears it down.
- Create: `tools/sqltest/supabase_stub.sql`: the parts of Supabase the functions need (roles, `auth.users`, `auth.identities`, `auth.uid()`) plus `test.login()` / `test.logout()`.
- Create: `tools/sqltest/tests/00_existing_schema_test.sql`: proves the harness reproduces today's schema.
- Create: `YolklingTests/SpeciesCatalogExportTests.swift`: writes the real catalog to JSON when asked.
- Create: `tools/gen_species_catalog.py`: JSON in, `docs/sql/species_catalog.sql` out.
- Create (generated): `docs/sql/species_catalog.sql`.
- Create: `docs/sql/species_cards.sql`: the tables and functions.
- Create: `tools/sqltest/tests/10_species_catalog_test.sql`, `tools/sqltest/tests/20_species_cards_test.sql`, `tools/sqltest/tests/30_eggs_test.sql`, `tools/sqltest/tests/40_hatch_test.sql`.
- Modify: `docs/sql/README.md`: the two new files in the order list, before the identity files.

---

### Task 1: A local test harness that reproduces production's schema

**Files:**
- Create: `tools/sqltest/run.sh`, `tools/sqltest/supabase_stub.sql`, `tools/sqltest/tests/00_existing_schema_test.sql`

**Interfaces:**
- Produces: `tools/sqltest/run.sh [extra.sql ...]` exits 0 when every file under `tools/sqltest/tests/` passes, non-zero on the first failure. Tests may call `test.login(apple_id text)` (signs in as that Apple user, creating the auth rows if needed) and `test.logout()`.

- [ ] **Step 1: Write the stub**

```sql
-- tools/sqltest/supabase_stub.sql
-- The slice of Supabase that docs/sql/*.sql relies on, for a vanilla Postgres.
create extension if not exists pgcrypto;

do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then create role service_role nologin; end if;
end $$;

create schema if not exists auth;
create table if not exists auth.users (id uuid primary key);
create table if not exists auth.identities (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  provider    text not null,
  provider_id text not null
);

create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
create or replace function auth.role() returns text language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claim.role', true), ''), 'anon')
$$;

create schema if not exists test;

create or replace function test.login(p_apple text) returns void language plpgsql as $$
declare v uuid;
begin
  select user_id into v from auth.identities where provider = 'apple' and provider_id = p_apple;
  if v is null then
    v := gen_random_uuid();
    insert into auth.users(id) values (v);
    insert into auth.identities(user_id, provider, provider_id) values (v, 'apple', p_apple);
  end if;
  perform set_config('request.jwt.claim.sub', v::text, false);
end $$;

create or replace function test.logout() returns void language sql as $$
  select set_config('request.jwt.claim.sub', '', false)
$$;
```

- [ ] **Step 2: Write the runner**

```bash
#!/bin/bash
# tools/sqltest/run.sh: a throwaway Postgres with today's schema, then every test.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
SQL="$ROOT/docs/sql"
PGDIR=$(mktemp -d /tmp/yolk-pg.XXXXXX)
PORT=${PORT:-55432}
initdb -D "$PGDIR" -U postgres --auth=trust >/dev/null
pg_ctl -D "$PGDIR" -o "-p $PORT -k $PGDIR -c listen_addresses=''" -l "$PGDIR/log" start >/dev/null
trap 'pg_ctl -D "$PGDIR" stop -m immediate >/dev/null 2>&1; rm -rf "$PGDIR"' EXIT
PSQL=(psql -h "$PGDIR" -p "$PORT" -U postgres -d postgres -v ON_ERROR_STOP=1 -q -X)

"${PSQL[@]}" -f "$ROOT/tools/sqltest/supabase_stub.sql"

# docs/sql/README.md order. drift_cron.sql is left out: it needs pg_cron, and
# schedules nothing these tests depend on. Identity files go last, always.
ORDER=(social social-living wallet rewards founding_grant moderation drift events backup
       account feedback trading tradeable_items friend_cards wallet_version
       species_catalog species_cards
       auth_identity auth_enforce)
for f in "${ORDER[@]}"; do
  [ -f "$SQL/$f.sql" ] || continue
  "${PSQL[@]}" -f "$SQL/$f.sql" >/dev/null || { echo "FAILED applying $f.sql"; exit 1; }
done
for f in "$@"; do "${PSQL[@]}" -f "$f" >/dev/null; done

fail=0
for t in "$ROOT"/tools/sqltest/tests/*.sql; do
  if "${PSQL[@]}" -f "$t" >/dev/null 2>"$PGDIR/err"; then
    echo "pass  $(basename "$t")"
  else
    echo "FAIL  $(basename "$t")"; sed 's/^/      /' "$PGDIR/err"; fail=1
  fi
done
exit $fail
```

Each test file runs in a fresh session but against the same database, so test files must use their own Apple ids (`t10-...`, `t20-...`) and never depend on another file's rows.

- [ ] **Step 3: Write the existing-schema test**

```sql
-- tools/sqltest/tests/00_existing_schema_test.sql
do $$ begin
  assert to_regclass('public.app_users') is not null, 'app_users missing';
  assert to_regclass('public.trade_offers') is not null, 'trade_offers missing';
  assert to_regprocedure('public.me()') is not null, 'me() missing';
  perform test.logout();
  begin
    perform public.me();
    raise exception 'expected me() to refuse an anonymous caller';
  exception when others then
    if sqlerrm not like '%not authenticated%' then raise; end if;
  end;
  insert into public.app_users(apple_user_id) values ('t00-a') on conflict do nothing;
  perform test.login('t00-a');
  assert public.me() = 't00-a', 'me() did not resolve the session';
end $$;
```

- [ ] **Step 4: Run it**

Run: `chmod +x tools/sqltest/run.sh && tools/sqltest/run.sh`
Expected: `pass  00_existing_schema_test.sql`. If an existing `docs/sql` file fails to apply, the failure names it: extend `supabase_stub.sql` with the missing Supabase object (a role, a schema, an extension), never edit the production file. Repeat until green.

- [ ] **Step 5: Commit**

```bash
git add tools/sqltest
git commit -m "A local Postgres harness that reproduces the production schema"
```

### Task 2: The species catalog, generated from the app

**Files:**
- Create: `YolklingTests/SpeciesCatalogExportTests.swift`, `tools/gen_species_catalog.py`, `docs/sql/species_catalog.sql` (generated), `tools/sqltest/tests/10_species_catalog_test.sql`

**Interfaces:**
- Consumes: `SpeciesCatalog.all: [Species]` (203 named species), `SpeciesCatalog.founding: [Species]` (16), `Species.id`, `Species.family`, `Species.rarity.rawValue`.
- Produces: table `public.species_catalog(species_id text primary key, family text, rarity text, active boolean)` holding every species the app knows.

- [ ] **Step 1: Write the export test**

```swift
// YolklingTests/SpeciesCatalogExportTests.swift
import Foundation
import Testing
import YolklingCore

/// Writes the app's species catalog to JSON so the server can be generated from the same
/// source of truth. Does nothing unless CATALOG_EXPORT_PATH is set, so the normal test run
/// stays side-effect free.
struct SpeciesCatalogExportTests {
    @Test func exportCatalogWhenAsked() throws {
        let species = SpeciesCatalog.all + SpeciesCatalog.founding
        #expect(Set(species.map(\.id)).count == species.count, "species ids must be unique")
        guard let path = ProcessInfo.processInfo.environment["CATALOG_EXPORT_PATH"] else { return }
        let rows = species.map { ["species_id": $0.id, "family": $0.family, "rarity": $0.rarity.rawValue] }
        let data = try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: path))
    }
}
```

- [ ] **Step 2: Run it with the export path set**

Run: `TEST_RUNNER_CATALOG_EXPORT_PATH=/tmp/species.json xcodebuild test -scheme Yolkling -destination "platform=iOS Simulator,id=9A3F2A47-5868-4956-B3AB-7531342B9347" -derivedDataPath /tmp/yolk-dd -only-testing:YolklingTests/SpeciesCatalogExportTests && python3 -c "import json; d=json.load(open('/tmp/species.json')); print(len(d))"`
Expected: `** TEST SUCCEEDED **` then `219` (203 named plus 16 founding). If the count differs, stop and report it: the catalog changed since this plan was written, and the tests in step 4 must use the real counts.

- [ ] **Step 3: Write the generator**

```python
#!/usr/bin/env python3
"""tools/gen_species_catalog.py: the app's species catalog as idempotent SQL.

Usage: python3 tools/gen_species_catalog.py /tmp/species.json > docs/sql/species_catalog.sql
Regenerate whenever species are added. Never hand-edit the output.
"""
import json, sys

RARITIES = {"common", "rare", "epic", "legendary", "founding"}

def q(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"

rows = json.load(open(sys.argv[1]))
for r in rows:
    assert r["rarity"] in RARITIES, r
ids = sorted(r["species_id"] for r in rows)
assert len(ids) == len(set(ids)), "duplicate species ids"

print("-- GENERATED by tools/gen_species_catalog.py from the app's SpeciesCatalog. Do not edit.")
print("-- Idempotent: safe to re-run. Species the app no longer has are marked inactive, never deleted,")
print("-- because cards may still point at them.")
print("""
create table if not exists public.species_catalog (
  species_id text primary key,
  family     text not null,
  rarity     text not null check (rarity in ('common','rare','epic','legendary','founding')),
  active     boolean not null default true
);
alter table public.species_catalog enable row level security;
revoke all on public.species_catalog from anon, authenticated;
""")
print("insert into public.species_catalog (species_id, family, rarity) values")
print(",\n".join(f"  ({q(r['species_id'])}, {q(r['family'])}, {q(r['rarity'])})"
                 for r in sorted(rows, key=lambda r: r["species_id"])))
print("on conflict (species_id) do update set family = excluded.family, rarity = excluded.rarity, active = true;")
print()
print("update public.species_catalog set active = false where species_id not in (")
print(",\n".join(f"  {q(i)}" for i in ids))
print(");")
```

- [ ] **Step 4: Write the catalog test**

```sql
-- tools/sqltest/tests/10_species_catalog_test.sql
do $$
declare n_all int; n_founding int; n_legendary int;
begin
  select count(*) into n_all from public.species_catalog where active;
  select count(*) into n_founding from public.species_catalog where active and rarity = 'founding';
  select count(*) into n_legendary from public.species_catalog where active and rarity = 'legendary';
  assert n_all = 219, format('expected 219 active species, got %s', n_all);
  assert n_founding = 16, format('expected 16 founding species, got %s', n_founding);
  assert n_legendary > 0, 'expected at least one legendary species to roll';
  assert not has_table_privilege('anon', 'public.species_catalog', 'select'), 'anon can read species_catalog';
end $$;
```

- [ ] **Step 5: Generate and run**

Run: `python3 tools/gen_species_catalog.py /tmp/species.json > docs/sql/species_catalog.sql && tools/sqltest/run.sh`
Expected: `pass  00_...`, `pass  10_species_catalog_test.sql`.

- [ ] **Step 6: Commit**

```bash
git add YolklingTests/SpeciesCatalogExportTests.swift tools/gen_species_catalog.py docs/sql/species_catalog.sql tools/sqltest/tests/10_species_catalog_test.sql Yolkling.xcodeproj
git commit -m "Species catalog on the server, generated from the app"
```

### Task 3: Cards, the Dex record, and the one-time import

**Files:**
- Create: `docs/sql/species_cards.sql` (first part), `tools/sqltest/tests/20_species_cards_test.sql`

**Interfaces:**
- Consumes: `public.me()`, `public.app_users(apple_user_id)`, `public.species_catalog`.
- Produces:
  - `public.my_cards() returns jsonb`: `{"ok": true, "imported": bool, "cards": [{"id": int, "species": text, "form": "normal"|"gilded", "source": text}], "seen": [{"species": text, "form": text}]}`.
  - `public.import_discovered(p_species text[]) returns jsonb`: `{"ok": true, "imported": int, "already": bool}` or `{"ok": false, "reason": "no_account"|"too_many"}`.
  - Internal helper `public.require_account() returns text`: the caller's id, or null when they have no `app_users` row.

- [ ] **Step 1: Write the failing tests**

```sql
-- tools/sqltest/tests/20_species_cards_test.sql
do $$
declare r jsonb; legendary text; founding text; n int;
begin
  select species_id into legendary from public.species_catalog where rarity = 'legendary' and active limit 1;
  select species_id into founding from public.species_catalog where rarity = 'founding' limit 1;

  -- Anonymous callers are refused.
  perform test.logout();
  begin
    perform public.my_cards();
    raise exception 'expected my_cards to refuse an anonymous caller';
  exception when others then
    if sqlerrm not like '%not authenticated%' then raise; end if;
  end;

  -- Signed in with Apple but never synced: a clean refusal, not a foreign key error.
  perform test.login('t20-ghost');
  r := public.import_discovered(array['celestial-stardrop']);
  assert r->>'reason' = 'no_account', format('ghost import: %s', r);

  -- A real player imports. Unknown ids, founding species and duplicates are ignored.
  insert into public.app_users(apple_user_id) values ('t20-a') on conflict do nothing;
  perform test.login('t20-a');
  r := public.import_discovered(array[legendary, legendary, 'not-a-species', founding]);
  assert (r->>'imported')::int = 1, format('first import: %s', r);
  assert (r->>'already')::boolean = false, format('first import: %s', r);

  r := public.my_cards();
  assert jsonb_array_length(r->'cards') = 1, format('cards after import: %s', r);
  assert r->'cards'->0->>'species' = legendary, format('wrong species: %s', r);
  assert r->'cards'->0->>'form' = 'normal', format('wrong form: %s', r);
  assert jsonb_array_length(r->'seen') = 1, format('seen after import: %s', r);
  assert (r->>'imported')::boolean, format('imported flag: %s', r);

  -- Second import is a no-op.
  r := public.import_discovered(array[legendary]);
  assert (r->>'already')::boolean, format('second import: %s', r);
  select count(*) into n from public.species_cards where user_id = 't20-a';
  assert n = 1, format('second import created cards: %s', n);

  -- An absurd list is refused outright.
  insert into public.app_users(apple_user_id) values ('t20-b') on conflict do nothing;
  perform test.login('t20-b');
  r := public.import_discovered(array_fill('x'::text, array[501]));
  assert r->>'reason' = 'too_many', format('oversized import: %s', r);

  -- Tables are closed to clients; only the functions reach them.
  assert not has_table_privilege('authenticated', 'public.species_cards', 'select'), 'authenticated can read species_cards';
  assert not has_table_privilege('anon', 'public.species_cards', 'insert'), 'anon can write species_cards';
end $$;
```

- [ ] **Step 2: Run to verify it fails**

Run: `tools/sqltest/run.sh`
Expected: `FAIL  20_species_cards_test.sql` with "function public.import_discovered(text[]) does not exist".

- [ ] **Step 3: Write the first part of `docs/sql/species_cards.sql`**

```sql
-- Species cards: the server's record of which creatures a player holds.
--
-- Until 1.1 the phone was the only record of discoveries (Player.discoveredSpeciesIDs),
-- which is fine for a collection and useless for trading: anything the phone says, the
-- phone could have made up. From here on the server holds the cards and makes every
-- random roll. `import_discovered` is the single moment the server takes the phone's
-- word, once per player, bounded by the catalog.
--
-- Additive only. Apply after species_catalog.sql and before auth_identity.sql /
-- auth_enforce.sql (docs/sql/README.md).

create table if not exists public.species_cards (
  id         bigint generated always as identity primary key,
  user_id    text not null references public.app_users(apple_user_id) on delete cascade,
  species_id text not null references public.species_catalog(species_id),
  form       text not null default 'normal' check (form in ('normal', 'gilded')),
  source     text not null check (source in ('import', 'egg', 'pack', 'trade', 'grant')),
  created_at timestamptz not null default now()
);
create index if not exists species_cards_user on public.species_cards(user_id, species_id);

-- The Dex: what a player has ever seen, which survives trading a card away.
create table if not exists public.dex_seen (
  user_id    text not null references public.app_users(apple_user_id) on delete cascade,
  species_id text not null references public.species_catalog(species_id),
  form       text not null check (form in ('normal', 'gilded')),
  first_seen timestamptz not null default now(),
  primary key (user_id, species_id, form)
);

create table if not exists public.card_imports (
  user_id     text primary key references public.app_users(apple_user_id) on delete cascade,
  imported_at timestamptz not null default now(),
  count       integer not null default 0
);

alter table public.species_cards enable row level security;
alter table public.dex_seen      enable row level security;
alter table public.card_imports  enable row level security;
revoke all on public.species_cards, public.dex_seen, public.card_imports from anon, authenticated;

-- The caller, if they have a player row. me() raises for anonymous callers; a signed-in
-- caller who never synced gets null rather than a foreign key error further down.
create or replace function public.require_account()
returns text language plpgsql stable security definer set search_path = public as $$
declare v text := public.me();
begin
  if exists (select 1 from app_users where apple_user_id = v) then return v; end if;
  return null;
end $$;

create or replace function public.my_cards()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_me text := public.require_account();
begin
  if v_me is null then return jsonb_build_object('ok', false, 'reason', 'no_account'); end if;
  return jsonb_build_object(
    'ok', true,
    'imported', exists (select 1 from card_imports where user_id = v_me),
    'cards', coalesce((select jsonb_agg(jsonb_build_object(
                         'id', c.id, 'species', c.species_id, 'form', c.form, 'source', c.source)
                         order by c.id)
                       from species_cards c where c.user_id = v_me), '[]'::jsonb),
    'seen', coalesce((select jsonb_agg(jsonb_build_object('species', s.species_id, 'form', s.form)
                        order by s.species_id, s.form)
                      from dex_seen s where s.user_id = v_me), '[]'::jsonb));
end $$;

create or replace function public.import_discovered(p_species text[])
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_me text := public.require_account(); v_n integer;
begin
  if v_me is null then return jsonb_build_object('ok', false, 'reason', 'no_account'); end if;
  if coalesce(array_length(p_species, 1), 0) > 500 then
    return jsonb_build_object('ok', false, 'reason', 'too_many');
  end if;

  -- Claim the import first. Two calls racing (two devices, a retry) both reach this
  -- line; the primary key lets exactly one through.
  insert into card_imports(user_id) values (v_me) on conflict (user_id) do nothing;
  if not found then
    return jsonb_build_object('ok', true, 'imported', 0, 'already', true);
  end if;

  insert into species_cards(user_id, species_id, form, source)
    select v_me, c.species_id, 'normal', 'import'
      from (select distinct unnest(coalesce(p_species, '{}'::text[])) as sid) s
      join species_catalog c on c.species_id = s.sid and c.active and c.rarity <> 'founding';
  get diagnostics v_n = row_count;

  insert into dex_seen(user_id, species_id, form)
    select v_me, species_id, 'normal' from species_cards
     where user_id = v_me and source = 'import'
    on conflict do nothing;

  update card_imports set count = v_n where user_id = v_me;
  return jsonb_build_object('ok', true, 'imported', v_n, 'already', false);
end $$;

revoke execute on function public.require_account() from public, anon, authenticated;
revoke execute on function public.my_cards() from public, anon;
revoke execute on function public.import_discovered(text[]) from public, anon;
grant execute on function public.my_cards() to authenticated;
grant execute on function public.import_discovered(text[]) to authenticated;
```

`require_account` is executable only by the definer functions that call it; the `revoke` lines keep clients from probing it.

- [ ] **Step 4: Run to verify it passes**

Run: `tools/sqltest/run.sh`
Expected: `pass  20_species_cards_test.sql`.

- [ ] **Step 5: Commit**

```bash
git add docs/sql/species_cards.sql tools/sqltest/tests/20_species_cards_test.sql
git commit -m "Species cards on the server, and the one-time import from the phone"
```

### Task 4: Eggs and steps

**Files:**
- Modify: `docs/sql/species_cards.sql` (append)
- Create: `tools/sqltest/tests/30_eggs_test.sql`

**Interfaces:**
- Consumes: `public.require_account()`.
- Produces:
  - `public.start_egg(p_tier_km integer) returns jsonb`: `{"ok": true, "egg": int, "steps_needed": int}` or reason `no_account` | `bad_tier` | `incubator_full`.
  - `public.report_steps(p_day date, p_total integer) returns jsonb`: `{"ok": true, "counted": int, "eggs": [{"id", "tier_km", "steps_walked", "steps_needed"}]}` or reason `no_account` | `bad_day`. `p_total` is the day's device-measured step total from Apple Health.
  - `public.my_eggs() returns jsonb`: `{"ok": true, "eggs": [...]}`, incubating eggs oldest first.

- [ ] **Step 1: Write the failing tests**

```sql
-- tools/sqltest/tests/30_eggs_test.sql
do $$
declare r jsonb; e1 int; e2 int;
begin
  insert into public.app_users(apple_user_id) values ('t30-a') on conflict do nothing;
  perform test.login('t30-a');

  assert public.start_egg(3)->>'reason' = 'bad_tier', 'tier 3 should be refused';

  r := public.start_egg(2);
  assert (r->>'steps_needed')::int = 2600, format('2 km egg: %s', r);
  e1 := (r->>'egg')::int;
  r := public.start_egg(10);
  assert (r->>'steps_needed')::int = 13000, format('10 km egg: %s', r);
  e2 := (r->>'egg')::int;
  perform public.start_egg(5);
  assert public.start_egg(5)->>'reason' = 'incubator_full', 'a fourth egg should be refused';

  -- Steps advance every incubating egg, and only increases count.
  r := public.report_steps(current_date, 3000);
  assert (r->>'counted')::int = 3000, format('first report: %s', r);
  r := public.report_steps(current_date, 2000);
  assert (r->>'counted')::int = 0, format('a lower total must count nothing: %s', r);
  assert (select steps_walked from public.eggs where id = e1) = 2600, 'egg must cap at its need';
  assert (select steps_walked from public.eggs where id = e2) = 3000, 'the 10 km egg should hold 3000';

  -- One day counts at most 40,000 steps.
  r := public.report_steps(current_date, 900000);
  assert (r->>'counted')::int = 37000, format('cap: %s', r);
  assert (select steps_walked from public.eggs where id = e2) = 13000, 'the 10 km egg should now be full';

  -- Only today and its neighbours, so a phone in another timezone still works.
  assert public.report_steps(current_date - 5, 1000)->>'reason' = 'bad_day', 'old days are refused';
  assert (public.report_steps(current_date - 1, 1000)->>'ok')::boolean, 'yesterday is accepted';

  r := public.my_eggs();
  assert jsonb_array_length(r->'eggs') = 3, format('my_eggs: %s', r);
end $$;
```

- [ ] **Step 2: Run to verify it fails**

Run: `tools/sqltest/run.sh`
Expected: `FAIL  30_eggs_test.sql`, "function public.start_egg(integer) does not exist".

- [ ] **Step 3: Append to `docs/sql/species_cards.sql`**

```sql
-- Eggs, warmed by walking. 1,300 steps make a kilometre. Every incubating egg advances
-- together, the way an incubator full of eggs would.
create table if not exists public.eggs (
  id           bigint generated always as identity primary key,
  user_id      text not null references public.app_users(apple_user_id) on delete cascade,
  tier_km      integer not null check (tier_km in (2, 5, 10)),
  steps_needed integer not null check (steps_needed > 0),
  steps_walked integer not null default 0 check (steps_walked >= 0),
  status       text not null default 'incubating' check (status in ('incubating', 'hatched')),
  card_id      bigint references public.species_cards(id) on delete set null,
  created_at   timestamptz not null default now(),
  hatched_at   timestamptz
);
create index if not exists eggs_user on public.eggs(user_id, status);

-- A high-water mark per player per day, so a re-sent or lower total never counts twice.
create table if not exists public.step_days (
  user_id text not null references public.app_users(apple_user_id) on delete cascade,
  day     date not null,
  steps   integer not null default 0 check (steps >= 0),
  primary key (user_id, day)
);

alter table public.eggs      enable row level security;
alter table public.step_days enable row level security;
revoke all on public.eggs, public.step_days from anon, authenticated;

create or replace function public.egg_list(p_user text)
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', e.id, 'tier_km', e.tier_km,
           'steps_walked', e.steps_walked, 'steps_needed', e.steps_needed)
           order by e.created_at, e.id), '[]'::jsonb)
    from eggs e where e.user_id = p_user and e.status = 'incubating';
$$;

create or replace function public.my_eggs()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare v_me text := public.require_account();
begin
  if v_me is null then return jsonb_build_object('ok', false, 'reason', 'no_account'); end if;
  return jsonb_build_object('ok', true, 'eggs', public.egg_list(v_me));
end $$;

create or replace function public.start_egg(p_tier_km integer)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_me text := public.require_account(); v_id bigint; v_need integer;
begin
  if v_me is null then return jsonb_build_object('ok', false, 'reason', 'no_account'); end if;
  if p_tier_km not in (2, 5, 10) then return jsonb_build_object('ok', false, 'reason', 'bad_tier'); end if;
  -- Serialise this player's egg starts so two taps cannot both pass the count.
  perform pg_advisory_xact_lock(hashtext('eggs:' || v_me));
  if (select count(*) from eggs where user_id = v_me and status = 'incubating') >= 3 then
    return jsonb_build_object('ok', false, 'reason', 'incubator_full');
  end if;
  v_need := p_tier_km * 1300;
  insert into eggs(user_id, tier_km, steps_needed) values (v_me, p_tier_km, v_need) returning id into v_id;
  return jsonb_build_object('ok', true, 'egg', v_id, 'steps_needed', v_need);
end $$;

create or replace function public.report_steps(p_day date, p_total integer)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_me text := public.require_account(); v_total integer; v_prev integer; v_delta integer;
begin
  if v_me is null then return jsonb_build_object('ok', false, 'reason', 'no_account'); end if;
  if p_day is null or p_day < current_date - 1 or p_day > current_date + 1 then
    return jsonb_build_object('ok', false, 'reason', 'bad_day');
  end if;
  v_total := greatest(0, least(coalesce(p_total, 0), 40000));

  insert into step_days(user_id, day) values (v_me, p_day) on conflict do nothing;
  select steps into v_prev from step_days where user_id = v_me and day = p_day for update;
  v_delta := v_total - v_prev;
  if v_delta <= 0 then
    return jsonb_build_object('ok', true, 'counted', 0, 'eggs', public.egg_list(v_me));
  end if;

  update step_days set steps = v_total where user_id = v_me and day = p_day;
  update eggs set steps_walked = least(steps_needed, steps_walked + v_delta)
   where user_id = v_me and status = 'incubating';
  return jsonb_build_object('ok', true, 'counted', v_delta, 'eggs', public.egg_list(v_me));
end $$;

revoke execute on function public.egg_list(text) from public, anon, authenticated;
revoke execute on function public.my_eggs(), public.start_egg(integer), public.report_steps(date, integer) from public, anon;
grant execute on function public.my_eggs(), public.start_egg(integer), public.report_steps(date, integer) to authenticated;
```

- [ ] **Step 4: Run to verify it passes**

Run: `tools/sqltest/run.sh`
Expected: `pass  30_eggs_test.sql`, and 00, 10, 20 still pass.

- [ ] **Step 5: Commit**

```bash
git add docs/sql/species_cards.sql tools/sqltest/tests/30_eggs_test.sql
git commit -m "Eggs warmed by steps, one high-water mark per day"
```

### Task 5: Hatching, with rare forms

**Files:**
- Modify: `docs/sql/species_cards.sql` (append)
- Create: `tools/sqltest/tests/40_hatch_test.sql`

**Interfaces:**
- Consumes: `public.eggs`, `public.species_catalog`, `public.species_cards`, `public.dex_seen`, `public.require_account()`.
- Produces:
  - `public.egg_rarity(p_tier_km integer, p_roll double precision) returns text`: pure, immutable; the odds table in Global Constraints.
  - `public.hatch_egg(p_egg bigint) returns jsonb`: `{"ok": true, "card": int, "species": text, "rarity": text, "form": "normal"|"gilded", "is_new": bool}` or reason `no_account` | `not_yours` | `already_hatched` | `not_ready` (with `"steps_left": int`).

- [ ] **Step 1: Write the failing tests**

```sql
-- tools/sqltest/tests/40_hatch_test.sql
do $$
declare r jsonb; e bigint; mine bigint; n_leg int; n_gold int; i int;
begin
  -- The odds table, at its edges.
  assert public.egg_rarity(2, 0.0) = 'common';
  assert public.egg_rarity(2, 0.7999) = 'common';
  assert public.egg_rarity(2, 0.80) = 'rare';
  assert public.egg_rarity(2, 0.98) = 'epic';
  assert public.egg_rarity(2, 0.999999) = 'epic', 'a 2 km egg never holds a legendary';
  assert public.egg_rarity(5, 0.99) = 'legendary';
  assert public.egg_rarity(10, 0.35) = 'rare';
  assert public.egg_rarity(10, 0.95) = 'legendary';

  insert into public.app_users(apple_user_id) values ('t40-a'), ('t40-b') on conflict do nothing;

  -- Not ready yet.
  perform test.login('t40-a');
  mine := (public.start_egg(2)->>'egg')::bigint;
  r := public.hatch_egg(mine);
  assert r->>'reason' = 'not_ready' and (r->>'steps_left')::int = 2600, format('not ready: %s', r);

  -- Somebody else's egg.
  perform test.login('t40-b');
  r := public.hatch_egg(mine);
  assert r->>'reason' = 'not_yours', format('not yours: %s', r);
  assert (select count(*) from public.species_cards where user_id = 't40-b') = 0, 'nothing may be created';

  -- Ready: a card, a Dex entry, and the egg closed.
  perform test.login('t40-a');
  update public.eggs set steps_walked = steps_needed where id = mine;
  r := public.hatch_egg(mine);
  assert (r->>'ok')::boolean and (r->>'is_new')::boolean, format('hatch: %s', r);
  assert r->>'rarity' in ('common', 'rare', 'epic'), format('2 km rarity: %s', r);
  assert (select status from public.eggs where id = mine) = 'hatched';
  assert exists (select 1 from public.dex_seen where user_id = 't40-a' and species_id = r->>'species');
  assert public.hatch_egg(mine)->>'reason' = 'already_hatched';

  -- Founding species are never rolled, and an empty rarity falls back a step.
  update public.species_catalog set active = false where rarity = 'legendary';
  for i in 1..30 loop
    insert into public.eggs(user_id, tier_km, steps_needed, steps_walked) values ('t40-a', 10, 13000, 13000) returning id into e;
    r := public.hatch_egg(e);
    assert r->>'rarity' <> 'legendary' and r->>'rarity' <> 'founding', format('fallback: %s', r);
  end loop;
  update public.species_catalog set active = true where rarity = 'legendary';

  -- The odds, over many hatches. Seeded, so the run is repeatable.
  perform setseed(0.42);
  n_leg := 0; n_gold := 0;
  for i in 1..2000 loop
    insert into public.eggs(user_id, tier_km, steps_needed, steps_walked) values ('t40-a', 10, 13000, 13000) returning id into e;
    r := public.hatch_egg(e);
    if r->>'rarity' = 'legendary' then n_leg := n_leg + 1; end if;
    if r->>'form' = 'gilded' then n_gold := n_gold + 1; end if;
  end loop;
  assert n_leg between 60 and 150, format('10 km legendary share off: %s of 2000 (expect ~100)', n_leg);
  assert n_gold between 15 and 50, format('gilded share off: %s of 2000 (expect ~31)', n_gold);
end $$;
```

- [ ] **Step 2: Run to verify it fails**

Run: `tools/sqltest/run.sh`
Expected: `FAIL  40_hatch_test.sql`, "function public.egg_rarity(integer, numeric) does not exist".

- [ ] **Step 3: Append to `docs/sql/species_cards.sql`**

```sql
-- The odds, in one immutable place, so they can be tested at their edges and quoted
-- exactly in the app and to App Review.
create or replace function public.egg_rarity(p_tier_km integer, p_roll double precision)
returns text language sql immutable as $$
  select case p_tier_km
    when 2  then case when p_roll < 0.80 then 'common' when p_roll < 0.98 then 'rare' else 'epic' end
    when 5  then case when p_roll < 0.60 then 'common' when p_roll < 0.90 then 'rare'
                      when p_roll < 0.99 then 'epic' else 'legendary' end
    when 10 then case when p_roll < 0.35 then 'common' when p_roll < 0.75 then 'rare'
                      when p_roll < 0.95 then 'epic' else 'legendary' end
  end;
$$;

create or replace function public.hatch_egg(p_egg bigint)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_me text := public.require_account();
  e eggs%rowtype;
  v_rarity text; v_species text; v_form text; v_card bigint; v_new boolean;
  v_ladder text[] := array['legendary', 'epic', 'rare', 'common'];
  v_i integer;
begin
  if v_me is null then return jsonb_build_object('ok', false, 'reason', 'no_account'); end if;
  select * into e from eggs where id = p_egg for update;
  -- Someone else's egg reads exactly like no egg, so ids cannot be probed.
  if not found or e.user_id <> v_me then return jsonb_build_object('ok', false, 'reason', 'not_yours'); end if;
  if e.status <> 'incubating' then return jsonb_build_object('ok', false, 'reason', 'already_hatched'); end if;
  if e.steps_walked < e.steps_needed then
    return jsonb_build_object('ok', false, 'reason', 'not_ready', 'steps_left', e.steps_needed - e.steps_walked);
  end if;

  v_rarity := public.egg_rarity(e.tier_km, random());
  -- Walk down the ladder from the rolled rarity until one has a species to give.
  v_i := array_position(v_ladder, v_rarity);
  while v_species is null and v_i <= array_length(v_ladder, 1) loop
    select species_id into v_species from species_catalog
     where active and rarity = v_ladder[v_i] order by random() limit 1;
    if v_species is not null then v_rarity := v_ladder[v_i]; end if;
    v_i := v_i + 1;
  end loop;
  if v_species is null then raise exception 'species_catalog has no active species to hatch'; end if;

  v_form := case when random() < 1.0 / 64 then 'gilded' else 'normal' end;

  insert into species_cards(user_id, species_id, form, source)
    values (v_me, v_species, v_form, 'egg') returning id into v_card;
  insert into dex_seen(user_id, species_id, form) values (v_me, v_species, v_form)
    on conflict do nothing;
  v_new := found;
  update eggs set status = 'hatched', hatched_at = now(), card_id = v_card where id = p_egg;

  return jsonb_build_object('ok', true, 'card', v_card, 'species', v_species,
                            'rarity', v_rarity, 'form', v_form, 'is_new', v_new);
end $$;

revoke execute on function public.hatch_egg(bigint) from public, anon;
grant execute on function public.hatch_egg(bigint) to authenticated;
grant execute on function public.egg_rarity(integer, double precision) to authenticated;
```

- [ ] **Step 4: Run to verify it passes**

Run: `tools/sqltest/run.sh`
Expected: `pass` for 00, 10, 20, 30 and 40.

- [ ] **Step 5: Commit**

```bash
git add docs/sql/species_cards.sql tools/sqltest/tests/40_hatch_test.sql
git commit -m "Hatching: server-side rolls, rare forms at 1 in 64"
```

### Task 6: Apply to production

**Files:**
- Modify: `docs/sql/README.md`

**Interfaces:**
- Consumes: everything above, green.
- Produces: the new tables and functions live on project `vlucekvrdxvpkvbizabz`.

- [ ] **Step 1: Add the files to the README order list**, after `tradeable_items.sql`:

```
species_catalog.sql      <- GENERATED: python3 tools/gen_species_catalog.py
species_cards.sql        <- MUST come after species_catalog.sql
```

- [ ] **Step 2: Run the harness one last time.** `tools/sqltest/run.sh` must print five `pass` lines. Do not continue on any `FAIL`.

- [ ] **Step 3: Get a working access token.** Ask the founder for a fresh Supabase personal access token and store it in `/Users/sankiii/yolkling-app/.env.local` as `SUPABASE_ACCESS_TOKEN` without echoing it. Confirm it works with a harmless query:

```bash
cd /Users/sankiii/yolkling-app
PAT=$(grep -E '^SUPABASE_ACCESS_TOKEN=' .env.local | cut -d= -f2- | tr -d '"'"'"'')
python3 -c "import json; print(json.dumps({'query':'select 1 as ok'}))" \
 | curl -s -X POST "https://api.supabase.com/v1/projects/vlucekvrdxvpkvbizabz/database/query" \
   -H "Authorization: Bearer $PAT" -H "Content-Type: application/json" --data @-
```
Expected: `[{"ok":1}]`. Anything else: stop.

- [ ] **Step 4: Confirm nothing by these names exists yet in production**

Query: `select relname from pg_class where relname in ('species_catalog','species_cards','dex_seen','card_imports','eggs','step_days') union all select proname from pg_proc where proname in ('require_account','my_cards','import_discovered','egg_list','my_eggs','start_egg','report_steps','egg_rarity','hatch_egg');`
Expected: `[]`. If anything comes back, stop: a name collides with something already live, and `create or replace` would overwrite it.

Then record the baseline the verification compares against: `select count(*) from app_users` and `select count(*) from inventory`. Write both numbers down.

- [ ] **Step 5: Apply both files in one transaction**

```bash
python3 - <<'PY'
import json, subprocess, os
root = "/Users/sankiii/iOSLocal/yolkling/docs/sql/"
sql = "begin;\n" + open(root + "species_catalog.sql").read() + "\n" + open(root + "species_cards.sql").read() + "\ncommit;\n"
open("/tmp/apply.json", "w").write(json.dumps({"query": sql}))
PY
curl -s -X POST "https://api.supabase.com/v1/projects/vlucekvrdxvpkvbizabz/database/query" \
  -H "Authorization: Bearer $PAT" -H "Content-Type: application/json" --data @/tmp/apply.json
rm -f /tmp/apply.json
```
Expected: `[]` (success with no rows). An error message means the transaction rolled back and nothing changed: report it, do not retry blindly.

- [ ] **Step 6: Verify, read-only**

Queries, each expected result in brackets:
- `select count(*) from species_catalog where active` [219]
- `select relname, relrowsecurity from pg_class where relname in ('species_cards','dex_seen','card_imports','eggs','step_days','species_catalog')` [six rows, all `true`]
- `select has_table_privilege('anon','public.species_cards','select'), has_table_privilege('authenticated','public.eggs','select')` [false, false]
- `select has_function_privilege('anon','public.hatch_egg(bigint)','execute'), has_function_privilege('authenticated','public.hatch_egg(bigint)','execute')` [false, true]
- `select count(*) from app_users`, `select count(*) from inventory` [both equal to the baseline from step 4: nothing existing changed]

- [ ] **Step 7: Commit**

```bash
git add docs/sql/README.md
git commit -m "Species cards live on the server"
```
