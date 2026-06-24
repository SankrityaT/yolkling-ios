# Yolkling — Monetization & Social Layer Research (2026)

> **Scope.** Actionable recommendations for (1) cosmetics-store monetization, (2) a Supabase-backed
> social/friends layer with local-first sync, and (3) Sign in with Apple minimal-data auth.
> **Context.** Yolkling is a cute social virtual-creature app. Free to hatch. Gentle cosmetic
> monetization purely to cover infra, *not* to maximize revenue. Privacy-first. One developer.
> Supabase already in use for the waitlist.
>
> Researched June 2026. All claims are cited inline. Current as of the dates noted; re-verify the
> App Store Review Guidelines and Apple legal pages before submission since they change frequently.

---

## TL;DR recommendations

1. **Monetize with StoreKit 2 directly** (no RevenueCat) — Yolkling is a single-platform, low-SKU,
   low-revenue, privacy-first app where RevenueCat's value (cross-platform, analytics, server
   receipt infra) is mostly wasted and its 1%-of-revenue fee past the free tier is a permanent tax
   on a project whose explicit goal is *covering infra, not maximizing revenue*. StoreKit 2 +
   `Transaction.currentEntitlements` gives you everything you need natively.
2. **Product types:** cosmetic hats/rooms/colours → **non-consumable** one-time unlocks
   (restorable, never expire). Soft currency ("yolks") earned by playing → **never sold** in v1; if
   you ever sell it, it must be a **consumable**. Supporter tier → **auto-renewable subscription**
   (or a **non-consumable "lifetime supporter" tip** if you want zero subscription-management
   burden). All digital → **must** use Apple IAP (Guideline 3.1.1).
3. **Enroll in the App Store Small Business Program** immediately → **15%** commission instead of
   30%. You almost certainly qualify (under $1M proceeds).
4. **Social layer on Supabase:** friend graph as a single `friendships` table with `(requester,
   addressee, status)`; enforce visibility entirely with RLS. Use **private Realtime channels** for
   "creatures visiting each other," authorized by RLS on `realtime.messages`.
5. **Local-first sync:** SwiftData (or a local SQLite/Core Data store) as source of truth + a
   **pending-mutation outbox** drained by a single `actor`. Last-write-wins with server timestamps
   for the cosmetic/creature state; this is appropriate because cosmetics are low-conflict.
6. **Auth:** Sign in with Apple only (for v1). Request **nothing but the stable `user` identifier**.
   Skip name. Skip email unless you have a concrete need; if you take email, support Hide My Email
   relay correctly and never try to defeat it.

---

## 1. Monetization

### 1.1 StoreKit 2 directly vs RevenueCat — the solo-dev tradeoff

The 2026 consensus: both are viable, and the calculus has shifted toward "StoreKit 2 is enough" for
small apps because Apple shipped App Store Server Library 2.0 and improved StoreKit 2 testing in
Xcode 16, closing the server-side gaps that made RevenueCat the default a few years ago.
([The Swift Kit, 2026](https://theswiftk.it.com/blog/storekit-2-vs-revenuecat-ios-subscriptions))

| Dimension | StoreKit 2 directly | RevenueCat |
|---|---|---|
| **Cost** | Free. No revenue share beyond Apple's commission. | Free under **$2,500/month** revenue; then **1% of tracked revenue (MTR)**. ([The Swift Kit](https://theswiftk.it.com/blog/storekit-2-vs-revenuecat-ios-subscriptions)) |
| **Integration time** | More upfront engineering, but modest for non-consumables. | ~30 min to first paywall. ([The Swift Kit](https://theswiftk.it.com/blog/storekit-2-vs-revenuecat-ios-subscriptions)) |
| **Cross-platform** | iOS/Apple only. | Abstracts iOS + Android + web. Wasted if you're iOS-only. |
| **Analytics / dashboards** | You build or skip. | Strong built-in subscription analytics. |
| **Receipt validation infra** | `Transaction` verification is native + on-device; optional App Store Server API. | They host it. |
| **Privacy** | No third party sees purchase data. | A third party processes purchase/receipt data — friction with a privacy-first stance. |
| **Lock-in** | None. | Their SDK + entitlement model. |

**Recommendation for Yolkling: use StoreKit 2 directly.** Rationale specific to this project:

- You're iOS-only, so RevenueCat's flagship benefit (cross-platform abstraction) is moot.
- Your catalog is mostly **non-consumables** (cosmetics), which are the *simplest* StoreKit 2 case —
  no server-side subscription-state machine, no renewal webhooks. `Transaction.currentEntitlements`
  is a single async loop.
- The explicit goal is *covering infra, not maximizing revenue.* A permanent 1% skim past the free
  tier is exactly the kind of recurring cost you're trying to avoid; the fundamental tradeoff is
  "ease/speed (RevenueCat) vs control/cost (StoreKit 2)" and your priorities point at control/cost.
  ([The Swift Kit](https://theswiftk.it.com/blog/storekit-2-vs-revenuecat-ios-subscriptions))
- Privacy-first: keeping purchase data out of a third party's hands is consistent with the brand.

> Note: if you later add a paid **auto-renewable supporter subscription** and want renewal/churn
> analytics without building it, RevenueCat's free tier is a reasonable place to reconsider — its
> value is highest for subscriptions, not one-time unlocks. For v1, StoreKit 2 alone.

**Implementation notes (StoreKit 2):**
- Drive entitlements from `Transaction.currentEntitlements` and listen on `Transaction.updates` for
  out-of-process renewals/refunds.
- Use a `.storekit` configuration file for local testing in Xcode; test restore-purchases explicitly
  (non-consumables **must** be restorable — see 1.3).
- For a server-authoritative inventory (so a user's owned cosmetics follow them across devices via
  Supabase), validate with the **App Store Server API / Server Library 2.0** in a Supabase Edge
  Function and write owned-SKU rows to Postgres. Keep the on-device entitlement as the fast path and
  the server copy as the durable record.

### 1.2 App Store Small Business Program — apply now (15%)

- **What:** reduces Apple's commission from **30% → 15%** on App Store earnings (paid apps + IAP).
  ([Qonversion, 2026](https://qonversion.io/blog/apple-reduces-app-store-commission-to-15);
  [Adapty, 2026](https://adapty.io/blog/app-store-small-business-program/))
- **Eligibility:** earned **under $1,000,000 in proceeds** in the prior calendar year (2025),
  aggregated across *all* your apps and across paid + IAP. **New developers** qualify too. Account
  must be in good standing (no open violations, no unpaid balance). Apple **aggregates associated
  accounts** sharing a tax ID / beneficial ownership.
  ([Adapty](https://adapty.io/blog/app-store-small-business-program/);
  [RevenueCat](https://www.revenuecat.com/blog/engineering/small-business-program/))
- **When the rate kicks in:** the 15% rate begins **15 days after the end of the fiscal month** in
  which Apple approves enrollment. ([Adapty](https://adapty.io/blog/app-store-small-business-program/))
- **If you cross $1M:** standard 30% applies to future sales for the rest of the year; you can
  **re-qualify** the following year if you drop back under $1M. ([Adapty](https://adapty.io/blog/app-store-small-business-program/))

**Action:** enroll in App Store Connect before/at first paid release. As a new solo dev you clearly
qualify; this single step halves Apple's cut. *Re-verify the current threshold and terms on Apple's
official program page when you apply.*

### 1.3 Apple's IAP rules for digital goods (Guideline 3.1.1)

The hard rules you must design around:

- **Digital content consumed in the app must use Apple IAP.** Any paid digital content, services, or
  functionality is sold through IAP under Guideline 3.1.1 — cosmetics qualify because they are
  digital content experienced inside the app.
  ([BuddyBoss](https://buddyboss.com/docs/app-store-guideline-3-1-1-business-payments-in-app-purchase/);
  [Apple IAP](https://developer.apple.com/in-app-purchase/))
- **No external payment for digital goods** outside the narrow, region-specific carve-outs. The US
  storefront now permits *external payment links* following the Epic v. Apple ruling, but most apps
  must **still** also offer IAP, and reader-app exceptions don't apply to you. For a privacy-first
  one-dev app, the simplest and safest path is **IAP only** — do not add a "buy on our website"
  button.
  ([Dodo Payments, 2026](https://dodopayments.com/blogs/digital-goods-outside-app-store);
  [RevenueCat anti-steering](https://www.revenuecat.com/blog/growth/apple-anti-steering-ruling-monetization-strategy/);
  [TechCrunch, 2025](https://techcrunch.com/2025/05/02/apple-changes-us-app-store-rules-to-let-apps-redirect-users-to-their-own-websites-for-payments))
- **Currency/credits rules** (directly relevant to "yolks"): credits or in-game currency bought via
  IAP **must be consumed within the app and may not expire**; currency bought *outside* the app may
  not be redeemed inside it; and apps **may not enable gifting** of IAP content/consumables to other
  users.
  ([Apple Store Guidelines via saniul mirror](https://github.com/saniul/AppStoreGuidelines/blob/master/App%20Store%20Guidelines.txt))
  → This has a concrete design implication: if creatures "visit" each other and you let players give
  each other cosmetics, that gift **cannot** be an IAP-purchased item being transferred. Gifting must
  be limited to **earned/free** items, or implemented as each user separately unlocking via IAP.

### 1.4 Product-type decision matrix for Yolkling

| Item | Product type | Why |
|---|---|---|
| **Hats, rooms, colours** (cosmetic unlocks) | **Non-consumable** | One-time, permanent, restorable, never expires. Restore-purchases is mandatory for non-consumables. ([create with swift](https://www.createwithswift.com/implementing-non-consumable-in-app-purchases-with-storekit-2/)) |
| **"Yolks" soft currency** earned by playing | **Not an IAP** (free, server/local ledger) | Keep it earn-only in v1. Earned currency isn't an IAP product at all. |
| **"Yolks" if ever sold for money** | **Consumable** | Currency that depletes is the canonical consumable; must be consumed in-app, can't expire, can't be gifted. ([Medium: consumable vs subscription](https://medium.com/@ishay_13213/consumable-vs-auto-renewable-subscription-in-apples-in-app-purchases-ec04250051dd)) |
| **Supporter tier** (recurring) | **Auto-renewable subscription** | Ongoing perks (monthly yolk stipend, supporter badge, early cosmetics). Renews until cancelled. ([Apple: subscriptions](https://www.developer.apple.com/app-store/subscriptions/)) |
| **Supporter tier** (one-time alternative) | **Non-consumable "lifetime supporter"** | If you want *zero* subscription lifecycle/billing-state burden as a solo dev, sell a one-time "supporter" unlock instead. Common indie pattern: pair a lifetime unlock with subscriptions. ([Medium: subscriptions guide](https://azamsharp.medium.com/storekit-subscriptions-a-practical-guide-d38516be3157)) |

**Strong recommendation:** for v1, **non-consumable cosmetics + an optional non-consumable
"lifetime supporter" tip**, and *defer* the auto-renewable subscription. Subscriptions add real
ongoing complexity (renewal handling, grace periods, billing-retry, churn, App Review scrutiny of
the paywall) that a solo dev covering-infra app doesn't need on day one. Add the auto-renewable tier
later if recurring infra cost genuinely demands recurring revenue.

### 1.5 Ethical, non-dark-pattern monetization

2026 is seeing a real industry shift toward ethical monetization: games that prioritize trust and
fairness see better retention and long-term revenue, because players spend more when they feel
respected. ([Team of Keys, 2026](https://teamofkeys.com/blog/top-mobile-game-monetization-strategies-for-2026/))
The principles to bake into Yolkling:

- **No loot boxes / no gacha / no randomized purchases.** Every purchase shows exactly what you get.
  This also sidesteps regulatory risk — Belgium and the Netherlands already restrict loot boxes, and
  the EU **Digital Fairness Act** (proposed late-2025/early-2026) targets loot-box mechanics.
  ([bgaitechstudio](https://blog.bgaitechstudio.com/en/ethical-considerations-in-mobile-game-design-and-monetization);
  [Team of Keys](https://teamofkeys.com/blog/top-mobile-game-monetization-strategies-for-2026/);
  [Modes of Play](https://www.modesofplay.com/from-gacha-to-ethical-crossroads/))
- **Earn-by-playing currency + optional buy.** Provide non-monetary paths to advancement (skill/time
  investment), so spending is a convenience, never a gate. ([bgaitechstudio](https://blog.bgaitechstudio.com/en/ethical-considerations-in-mobile-game-design-and-monetization))
  For Yolkling: yolks earned through gentle daily play; cosmetics buyable with yolks *or* with money,
  so nothing is paywalled-only.
- **Transparent, upfront pricing; no obfuscating premium currency.** Show the real price; don't hide
  cost behind currency-conversion layers. If you ever sell yolks, show the real-money cost of every
  cosmetic in both yolks and currency. ([bgaitechstudio](https://blog.bgaitechstudio.com/en/ethical-considerations-in-mobile-game-design-and-monetization))
- **Subscription = recurring *perks*, not removing artificial pain.** Modern ethical subscriptions
  give monthly currency / cosmetics / event access, not "pay to stop being annoyed."
  ([Team of Keys](https://teamofkeys.com/blog/top-mobile-game-monetization-strategies-for-2026/))
- **No FOMO/manipulation patterns:** no fake countdown timers, no manufactured scarcity, no
  confirm-shaming. Honor restore-purchases. Make cancellation/refund frictionless.

This is fully aligned with Yolkling's stated "gentle, cover-infra, privacy-first" intent and is
likely a net *positive* for retention.

---

## 2. Social / friends layer + sync on Supabase

### 2.1 Friend-graph schema

Model the whole graph as one table. A single-row-per-relationship design with explicit direction +
status is simpler to secure than two mirrored rows:

```sql
-- status: 'pending' | 'accepted' | 'blocked'
create table public.friendships (
  id          uuid primary key default gen_random_uuid(),
  requester   uuid not null references auth.users(id) on delete cascade,
  addressee   uuid not null references auth.users(id) on delete cascade,
  status      text not null default 'pending'
                check (status in ('pending','accepted','blocked')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  -- one relationship per unordered pair
  constraint  no_self  check (requester <> addressee),
  constraint  uniq_pair unique (least(requester,addressee), greatest(requester,addressee))
);

create index friendships_requester_idx on public.friendships (requester);
create index friendships_addressee_idx on public.friendships (addressee);
```

The mutual-friendship alternative (insert both `(a,b)` and `(b,a)`) is well-documented but doubles
rows and RLS surface; the single-row + `least/greatest` unique constraint avoids that.
([Minimal Modeling: mutual friendship](https://minimalmodeling.substack.com/p/modeling-mutual-friendship))

### 2.2 RLS policies for the friend graph

Enable RLS and write policies for each verb. Reads/deletes use `USING`; writes use `WITH CHECK`.
**Index every column referenced in a policy** — Supabase explicitly calls this out as the top
performance footgun. ([Supabase RLS docs](https://supabase.com/docs/guides/database/postgres/row-level-security);
[makerkit RLS best practices](https://makerkit.dev/blog/tutorials/supabase-rls-best-practices))

```sql
alter table public.friendships enable row level security;

-- See a friendship row only if you're one of the two parties.
create policy "see own friendships"
on public.friendships for select to authenticated
using ( (select auth.uid()) in (requester, addressee) );

-- Only the requester can create, and only as 'pending', and only for themselves.
create policy "send friend request"
on public.friendships for insert to authenticated
with check ( requester = (select auth.uid()) and status = 'pending' );

-- Either party can update (accept/block); cannot reassign the pair.
create policy "respond to friendship"
on public.friendships for update to authenticated
using ( (select auth.uid()) in (requester, addressee) )
with check ( (select auth.uid()) in (requester, addressee) );

-- Either party can remove/unfriend.
create policy "remove friendship"
on public.friendships for delete to authenticated
using ( (select auth.uid()) in (requester, addressee) );
```

Wrap `auth.uid()` in a subselect (`(select auth.uid())`) so Postgres caches it per-statement — a
documented RLS performance pattern. ([makerkit](https://makerkit.dev/blog/tutorials/supabase-rls-best-practices))

For "who can see whose creature/profile," add a helper and reuse it:

```sql
create or replace function public.are_friends(a uuid, b uuid)
returns boolean language sql stable security invoker as $$
  select exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and least(f.requester,f.addressee)   = least(a,b)
      and greatest(f.requester,f.addressee)= greatest(a,b)
  );
$$;

-- profiles readable by self or accepted friends
create policy "profiles visible to friends"
on public.profiles for select to authenticated
using ( id = (select auth.uid()) or public.are_friends((select auth.uid()), id) );
```

### 2.3 "Creatures visiting each other" — Realtime design

Use **private Realtime channels** authorized by RLS, not public broadcast. As of 2026, Realtime
Authorization is **on by default**: you create RLS policies on the `realtime.messages` table, and
clients subscribe with `private: true`. On subscribe, Realtime runs SELECT/INSERT against
`realtime.messages` and **rolls them back** (nothing is persisted); policies are **cached for the
connection's duration**, so your DB isn't hit per message.
([Supabase Realtime Authorization](https://supabase.com/docs/guides/realtime/authorization);
[Supabase blog: broadcast & presence auth](https://supabase.com/blog/supabase-realtime-broadcast-and-presence-authorization))

Pattern: a "visit" is a presence/broadcast on a topic scoped to the host's space, e.g.
`creature:{host_user_id}`. Authorize with `realtime.topic()`:

```sql
-- Only the host and the host's accepted friends may join a creature's visit channel.
create policy "friends can visit creature"
on realtime.messages for select to authenticated
using (
  realtime.messages.extension in ('broadcast','presence')
  and (
    -- topic is 'creature:<host_uuid>'
    split_part(realtime.topic(), ':', 1) = 'creature'
    and (
      split_part(realtime.topic(), ':', 2) = (select auth.uid())::text
      or public.are_friends(
           (select auth.uid()),
           split_part(realtime.topic(), ':', 2)::uuid)
    )
  )
);

-- Mirror an INSERT policy (with check) if visitors broadcast presence/waves.
create policy "friends can broadcast in creature"
on realtime.messages for insert to authenticated
with check ( /* same predicate as above */ true );
```

Also **disable "Allow public access"** in Realtime settings and keep **JWT expiry short**, because
the access policy only refreshes on connect or when the client sends a fresh `access_token`.
([Supabase Realtime Authorization](https://supabase.com/docs/guides/realtime/authorization))

**Gotcha to plan for:** enabling RLS on a table is a well-known cause of Realtime going silent —
Postgres-changes / broadcast events stop arriving if your **SELECT policy doesn't cover the rows the
client should receive.** Make sure the SELECT policy matches exactly the rows/topics a friend should
see. ([GitHub issue #35282](https://github.com/supabase/supabase/issues/35282);
[technetexperts](https://www.technetexperts.com/realtime-rls-solved/))

### 2.4 Local-first / offline-first sync (pending-mutation queue via an actor)

Target architecture (matches the "local-first" pattern you described and current 2026 Swift
practice):

1. **Local store is the source of truth.** SwiftData (Swift-native, lightweight) or SQLite/Core Data
   holds creatures, owned cosmetics, friends. The UI **only ever reads/writes locally** so it stays
   responsive offline. ([Medium: Local-first SwiftData + Supabase](https://medium.com/@mabuex/local-first-with-swiftdata-and-supabase-434b0a473dd6);
   [PowerSync](https://powersync.com/blog/bringing-offline-first-to-supabase))
2. **Pending-mutation outbox.** Represent each change as an enum case
   (`.equipHat`, `.acceptFriend`, `.renameCreature`, …) with a payload + client timestamp + a
   client-generated UUID for idempotency. Persist it to a local `pendingMutations` table. This is
   the standard mutation-queue pattern: save the mutation locally, sync later.
   ([RxDB outbound queue](https://rxdb.info/replication-supabase.html))
3. **A single `actor` drains the queue.** One `actor SyncEngine` serializes all replication so
   there's no data race; it's woken by connectivity changes and `Transaction.updates`-style events.
   This is the current recommended approach: Swift Concurrency + an actor-based sync engine to handle
   unreliable networks. ([Medium: offline-first with Swift Concurrency](https://medium.com/@er.rajatlakhina/designing-offline-first-architecture-with-swift-concurrency-and-core-data-sync-46ad5008c7b5);
   [DEV: offline-first SwiftUI](https://dev.to/sebastienlato/offline-first-swiftui-architecture-4bei))
4. **Drain loop:** for each pending mutation, push to Supabase (REST/RPC); on success, mark applied
   and delete from the outbox; on failure, keep it and retry with backoff. Make every mutation
   **idempotent** (the client UUID lets the server upsert safely) so retries are harmless.
5. **Pull side:** subscribe to Realtime for the rows/topics you can see (friend updates, visits) and
   reconcile into the local store.

```swift
actor SyncEngine {
    private var isDraining = false

    func enqueue(_ m: PendingMutation) async {
        await localStore.insertPending(m)
        await drain()
    }

    func drain() async {
        guard !isDraining, await network.isOnline else { return }
        isDraining = true; defer { isDraining = false }
        for m in await localStore.pendingMutations() {     // FIFO
            do {
                try await remote.apply(m)                  // idempotent upsert keyed by m.id
                await localStore.markApplied(m.id)
            } catch is RetryableError {
                break                                      // stop; retry on next wake
            } catch let e as ConflictError {
                await resolveConflict(e, for: m)           // see 2.5
                await localStore.markApplied(m.id)
            }
        }
    }
}
```

### 2.5 Conflict handling

- **Default: last-write-wins on server timestamps.** Compare timestamps; the newest version wins, and
  sync recovers by re-attempting if the local copy is newer. This is the documented SwiftData +
  Supabase approach and is appropriate here because cosmetic/creature state is **low-conflict**
  (a user mostly edits their own creature). ([Medium: Local-first SwiftData + Supabase](https://medium.com/@mabuex/local-first-with-swiftdata-and-supabase-434b0a473dd6))
- **Per-field LWW** where it matters (e.g., equipped hat vs creature name are independent) to avoid a
  stale full-object overwrite clobbering an unrelated field.
- **State-machine fields use server authority, not LWW.** Friendship `status` and any
  IAP-derived owned-cosmetics should be resolved by the server (the friend-accept transition and IAP
  validation are authoritative), not by whichever client wrote last.
- **If you outgrow LWW**, the escape hatch is CRDT-style / a sync engine like PowerSync or RxDB that
  syncs Postgres ⇄ local SQLite and manages the queue for you — but that's almost certainly
  over-engineering for v1 Yolkling. ([PowerSync + Supabase](https://docs.powersync.com/integration-guides/supabase-+-powersync);
  [RxDB Supabase replication](https://rxdb.info/replication-supabase.html))

### 2.6 Privacy-respecting data minimization (social)

- **Share the minimum.** A visiting friend needs only: display name, creature appearance + equipped
  cosmetics, and presence. They do **not** need email, precise activity logs, purchase history, or
  device identifiers. Enforce this with column-scoped reads (a `public_profiles` view exposing only
  safe columns) rather than relying on the client to filter.
- **Block must mean block.** A `'blocked'` status row should fail both friend visibility and Realtime
  topic predicates.
- **No global directory.** Friend discovery by short invite code / link, not by scanning all users —
  avoids enumeration and keeps the graph opt-in.
- **Don't broadcast PII over Realtime.** Visit/presence payloads carry creature state and a stable
  user id, never email or relay address.

---

## 3. Sign in with Apple — minimal-data auth

### 3.1 Why SIWA fits Yolkling

Sign in with Apple lets people use their Apple Account and **skip forms, email verification, and
passwords**, which is the lowest-friction, most privacy-aligned option for a privacy-first app.
([Apple HIG: Sign in with Apple](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple))
Supabase Auth supports it natively, so it slots into your existing backend.

### 3.2 What to collect — and what to avoid

- **Collect only the stable user identifier.** SIWA returns a stable `user` string per
  (developer-account, Apple-ID). Use that as your account key. For v1 you need **nothing else** to
  identify a returning user. The display name and creature are app-domain data the user types in,
  not auth PII.
- **Skip name.** Apple offers it only on first sign-in; let users pick their own Yolkling display
  name instead of harvesting the Apple Account name.
- **Skip email unless you have a concrete need** (e.g., transactional mail, account recovery). If you
  don't email users, don't request the email scope at all.
- **Ask for optional data later, in context.** Apple's guidance: give people a chance to engage with
  your app before asking for optional data, and lean on non-email identifiers where possible.
  ([Apple HIG: Sign in with Apple](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple))

### 3.3 If you do take email (Hide My Email / private relay)

- Users can choose **Hide My Email**, which gives you a unique
  `<random>@privaterelay.appleid.com` address that forwards to their real inbox and is **unique per
  app**, so services can't cross-link the user. Treat it as a real, valid address.
  ([Maileroo](https://maileroo.com/blog/understanding-apples-private-relay-email-addresses-privaterelay-appleid-com-what-they-are-and-how-they-work/);
  [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple))
- **Never try to force a real email** when the user chose Hide My Email — it's against Apple's intent
  and the relay address is the address you're meant to use. ([Apple HIG](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple))
- To actually send mail to relay addresses you must **configure the private email relay service** in
  your Apple Developer account (register your sending domains/sources), or forwarded mail bounces.
  ([Apple: configure private email relay](https://developer.apple.com/help/account/capabilities/configure-private-email-relay-service/);
  [Apple: communicating via private relay](https://developer.apple.com/documentation/signinwithapple/communicating-using-the-private-email-relay-service))
- Email is delivered **only on first authorization**; persist it then. To retrieve it later, direct
  users to Settings rather than re-prompting. ([Apple HIG](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple))

### 3.4 Data you can avoid collecting entirely

For a privacy-first creature app, you can ship without: real name, real email (use relay or none),
phone number, contacts, precise location, IDFA/ad identifiers, and third-party analytics SDKs. This
keeps your **App Privacy "nutrition label"** minimal and is a genuine differentiator. Pair SIWA-only
auth with an in-app **account deletion** path (an App Store requirement for accounts) so the full
lifecycle is privacy-respecting.

---

## Sources

**Monetization**
- StoreKit 2 vs RevenueCat (2026): https://theswiftk.it.com/blog/storekit-2-vs-revenuecat-ios-subscriptions
- Small Business Program (Qonversion, 2026): https://qonversion.io/blog/apple-reduces-app-store-commission-to-15
- Small Business Program (Adapty, 2026): https://adapty.io/blog/app-store-small-business-program/
- Small Business Program (RevenueCat, 2026): https://www.revenuecat.com/blog/engineering/small-business-program/
- Selling digital goods outside the App Store (Dodo, 2026): https://dodopayments.com/blogs/digital-goods-outside-app-store
- Anti-steering ruling (RevenueCat): https://www.revenuecat.com/blog/growth/apple-anti-steering-ruling-monetization-strategy/
- US external-payment rule change (TechCrunch, 2025): https://techcrunch.com/2025/05/02/apple-changes-us-app-store-rules-to-let-apps-redirect-users-to-their-own-websites-for-payments
- Guideline 3.1.1 resolution (BuddyBoss): https://buddyboss.com/docs/app-store-guideline-3-1-1-business-payments-in-app-purchase/
- Apple In-App Purchase overview: https://developer.apple.com/in-app-purchase/
- App Store Guidelines text (currency/gifting rules, mirror): https://github.com/saniul/AppStoreGuidelines/blob/master/App%20Store%20Guidelines.txt
- Consumable vs subscription (Medium): https://medium.com/@ishay_13213/consumable-vs-auto-renewable-subscription-in-apples-in-app-purchases-ec04250051dd
- Non-consumable with StoreKit 2 (create with swift): https://www.createwithswift.com/implementing-non-consumable-in-app-purchases-with-storekit-2/
- StoreKit subscriptions practical guide (AzamSharp): https://azamsharp.medium.com/storekit-subscriptions-a-practical-guide-d38516be3157
- Apple auto-renewable subscriptions: https://www.developer.apple.com/app-store/subscriptions/
- Ethical monetization trends 2026 (Team of Keys): https://teamofkeys.com/blog/top-mobile-game-monetization-strategies-for-2026/
- Ethics of gacha (Modes of Play): https://www.modesofplay.com/from-gacha-to-ethical-crossroads/
- Ethical game design/monetization (bgaitechstudio): https://blog.bgaitechstudio.com/en/ethical-considerations-in-mobile-game-design-and-monetization

**Social / Supabase**
- Realtime Authorization (Supabase docs): https://supabase.com/docs/guides/realtime/authorization
- Broadcast & Presence Authorization (Supabase blog): https://supabase.com/blog/supabase-realtime-broadcast-and-presence-authorization
- Row Level Security (Supabase docs): https://supabase.com/docs/guides/database/postgres/row-level-security
- RLS best practices (makerkit): https://makerkit.dev/blog/tutorials/supabase-rls-best-practices
- Modeling mutual friendship (Minimal Modeling): https://minimalmodeling.substack.com/p/modeling-mutual-friendship
- RLS + Realtime incompatibility issue #35282: https://github.com/supabase/supabase/issues/35282
- Realtime RLS silent-events fix (technetexperts): https://www.technetexperts.com/realtime-rls-solved/
- Local-first SwiftData + Supabase (Medium): https://medium.com/@mabuex/local-first-with-swiftdata-and-supabase-434b0a473dd6
- Offline-first with Swift Concurrency + Core Data (Medium): https://medium.com/@er.rajatlakhina/designing-offline-first-architecture-with-swift-concurrency-and-core-data-sync-46ad5008c7b5
- Offline-first SwiftUI architecture (DEV): https://dev.to/sebastienlato/offline-first-swiftui-architecture-4bei
- RxDB Supabase replication (outbound queue): https://rxdb.info/replication-supabase.html
- PowerSync + Supabase: https://docs.powersync.com/integration-guides/supabase-+-powersync
- PowerSync offline-first blog: https://powersync.com/blog/bringing-offline-first-to-supabase

**Sign in with Apple**
- Apple HIG — Sign in with Apple: https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
- Apple — configure private email relay service: https://developer.apple.com/help/account/capabilities/configure-private-email-relay-service/
- Apple — communicating via private email relay: https://developer.apple.com/documentation/signinwithapple/communicating-using-the-private-email-relay-service
- Understanding Apple private relay addresses (Maileroo): https://maileroo.com/blog/understanding-apples-private-relay-email-addresses-privaterelay-appleid-com-what-they-are-and-how-they-work/

> _Last researched: June 2026. Apple's App Store Review Guidelines, Small Business Program terms, and
> Supabase Realtime APIs change frequently — re-verify on the official pages before implementation._
