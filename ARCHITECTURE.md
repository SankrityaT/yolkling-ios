# Yolkling iOS, architecture decisions

Synthesized from the four research docs in `docs/research/`. This is the source of truth for how we build. Privacy-first, social-first, production quality, no slop.

## stack
- SwiftUI, iOS 18 deployment (use iOS 26 APIs behind availability where they help)
- Swift 6.2 with **Default Actor Isolation = MainActor** + Approachable Concurrency (stop fighting the compiler; `@concurrent` only for measured background work)
- **SwiftData as the on-device store, NO CloudKit.** "Local-only" here means we do not use Apple's CloudKit auto-sync, it is NOT a no-backend decision. SwiftData is the fast local cache (instant + offline). Supabase is the one backend for sync + the whole social layer (see below). Skipping CloudKit avoids a second sync system fighting Supabase and shrinks the privacy surface.
- **Supabase backend (Postgres + Realtime + RLS)** powers everything social and cross-device: the friend graph, creature visits, postcards, and syncing your creature across your own devices. Reuses the existing yolkling project.
- StoreKit 2 directly (not RevenueCat)
- Sign in with Apple (stable user id only, Hide My Email honored)
- Generated with **xcodegen** (reproducible project, no hand-edited pbxproj)

## architecture: MV, not MVVM
- `@MainActor @Observable` aggregate **stores** scoped by bounded context: `CreatureStore`, `CareStore` (wellness), `SocialStore`, injected via `@Environment`.
- No per-screen ViewModels. Add a dedicated adapter object only to bridge non-SwiftUI APIs (notifications, HealthKit, StoreKit, sharing).
- Matches Apple's own samples (Backyard Birds, Food Truck) and plays best with SwiftData `@Query`.

## structure (feature-first)
```
Packages/
  YolklingCore/   local SPM package: the shared creature layer (Creature, Cosmetics,
                  colour/spacing/type tokens, CreaturePalette, watch sync contract).
                  Depended on by app + widget + watch + tests; never imports
                  RevenueCat / HealthKit / SwiftData / Supabase. See its README.
Yolkling/
  App/            YolklingApp, AppRoot, environment wiring
  Core/
    Configuration/   AppEnvironment (public URLs + anon key), fail-fast validation
    DesignSystem/    app-only components (YolkDialog, YolkMenu, ...); tokens live in YolklingCore
    Persistence/     SwiftData @Model schemas, ModelContainerFactory, @ModelActor
    Crypto/          client-side encryption for E2E content
    Networking/      Supabase client wrapper
    Health/          HealthKit adapter (wellness signals)
    Sync/            local-first outbox + sync actor
    Watch/           WatchPublisher (phone -> watch WatchConnectivity push)
  Features/
    Onboarding/  Hatch (vibe -> creature), Sign in with Apple
    Home/        the creature, today's care, focus session
    Friends/     friend graph, creature visits, postcards
    Store/       cosmetics (StoreKit 2)
    Settings/    privacy, account, data export/delete
YolklingWatch/    the watchOS companion app (creature on the wrist, docs/WATCH_APP.md)
```

## navigation
- `Codable`/`Hashable` `Route` enum + typed `[Route]` arrays, one `@Observable` Router per tab via `@Environment` (not `NavigationPath`, which can't be inspected).

## SwiftData
- One `ModelContainer` at app root. Local-only.
- `VersionedSchema` from v1 with tested migrations (top data-loss risk, handle from day one).
- A single `@ModelActor` for background maintenance. Respect ModelContext non-Sendability.

## security + privacy + E2E (hard requirement)
- Keychain: access/session tokens `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, refresh `AfterFirstUnlock`. Secure Enclave for keys, not data.
- Embed the Supabase **anon/publishable** key (safe, RLS guards data). NEVER ship service_role.
- At rest on device: iOS Data Protection + SwiftData file protection.
- **E2E:** client encrypts content before it leaves the device (creature data, wellness signals, postcards/visits between friends). Server only ever holds ciphertext. Honest caveat: the server sees the bare friend graph (A is friends with B) to route visits, never the content. Market exactly that, no "zero knowledge" overclaim.
- Privacy manifest (PrivacyInfo.xcprivacy) + required-reason APIs. Near-empty nutrition label. No ATT (collect nothing trackable). ATS defaults, skip cert pinning for v1.

## the creature (centerpiece)
- Pure SwiftUI `Shape` + `PhaseAnimator` for breathe/blink/react. Metal `Shader` only for the fancier touches (jiggle, glow). Not Canvas, not SpriteKit.
- Parametric: a `Vibe` drives color, body shape, face. A handful of parts -> millions of unique creatures, all in code, no art team.
- Widget is a hero surface (a little yolk on the home screen). Live Activity reserved for the focus-session timer.

## the wellness mechanic (3 tiers, deliver tiers 1 and 2, tier 3 is the bonus)
1. **Grows from wellness (solid):** HealthKit, sleep / steps / daylight / mindful minutes. No special entitlement.
2. **Phone-down focus sessions (solid, ours):** a focus timer + Live Activity. Creature thrives while you are off. This delivers "off your phone" with zero entitlement risk.
3. **Passive doomscroll reaction (bonus):** Family Controls / Screen Time entitlement, opt-in, privacy-blind (sees "2h on social", never what). Pursue it, never depend on it.

## monetization (gentle, ethical)
- StoreKit 2 direct. Non-consumable cosmetics + an optional one-time "supporter" tip. Defer subscriptions.
- Apple Small Business Program (15%). IAP only for digital goods. Earn-by-play currency + optional buy. No gacha, no loot boxes.

## social + sync
- Supabase friend graph + "creature visiting" over private Realtime channels secured by RLS.
- SwiftData local-first outbox drained by a single sync actor. Last-write-wins; server authoritative for friendship + IAP state.

## testing
- Swift Testing (`#expect`/`#require`) with in-memory `ModelContainer`. A few XCUITest happy paths. swift-snapshot-testing for the creature + key views.

## engineering principles (the bar for every line of code)
- **Loose coupling + dependency inversion.** Features depend on protocols, never concrete services. HealthKit sits behind `CareSignalsProviding`, sync behind a `SyncClient`, the shop behind a `CosmeticsStore`, creature data behind repositories. Concretes are injected at the composition root (the App), swapped for fakes in tests and previews.
- **Single responsibility / separation of concerns.** Core (domain + infrastructure) knows nothing about Features (UI). Each `@Observable` store owns exactly one bounded context. The creature renderer is pure presentation, zero data. Pure logic (the creature generator, currency math, sync reconciliation) lives in plain `Sendable` types with no UI and no IO, so it is trivially testable and Android-portable later.
- **Scalable structure.** Feature-first folders so features grow independently; the local-first outbox + a single sync actor keep the social layer off the main thread; DesignSystem / Persistence get extracted to local SPM packages when build times warrant; the procedural creature is data-driven, so adding species is adding data, not code.
- **Open/closed + interface segregation.** Small focused protocols. New behavior arrives as new conformances, not edits to existing types. No god objects.
- **Testability first.** Value types and pure functions by default (Vibe is a `struct`). A protocol seam at every external boundary. The screenshot seam pattern for deterministic UI captures.
- **No premature abstraction.** Apply the above where it earns its keep, not cargo-culted. A struct stays a struct until a protocol is genuinely needed.
