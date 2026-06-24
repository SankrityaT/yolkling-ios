# Yolkling — Architecture Research & Recommendations (2026)

> **Scope:** Production SwiftUI app, iOS 18 minimum / iOS 26 target, Swift 6 (with Swift 6.2 "Approachable Concurrency"), one developer, must be genuinely production quality.
> **App:** Yolkling — a cute, social, privacy-first virtual-creature companion (modern Tamagotchi crossed with a gentle self-care app), iOS first.
> **Date:** June 2026. Every recommendation below is backed by inline source links.

---

## 0. TL;DR — The Recommended Stack for Yolkling

| Concern | Recommendation |
| --- | --- |
| **Architecture** | **MV (Model–View)** with `@Observable` stores injected via `@Environment`. No per-screen ViewModels by default. |
| **State objects** | Plain `@Observable` classes, `@MainActor`. `@State` to own, `@Bindable` to bind, `@Environment` to share. |
| **TCA** | **Skip it** at app level. Keep in pocket for one genuinely complex feature later (it composes per-feature). |
| **Project structure** | One app target. `App/` + `Features/` + `Core/` + `Shared/`. Feature-first. |
| **Modularization** | Folders first. Extract `DesignSystem`/`Persistence` to local SPM packages only when build pain appears. No Tuist. |
| **Persistence** | SwiftData, **local-only** (privacy-first). One `ModelContainer` at root. `VersionedSchema` from v1. |
| **Concurrency** | Enable **Default Actor Isolation = MainActor** + **Approachable Concurrency**. App code is mostly `@MainActor`; `@concurrent` only for measured background work. |
| **Navigation** | One `Codable`/`Hashable` `Route` enum + typed `[Route]` array, one `@Observable` Router per tab via `@Environment`. |
| **Testing** | Swift Testing (`#expect`/`#require`) for units; in-memory `ModelContainer`; a few XCUITest happy-paths; swift-snapshot-testing for views. |
| **DI** | `@Entry` for environment values (with defaults); `.environment(store)` for `@Observable` stores; constructor-inject protocols into services. No DI library. |

---

## 1. App Architecture: MV vs MVVM vs TCA

### 1.1 The 2026 consensus

The center of gravity in 2026 has clearly shifted to the **MV (Model–View) pattern** built on `@Observable` / the Observation framework, with `@Environment`-injected model/store objects and plain services. ViewModels are no longer the default — but they are *not* dead, and a principled dissent exists.

**Apple's de facto position** (never officially named, but visible in sample code and WWDC "Data Flow Through SwiftUI" / "Discover Observation in SwiftUI"): views observe `@Observable` models directly, organized **by feature, not by technical layer**, with **"simplicity first… start with basic MV, add complexity only when needed."** This is what Apple's [Backyard Birds](https://developer.apple.com/documentation/swiftui/backyard-birds-sample) and [Food Truck](https://developer.apple.com/documentation/swiftui/food-truck-building-a-swiftui-multiplatform-app) samples actually do — no intermediate ViewModel layer. ([Analysis of Apple's structure](https://agenthicks.com/research/swiftui-project-structure-apple-guidance))

**Thomas Ricouard / Dimillian** (Ice Cubes app) is the loudest "forget MVVM" voice: *"You don't need ViewModels in SwiftUI. You never did. You never will."* He attributes MVVM adoption to UIKit baggage and argues a ViewModel means *"fighting the framework's core design."* His recommended stack: prefer `@State`, `@Environment`, `@Query`, `.task`, `.onChange`; inject services/shared models via `@Environment`; keep logic in services/models. ([SwiftUI in 2025: Forget MVVM](https://dimillian.medium.com/swiftui-in-2025-forget-mvvm-262ff2bbd2ed), [MV patterns reference](https://github.com/Dimillian/Skills/blob/main/swiftui-view-refactor/references/mv-patterns.md))

**azamsharp** (who popularized the "MV pattern" name): *"Views are the view model."* Per-screen ViewModels manufacture redundant sources of truth. His pattern:
1. View → Model directly.
2. One `@Observable` **aggregate root / Store** is the gateway to value-type models (structs), owning networking, persistence, sorting.
3. Inject the Store via the Environment at the app root.
4. **Scale by bounded context, not by screen count** — multiple Stores aligned to business domains (e.g. for Yolkling: a `CreatureStore`, a `CareStore`, a `SocialStore`), never "one store per screen."
5. Validation → testable structs; test *behavior*, not implementation; avoid heavy mocking.

([Building Large Scale Apps in SwiftUI](https://azamsharp.com/2023/02/28/building-large-scale-apps-swiftui.html), [Intro to MV State Pattern](https://azamsharp.com/2022/08/09/intro-to-mv-state-pattern.html), [Practical MV Pattern CRUD](https://azamsharp.com/2022/10/06/practical-mv-pattern-crud.html))

### 1.2 The principled dissent (keep as a guardrail)

**Matteo Manferdini** argues MV is *"just MVC with a fresh coat of paint"* and that ideologically rejecting ViewModels is itself an anti-pattern that hurts testability/maintainability as an app grows. His real, useful point: distinguish a *legitimate presentation/state object* from a cargo-culted per-screen `ObservableObject`. ([The Myth of the MV pattern](https://matteomanferdini.com/swiftui-mv-pattern/), [Why Dismissing View Models…](https://matteomanferdini.com/swiftui-viewmodel/))

**The durable principle under all the labels:** *keep domain/business logic out of your views and independently testable.* MV satisfies this **as long as your Stores aren't god objects.** Rule of thumb: split any `@Observable` class that exceeds ~10–12 properties or mixes unrelated bounded contexts. ([Emrld Labs — Solo Dev Architecture 2026](https://emrldlabs.com/blog/swiftui-app-architecture-for-solo-developers-in-2026/))

### 1.3 When is a ViewModel STILL worth it?

From Dimillian's MV-patterns reference — treat a dedicated state object as the **exception, not the default**.

**Do NOT add one** if it would primarily: mirror local view state; wrap `@Environment` values already available; duplicate `@Query`/`@State` flow; exist only because the view body is long (split the view instead); or hold one-off async loading (use `.task` + a service). Critically, **do not add a ViewModel just to make a simple view "testable"** — test the service/model/transformation instead.

**A dedicated state object IS justified when:**
- **Complex form/business logic** that benefits from isolated unit tests (put it in a testable struct or the Store — out of the view).
- **Bridging non-SwiftUI APIs** — a delegate-based SDK, `CLLocationManager`, a Combine publisher, `HealthKit`/notification callbacks. You need an adapter object. **This is the most likely legitimate case for Yolkling** (e.g. wrapping local notification scheduling for creature care reminders, or a Game Center / sharing SDK).
- **Multiple views sharing presentation-specific state** not better modeled at app/environment level.

**SwiftData nudge:** `@Query` only works inside a SwiftUI view's environment, which makes it incompatible with a classic MVVM ViewModel. Paul Hudson notes MVVM *"works really badly with SwiftData."* Since Yolkling uses SwiftData, this strongly reinforces MV. ([Paul Hudson — MVVM + SwiftData](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-use-mvvm-to-separate-swiftdata-from-your-views))

### 1.4 `@Observable` vs `@ObservableObject` — settled

For all new iOS 17+ code, use **`@Observable`**. Headline win: **fine-grained, per-property observation** — SwiftUI re-renders only the views that read the *changed* property, versus `ObservableObject` notifying *every* observer on *any* `@Published` change. ([Donny Wals — @Observable explained](https://www.donnywals.com/observable-in-swiftui-explained/))

**Migration map:**

| Old (`ObservableObject`) | New (`@Observable`) | Role |
| --- | --- | --- |
| `@StateObject var x = Foo()` | `@State var x = Foo()` | **Ownership/lifecycle** — the view that *creates* it |
| `@ObservedObject var x: Foo` | plain `let x: Foo` | **Dependency** — a view that *receives* it |
| `@ObservedObject` + needs `$binding` | `@Bindable var x: Foo` | Receives **and** needs two-way bindings (`$x.name`) |
| `@EnvironmentObject var x: Foo` | `@Environment(Foo.self) var x` (+ `.environment(foo)`) | **Shared** dependency |

Subtleties:
- `@State` on an `@Observable` is about **caching the instance across redraws** (lifecycle), *not* triggering redraws. Only the view that *creates* the instance uses `@State`. ([Donny Wals](https://www.donnywals.com/observable-in-swiftui-explained/))
- A plain `let` property cannot produce `$`-bindings — use `@Bindable` when a child view needs to bind into a received/`@Environment` object.
- **Not a literal drop-in**: observation fires only for properties *read in the body*; computed properties and collections behave differently than naive `ObservableObject` expectations. ([Jesse Squires](https://www.jessesquires.com/blog/2024/09/09/swift-observable-macro/))
- Mark UI-bound `@Observable` classes `@MainActor` (mostly automatic under Swift 6.2 default isolation — see §4).

### 1.5 TCA in 2026 — skip it for Yolkling

TCA gives traceable unidirectional state, explicit/testable side effects, and exhaustive tests. The modern `@Reducer` + `@ObservableState` macros killed the old `ViewStore` ceremony. ([Point-Free TCA](https://github.com/pointfreeco/swift-composable-architecture), [Observation comes to TCA](https://www.pointfree.co/blog/posts/130-observation-comes-to-the-composable-architecture))

**But for a solo dev on a medium app, it's usually overkill:** significant learning curve and boilerplate even with macros, a third-party dependency to track against Swift/SwiftUI releases (Swift 6.2 main-actor changes already caused friction), and it fights `@Query`/`@Environment`-native flow. Repeated community guidance: *"Don't adopt TCA solo unless you specifically want to invest in learning it… use MV until you hit a specific problem it cannot solve, then consider TCA for that feature only."* ([Emrld Labs](https://emrldlabs.com/blog/swiftui-app-architecture-for-solo-developers-in-2026/), [7Span — MVVM vs Clean vs TCA](https://7span.com/blog/mvvm-vs-clean-architecture-vs-tca))

**Verdict for Yolkling:** MV is the right default. It matches Apple's samples, Dimillian, and azamsharp, is the lowest-friction path for a solo dev, and plays best with SwiftData. TCA stays optional and per-feature.

---

## 2. Project / Folder Structure

### 2.1 Feature-first hybrid

The 2026 consensus: **organize by feature, not by type.** A feature folder is self-contained (delete it to delete the feature). Cross-cutting code lives in a shared tree. The de-facto layout is a **three-pronged hybrid**: `Features/` + `Core/` + `Shared/`, plus a top-level `App/` and `Resources/`. Inside a single feature, the small `Views/ViewModels/Components` split is fine because the set is small and cohesive. ([How to Structure a SwiftUI Project in 2026](https://dev.to/__be2942592/how-to-structure-a-swiftui-project-in-2026-41m8), [How I Structure My SwiftUI Projects for Scalability](https://medium.com/ios-lab/how-i-structure-my-swiftui-projects-for-scalability-555dbcc7637e))

Keep `App/` and `Assets.xcassets` at the **top level**, and mirror the filesystem to Xcode groups (Xcode 16/26 synchronized folder groups do this automatically). ([BottleRocket iOS Project Standards](https://github.com/BottleRocketStudios/iOS-Project-Standards/blob/main/Project%20Structure/Project%20Structure.md))

### 2.2 Modularization: folders first, packages later, no Tuist

For a solo medium app, **start with a single app target.** Modularization's payoff (build isolation, enforced `public`/`internal` boundaries) only materializes at scale — the pain shows up around ~40 features, not 4. ([Nitish Gadangi](https://nitishgadangi.medium.com/building-modular-ios-apps-that-scale-part-1-the-foundation-2b6c0c05c758), [Pixelmatters](https://www.pixelmatters.com/insights/how-we-cut-ios-build-times-using-swift-packages))

**Middle path:** extract the *stable, cross-cutting* pieces into **local SPM packages early** when build pain appears — `DesignSystem` first (most reused, most stable), then `Persistence`, then any `Networking`. Local packages give you compiler-enforced boundaries (`internal` is default; only `public` escapes) and faster incremental builds. Keep `Features/` as folders far longer. ([Garejakirit — Modular SPM](https://medium.com/@garejakirit/modern-ios-architecture-building-a-modular-project-with-swift-package-manager-94f6d3fc106c), [Nimble — Modularize iOS + SPM](https://nimblehq.co/blog/modern-approach-modularize-ios-swiftui-spm))

**Tuist is overkill** below ~20 modules. Recommendation: *"Start with SPM — and when build times or project management become painful, evaluate Tuist."* A solo dev on Yolkling should **not** adopt Tuist. ([Andre Nogueira — SPM vs Tuist](https://andrevini.dev/blog/ios-modularization-tools), [Runway — Getting started with Tuist](https://www.runway.team/blog/getting-started-with-tuist-for-xcode-project-generation-and-modularization-on-ios))

### 2.3 Recommended structure for Yolkling

```
Yolkling/
├── App/
│   ├── YolklingApp.swift            # @main; builds ModelContainer, injects env stores
│   ├── AppConfiguration.swift
│   └── RootView.swift               # TabView root + per-tab NavigationStacks
│
├── Features/
│   ├── Onboarding/
│   │   ├── Views/
│   │   │   ├── OnboardingScreen.swift
│   │   │   └── WelcomePageView.swift
│   │   └── OnboardingState.swift    # @AppStorage "hasOnboarded", egg-hatch flow
│   │
│   ├── Home/                        # the nursery / main creature view
│   │   ├── Views/
│   │   │   ├── HomeScreen.swift
│   │   │   └── CreatureSceneView.swift
│   │   └── Components/
│   │
│   ├── CreatureDetail/
│   │   ├── Views/
│   │   │   ├── CreatureDetailScreen.swift
│   │   │   ├── CreatureStatsView.swift
│   │   │   └── CareActionsView.swift
│   │   └── Components/
│   │
│   ├── Care/                        # feeding, play, self-care check-ins
│   │   ├── Views/
│   │   └── CareReminderService.swift # adapter: wraps UNUserNotificationCenter
│   │
│   ├── Social/                      # privacy-first sharing (see §8)
│   │   └── Views/
│   │
│   └── Settings/
│       └── Views/
│           └── SettingsScreen.swift
│
├── Core/
│   ├── Models/                      # SwiftData @Model — app-wide entities
│   │   ├── Creature.swift
│   │   ├── CareEvent.swift
│   │   └── MoodLog.swift
│   ├── Persistence/
│   │   ├── ModelContainer+App.swift # schema + VersionedSchema config
│   │   ├── Schema/                  # SchemaV1, SchemaV2, MigrationPlan
│   │   └── DataActor.swift          # @ModelActor for background imports/maintenance
│   ├── Stores/                      # @Observable aggregate roots (bounded contexts)
│   │   ├── CreatureStore.swift
│   │   └── CareStore.swift
│   └── Services/
│       └── HapticsService.swift
│
├── Shared/
│   ├── DesignSystem/                # → first local SPM package candidate
│   │   ├── Theme/  (Colors, Fonts, Spacing)
│   │   └── Components/ (PrimaryButton, GlassCard, LoadingView)
│   ├── Navigation/
│   │   ├── Route.swift              # Hashable + Codable route enum
│   │   └── Router.swift            # @Observable, one instance per tab
│   ├── Environment/
│   │   └── EnvironmentValues+App.swift  # @Entry custom values
│   ├── Extensions/                  # Type+Purpose.swift
│   └── Utilities/
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.xcstrings
│   └── Info.plist
│
├── YolklingTests/                   # Swift Testing
└── YolklingUITests/                 # XCUITest (a few happy-paths)
```

**Key placement decisions:**
- `Creature` is shared by Home + Detail + Care → **`Core/Models/`** (app-wide). A model used by only one feature would live in that feature.
- The `ModelContainer` is configured in `Core/Persistence/` and injected at the App root. Views use `@Query`/`@Environment(\.modelContext)` directly — no repository layer unless a real second backend appears. ([azamsharp — SwiftData Architecture Patterns](https://azamsharp.com/2025/03/28/swiftdata-architecture-patterns-and-practices.html))
- **Naming conventions:** one type per file; `…Screen` for full screens vs `…View` for reusable views ([Scott Smith](https://scottsmithdev.com/screen-vs-view-in-swiftui)); `Type+Purpose.swift` for extensions; `UpperCamelCase` types / `lowerCamelCase` members ([Google Swift Style Guide](https://google.github.io/swift/)).

---

## 3. SwiftData Best Practices & Gotchas

> **Blunt framing:** SwiftData is production-viable for a Yolkling-sized app but is **less mature than Core Data** (no batch insert/update, predicate holes, iOS 18-era regressions). Since Yolkling is **privacy-first and local-only**, you sidestep the single hardest area (CloudKit sync) — a major risk reduction. ([Fatbobman — Key Considerations](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/))

### 3.1 ModelContainer setup

- **One container, created at the app root** via the `.modelContainer(...)` modifier. That wires `mainContext` into `\.modelContext` and the system `undoManager`. Centralize creation in `Core/Persistence/`. ([Use Your Loaf — Saving Changes](https://useyourloaf.com/blog/swiftdata-saving-changes/))
- **Local-only (privacy-first):** simply do *not* add the iCloud/CloudKit capability. SwiftData defaults to a local SQLite store. Local-first treats the on-device store as primary; this aligns perfectly with Yolkling's no-account, no-tracking model. ([Designing Local-First Architectures with SwiftData](https://medium.com/@gauravharkhani01/designing-efficient-local-first-architectures-with-swiftdata-cc74048526f2), [Emrld Labs — Privacy-First App Design](https://emrldlabs.com/blog/privacy-first-app-design/))
- **Previews/tests:** in-memory container via `ModelConfiguration(isStoredInMemoryOnly: true)`. In Xcode 16+, prefer the `PreviewModifier`/`@Previewable` machinery for shared preview data. ([Paul Hudson — SwiftData in Previews](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-use-swiftdata-in-swiftui-previews))
- **Preview crash gotcha:** reading `\.modelContext` in a view without attaching a container crashes the preview/app.
- **Autosave** is on by default for the main context; group related writes in `context.transaction { }` (persists even if autosave is off). ([Fatbobman — Transactions vs Save](https://fatbobman.com/en/posts/using-transactions-instead-of-save-in-swiftdata-and-core-data/))

### 3.2 @Model design

- **Relationships:** default delete rule is `.nullify`; set `.cascade` explicitly where children should die with the parent (e.g. a `Creature`'s `CareEvent`s likely cascade). **Always set inverse relationships explicitly** — SwiftData only infers them in limited cases, and missing/mis-set inverses cause "delete not working"/orphan bugs. ([Fatbobman — Relationships](https://fatbobman.com/en/posts/relationships-in-swiftdata-changes-and-considerations/), [Paul Hudson — cascade deletes](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-cascade-deletes-using-relationships))
- **To-many append performance — major gotcha:** appending to a relationship **one element at a time** is catastrophically slow (~750× slower than Core Data because SwiftData diffs the whole array per append). Build a local array and `append(contentsOf:)` once. ([Fatbobman](https://fatbobman.com/en/posts/relationships-in-swiftdata-changes-and-considerations/))
- **`#Unique` / `#Index` (iOS 18+):** compound uniqueness (`#Unique<Creature>([\.name, \.hatchedDate])`, upserts on conflict) and stored indexes on hot filter/sort columns (`#Index<Creature>([\.name])`). ([Yaacoub — Index/Unique macros](https://yaacoub.github.io/articles/swift-tip/swiftdata-s-new-index-and-unique-macros/))
- **Enums in predicates — runtime trap:** filtering/sorting by an enum case in `#Predicate` compiles but **throws `unsupportedPredicate` at runtime**. Workaround: persist the `rawValue` (e.g. `moodRaw: Int`) and expose the enum as a computed property; filter on `moodRaw`. (Improved in iOS 26, but use the workaround for iOS 18 support.) ([Fatbobman — Codable & Enums](https://fatbobman.com/en/posts/considerations-for-using-codable-and-enums-in-swiftdata-models/), [azamsharp — filtering by enum](https://azamsharp.com/2025/01/23/filtering-swiftdata-models-using-enum.html))
- **Init gotcha:** assigning a default relationship instance in an initializer (e.g. `var tag: Tag = Tag(...)`) compiles but crashes with "Failed to find any currently loaded container."
- **`@Transient`** for computed/non-persisted state (needs a default).

### 3.3 Schema migrations (highest data-loss risk)

- **Ship a `VersionedSchema` from v1**, even though it's painful to retrofit. Bump `Schema.Version` on **every** change — identical version identifiers silently misbehave. ([AtomicRobot — Migrations Guide](https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/), [Manikanta — Practical Guide](https://medium.com/@manikantasirumalla5/handling-swiftdata-schema-migrations-a-practical-guide-e58e05bd3071))
- **Lightweight** handles additive changes (new models, new properties *with defaults*). Anything structural (rename, type change, split/merge) needs a **custom `MigrationStage`** in a `SchemaMigrationPlan` with `willMigrate`/`didMigrate`. ([Paul Hudson — complex migration](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-complex-migration-using-versionedschema))
- **Production gotchas:** changing a property's **type** can silently drop data; multi-version plans frequently **"work in Xcode but crash in TestFlight/App Store on first launch."** **Test migrations from an actually-installed prior build** and via TestFlight before release — write Swift Testing cases that seed a v(N-1) store, run the plan, and assert rows/fields survive. ([Apple Forums — data loss](https://developer.apple.com/forums/thread/758203), [Apple Forums — production crash](https://developer.apple.com/forums/thread/742904), [Anton Begehr — Testing Migrations](https://medium.com/@abegehr/testing-swiftdata-migrations-7a612da2c91c))

### 3.4 Fetch performance

- **`#Predicate` limits:** enum/RawRepresentable comparisons throw at runtime (use rawValue); "member access without an explicit base" → capture values into locals before the closure. ([MarkBattistella](https://markbattistella.com/writings/2025/swift-data-predicate/))
- **`FetchDescriptor` tuning:** `fetchLimit`/`fetchOffset` (pagination), `propertiesToFetch` (avoid loading all fields), `relationshipKeyPathsForPrefetching` (avoid N+1 faulting), `sortBy:`. ([Paul Hudson — optimize performance](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-optimize-the-performance-of-your-swiftdata-apps))
- **`@Query` runs on the main thread and loads all fields.** Fine for Yolkling's expected small datasets (a handful of creatures, care logs), but for any large history view, fetch off-main via a `ModelActor` and hand back lightweight DTOs, or use `FetchDescriptor` on a background context. ([Apple Forums — large datasets](https://developer.apple.com/forums/thread/811903))
- **Batch:** `context.enumerate(_:batchSize:)` streams large sets (default batchSize 5000). `delete(model:where:)` for batch delete. **Batch insert/update are still not available natively.** ([Paul Hudson — enumerate](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-enumerate-a-fetch-request-to-handle-lots-of-data-efficiently), [Fatbobman — Batch Delete](https://fatbobman.com/en/snippet/how-to-batch-delete-data-in-swiftdata/))

### 3.5 Threading / concurrency under Swift 6 (critical)

**Memorize the Sendability rules:**
- `ModelContainer` **IS Sendable** → safe to pass into actors.
- `PersistentIdentifier` **IS Sendable** → the correct way to pass model references across contexts/actors.
- `ModelContext` is **NOT Sendable**, and `@Model` objects (`PersistentModel`) are **NOT Sendable.** The Swift 6 compiler now *enforces* this. **Never pass a context or live model between actors/threads.** ([Paul Hudson — SwiftData + concurrency](https://www.hackingwithswift.com/quick-start/swiftdata/how-swiftdata-works-with-swift-concurrency), [Fatbobman — Concurrent Programming](https://fatbobman.com/en/posts/concurret-programming-in-swiftdata/))

**`@ModelActor` for background work:** pass the (Sendable) container into a `@ModelActor`, which owns an actor-isolated context on a serial executor.

```swift
@ModelActor
actor DataActor {
    func purgeOldCareEvents(before date: Date) throws { /* fetch + delete + save */ }
}
```

Crossing the boundary safely — **two patterns:** (1) pass `PersistentIdentifier`s and re-fetch via `context.model(for:)`; or (2) map to immutable **`Sendable` DTOs** inside the actor and return those.

**The "where does the actor run?" gotcha:** a `@ModelActor`'s thread is fixed at *instantiation time* by the creating thread. Create it on the main thread and its context runs on the main queue (no background benefit). To truly go off-main, instantiate from `Task.detached` (or a background context). Avoid `.background` task priority (~5× slowdown). ([Fatbobman — Concurrent Programming](https://fatbobman.com/en/posts/concurret-programming-in-swiftdata/), [SamHastings — Use SwiftData like a boss](https://medium.com/@samhastingsis/use-swiftdata-like-a-boss-92c05cba73bf))

**Swift 6.2 / Xcode 26 default-isolation gotcha:** under module-wide `@MainActor` default isolation, an unannotated `@Model` is inferred `@MainActor`; using it from a background `@ModelActor` errors with *"Main actor-isolated conformance… cannot be used in actor-isolated context."* Fix: mark models used in background actors `@Model nonisolated final class …` (does **not** make them Sendable). ([Donny Wals — actor-isolated conformance](https://www.donnywals.com/solving-actor-isolated-protocol-conformance-related-errors-in-swift-6-2/))

**For Yolkling:** most data work is small and main-thread `@Query` is fine. Reserve a single `DataActor` for occasional background maintenance (purging old logs, seeding/importing creature templates). Don't over-engineer background contexts you don't need.

### 3.6 Known bugs / status (2024–2026)

- **Background `@ModelActor` writes didn't refresh `@Query` views (iOS 18)** — a regression from iOS 17; partially fixed in 18.1, **reported resolved in the iOS 26 cycle.** Prefer **iOS 18.1+** if you rely on background→UI updates. ([Apple Forums](https://developer.apple.com/forums/thread/758882), [CreateWithSwift — WWDC 2025](https://www.createwithswift.com/wwdc-2025-whats-new-for-the-apple-community/))
- iOS 18 is generally **less stable than iOS 17** (large internal rewrite); iOS 26 closes several gaps (Codable in predicates, `@Query` sectioning, model inheritance, new observer APIs).
- **AppIntent/extension isolation (iOS 18):** a `ModelContainer` built in an extension writes data the main app won't see until relaunch — relevant if Yolkling adds widgets/App Intents for creature status.

---

## 4. Swift 6 Strict Concurrency — Practical Guidance

> **The single most important takeaway:** in 2026, app code should be **mostly `@MainActor`**, and Swift 6.2's "Approachable Concurrency" + "Default Actor Isolation = MainActor" build settings exist specifically to make that the default so you stop fighting the compiler.

### 4.1 The recommended setup

1. **Enable both Xcode 26 build settings** on the app target: `Default Actor Isolation = MainActor` and `Approachable Concurrency = Yes`. New Xcode 26 projects do this by default; verify yours does. ([Donny Wals — default actor isolation in Xcode 26](https://www.donnywals.com/setting-default-actor-isolation-in-xcode-26/), [SwiftLee — Default Actor Isolation](https://www.avanderlee.com/concurrency/default-actor-isolation-in-swift-6-2/))
2. Let almost everything be `@MainActor` implicitly. Target architecture: *"lots of `@MainActor` with little bits of `nonisolated`/`@concurrent` here and there to get stuff off the main thread."* ([Massicotte — Mistakes with Concurrency](https://www.massicotte.org/mistakes-with-concurrency/))
3. Reach for **`@concurrent`** only with a *measured* need (image processing for creature avatars, large JSON decode). ([Donny Wals — @concurrent](https://www.donnywals.com/what-is-concurrent-in-swift-6-2/))
4. **Avoid custom `actor` types** unless you have non-Sendable mutable state requiring atomicity that can't live on an existing actor. (The `@ModelActor` for SwiftData is the main legit actor in Yolkling.)

### 4.2 @MainActor

- **SwiftUI `View`s are already `@MainActor`** (the whole protocol, since Xcode 16) — you don't annotate views. Opt a method out with `nonisolated func … async`. ([Fatbobman — Views and @MainActor](https://fatbobman.com/en/posts/swiftui-views-and-mainactor/))
- **`@Observable` stores:** main-actor bound (Apple WWDC25 "Elevate an app with Swift concurrency" / DTS guidance). With default isolation on, the *"Main actor-isolated default value in a nonisolated context"* error for `@State var store = Store()` largely evaporates because view + store + surrounding code are all implicitly `@MainActor`. ([Apple Forums](https://developer.apple.com/forums/thread/798211))
- Prefer `@MainActor` on the **whole type**, `nonisolated` on the **specific** members that must run off-main.

### 4.3 Sendable, actors, the toolkit

- **Sendable** = safe to cross isolation boundaries. Value types are implicitly Sendable if all members are; `final` classes with immutable `let` Sendable properties qualify. **`@unchecked Sendable` is a smell** — it disables checking, not adds safety; use only for reference types with genuine internal synchronization, documented. ([SwiftLee — Sendable](https://www.avanderlee.com/swift/sendable-protocol-closures/))
- **Region-based isolation (Swift 6)** lets you pass a non-Sendable value across a boundary if the compiler proves you don't use it again on the original side — this is why much code that *would* have errored now compiles. `sending` is the explicit escape hatch. ([Massicotte — Glossary](https://www.massicotte.org/concurrency-glossary/))
- **Custom `actor` only when** all are true: non-Sendable mutable state, **and** operations must be atomic, **and** they can't run on an existing actor. A stateless actor used just to "run off main" is an anti-pattern — use `@concurrent`/`nonisolated`. ([Massicotte](https://www.massicotte.org/mistakes-with-concurrency/))
- **`@concurrent` (Swift 6.2):** forces an async function onto the global/background executor. Needed because 6.2 changed `nonisolated async` to inherit the caller's isolation rather than auto-hopping to background. ([Donny Wals — @concurrent](https://www.donnywals.com/what-is-concurrent-in-swift-6-2/))

### 4.4 Common migration pitfalls (how not to fight the compiler)

- **"Non-Sendable crossing actor boundary":** fix order → value type → `final` immutable class → rely on region-based isolation → `sending` → (last resort) documented `@unchecked Sendable`.
- **Capturing `self`/mutable vars in `Task`/`@Sendable` closures:** capture immutable `let` copies, or keep work on the same actor. Mental model: *imagine every `Task { }` randomly delays its body.* ([Massicotte](https://www.massicotte.org/mistakes-with-concurrency/))
- **Bridging callbacks:** `withChecked[Throwing]Continuation` with a `@Sendable` callback; do main-actor UI updates *after* `await`, back on the actor. ([Swift Forums](https://forums.swift.org/t/using-withcheckedcontinuation-etc-in-an-actor/58763))
- **Third-party non-Sendable types:** `@preconcurrency import SomeFramework` is a legitimate *staged* tool, not defeat.
- **Actor-isolated protocol conformance** (e.g. `Codable`/`Equatable` on a `@MainActor` type): mark the **conformance** `@MainActor` if no background benefit, or the type `nonisolated` if you want background encode/decode. ([Donny Wals — actor-isolated conformance](https://www.donnywals.com/solving-actor-isolated-protocol-conformance-related-errors-in-swift-6-2/))

### 4.5 Structured concurrency

- `Task { }` inherits enclosing actor + priority; `Task.detached { }` does not — avoid unless deliberately escaping isolation.
- `async let` for a fixed number of concurrent children; `TaskGroup` for a dynamic number (auto-cancels children if the parent is cancelled).
- Cancellation is cooperative — check `Task.isCancelled` in long loops. SwiftUI's `.task {}` auto-cancels on disappear.
- `MainActor.assumeIsolated { }` is a runtime assertion you're *already* on main — use only when you can guarantee it (it traps otherwise).

### 4.6 Migration strategy (even for a fresh project)

Start a new Yolkling project in **Xcode 26 with the Swift 6 + Approachable Concurrency defaults** — you skip the legacy migration. If you ever pull in older code: Swift 5 mode + `SWIFT_STRICT_CONCURRENCY = complete` (warnings) → fix leaf→app → flip to Swift 6 per target. *Enabling the warnings is progress, not failure.* ([Official Migration Guide](https://github.com/swiftlang/swift-migration-guide/blob/main/Guide.docc/MigrationGuide.md), [SwiftLee](https://www.avanderlee.com/concurrency/swift-6-migrating-xcode-projects-packages/))

**Quick reference card:**

| Situation | Do this |
| --- | --- |
| App target, Xcode 26 | Enable Approachable Concurrency + Default Actor Isolation = MainActor |
| `@Observable` store | `@Observable` + `@MainActor` (implicit under default isolation) |
| SwiftUI View | Already `@MainActor` — don't annotate |
| Heavy decode/image work | `@concurrent func` |
| SwiftData background maintenance | `@ModelActor` created from `Task.detached`; pass `PersistentIdentifier`/DTOs |
| `@Model` used off-main | `@Model nonisolated final class …` |
| Bridge a callback API | `withCheckedContinuation` + `@Sendable` callback |
| Make an error vanish "for now" | `@preconcurrency import` / `@unchecked Sendable` — staged, documented |

---

## 5. Navigation: NavigationStack + Programmatic Routing

### 5.1 Core rules

- **Always use value-based navigation:** `NavigationLink(value:)` / programmatic path append + `.navigationDestination(for: Route.self)`. Never nest `NavigationStack`s. ([SwiftUI Navigation in 2026](https://dev.to/__be2942592/swiftui-navigation-in-2026-the-complete-guide-navigationstack-deep-links-coordinators-hpk))
- **Typed `[Route]` array over `NavigationPath`** for Yolkling: `NavigationPath` is type-erased and **can't expose its contents** (you can only `count`/`removeLast`). A single homogeneous `Route` enum in a typed array is inspectable, trivially `Codable`, and easy to reconstruct from deep links. Use `NavigationPath` only if you genuinely need heterogeneous route types in one stack. ([NavigationPath Mastery](https://21zerixpm.medium.com/programmatic-navigation-in-swiftui-navigationpath-mastery-c68394a994ff), [Swift with Majid — NavigationPath](https://swiftwithmajid.com/2022/10/05/mastering-navigationstack-in-swiftui-navigationpath/))

### 5.2 The @Observable Router pattern (recommended)

```swift
@Observable
final class Router {
    var path: [Route] = []
    func push(_ route: Route) { path.append(route) }
    func pop() { if !path.isEmpty { path.removeLast() } }
    func popToRoot() { path.removeAll() }
}
```

This replaces the heavier UIKit-era Coordinator (no protocols/delegates/factories) and handles ~80% of what elaborate coordinator systems did, far more simply. Inject it via `@Environment`; **keep nav state in the Router, not in stores/view models** (storing nav state in view models is explicitly called out as a mistake). The formal Coordinator protocol is over-engineering for a solo medium app. ([Router Pattern — Type-Safe Navigation](https://21zerixpm.medium.com/router-pattern-in-swiftui-type-safe-navigation-made-simple-7bcf5178bbe0), [dev.to 2026 guide](https://dev.to/__be2942592/swiftui-navigation-in-2026-the-complete-guide-navigationstack-deep-links-coordinators-hpk))

### 5.3 Tabs, iPad, sheets, deep links

- **iOS 18 `Tab` API:** `TabView { Tab("Home", systemImage: "house") { … } }` — type-safe, replaces deprecated `.tabItem`. **Each tab gets its own `NavigationStack` + its own `Router`** — sharing one path across tabs causes bugs. On iOS 26, tab bars auto-adopt Liquid Glass. ([iOS 18 Tab API](https://swiftuiblog.substack.com/p/hello-world), [Donny Wals — tab bars on iOS 26](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/))
- **iPad:** `NavigationSplitView`, or `.tabViewStyle(.sidebarAdaptable)`. Test combinations carefully (documented rough edges). (Yolkling is iOS-first, so keep iPad support minimal initially.)
- **Sheets/modals are separate from the stack:** `Identifiable` enum + `.sheet(item:)`. Don't model sheets as stack pushes.
- **Deep linking:** parse incoming URLs into a `Route`, `popToRoot()`, then push. **State restoration:** with a `Codable` `Route` enum, JSON-encode the typed array into `@SceneStorage` to restore after termination. ([Swift with Majid — Deep Linking](https://swiftwithmajid.com/2022/06/21/mastering-navigationstack-in-swiftui-deep-linking/), [State Restoration / Cold Launch / Deep Links / Tabs](https://dev.to/sebastienlato/swiftui-navigation-state-restoration-cold-launch-deep-links-tabs-543c))

---

## 6. Testing

### 6.1 Swift Testing as the default

Swift Testing (WWDC 2024, ships with Xcode 16+/Swift 6) is the 2026 default for **all new unit/integration tests.** XCTest isn't deprecated and the two coexist in one target, so **don't rewrite — write new tests in Swift Testing, migrate old ones opportunistically.** Don't mix the two *within a single test*. ([Fatbobman — Mastering Swift Testing](https://fatbobman.com/en/posts/mastering-the-swift-testing-framework/), [Swift Testing vs XCTest](https://swiftpublished.in/article/swift-testing-xctest))

- **Two assertions replace 40+ `XCTAssert*`:** `#expect(...)` (soft — records and continues) and `#require(...)` (hard — throws/stops; also unwraps optionals).
- **`@Test` / `@Suite`:** no `XCTestCase` subclassing; a fresh suite instance per test, so no state leakage; **parallel by default**; async/await is first-class; `confirmation` for callback APIs.
- **Traits:** `.tags(...)`, `.enabled(if:)`, `.disabled(...)`, `.serialized`, `.timeLimit(...)`, `.bug(...)`. Tags cross suite boundaries.
- **Parameterized:** `@Test(arguments:)` runs one body across many inputs; `zip(...)` to pair (vs Cartesian product of two collections). ([SwiftLee — parameterized](https://www.avanderlee.com/swift-testing/parameterized-tests-reducing-boilerplate-code/), [Swift with Majid — parameterized](https://swiftwithmajid.com/2024/11/12/introducing-swift-testing-parameterized-tests/))

**What stays in XCTest:** UI tests (XCUITest) and `measure`-based performance tests.

### 6.2 Testing SwiftData + @Observable

- **In-memory `ModelContainer`** (`isStoredInMemoryOnly: true`) per test → clean, isolated, disk-free. Inject its `mainContext` into the store/model under test. ([Paul Hudson — unit tests for SwiftData](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code))

```swift
@Test func feedingIncreasesFullness() throws {
    let container = try ModelContainer(
        for: Creature.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let store = CreatureStore(context: container.mainContext)
    let yolk = Creature(name: "Yolk")
    store.insert(yolk)
    store.feed(yolk)
    #expect(yolk.fullness > 0)
}
```

- **`@Observable` stores:** inject `ModelContext`/service protocol via init so tests swap in the in-memory context or a mock. `@MainActor`-isolated tests respect isolation naturally with async/await.
- **Mock via protocols + DI** — depend on protocols, never concrete services. Especially important for the **adapter objects** (notification scheduler, any social/sharing SDK) so they're testable without real system services.
- **Write migration tests** (§3.3) — seed v(N-1), run the plan, assert survival. This is the highest-value test category for SwiftData.

### 6.3 UI / snapshot testing (calibrated for a solo dev)

- **XCUITest** remains the only native UI driver. It's slow and flaky — reserve it for a *small* set of critical happy-paths (onboarding/egg-hatch, core care loop, settings reset). Use **accessibility identifiers** (`onboarding_continue_button`) + the **Page Object pattern**. Launch with an argument flipping the container to `isStoredInMemoryOnly` for clean state. ([7 patterns for XCUITest](https://medium.com/@tojosphine/7-proven-patterns-for-maintainable-xcuitest-suites-839ad1bfffae), [Paul Hudson — UI tests for SwiftData](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-ui-tests-for-your-swiftdata-code))
- **Snapshot testing — high ROI for a solo dev:** Point-Free's **swift-snapshot-testing (≥ 1.17.0)** supports Swift Testing (`assertSnapshot` inside `@Test`). Host SwiftUI views in a `UIHostingController` with fixed device/size. Great for catching visual regressions in the design system and creature views cheaply versus broad XCUITest suites. ([swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing))

---

## 7. Dependency Injection via SwiftUI Environment

### 7.1 The `@Entry` macro for environment values

The **`@Entry` macro** (Xcode 16/iOS 18) removes all the old `EnvironmentKey` boilerplate — declare the value with a default directly in an `EnvironmentValues` extension:

```swift
extension EnvironmentValues {
    @Entry var theme: Theme = .yolkling   // synthesizes key/getter/setter
}
```

Always provide a **default** so reads never crash when unset. The generated code is backward-compatible to older OS versions. ([Use Your Loaf — @Entry](https://useyourloaf.com/blog/entry-macro-for-custom-swiftui-environment-values/), [SwiftLee — @Entry](https://www.avanderlee.com/swiftui/entry-macro-custom-environment-values/))

### 7.2 Injecting @Observable stores

- **`.environment(store)` + `@Environment(CreatureStore.self)`** — the iOS 17+ replacement for `@EnvironmentObject`; the idiomatic way to share `@Observable` aggregate stores across the view tree.
- **`@Entry` + `@Environment(\.keyPath)`** — for values that need a default (theme, feature flags, config).

### 7.3 Three injection patterns and testability

- **Constructor injection** of **protocols** — max compile-time safety, easiest to mock; use for **services and adapter objects** (this is your test/preview swap seam).
- **Environment injection** — for **app-wide, cross-cutting** state (the stores). Caveat: it's view-tree-bound, so a plain `@Observable` store can't read `@Environment` directly (inject from a view); and `@Environment` *without a default* can crash at runtime — `@Entry` defaults avoid this. ([Lucas van Dongen — DI frameworks compared](https://lucasvandongen.dev/di_frameworks_compared.php), [DI in Swift 2026](https://medium.com/@garejakirit/dependency-injection-in-swift-building-clean-scalable-architecture-for-modern-ios-apps-2026-59032bcd00bd))
- For **#Previews**, inject mocks via `.environment(...)`; for tests, inject via init. Depend on protocols with real / mock / preview implementations.

### 7.4 Do you need a DI library?

**No — plain Environment is enough for Yolkling.** For small-to-mid apps, manual/Environment DI is cleaner than a container. Only reach for a library if (a) your services need dependencies but can't see `@Environment`, or (b) you want centralized test/preview override ergonomics. In that case the lightest option is **Factory** (smallest, fastest); **swift-dependencies** (Point-Free) if you want overrides *outside* the view tree. Reserve Swinject/Needle for large modular codebases. ([Lucas van Dongen](https://lucasvandongen.dev/di_frameworks_compared.php), [Factory](https://github.com/hmlongco/Factory))

---

## 8. Yolkling-Specific Notes (Privacy-First, Social, Self-Care)

- **Privacy-first = local-first by default.** Skipping accounts, analytics, and tracking simplifies development *and* builds trust. SwiftData with a **local-only** store (no CloudKit capability) is the natural fit and removes the hardest SwiftData risk area. ([Emrld Labs — Privacy-First App Design](https://emrldlabs.com/blog/privacy-first-app-design/), [Local-First with SwiftData](https://medium.com/@gauravharkhani01/designing-efficient-local-first-architectures-with-swiftdata-cc74048526f2))
- **"Social" without accounts:** prefer share-sheet exports (render a creature card to an image/video and `ShareLink` it), and consider deep links / on-device handles rather than a backend identity. If real sync/sharing becomes a requirement later, evaluate **`CKSyncEngine`** (with private DB + CloudKit sharing) rather than SwiftData auto-sync, or a local-first DB like Point-Free's `sqlite-data`. Keep this behind a `SocialStore` bounded context so it's swappable.
- **Self-care / care reminders:** wrap `UNUserNotificationCenter` in a `CareReminderService` adapter (a legitimate "ViewModel-ish" object per §1.3) so scheduling logic is testable without the real system.
- **Sensitive data:** if any journaling/mood notes are stored, use Data Protection (default file protection is strong) and keep it on-device; avoid logging PII. ([OWASP MASTG — iOS Data Storage](https://mas.owasp.org/MASTG/0x06d-Testing-Data-Storage/))
- **iOS 26 Liquid Glass:** recompiling with Xcode 26 restyles `TabView`/`NavigationStack`/toolbars automatically — generally zero code changes for structural components, which suits the cute, soft aesthetic. ([Donny Wals — Liquid Glass tab bars](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/))

---

## 9. Recommended Architecture Summary

**Pattern:** MV (Model–View) on `@Observable`. Views are thin; local UI state in `@State`; shared state in `@MainActor @Observable` **aggregate stores** scoped by bounded context (`CreatureStore`, `CareStore`, `SocialStore`), injected via `.environment(_:)` and read with `@Environment(Store.self)`. Domain logic lives in stores/services and is unit-tested directly. Add a dedicated adapter object only to bridge non-SwiftUI APIs (notifications, sharing SDKs) — never one per screen.

**Persistence:** SwiftData, local-only, one `ModelContainer` at the root, `VersionedSchema` from v1, models in `Core/Models/`, `@Query` in views for small datasets, a single `@ModelActor` for occasional background maintenance. Test against in-memory containers and write migration tests.

**Concurrency:** Swift 6.2 with Default Actor Isolation = MainActor + Approachable Concurrency. Mostly `@MainActor`; `@concurrent` for measured background work; the `@ModelActor` is the one real actor.

**Navigation:** `Codable`/`Hashable` `Route` enum + typed `[Route]` array, one `@Observable` Router per tab via `@Environment`, value-based `.navigationDestination(for:)`, sheets via `.sheet(item:)`, deep links + `@SceneStorage` restoration.

**Project:** single app target, feature-first (`App/` + `Features/` + `Core/` + `Shared/`); extract `DesignSystem`/`Persistence` to local SPM packages only when build pain appears; no Tuist.

**Testing:** Swift Testing for units (in-memory SwiftData, protocol mocks), a few XCUITest happy-paths, swift-snapshot-testing for views.

**DI:** `@Entry` for environment values (with defaults), `.environment(store)` for `@Observable` stores, constructor-injected protocols for services. No DI library.

**Guardrail:** the durable principle is *keep domain logic out of views and independently testable.* MV satisfies this only if stores stay focused — split any store past ~10–12 properties or mixing bounded contexts.

---

## Appendix: Key Sources

**Architecture:** [Dimillian — Forget MVVM](https://dimillian.medium.com/swiftui-in-2025-forget-mvvm-262ff2bbd2ed) · [Dimillian — MV patterns ref](https://github.com/Dimillian/Skills/blob/main/swiftui-view-refactor/references/mv-patterns.md) · [azamsharp — Large Scale Apps](https://azamsharp.com/2023/02/28/building-large-scale-apps-swiftui.html) · [Donny Wals — @Observable](https://www.donnywals.com/observable-in-swiftui-explained/) · [Manferdini — Myth of MV](https://matteomanferdini.com/swiftui-mv-pattern/) · [Point-Free TCA](https://github.com/pointfreeco/swift-composable-architecture) · [Emrld Labs — Solo Dev 2026](https://emrldlabs.com/blog/swiftui-app-architecture-for-solo-developers-in-2026/) · [Apple Backyard Birds](https://developer.apple.com/documentation/swiftui/backyard-birds-sample)

**Project structure:** [How to Structure a SwiftUI Project in 2026](https://dev.to/__be2942592/how-to-structure-a-swiftui-project-in-2026-41m8) · [iOS Lab — Scalable structure](https://medium.com/ios-lab/how-i-structure-my-swiftui-projects-for-scalability-555dbcc7637e) · [Andre Nogueira — SPM vs Tuist](https://andrevini.dev/blog/ios-modularization-tools) · [BottleRocket Standards](https://github.com/BottleRocketStudios/iOS-Project-Standards/blob/main/Project%20Structure/Project%20Structure.md)

**SwiftData:** [Fatbobman — Concurrent Programming](https://fatbobman.com/en/posts/concurret-programming-in-swiftdata/) · [Fatbobman — Relationships](https://fatbobman.com/en/posts/relationships-in-swiftdata-changes-and-considerations/) · [Fatbobman — Key Considerations](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/) · [Paul Hudson — SwiftData + concurrency](https://www.hackingwithswift.com/quick-start/swiftdata/how-swiftdata-works-with-swift-concurrency) · [AtomicRobot — Migrations](https://atomicrobot.com/blog/an-unauthorized-guide-to-swiftdata-migrations/) · [azamsharp — SwiftData Architecture](https://azamsharp.com/2025/03/28/swiftdata-architecture-patterns-and-practices.html)

**Concurrency:** [Massicotte — Mistakes with Concurrency](https://www.massicotte.org/mistakes-with-concurrency/) · [Massicotte — Glossary](https://www.massicotte.org/concurrency-glossary/) · [Donny Wals — default actor isolation Xcode 26](https://www.donnywals.com/setting-default-actor-isolation-in-xcode-26/) · [Donny Wals — @concurrent](https://www.donnywals.com/what-is-concurrent-in-swift-6-2/) · [SwiftLee — Default Actor Isolation](https://www.avanderlee.com/concurrency/default-actor-isolation-in-swift-6-2/) · [Official Migration Guide](https://github.com/swiftlang/swift-migration-guide/blob/main/Guide.docc/MigrationGuide.md)

**Navigation:** [SwiftUI Navigation in 2026](https://dev.to/__be2942592/swiftui-navigation-in-2026-the-complete-guide-navigationstack-deep-links-coordinators-hpk) · [Router Pattern](https://21zerixpm.medium.com/router-pattern-in-swiftui-type-safe-navigation-made-simple-7bcf5178bbe0) · [Swift with Majid — NavigationPath](https://swiftwithmajid.com/2022/10/05/mastering-navigationstack-in-swiftui-navigationpath/)

**Testing:** [Fatbobman — Swift Testing](https://fatbobman.com/en/posts/mastering-the-swift-testing-framework/) · [Swift Testing vs XCTest](https://swiftpublished.in/article/swift-testing-xctest) · [Paul Hudson — unit tests for SwiftData](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code) · [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)

**DI:** [Use Your Loaf — @Entry](https://useyourloaf.com/blog/entry-macro-for-custom-swiftui-environment-values/) · [SwiftLee — @Entry](https://www.avanderlee.com/swiftui/entry-macro-custom-environment-values/) · [Lucas van Dongen — DI frameworks compared](https://lucasvandongen.dev/di_frameworks_compared.php)

**Privacy:** [Emrld Labs — Privacy-First App Design](https://emrldlabs.com/blog/privacy-first-app-design/) · [Local-First with SwiftData](https://medium.com/@gauravharkhani01/designing-efficient-local-first-architectures-with-swiftdata-cc74048526f2) · [OWASP MASTG — iOS Data Storage](https://mas.owasp.org/MASTG/0x06d-Testing-Data-Storage/)

*Sourcing caveat: some 2026-dated articles are secondary/aggregator content; primary sources (Apple docs/samples/WWDC, Donny Wals, azamsharp, Fatbobman, Point-Free, Massicotte, Paul Hudson, Manferdini, SwiftLee, Swift with Majid) were weighted more heavily for specific claims and quotes.*
