#!/usr/bin/env python3
"""Regenerate docs/sql/tradeable_items.sql from CosmeticCatalog.

Run after adding or removing a cosmetic, then apply the SQL. The allowlist and the
Swift catalog are the same list; keeping it generated is what stops them drifting —
the same reason postcard_phrases.sql is generated rather than hand-maintained.

    python3 tools/gen_tradeable.py
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "Yolkling/Core/Cosmetics/Cosmetic.swift"
OUT = ROOT / "docs/sql/tradeable_items.sql"

HEADER = """-- Which items may cross between two players.
--
-- GENERATED from CosmeticCatalog.all by tools/gen_tradeable.py. Do not hand-edit.
--
-- WHY AN ALLOWLIST
--
-- The first version was `p_item not like 'founding-%'` — a blocklist. But `inventory`
-- does not hold only cosmetics. It holds colour swatches (color-*), room themes
-- (room-*) and decor (decor-*) too, so everything except founding species was
-- tradeable by default, including the colour of your creature's face.
--
-- That was exploitable, not merely wrong. `Player.colorHex` and `Player.roomThemeID`
-- store the APPLIED value, not a reference to an owned item, so you could buy a
-- colour, apply it, trade the swatch away for something else, and keep the colour.
-- Same for a room theme. Value out of nothing, repeatable.
--
-- It is also wrong on the design. The creature you made in onboarding is meant to be
-- the one thing in this app that is yours and cannot be swapped away. Its colour, its
-- pattern and its room are part of that creature, not inventory. What players trade is
-- the COSTUME — hats, glasses, scarves, neck items — which is exactly this list.
--
-- A blocklist fails open: every future item family is tradeable until someone
-- remembers to exclude it. An allowlist fails closed.
--
-- WHY THE FREE STARTERS ARE EXCLUDED
--
-- `Wallet.owns` short-circuits on price: `cost == 0 && !grantOnly` is owned by
-- definition, whatever the wallet says (Wallet.swift). So the client cannot express
-- "I traded my beanie away" — removing it from `owned` changes nothing on screen and
-- the next push_wallet re-inserts it. Letting them be traded would create a
-- duplication hole the client model structurally cannot close, for items worth
-- nothing. They are omitted below.

create table if not exists public.tradeable_items (
  item_id text primary key
);

alter table public.tradeable_items enable row level security;

-- Rebuilt wholesale so a cosmetic REMOVED from the catalog also leaves the allowlist.
-- An append-only seed would keep a retired item tradeable forever.
delete from public.tradeable_items;

insert into public.tradeable_items(item_id) values
"""

FOOTER = """
on conflict (item_id) do nothing;

-- Founding species live in `inventory` too, and are excluded simply by not being
-- cosmetics. The explicit guard is a second gate: if a founding id were ever added to
-- the catalog by mistake, this still refuses it.
create or replace function is_tradeable(p_item text)
returns boolean language sql stable as $$
  select exists (select 1 from public.tradeable_items where item_id = p_item)
     and p_item not like 'founding-%';
$$;

grant execute on function is_tradeable(text) to anon, authenticated;
grant select on public.tradeable_items to anon, authenticated;

-- Offers proposed under the old blocklist are now illegal, but they are still
-- `pending` and respond_trade did not re-check tradeability — so without this they
-- would still complete. Letting one land would move a colour swatch out of inventory
-- while Player.colorHex kept rendering it, and nothing could repair that.
update public.trade_offers set status = 'expired'
 where status = 'pending'
   and (not is_tradeable(offer_item) or not is_tradeable(want_item));

notify pgrst, 'reload schema';
"""

IDENTITY_PREFIXES = ("color-", "room-", "decor-", "founding-")


def main() -> None:
    src = SRC.read_text()

    # (id, the rest of that catalog line) so cost/grantOnly can be read off it.
    entries = re.findall(r'Cosmetic\(id:\s*"([^"]+)"([^\n]*)', src)
    if not entries:
        raise SystemExit("no cosmetics found — did Cosmetic.swift change shape?")

    ids = [i for i, _ in entries]

    # A cosmetic colliding with an identity family would put a colour or a theme on the
    # allowlist and reopen the exact hole this file closes.
    bad = [i for i in ids if i.startswith(IDENTITY_PREFIXES)]
    if bad:
        raise SystemExit(f"cosmetic ids collide with identity prefixes: {bad}")

    dupes = sorted({i for i in ids if ids.count(i) > 1})
    if dupes:
        raise SystemExit(f"duplicate cosmetic ids: {dupes}")

    tradeable, free = [], []
    for item_id, rest in entries:
        cost = re.search(r"cost:\s*(\d+)", rest)
        grant_only = "grantOnly: true" in rest
        if cost and int(cost.group(1)) == 0 and not grant_only:
            free.append(item_id)          # see header: the client can't lose these
        else:
            tradeable.append(item_id)

    rows = ",\n".join("  ('%s')" % i.replace("'", "''") for i in tradeable)
    OUT.write_text(HEADER + rows + FOOTER)
    print(f"wrote {OUT.relative_to(ROOT)}")
    print(f"  {len(tradeable)} tradeable")
    print(f"  {len(free)} free starters excluded: {', '.join(free)}")


if __name__ == "__main__":
    main()
