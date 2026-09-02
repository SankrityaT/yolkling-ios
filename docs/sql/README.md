# Applying the SQL

> **APPLY `auth_identity.sql` THEN `auth_enforce.sql` LAST, ALWAYS.**
>
> They were missing from this list, which meant a by-the-book deploy shipped with no
> identity enforcement at all. Worse, several files below `create or replace` the guarded
> functions with unguarded twins that trust a client-supplied `p_user` — `wallet.sql`,
> `account.sql`, `backup.sql`, `social.sql`, `friend_cards.sql`, `social-living.sql`,
> `founding_grant.sql`, and `drift.sql` (gift_yolks / send_wave) all do. Re-running any
> of them to pick up an unrelated change silently reopens the IDOR that `auth_identity.sql`
> documents as demonstrated live. This is the same trap the `is_tradeable` note below
> describes, applied to the entire auth layer.

Every file here is idempotent — `create table if not exists`, `create or replace
function` — so re-running one is safe on its own. **Order is not arbitrary, though.**

## Order

```
social.sql
social-living.sql
wallet.sql
rewards.sql
founding_grant.sql
moderation.sql
drift.sql
events.sql
backup.sql
account.sql
feedback.sql
trading.sql
tradeable_items.sql      <- MUST come after trading.sql
```

## The one real dependency

`is_tradeable` is defined in **`tradeable_items.sql`**, not in `trading.sql`, and it
must be applied second.

It used to live in `trading.sql` as `p_item not like 'founding-%'`. That blocklist was a
live exploit: `inventory` also holds colour swatches (`color-*`), room themes (`room-*`)
and decor (`decor-*`), so everything except founding species was tradeable by default —
including the colour of your creature's face. Because `Player.colorHex` stores the
*applied* value rather than a reference to an owned item, you could buy a colour, apply
it, trade the swatch away, and keep the colour. Repeatable, value out of nothing.

The definition was **moved** rather than fixed in place, deliberately. Had it stayed in
`trading.sql` as a `create or replace`, re-running that file to pick up an unrelated
change would silently reinstate the blocklist and reopen the hole. Now `trading.sql`
carries only a comment pointing here, so the failure mode is a missing function (loud)
rather than a permissive one (silent).

## Regenerating the allowlist

`tradeable_items.sql` is **generated** — do not hand-edit it:

```sh
python3 tools/gen_tradeable.py
```

It reads `CosmeticCatalog.all` out of `Yolkling/Core/Cosmetics/Cosmetic.swift`, so the
allowlist and the client catalog cannot drift. The same reasoning as
`postcard_phrases` in `drift.sql`: a list maintained by hand in two places will drift,
and the day it does is the day a new hat is silently untradeable.

The generator also refuses to run if a cosmetic id collides with an identity prefix
(`color-`, `room-`, `decor-`, `founding-`), which would put a colour back on the
allowlist and undo all of this.
