# 03 — Creature Rendering & Wellness Signals

**Project:** Yolkling — a cute virtual creature (iOS-first) that grows from real-life wellness and wants you OFF your phone.
**Scope:** Rendering/animating the creature, the "grow from self-care" signal sources (HealthKit + Screen Time), tasteful notifications, and WidgetKit/Live Activities.
**Researched:** June 2026 (iOS 26 / WWDC26 era). All claims cited inline; full source list at the end of each section.

> **TL;DR for the whole doc**
> 1. **Render the creature with plain SwiftUI `Shape`/`Path` layering** driven by `PhaseAnimator` (idle breathe/blink) + `withAnimation` springs (tap), recolored with `fill`/gradients and one `.colorEffect` Metal shader. Reserve `Canvas`+`TimelineView(.animation)` for genuinely procedural sub-effects only. Avoid SpriteKit unless it becomes a game.
> 2. **Build the "care economy" on HealthKit** (sleep, mindful minutes, steps, workouts) — reliable, grant-able, brand-aligned. Treat Screen Time / doomscroll detection as an optional, entitlement-gated, privacy-sandboxed *nudge* layer that does **not** give you per-app analytics.
> 3. **Notifications:** `.provisional` authorization + `.passive` interruption level, ≤1 gentle check-in/day, user-tunable, never guilt-trippy. Fully functional with notifications off.
> 4. **Widget is the hero surface** (ambient glance, no app session). **Skip an always-on Live Activity** — only use one for a finite, user-started phone-free focus timer.

---

## 1. Rendering & Animating the Creature (SwiftUI, 60fps, low battery)

### 1.1 Recommendation (bottom line)

For an always-visible creature that **breathes, blinks, reacts to taps, and is recolorable/parametric**, use:

- **Body & features = composed custom `Shape`s** with parameters exposed via `animatableData` (eye-openness, mouth-curve, squish, bob-offset, antenna-angle → animatable `CGFloat`/`AnimatablePair`). This is what makes the creature *parametric* and lets SwiftUI tween it on the GPU.
- **Idle loop = `PhaseAnimator` (iOS 17+)** for breathe-in → hold → breathe-out + periodic blink (loops indefinitely by default). Use **`KeyframeAnimator`** instead if you want eyes/body/antenna on *independent* timelines for extra life.
- **Tap reaction = `withAnimation(.spring(response:0.3, dampingFraction:0.4))`** toggling a squish/scale parameter, plus a one-shot `PhaseAnimator(trigger:)` for a blink/bounce.
- **Recolor = `fill`/gradients** for the base palette + one **`.colorEffect`** Metal shader (iOS 17+) for skin/theme variants; optional `.layerEffect`/`.distortionEffect` for premium glow/wobble.
- **Reserve `Canvas` + `TimelineView(.animation)`** only for genuinely per-frame procedural sub-effects (jelly wobble, particle sparkles), split into a separate layer and throttled.

**Why this wins:** the creature's motions are *discrete, named states* (idle, blink, squish-on-tap), not an arbitrary per-frame simulation. SwiftUI's declarative animators **redraw only on state transitions**, are GPU-composited, go fully idle between events, and integrate natively with Reduce Motion / scenePhase / the shader recolor pipeline. The single biggest avoidable battery cost is `TimelineView(.animation)`, which redraws **every display frame whether or not anything changed**.

### 1.2 Approach comparison

| Approach | Best for | Redraw cadence | Battery | Verdict for Yolkling |
|---|---|---|---|---|
| **`Shape`/`Path` + `animatableData` + `PhaseAnimator`/`KeyframeAnimator`/spring** | State-based organic motion (breathe, blink, tap squish), parametric character | Only during active transitions; idle between events | Lowest for state-based motion; GPU-composited | **Primary / core** |
| **`Canvas` (GraphicsContext)** | Genuinely procedural per-frame art (blob metaballs, particles, fluid) | Only when inputs change — *but every frame once driven by `TimelineView(.animation)`* | Closure runs on CPU each redraw; cheap if rarely redrawn, expensive if per-frame | **Sub-effects only** |
| **`TimelineView`** | Continuous time signal feeding procedural Canvas math | `.animation` = display refresh rate (60/120Hz); `.periodic`/`.everyMinute`/`.explicit` = cheaper | `.animation` is a power-hungry render loop | **Only while something is actively moving; pause otherwise** |
| **SpriteKit / `SpriteView`** | Physics, particles, collisions, sprite-sheet games | Continuous 60/120fps render loop **even when nothing changes** | Wasteful for a mostly-still creature; pause via `isPaused` | **Avoid unless it becomes a game** |

### 1.3 Key mechanics & gotchas

**TimelineView cadence (the crux of the battery question):**
- `TimelineView(.animation)` **runs at the display refresh rate** (60Hz, or up to 120Hz on ProMotion) — it is your every-frame driver and the expensive mode. ([swiftui-lab part4](https://swiftui-lab.com/swiftui-animations-part4/))
- Its two battery levers: **`minimumInterval`** (throttle, e.g. `.animation(minimumInterval: 1.0/30.0)` caps to 30fps) and **`paused: Bool`** (halts updates entirely). Flip `paused: true` when idle/off-screen/backgrounded.
- Other schedules: `.periodic(from:by:)` (fixed interval), `.everyMinute` (most efficient built-in), `.explicit([Date])` (exact instants). ([Swift with Majid](https://swiftwithmajid.com/2022/05/18/mastering-timelineview-in-swiftui/))
- `cadence` (`live`/`seconds`/`minutes`) is *read-only, device-driven* — reduce drawn detail when it drops (mainly watchOS).

**Canvas cost (measured):** naive continuous Canvas updates hit ~30% CPU; `minimumInterval: 0.06` → ~14%; splitting static vs. dynamic content into separate canvases → ~6%; seconds-only updates → <1%. **Divide and conquer:** put unchanging art in one layer, only the moving part in an animated one. ([swiftui-lab part5](https://swiftui-lab.com/swiftui-animations-part5/))

**`drawingGroup()`:** flattens a SwiftUI subtree into one off-screen Metal image — speeds up *complex compositions of many primitives* but **adds an off-screen pass that can slow down simple drawing**. Only reach for it after measuring. `Canvas` is already GPU-composited, so wrapping a plain Canvas in it is usually redundant. ([Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/enabling-high-performance-metal-rendering-with-drawinggroup))

**PhaseAnimator vs KeyframeAnimator:**
- **PhaseAnimator** = discrete sequential *states*; all properties animate together per phase; loops trivially. → idle breathe/blink, simple readable loops. ([appcoda](https://www.appcoda.com/phaseanimator/))
- **KeyframeAnimator** = continuous *timeline* with independent tracks per property and explicit per-segment easing (`LinearKeyframe`/`SpringKeyframe`/`CubicKeyframe`/`MoveKeyframe`). → eyes/body/antenna desynchronized for richer organic motion. ([appcoda](https://www.appcoda.com/keyframeanimator/))
- Practical split for Yolkling: **PhaseAnimator** for breathe+blink, **KeyframeAnimator** if you want desync, **spring** for tap.

**Recoloring (cheapest first):**
1. **`fill`/gradients** — `LinearGradient`/`RadialGradient`/`AngularGradient` driven by `@State` colors. Free, animates via `withAnimation`. Usually all you need.
2. **`.colorEffect` Metal shader (iOS 17+)** — per-pixel GPU shader for palette swaps / hue shifts / tinting in one cheap pass. ([Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-metal-shaders-to-swiftui-views-using-layer-effects), [jacobstechtavern](https://blog.jacobstechtavern.com/p/metal-in-swiftui-how-to-write-shaders))
3. **`.layerEffect`/`.distortionEffect` (iOS 17+)** — samples neighboring pixels for glow/outline/displacement/jelly wobble. Slightly costlier, still GPU-resident. Borrow from [twostraws/Inferno](https://github.com/twostraws/Inferno).

   Shaders run on the GPU (no CPU load even when animated), compiled from `.metal` files via `ShaderLibrary`.

### 1.4 Throttling / pausing (battery-critical glue)

Wire all of these at the creature view so it goes dormant whenever unobserved:

- **`@Environment(\.scenePhase)` + `.onChange`** → set `TimelineView`'s `paused: true` and stop loops on `.inactive`/`.background`; resume on `.active`.
- **`.onAppear`/`.onDisappear`** (or a visibility flag) → pause when off-screen/covered.
- **Low Power Mode:** read `ProcessInfo.processInfo.isLowPowerModeEnabled`, subscribe to `NSProcessInfoPowerStateDidChange`, expose as a custom `@Environment` value. Degrade to a simpler/slower loop or freeze decorative motion. (iOS also forces ≤60Hz in LPM.) ([useyourloaf](https://useyourloaf.com/blog/detecting-low-power-mode/))
- **`@Environment(\.isLuminanceReduced)`** → true on always-on/dimmed displays; reduce/stop motion. ([WWDC22](https://developer.apple.com/videos/play/wwdc2022/10050/))
- **ProMotion / `CADisplayLink`:** if you ever drive a custom render loop, set `preferredFrameRateRange = CAFrameRateRange(...)` to *request a lower* rate (e.g. 30–60) for a calm creature — don't request 120 unless needed. On iPhone you must set `CADisableMinimumFrameDurationOnPhone = YES` in Info.plist to exceed 60Hz at all. For SwiftUI's own animators, let the system pace them. ([Apple forum](https://developer.apple.com/forums/thread/761616))

### 1.5 Accessibility: Reduce Motion (required)

- Gate animations on **`@Environment(\.accessibilityReduceMotion)`**. Return `nil` from a computed animation (`reduceMotion ? nil : .spring(...)`) or pass `nil` into `.animation(_:value:)`. ([Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting), [tanaschita](https://tanaschita.com/ios-accessibility-reduced-motion/))
- For Yolkling: when on, stop/slow the breathe+blink loop, swap the bouncy tap squish for a quick opacity/color pulse, and **never** run a `TimelineView(.animation)` procedural loop.

### 1.6 iOS 26 caveat — SpriteKit regression

There is a **documented SpriteKit/RealityKit + SwiftUI performance regression on iOS 26** (framerate drops when a SwiftUI overlay sits over an animated `SKView`), with a fix reportedly landing ~iOS 26.2 beta 3. Another reason to keep the creature in pure SwiftUI for now. ([Apple forum 804973](https://developer.apple.com/forums/thread/804973))

**Sources (rendering):** swiftui-lab parts [4](https://swiftui-lab.com/swiftui-animations-part4/)/[5](https://swiftui-lab.com/swiftui-animations-part5/)/[7](https://swiftui-lab.com/swiftui-animations-part7/) · [Swift with Majid TimelineView](https://swiftwithmajid.com/2022/05/18/mastering-timelineview-in-swiftui/) · [drawingGroup (HWS)](https://www.hackingwithswift.com/books/ios-swiftui/enabling-high-performance-metal-rendering-with-drawinggroup) · [PhaseAnimator](https://www.appcoda.com/phaseanimator/) · [KeyframeAnimator](https://www.appcoda.com/keyframeanimator/) · [Metal shaders in SwiftUI](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-metal-shaders-to-swiftui-views-using-layer-effects) · [Inferno shaders](https://github.com/twostraws/Inferno) · [Low Power Mode](https://useyourloaf.com/blog/detecting-low-power-mode/) · [Reduce Motion](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting) · [isLuminanceReduced (WWDC22)](https://developer.apple.com/videos/play/wwdc2022/10050/) · [frame rate / CADisplayLink](https://developer.apple.com/forums/thread/761616) · [SpriteKit iOS26 regression](https://developer.apple.com/forums/thread/804973)

---

## 2. The "Grows When You Take Care of Yourself" Signals

**Bottom line:** **HealthKit is the reliable, grant-able backbone.** Screen Time / doomscroll detection is a high-risk, privacy-sandboxed, entitlement-gated path that does **not** give you the analytics most product plans assume — treat it as an optional v2 *nudge/focus* layer, not a data source.

### 2.1 HealthKit — the recommended foundation

**Signals you can legitimately read** (all first-class, no special entitlement beyond standard HealthKit capability):

| Signal | API | Use as |
|---|---|---|
| Sleep | `HKCategoryTypeIdentifier.sleepAnalysis` (values via `HKCategoryValueSleepAnalysis`: `.inBed`, `.asleepCore/.Deep/.REM`, `.awake`) | Primary "rested" growth signal |
| Mindful minutes | `HKCategoryTypeIdentifier.mindfulSession` (duration = end − start) | "You meditated" event |
| Steps | `HKQuantityTypeIdentifier.stepCount` | Daily movement |
| Active energy | `HKQuantityTypeIdentifier.activeEnergyBurned` | Activity intensity |
| Workouts | `HKWorkoutType` / `HKWorkout` (`HKWorkoutActivityType`) | "Did a workout" milestone |

**Authorization flow:**
1. Add **HealthKit capability** in Xcode (adds `com.apple.developer.healthkit` entitlement).
2. Add **Info.plist usage strings** (app crashes on auth request if missing): `NSHealthShareUsageDescription` (read), `NSHealthUpdateUsageDescription` (write — only if you ever write).
3. Guard: `if HKHealthStore.isHealthDataAvailable() { … }`.
4. `try await healthStore.requestAuthorization(toShare:read:)` — or SwiftUI's `.healthDataAccessRequest(...)` modifier (`import HealthKitUI`).

**THE critical privacy gotcha (read twice):** your app can **never** tell whether the user granted or denied **READ** permission. `authorizationStatus(for:)` only reflects **write/share**. Apple: *"If they denied permission, attempts to read data from HealthKit return only samples that your app successfully saved... From the app's point of view, no data of that type exists."* Design implications:
- **Never gate read features or detect denial via `authorizationStatus`.** An empty result is ambiguous (denied / no data / no data yet today). Treat "no data" as a soft state → creature simply doesn't get that day's boost; never show "permission denied" UI.
- **Request all read types you'll ever need up front** — re-prompting can't be reliably triggered.
- **Prime + deep-link:** show a friendly explainer before the system sheet ("Yolkling grows when you sleep, move, and breathe"), and deep-link to **Settings → Health → Yolkling** if data seems absent, rather than asserting denial.

**Background / incremental reads** (so the creature reacts while the phone stays pocketed — itself on-brand):
- Pattern: **`HKObserverQuery`** (fires on new/deleted samples — *always call the completion handler in every path* or delivery silently stops) → **`HKAnchoredObjectQuery`** (fetch only deltas since the stored anchor) → update creature → call completion.
- **`enableBackgroundDelivery(for:frequency:)`** wakes the app in background (throttled; requires `com.apple.developer.healthkit.background-delivery` entitlement). Does **not** fire while the device is locked (HealthKit is encrypted at rest when locked) — deliveries land on unlock.

**App Store review rules (HealthKit) — what gets you rejected** (Guideline **5.1.3**, reinforced by **5.1.2(vi)**):
- No using Health data for advertising/marketing/use-based data mining; no sending raw Health data to third-party SDKs (watch your analytics/attribution SDKs).
- No writing **false** samples (don't "log" a workout the user didn't do to game the creature).
- Don't store personal health info in **iCloud** — keep only **derived game state** (not raw HealthKit samples), and disclose it.
- **Privacy policy is mandatory** and must name every Health type you read. Usage strings must clearly state purpose; don't request types you don't use.

### 2.2 Screen Time / doomscroll detection — proceed with eyes open

**The three frameworks:** **FamilyControls** (permission + `FamilyActivityPicker` → opaque tokens), **ManagedSettings** (apply shields/blocks via `ManagedSettingsStore`), **DeviceActivity** (`DeviceActivitySchedule`, `DeviceActivityEvent` thresholds, `DeviceActivityMonitor` extension callbacks, `DeviceActivityReport` sandboxed SwiftUI view).

**The entitlement gate (`com.apple.developer.family-controls`):**
- Must be **requested from Apple** before submission (Family Controls **Distribution** request form), **separately for each extension** (Monitor, Report, ShieldAction, ShieldConfiguration). A free **development** version exists for local testing; **distribution requires manual Apple approval**.
- **Reality for indies (2026):** approval ranges from a few days to **several weeks or months**, with non-trivial rejection risk. It **is** grantable to a legitimate consumer wellbeing app (the iOS 16 `.individual` path exists for non-parental self-monitoring), but the APIs do **nothing** without it → **request it on day one** if you want this feature.

**Consumer mode:** since iOS 16, `.individual` authorization lets an adult authorize Screen Time control on *their own* device via Face/Touch ID — no Family Sharing, no child account, none of child mode's lockdowns. Correct mode for Yolkling.

**What you ACTUALLY get vs. the hard privacy wall:**

✅ You CAN: let the user pick apps/categories (opaque tokens only — you **never learn it's "Instagram"**); set **usage thresholds** (`DeviceActivityEvent`) and get `eventDidReachThreshold` callbacks in the extension; get `intervalDidStart`/`intervalDidEnd`; **shield (block)** apps/categories/web domains via `ManagedSettingsStore`.

❌ You CANNOT: read **"minutes spent doomscrolling on Instagram"** as a number — you get *threshold-crossed events*, not analytics. The only place real usage numbers exist is inside a **`DeviceActivityReport`** — a **SwiftUI-only view in a sandboxed extension that cannot pass data back to the host app** (writes fail *silently*, network is blocked). You can render a chart to the user but can't read/store/sync/widget that number. Tokens are **opaque and unstable** (iOS silently re-issues them after OS/app updates, breaking stored restrictions until the user re-picks apps).

**Practical patterns that DO work (event-driven nudges, not analytics):**
1. **Threshold nudge (core):** user picks distracting apps → `DeviceActivityEvent` threshold (e.g. 20 min) → on `eventDidReachThreshold`, shield the apps and/or fire a local notification ("Your Yolkling is getting sleepy — time for a break"). Tie growth to *not* hitting thresholds.
2. **Schedule focus windows:** `DeviceActivitySchedule` for bedtime/focus hours → shield during the window → creature thrives on respected focus time.
3. **Optional self-blocking:** opt-in `ManagedSettings` shielding with a custom `ShieldConfiguration`.
4. **Coarse self-reported display only:** embed a `DeviceActivityReport` to *show* the user their time — but accept you can't read it programmatically.

Communicate tokens to the extension via an **App Group** (serialize the `Codable` `FamilyActivitySelection`, not raw tokens). Re-prompt the picker when restrictions stop working (token churn).

**iOS 26 reliability caveats (mid-2026):** thresholds not firing / firing immediately; intensified token instability; corrupted report data; after force-quit the monitor extension may not wake until the app reopens. **Treat Screen Time enforcement as best-effort and flaky — never a source of truth the creature's life depends on.**

### 2.3 Recommendation for Yolkling's signal architecture

1. **Build the care economy on HealthKit** (sleep + mindful + steps + workouts) — reliable, grant-able, real-time via observer/anchored/background delivery, and brand-aligned. This is the safe, shippable core.
2. **Design for read-blindness** (never branch on read auth; empty = "no growth today"; prime + deep-link).
3. **Keep Health data local** (derived game state only, never raw samples in iCloud; privacy policy names every type; no Health data to ad/analytics SDKs).
4. **Treat Screen Time as optional v2.** The honest "get off your phone" mechanic is **threshold-triggered shields + notifications** rewarding restraint — you will *not* get per-app doomscroll minutes. **The strongest, lowest-risk Yolkling barely needs Screen Time** — positive off-phone behaviors (sleep, movement, breathing) via HealthKit sidestep the entire FamilyControls gauntlet.

**Sources (signals):** [Authorizing access to Health data](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data) · [Protecting user privacy](https://developer.apple.com/documentation/healthkit/protecting-user-privacy) · [sleepAnalysis](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/sleepanalysis) · [mindfulSession](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/mindfulsession) · [stepCount](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier/stepcount) · [HKObserverQuery](https://developer.apple.com/documentation/healthkit/hkobserverquery) · [enableBackgroundDelivery](https://developer.apple.com/documentation/HealthKit/HKHealthStore/enableBackgroundDelivery(for:frequency:withCompletion:)) · [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) · [FamilyControls](https://developer.apple.com/documentation/familycontrols) · [Requesting the Family Controls entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement) · [DeviceActivity](https://developer.apple.com/documentation/deviceactivity) · [What's new in Screen Time API (WWDC22)](https://developer.apple.com/videos/play/wwdc2022/110336/) · [iOS26 Screen Time regressions (forum)](https://developer.apple.com/forums/thread/819997) · [Screen Time API in practice (Jun 2026)](https://medium.com/@nikkieke001/what-no-one-tells-you-about-building-with-apples-screen-time-api-e061d14d1f66) · [DeviceActivityReport data wall](https://letvar.medium.com/time-after-screen-time-part-2-the-device-activity-report-extension-10eeeb595fbd)

---

## 3. Local Notifications, Done Tastefully

Brand constraint: Yolkling wants users *off* their phone, so engagement-maximizing notification patterns are actively off-brand.

### 3.1 Lead with provisional authorization (no hard prompt)

Request **`.provisional`** (in `UNAuthorizationOptions`) instead of the standard interrupting prompt:
- **No permission dialog at all** — notifications start flowing immediately but *quietly*, straight to Notification Center, no sound/banner/screen-wake.
- Each provisional notification carries a built-in **Keep / Turn Off** prompt (Keep → "Deliver Quietly" vs "Deliver Prominently"), so the user decides *after* seeing real examples. Status is `.provisional`; "Deliver Prominently" upgrades to `.authorized`; declining silently stops you being shown — no nag, no degraded app.
- Pass `.provisional` *alongside* `.alert`/`.sound`/`.badge` so the system knows your preferred presentation if upgraded.

**Recommendation:** ship with `.provisional`, never a hard prompt. Only escalate to full `requestAuthorization(options:)` if a user explicitly opts into a louder experience in Settings. ([Asking permission](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications), [.provisional](https://developer.apple.com/documentation/usernotifications/unauthorizationoptions/provisional))

### 3.2 Interruption level: stay at `.passive`

`UNNotificationContent.interruptionLevel`:

| Level | Behavior | Yolkling |
|---|---|---|
| **`.passive`** | Added to list **without lighting the screen or playing a sound** | **Default for everything** — the brand in one enum case |
| `.active` | System default (screen + maybe sound) | Only if user opts into louder reminders |
| `.timeSensitive` | Breaks through Focus/DND/Scheduled Summary; **requires entitlement** | **Avoid** — a cute creature is never urgent |
| `.critical` | Breaks through ringer switch + DND; **special Apple-granted entitlement** (health/safety only) | **Never** — Apple would reject a virtual pet |

`.passive` pairs naturally with `.provisional`. ([UNNotificationInterruptionLevel](https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel))

### 3.3 Respect Focus / DND / Scheduled Summary (don't fight them)

Because Yolkling stays `.passive`, its notifications are naturally held and bundled into the user's Scheduled Summary or wait quietly in Notification Center — **exactly what you want.** Do **not** mark notifications `.timeSensitive` to escape the Summary; that's the manipulative pattern Apple built these systems to defeat. ([Communication notifications & Focus](https://developer.apple.com/documentation/UserNotifications/handling-communication-notifications-and-focus-status-updates))

### 3.4 Frequency & user control

No documented numeric cap; HIG guidance is qualitative (timely, high-value, glanceable). Hard product rules for the brand:
- **Default very low cadence** — at most **one gentle check-in/day**, ideally fewer. Charming once a day; nagging at three.
- **In-app cadence dial:** Off / Rare / Daily / A-few-times-a-week + quiet hours, stored client-side.
- **Never escalate frequency to punish absence.** No "Your Yolkling is dying because you left!" guilt loops — prefer warm copy ("Yolkling napped while you were out").
- Use **`threadIdentifier`** so multiple notifications group cleanly. ([Notifications HIG](https://developer.apple.com/design/human-interface-guidelines/notifications))

### 3.5 Scheduling mechanics + the 64 limit

- `UNTimeIntervalNotificationTrigger` (in N seconds, `repeats: true` for fixed intervals) and `UNCalendarNotificationTrigger` (clock time / day — e.g. a daily wind-down; note it's measurably slower to schedule, so batch off the main thread).
- **Hard limit: 64 pending requests per app** (oldest dropped beyond that). With low cadence this is a non-issue; pattern: schedule a rolling ~1–2 week window, top up on launch / background refresh. Audit with `getPendingNotificationRequests`. ([forum: 64 limit](https://developer.apple.com/forums/thread/811171))
- Implement `UNUserNotificationCenterDelegate`: `willPresent` (foreground presentation — a calm app may choose *not* to present in foreground) and `didReceive` (route taps).

### 3.6 App Store review (notifications)

- **4.5.4:** push must not be required to function; no promotions/marketing without explicit in-app opt-in + an in-app opt-out. (Scoped to APNs but App Review applies the spirit to local re-engagement too.) → Yolkling must work fully with notifications **off**; any "come back" messaging needs opt-in + visible opt-out.
- **Anti-spam clause** explicitly names Push Notifications **and Live Activities**.
- **5.1.1:** don't gate core functionality behind a declinable permission. ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/))

### 3.7 Rich notifications & actions (on-brand)

- **Rich notifications** (Notification Service/Content extension) can attach a cute image of the creature's current state — delightful, doesn't increase frequency.
- **Notification actions** ("Wave back", "Snooze for today") let the user resolve *without opening the app* — which serves "off your phone" better than deep-linking them in.
- **Do not** dress up creature messages as **communication notifications** to win Focus breakthrough — misuse + App Review risk.

**Sources (notifications):** [Asking permission](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications) · [.provisional](https://developer.apple.com/documentation/usernotifications/unauthorizationoptions/provisional) · [Interruption levels](https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel) · [Notifications HIG](https://developer.apple.com/design/human-interface-guidelines/notifications) · [Managing notifications HIG](https://developer.apple.com/design/human-interface-guidelines/managing-notifications) · [64 limit (forum)](https://developer.apple.com/forums/thread/811171) · [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) · [Communication notifications & Focus](https://developer.apple.com/documentation/UserNotifications/handling-communication-notifications-and-focus-status-updates)

---

## 4. WidgetKit Widgets & Live Activities

### 4.1 Widget = the hero surface (ambient glance, no app session)

A home/lock-screen widget showing the creature's current state is the **most brand-aligned feature** — an ambient glance instead of an app session.

- Build with a **timeline provider** — `AppIntentTimelineProvider` (configurable, replaces SiriKit `IntentTimelineProvider`) or plain `TimelineProvider`. Supply `Timeline` entries with a reload policy (`.atEnd` / `.after(date)` / `.never`).
- **Refresh budget (central constraint):** *"a daily budget typically includes from 40 to 70 refreshes... roughly every 15 to 60 minutes."* The 24-hour window is **tuned to the user's usage pattern and does not reset at midnight.** ([Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date))
- **You cannot run a real animation loop** — while a widget is on screen your code is not running. Drive visible change only via a *timeline of pre-rendered entries*:
  - Show creature "frames" as a sequence of poses across the day — a **living still-life slideshow**, not 60fps animation.
  - SwiftUI in widgets is a **limited subset** (no custom/arbitrary animations, no video; limited transitions). Design for *state changes / expressions / day-night*, not motion.
  - **Don't refresh-every-minute to fake animation** — you'd exhaust the 40–70 budget by mid-morning and the creature freezes. Pick a few meaningful daily state changes.

### 4.2 Interactive widgets (iOS 17+)

- Use **only `Button`/`Toggle` initialized with an `AppIntent`**; the intent's `perform()` runs without launching the app.
- **Interaction-triggered reloads are guaranteed** (unlike best-effort timeline reloads). On-brand use: a **"pet" / "wave" button** giving a tiny in-place reward — a few seconds of joy, no app session. `perform()` `throws` → handle errors, show a "stale" state. ([Adding interactivity](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities))
- Update from the app via `WidgetCenter.shared.reloadTimelines(ofKind:)` on **real state changes** (still best-effort, still counts against budget) — not on a timer.

### 4.3 Live Activities — likely a brand/battery mismatch for an always-on creature

**Recommendation: do NOT use a Live Activity as an always-on creature display.**
- They're explicitly for **ephemeral, finite, time-bound** events (sports, delivery, workout). An always-present pet is the opposite. ([ActivityKit](https://developer.apple.com/documentation/activitykit), [Live Activities essentials WWDC26](https://developer.apple.com/videos/play/wwdc2026/223/))
- **Hard duration limits:** system auto-ends after **8 hours** (removed from Dynamic Island immediately); persists on Lock Screen up to **4 more** → **12h max**. You physically can't keep a creature "always on." ([forum: 8h/12h](https://developer.apple.com/forums/thread/797676))
- **Battery/policy:** frequent updates require `NSSupportsLiveActivitiesFrequentUpdates` + high-priority pushes against a per-device APNs budget; over-budget activities get throttled. High-frequency updates are a known battery drain — at odds with "get off your phone." Live Activities are also named in the App Review anti-spam clause.

**Where a Live Activity IS on-brand:** a genuine, user-initiated, finite **"phone-free focus session" timer** ("Yolkling is guarding your focus — 23:14 left") — ephemeral, rewards being away, ends cleanly. If built: use `ActivityContent.staleDate` + `relevanceScore`; prefer **local updates** (`activity.update(...)`) for an on-device countdown (battery-cheap) over push. iOS 26/WWDC26 adds a landscape Dynamic Island style.

### 4.4 2026 changes: Liquid Glass, Control widgets, cross-platform

- **Liquid Glass / accented rendering (iOS 26):** Home Screen can present widgets in clear/tinted glass. **Adopt accented rendering mode** — pass `fullColor` only where truly needed; otherwise **desaturated** / **accented desaturated** so the creature blends. (watchOS ignores `fullColor`.) **Action:** design the creature with a **strong silhouette + a monochrome variant** so it survives accented rendering and lock-screen tinting. ([Optimizing for accented rendering / Liquid Glass](https://developer.apple.com/documentation/WidgetKit/optimizing-your-widget-for-accented-rendering-mode-and-liquid-glass))
- **Control widgets (iOS 18+, `ControlWidget`):** button/toggle controls (App Intent-backed) in Control Center, Lock Screen, and Action button. On-brand use: one-tap **"Start focus session with Yolkling"** → phone down. Don't render the animated creature here (symbol + title + tint only). ([Creating controls](https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system))
- **Cross-platform:** controls work on macOS Tahoe + watchOS 26; on **watchOS 26 relevant widgets surface in the Smart Stack** by routine/location. Sharing widget/control code to watch is low-effort and arguably the *most* "off your phone" surface. ([What's new in watchOS 26](https://developer.apple.com/videos/play/wwdc2025/334/))

### 4.5 Recommendation for Yolkling's surfaces

1. **Widget is the hero feature** — living still-life within the 40–70/day budget, one interactive "pet" Button. Adopt accented rendering + a monochrome variant.
2. **Control widget** for one-tap "Start focus session"; share to watchOS Smart Stack + macOS.
3. **Skip the always-on Live Activity.** Only use one for a finite, user-started phone-free focus timer (local updates, `staleDate`), where being away is the rewarded behavior.

**Sources (widgets/Live Activities):** [Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date) · [AppIntentTimelineProvider](https://developer.apple.com/documentation/widgetkit/appintenttimelineprovider) · [Adding interactivity](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities) · [reloadTimelines](https://developer.apple.com/documentation/widgetkit/widgetcenter/reloadtimelines(ofkind:)) · [ActivityKit](https://developer.apple.com/documentation/activitykit) · [staleDate](https://developer.apple.com/documentation/activitykit/activitycontent/staledate) · [NSSupportsLiveActivitiesFrequentUpdates](https://developer.apple.com/documentation/bundleresources/information-property-list/nssupportsliveactivitiesfrequentupdates) · [Live Activities essentials (WWDC26)](https://developer.apple.com/videos/play/wwdc2026/223/) · [WidgetKit foundations (WWDC26)](https://developer.apple.com/videos/play/wwdc2026/277/) · [8h/12h limit (forum)](https://developer.apple.com/forums/thread/797676) · [Accented rendering / Liquid Glass](https://developer.apple.com/documentation/WidgetKit/optimizing-your-widget-for-accented-rendering-mode-and-liquid-glass) · [Creating controls](https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system) · [watchOS 26 (WWDC25)](https://developer.apple.com/videos/play/wwdc2025/334/)

---

## 5. Consolidated Action Items

**Creature rendering**
- [ ] Model the creature as composed custom `Shape`s with `animatableData` parameters (eye-open, mouth-curve, squish, bob, antenna).
- [ ] `PhaseAnimator` for the breathe+blink idle loop; `withAnimation(.spring)` + one-shot `PhaseAnimator(trigger:)` for tap. (KeyframeAnimator if you want desync'd tracks.)
- [ ] Recolor via `fill`/gradients + one `.colorEffect` shader; keep optional `.layerEffect` for premium looks.
- [ ] Pause on `scenePhase != .active`, `.onDisappear`, `isLuminanceReduced`; degrade under `isLowPowerModeEnabled`; gate all motion on `accessibilityReduceMotion`.
- [ ] Use `Canvas`+`TimelineView(.animation)` *only* for procedural sub-effects, throttled with `minimumInterval` + `paused`. Avoid SpriteKit (incl. iOS 26 regression).

**Signals**
- [ ] HealthKit capability + Info.plist usage strings; request all read types up front; never branch on read auth (empty = no growth today); prime + deep-link to Settings.
- [ ] `HKObserverQuery` + `HKAnchoredObjectQuery` + background delivery for pocket-friendly growth.
- [ ] Store only derived game state (no raw samples in iCloud); ship a privacy policy naming every Health type; no Health data to ad/analytics SDKs.
- [ ] If pursuing Screen Time: request `com.apple.developer.family-controls` (Distribution) on day one; use `.individual` auth; design around opaque/unstable tokens + the report data wall; threshold-shield + notify (not analytics). Otherwise skip it and rely on HealthKit positive signals.

**Notifications**
- [ ] `.provisional` authorization, `.passive` interruption level; ≤1 gentle check-in/day; in-app cadence dial + quiet hours; warm copy; `threadIdentifier`; rolling ≤2-week schedule (64 limit); fully functional with notifications off.

**Widgets / Live Activities**
- [ ] Ship the creature widget as the hero surface (living still-life, 40–70/day budget, one "pet" Button); accented-rendering + monochrome variant.
- [ ] Control widget "Start focus session"; share to watchOS Smart Stack.
- [ ] No always-on Live Activity; only a finite user-started phone-free focus timer (local updates, `staleDate`).

---

*Sourcing caveat: a few Apple HIG/API pages render client-side and couldn't be fetched verbatim; those specifics (e.g. `minimumInterval`/`paused`, 64-pending limit, 40–70 widget refreshes, 8h/12h Live Activity, guideline 4.5.4) are corroborated across multiple independent sources cited above.*
