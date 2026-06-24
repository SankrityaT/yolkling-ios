# SwiftUI Motion for "Wow"-Tier Onboarding (2026 / iOS 18+26 / Swift 6)

Research for **Yolkling** — a cute virtual creature you hatch from your vibe. The goal: a hatch onboarding that feels alive, premium, and buttery at 120fps. This doc collects concrete, copy-pasteable SwiftUI patterns, organized by technique, with guidance on *when* to reach for each and how they map to the hatch beats.

**Target stack:** iOS 18 minimum (so `.navigationTransition(.zoom)`, SF Symbols 6, `@Observable` are all fair game), with iOS 26 niceties (`@Animatable` macro, Liquid Glass) gated behind `#available`. Swift 6 language mode (everything here is `@MainActor` view code; the only concurrency concern is keeping animation drivers off background actors).

The **hatch beat sheet** referenced throughout:
1. **Vibe pick** — user taps a mood/vibe; egg appears.
2. **Charge** — egg pulses, wobbles, cracks form (anticipation).
3. **Hatch** — shell bursts, creature pops out (the payoff).
4. **Reveal** — creature settles, name/celebration, confetti.
5. **Handoff** — creature shrinks/flies into the home/nav as the persistent hero.

---

## Table of contents
1. [Hero element across screens](#1-hero-element-across-screens)
2. [Choreographed multi-step animation](#2-choreographed-multi-step-animation)
3. [Spring physics](#3-spring-physics)
4. [Haptics timed to moments](#4-haptics-timed-to-moments)
5. [Ambient motion & effects](#5-ambient-motion--effects)
6. [SF Symbols animations](#6-sf-symbols-animations)
7. [Reduce Motion accessibility](#7-reduce-motion-accessibility)
8. [Performance: hitting 60/120fps](#8-performance-hitting-60120fps)
9. [Putting it together: the Yolkling hatch](#9-putting-it-together-the-yolkling-hatch)

---

## 1. Hero element across screens

You have **two distinct tools** and they solve different problems. Picking the wrong one is the #1 cause of janky hero transitions.

| Tool | Use when | Lives where |
|---|---|---|
| `matchedGeometryEffect` | Both source and destination are **on screen at the same time** in the same view tree (conditional `if`/`else`, `ZStack` swap). Full control over the interpolation. | Within one screen / one `body`. |
| `.navigationTransition(.zoom)` + `.matchedTransitionSource` | Crossing a **presentation boundary** — a `NavigationStack` push or a `.sheet`/`.fullScreenCover`. Cheaper, more robust than MGE across navigation. iOS 18+. | Across navigation/presentation. |

### 1a. `matchedTransitionSource` + `.navigationTransition(.zoom)` (iOS 18, the modern path)

Three required pieces, all sharing one `@Namespace` and one `id`:

```swift
struct OnboardingHome: View {
    @Namespace private var heroNS

    var body: some View {
        NavigationStack {
            VStack {
                EggThumbnail()
                    // 1. Mark the SOURCE
                    .matchedTransitionSource(id: "egg", in: heroNS)
                NavigationLink("Hatch") {
                    HatchScreen()
                        // 2. Mark the DESTINATION with the zoom transition
                        .navigationTransition(.zoom(sourceID: "egg", in: heroNS))
                }
            }
        }
    }
}
```

Same pattern works for sheets — put `.navigationTransition(.zoom(...))` on the sheet's root content and `.matchedTransitionSource(id:in:)` on the thing that presented it. As of iOS 26 the presentation-transition story expanded further (custom presentation transitions), but `.zoom` remains the workhorse.

Notes & gotchas:
- The `id` is a *(possibly non-unique)* identifier; `id + namespace` together form the unique key. Keep it stable.
- iOS 18+ only — gate with `if #available(iOS 18, *)` and fall back to a plain push otherwise.
- Known quirk: during the zoom, the nav title / toolbar items can slide horizontally (Apple Developer Forums thread 810940). For an onboarding flow, hide the nav bar (`.toolbar(.hidden)`) during the hero moment to sidestep it.
- It is **simpler and more reliable than `matchedGeometryEffect` across navigation** — MGE across a `NavigationStack` push is notoriously fiddly; this API exists specifically to replace that.

Sources: [createwithswift — zoom navigation transition](https://www.createwithswift.com/using-the-zoom-navigation-transition-in-swiftui/) · [Hacking with Swift — zoom animations](https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-zoom-animations-between-views) · [Peter Friese — Hero Animations](https://peterfriese.dev/blog/2024/hero-animation/) · [AppCoda — Navigation Transition hero](https://www.appcoda.com/navigation-transition/)

### 1b. `matchedGeometryEffect` (the within-screen continuous hero)

This is what you want for **Yolkling's egg/creature growing continuously through the flow** when the steps live in one view (a `ZStack` + step enum, no navigation push between beats). The creature keeps the *same* `id` in the same namespace; as you swap which container it lives in, SwiftUI interpolates frame/position/size for you.

```swift
struct HatchFlow: View {
    @Namespace private var ns
    @State private var step: Step = .vibe

    enum Step { case vibe, charge, hatch, reveal }

    var body: some View {
        ZStack {
            switch step {
            case .vibe:
                // small, bottom — anchored to the vibe card
                CreatureBlob()
                    .matchedGeometryEffect(id: "creature", in: ns)
                    .frame(width: 80, height: 80)
                    .offset(y: 200)
            case .charge, .hatch:
                // centered, bigger
                CreatureBlob()
                    .matchedGeometryEffect(id: "creature", in: ns)
                    .frame(width: 220, height: 220)
            case .reveal:
                // settles slightly up, hero size
                CreatureBlob()
                    .matchedGeometryEffect(id: "creature", in: ns)
                    .frame(width: 260, height: 260)
                    .offset(y: -40)
            }
        }
        .animation(.bouncy(duration: 0.6), value: step)
    }
}
```

Key rules for MGE:
- The element must be the **same logical view with the same `id`** in both branches — keep it a single reusable subview (`CreatureBlob`) so identity is preserved.
- Only **one** view per `id` should be the *source of truth* at a time (use `isSource:` if you have ambiguity). When you have it in two places simultaneously, set `isSource: false` on the placeholder.
- It animates frame and position; for *content morphing* (egg → creature shape) you pair it with a cross-fade `.transition` on the inner content, or swap inside the matched container.
- Continuous growth across many steps: because the `id` is stable, every `step` change re-targets the same matched frame, so the creature visually **grows and travels** from beat to beat in one continuous spring. This is the core of the "it's the same little guy the whole time" feeling.

Sources: [SwiftUI Lab — matchedGeometryEffect Part 1](https://swiftui-lab.com/matchedgeometryeffect-part1/) · [Design+Code — Matched Geometry Effect](https://designcode.io/swiftui-handbook-matched-geometry-effect/) · [Medium — custom transition w/ matched geometry](https://medium.com/@lugope/how-to-implement-custom-transition-with-swiftui-using-matched-geometry-9ef808d4db2)

### 1c. Handoff to the persistent home hero

For beat 5 (creature flies into the nav/home), either:
- If onboarding and home are in the same view tree: keep the same MGE `id` and just change `step` to `.home` with a target frame near the tab bar.
- If you push/replace into the real app: use `.navigationTransition(.zoom)` with the creature as `sourceID`.

---

## 2. Choreographed multi-step animation

### 2a. `PhaseAnimator` vs `KeyframeAnimator` — when to use each

This is the single most important decision in the choreography. Mental model:

- **`PhaseAnimator`** = a *state machine of discrete poses*. SwiftUI animates **all properties together** from phase to phase, waits for the spring to settle, then advances to the next phase. You describe *poses*; SwiftUI fills in the motion between them. Best for: **anticipation/charge loops, a discrete "pop" sequence, retriggerable reactions.** All properties move in lockstep.
- **`KeyframeAnimator`** = *independent timelines per property*. Each `KeyframeTrack` controls one property (scale, rotation, y-offset) with its **own timing and curves**, running in parallel. Best for: **the hatch payoff** where scale should overshoot on one curve while rotation wobbles on another and vertical position arcs on a third — i.e. a hand-tuned, cinematic, one-shot beat.

Rule of thumb (from the sources): start with implicit `.animation`; graduate to explicit `withAnimation`; reach for **PhaseAnimator for multi-step sequences** and **KeyframeAnimator for independent property timelines / precise choreography**.

### 2b. `PhaseAnimator` — the charge/idle loop and the pop

Looping ambient version (no trigger → repeats forever) for the egg's idle "breathing":

```swift
CreatureEgg()
    .phaseAnimator([1.0, 1.06, 0.98]) { egg, scale in
        egg.scaleEffect(scale)
    } animation: { scale in
        .easeInOut(duration: 0.9)
    }
```

Triggered, discrete-pose version for the hatch "pop" — define poses as a `CaseIterable` enum and fire it with a trigger:

```swift
enum HatchPhase: CaseIterable {
    case rest, anticipate, burst, settle

    var scale: CGFloat {
        switch self { case .rest: 1; case .anticipate: 0.85; case .burst: 1.4; case .settle: 1 }
    }
    var yOffset: CGFloat {
        switch self { case .rest: 0; case .anticipate: 8; case .burst: -30; case .settle: 0 }
    }
}

struct HatchPop: View {
    @State private var trigger = 0
    var body: some View {
        CreatureBlob()
            .phaseAnimator(HatchPhase.allCases, trigger: trigger) { content, phase in
                content
                    .scaleEffect(phase.scale)
                    .offset(y: phase.yOffset)
            } animation: { phase in
                switch phase {
                case .anticipate: .easeIn(duration: 0.18)   // wind up slow
                case .burst:      .snappy(duration: 0.22, extraBounce: 0.3) // explode
                case .settle:     .bouncy(duration: 0.5)    // jiggle to rest
                case .rest:       .smooth
                }
            }
            .onTapGesture { trigger += 1 }  // re-fire the whole sequence
    }
}
```

The `animation:` closure giving **per-phase timing** is what makes this read as a real animation (slow wind-up, fast burst, soft settle) instead of a uniform ease.

Sources: [Hacking with Swift — phase animators](https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-multi-step-animations-using-phase-animators) · [AppCoda — PhaseAnimator](https://www.appcoda.com/phaseanimator/) · [SwiftUI Lab — Part 7 PhaseAnimator](https://swiftui-lab.com/swiftui-animations-part7/) · [Medium — Comprehensive PhaseAnimator guide](https://medium.com/@byfilippov/comprehensive-guide-to-using-phaseanimator-in-swiftui-120f60794528)

### 2c. `KeyframeAnimator` — the cinematic hatch payoff

Independent tracks let scale, rotation, and vertical arc each have their own curve:

```swift
struct HatchKeyframes {
    var scale = 1.0
    var verticalOffset = 0.0
    var rotation = Angle.zero
}

CreatureBlob()
    .keyframeAnimator(initialValue: HatchKeyframes(), trigger: didHatch) { content, value in
        content
            .scaleEffect(value.scale)
            .rotationEffect(value.rotation)
            .offset(y: value.verticalOffset)
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            SpringKeyframe(0.8, duration: 0.15)            // squash
            SpringKeyframe(1.5, duration: 0.25, spring: .bouncy)  // stretch up & overshoot
            SpringKeyframe(1.0, duration: 0.4, spring: .snappy)   // settle
        }
        KeyframeTrack(\.verticalOffset) {
            CubicKeyframe(-60, duration: 0.4)              // arc up
            CubicKeyframe(0, duration: 0.4)               // fall back
        }
        KeyframeTrack(\.rotation) {
            CubicKeyframe(.degrees(-8), duration: 0.2)
            CubicKeyframe(.degrees(8), duration: 0.2)
            CubicKeyframe(.zero, duration: 0.4)           // wobble to center
        }
    }
```

`SpringKeyframe`, `CubicKeyframe`, `LinearKeyframe`, `MoveKeyframe` are your keyframe types. Tracks of different total durations run concurrently and independently — that's the whole point.

Sources: [AppCoda — KeyframeAnimator](https://www.appcoda.com/keyframeanimator/) · [Augmented Code — keyframe animator](https://augmentedcode.io/2023/09/18/animating-with-keyframe-animator-in-swiftui/) · [Design+Code — Phase Animator](https://designcode.io/swiftui-handbook-phase-animator/)

### 2d. Staggered reveals (text, dots, UI chrome)

Stagger by feeding each element an increasing delay derived from its index:

```swift
ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
    Text(line)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.smooth(duration: 0.5).delay(Double(i) * 0.08), value: appeared)
}
```

`.onAppear { appeared = true }` triggers the cascade. For the reveal beat, stagger the creature's name letters, the "Meet your Yolkling" copy, and the CTA button each by ~80ms for a polished waterfall.

### 2e. Custom transitions — `AnyTransition` and the `Transition` protocol

For elements entering/leaving (cracks appearing, shell shards leaving, confetti container), define reusable transitions.

Classic `AnyTransition` (combine + asymmetric + modifier):

```swift
extension AnyTransition {
    static var hatchPop: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.3).combined(with: .opacity)
                .animation(.bouncy(duration: 0.6)),
            removal: .scale(scale: 1.4).combined(with: .opacity)
                .animation(.easeIn(duration: 0.2))
        )
    }
}
// usage: CreatureBlob().transition(.hatchPop)
```

Modern `Transition` protocol (iOS 17+) — composable, type-safe, can read `phase` (`.willAppear`/`.identity`/`.didDisappear`):

```swift
struct ShardFly: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(phase.isIdentity ? 1 : 0.4)
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity ? 0 : 8)
            .rotationEffect(.degrees(phase == .didDisappear ? 40 : 0))
    }
}
// usage: shard.transition(ShardFly())
```

Sources: [Better Programming — Exploring SwiftUI Transitions](https://betterprogramming.pub/exploring-swiftui-transitions-85d933d3fa3c) · [Pavel Zak — Mastering transitions](https://nerdyak.tech/development/2020/10/12/transitions-in-swiftui.html)

---

## 3. Spring physics

Forget cubic beziers for almost everything — modern SwiftUI motion is **spring-first**. The four presets, by damping:

| Preset | Damping | Feel | Use for |
|---|---|---|---|
| `.smooth` | critically damped — **no overshoot** | clean, settled arrival | dismissals, fades, "calm" moments, reduce-motion paths |
| `.snappy` | slightly underdamped — **tiny overshoot** | responsive, lively but controlled | most UI: taps, toggles, step advances |
| `.bouncy` | more underdamped — **visible overshoot + oscillation** | playful, draws the eye | the hatch payoff, the creature settling, celebratory beats |
| `.spring` | the default tunable spring | balanced | general-purpose default |

Each preset has a `(duration:extraBounce:)` form:

```swift
.animation(.bouncy(duration: 0.5, extraBounce: 0.2), value: step)   // more jiggle
.animation(.snappy(duration: 0.3), value: tappedVibe)
.animation(.smooth(duration: 0.4), value: reduceMotion ? false : revealed)
```

Guidance from the sources: **springs don't always need to be bouncy — use bounciness intentionally.** A smooth or snappy spring is right most of the time; reserve `.bouncy` for the 2–3 hero moments (the hatch, the settle, the confetti). If everything bounces, nothing feels special. Yolkling is cute, so lean slightly bouncier than a productivity app — but still ration it.

Custom physics when you need it: `.spring(response:dampingFraction:blendDuration:)`. Lower `dampingFraction` = more bounce; `response` ≈ how quick.

```swift
.animation(.spring(response: 0.35, dampingFraction: 0.55), value: hatched)
```

### Interactive / gesture-driven springs

For a draggable creature or a "pull the egg to crack it" gesture, use `interactiveSpring` (tuned to feel near-instant while the finger is down) and switch to a settle spring on release:

```swift
@State private var drag: CGSize = .zero

CreatureBlob()
    .offset(drag)
    .gesture(
        DragGesture()
            .onChanged { v in
                withAnimation(.interactiveSpring(response: 0.15,
                                                 dampingFraction: 0.86,
                                                 blendDuration: 0.25)) {
                    drag = v.translation
                }
            }
            .onEnded { _ in
                withAnimation(.bouncy(duration: 0.6)) { drag = .zero } // spring home
            }
    )
```

`interpolatingSpring()` is the variant that **accumulates** velocity across overlapping animations (rather than replacing) — use it when rapid repeated gestures should compound momentum (e.g. tapping the egg fast to charge it). Springs in SwiftUI also automatically **carry gesture velocity** into the release animation when you hand off translation, which is what makes flick-to-dismiss feel physical.

Sources: [nilcoalescing — Animation timing](https://nilcoalescing.com/blog/AnimationTimingInSwiftUI/) · [Amos Gyamfi — Spring Animation Cheat Sheet](https://medium.com/@amosgyamfi/swiftui-spring-animation-cheat-sheet-for-developers-1411fd80eda4) · [Amos Gyamfi — Meaning, Maths & Physics of Spring](https://medium.com/@amosgyamfi/the-meaning-maths-and-physics-of-swiftui-spring-animation-amos-gyamfis-manifesto-0044755da208) · [GetStream — swiftui-spring-animations repo](https://github.com/GetStream/swiftui-spring-animations)

---

## 4. Haptics timed to moments

Haptics are what turn a nice animation into a *felt* one. Two APIs:

- **`.sensoryFeedback`** (iOS 17+) — declarative, trigger-based, the default choice in SwiftUI. Fires when an equatable trigger value changes.
- **`UIImpactFeedbackGenerator` / Core Haptics (`CHHapticEngine`)** — imperative, for precise timing not tied to a state change, or custom patterns synced to audio. Reach for Core Haptics only when you need a bespoke rumble (e.g. a rising "charge" buzz that crescendos into the crack).

> iPad has **no haptics** — never make feedback load-bearing. And always honor a user toggle.

### `.sensoryFeedback` patterns

```swift
// Simple: play when `step` changes
.sensoryFeedback(.impact(weight: .light), trigger: step)

// Map the moment to the right feedback dynamically
.sensoryFeedback(trigger: hatchBeat) { _, beat in
    switch beat {
    case .crackForm:  .impact(flexibility: .rigid, intensity: 0.6) // tiny ticks
    case .burst:      .impact(weight: .heavy, intensity: 1.0)      // the big one
    case .settle:     .impact(weight: .medium, intensity: 0.5)
    case .celebrate:  .success                                     // notification-success
    default: nil
    }
}

// Condition closure — only fire on a specific transition
.sensoryFeedback(.selection, trigger: selectedVibe) { old, new in new != nil }
```

Feedback vocabulary: `.selection`, `.success`, `.warning`, `.error`, `.increase`/`.decrease`, `.impact(weight:intensity:)`, `.impact(flexibility:intensity:)`. Weights: `.light/.medium/.heavy`. Flexibility: `.rigid/.soft/.solid`.

### Mapping haptics to the hatch beats

| Beat | Haptic |
|---|---|
| Vibe selected | `.selection` (light tick) |
| Charge pulses | repeated `.impact(weight:.light, intensity: rising)` per pulse — escalate intensity to build tension |
| Each crack forms | `.impact(flexibility: .rigid, intensity: 0.5)` — sharp, brittle |
| **Burst / hatch** | `.impact(weight: .heavy, intensity: 1.0)` — the payoff thump |
| Creature settles | `.impact(weight: .medium)` once |
| Confetti / celebrate | `.success` |

Best practices: use predefined styles for their intended meaning, **don't overuse** (the heavy thump only lands if the run-up was restrained), be consistent, and respect a settings toggle.

For a *crescendo* charge that a discrete generator can't express, drive a `CHHapticEngine` continuous event with a ramping intensity curve and synchronize it to the same `startDate` your shader/animation uses — so the buzz, the visual pulse, and the eventual crack all peak together.

Sources: [Use Your Loaf — SwiftUI Sensory Feedback](https://useyourloaf.com/blog/swiftui-sensory-feedback/) · [BleepingSwift — Sensory Feedback & Haptics](https://bleepingswift.com/blog/sensory-feedback-haptics-swiftui) · [Hacking with Swift — adding haptic effects](https://www.hackingwithswift.com/books/ios-swiftui/adding-haptic-effects) · [Medium — Core Haptics in SwiftUI](https://medium.com/@dhavaljasoliya8/unlock-the-power-of-core-haptics-in-swiftui-a91d7c40efbb)

---

## 5. Ambient motion & effects

The difference between "screen with a button" and "world that's alive" is subtle continuous motion in the background. Three primitives.

### 5a. `TimelineView` — the per-frame clock

`TimelineView(.animation)` re-evaluates its body every frame (60/120Hz), giving you a `context.date` to drive math. This is the heartbeat for shaders and Canvas.

```swift
TimelineView(.animation) { context in
    let t = context.date.timeIntervalSinceReferenceDate
    BackgroundBlob(time: t)   // gently drift gradients with sin(t)
}
```

Use `.animation(minimumInterval:)` if you want to throttle (e.g. a slow ambient drift at 30fps to save battery). For a quick, paused-when-offscreen ambient loop, `.animation(paused:)`.

### 5b. `Canvas` — many cheap shapes in one drawing pass

Drawing N particles as N SwiftUI views is murder on the layout engine. `Canvas` rasterizes them in a single pass. Pre-render the particle as a **symbol** so it's drawn once and stamped many times:

```swift
struct AmbientSparkles: View {
    let count = 200
    private let offsets = (0..<200).map { _ in CGFloat.random(in: 0...1) }
    private let phases  = (0..<200).map { _ in CGFloat.random(in: 0...(.pi * 2)) }

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                let sparkle = canvas.resolveSymbol(id: 0)!     // pre-rendered once
                for i in 0..<count {
                    let cycle = (t + offsets[i] * 3).truncatingRemainder(dividingBy: 3) / 3
                    let x = size.width/2 + cos(1.5 * cycle * .pi * 2 + phases[i]) * size.width/2 * (1 - cycle)
                    let y = (1 - cycle * cycle) * size.height
                    canvas.opacity = 1 - cycle
                    canvas.draw(sparkle, at: CGPoint(x: x, y: y))
                }
            } symbols: {
                Circle().fill(.orange.opacity(0.4))
                    .frame(width: 30, height: 30)
                    .blur(radius: 10).blendMode(.plusLighter)
                    .tag(0)
            }
        }
    }
}
```

This is **very performant** — Canvas + pre-rendered symbols composites to one surface instead of hundreds of views. Use it for the confetti burst (beat 4) and ambient floating motes behind the egg.

For confetti specifically, you can build it by hand (gravity + initial velocity + rotation per particle in the Canvas loop) or use **[Vortex](https://github.com/twostraws/Vortex)** (free, high-performance, has a confetti preset) to skip the boilerplate.

Sources: [Pavel Zak — Particle effects with Canvas](https://nerdyak.tech/development/2024/06/27/particle-effects-with-SwiftUI-Canvas.html) · [Hacking with Swift — Special Effects with SwiftUI](https://www.hackingwithswift.com/articles/246/special-effects-with-swiftui) · [Vortex (twostraws)](https://github.com/twostraws/Vortex)

### 5c. Metal shaders — `colorEffect`, `distortionEffect`, `layerEffect`

GPU pixel programs for effects SwiftUI can't express: shimmer, holographic sheen, heat-haze around the egg, a dissolve/burn on the shell. Three modifiers, three signatures:

| Modifier | Shader signature | Does |
|---|---|---|
| `.colorEffect` | `[[stitchable]] half4 f(float2 pos, half4 color)` | recolor each pixel (tint, gradient, glow) |
| `.distortionEffect` | `[[stitchable]] float2 f(float2 pos)` | warp geometry (ripple, wobble, heat haze) |
| `.layerEffect` | `[[stitchable]] half4 f(float2 pos, SwiftUI::Layer layer)` | sample neighboring pixels (blur, pixelate, dissolve) |

Call from SwiftUI via `ShaderLibrary`, animate by feeding time from `TimelineView`:

```swift
struct ShimmerShader: ViewModifier {
    let start = Date()
    func body(content: Content) -> some View {
        TimelineView(.animation) { ctx in
            let t = start.distance(to: ctx.date)
            content.colorEffect(ShaderLibrary.shimmer(.float(t)))
        }
    }
}
```

```c++
// Shimmer.metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]]
half4 shimmer(float2 pos, half4 color, float time) {
    float wave = sin(pos.x * 0.05 + time * 3.0) * 0.5 + 0.5;
    return color + half4(wave * 0.3); // sweeping highlight
}
```

For `distortionEffect`/`layerEffect` you must give SwiftUI a `maxSampleOffset` (how far the shader reads/moves pixels) and usually `.drawingGroup()` upstream. Shaders are extremely cheap on Apple GPUs (~thousands of FP ops per pixel per frame budget) — far cheaper than animating many views. **[Inferno](https://github.com/twostraws/Inferno)** is a free library of ready-made SwiftUI Metal shaders (dissolves, glows, water) — great starting point for the shell-dissolve at hatch.

Sources: [Jacob Bartlett — Metal in SwiftUI: How to Write Shaders](https://blog.jacobstechtavern.com/p/metal-in-swiftui-how-to-write-shaders) · [Hacking with Swift — Metal layer effects](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-metal-shaders-to-swiftui-views-using-layer-effects) · [Inferno (twostraws)](https://github.com/twostraws/Inferno) · [Cindori — Shaders Wave Effect](https://cindori.com/developer/swiftui-shaders-wave)

---

## 6. SF Symbols animations (`.symbolEffect`)

For incidental icon moments — the CTA arrow, a sparkle, a heart on "love your Yolkling." iOS 18 / SF Symbols 6 added **Wiggle, Rotate, Breathe** on top of the iOS 17 set (Bounce, Pulse, Scale, Variable Color, Appear/Disappear, Replace).

```swift
// One-shot bounce when a value changes (e.g., creature reacts)
Image(systemName: "heart.fill")
    .symbolEffect(.bounce, value: tapCount)

// Discrete directional bounce
Image(systemName: "arrow.down")
    .symbolEffect(.bounce.down, options: .repeat(.continuous))

// iOS 18 wiggle — playful, perfect for a "tap me" egg hint
Image(systemName: "hand.tap")
    .symbolEffect(.wiggle, options: .repeating)

// iOS 18 breathe — gentle idle "alive" pulse
Image(systemName: "circle.fill")
    .symbolEffect(.breathe)

// Variable color charge meter
Image(systemName: "wifi")
    .symbolEffect(.variableColor.iterative.reversing)

// Content-aware swap with a transition
Image(systemName: isHatched ? "bird.fill" : "oval.fill")
    .contentTransition(.symbolEffect(.replace))
```

Combine multiple `.symbolEffect` modifiers, tune with `.speed(_:)`, `.repeating`, `.repeat(.continuous)`. Map: `.breathe` for the idle egg, `.wiggle` as a "tap me" nudge, `.bounce` on successful hatch, `.replace` content transition for egg→creature glyphs in any chrome.

Sources: [createwithswift — animating SF Symbols](https://www.createwithswift.com/animating-sf-symbols-with-the-symbol-effect-modifier/) · [Hacking with Swift — animate SF Symbols](https://www.hackingwithswift.com/quick-start/swiftui/how-to-animate-sf-symbols) · [Rudrank — make SF Symbols wiggle](https://rudrank.com/exploring-swiftui-make-sf-symbols-wiggle) · [Blake Crosley — Symbol Effects vocabulary](https://blakecrosley.com/blog/symbol-effects-vocabulary)

---

## 7. Reduce Motion accessibility

Large scale/translate/spin animations can cause real discomfort. Read the environment value and **degrade gracefully — don't just kill all motion** (a hard cut is worse UX than a gentle fade). The rule: replace *positional/scaling* motion with *opacity* cross-fades; keep informational continuity.

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

A reusable helper (since `withAnimation` does **not** auto-respect Reduce Motion):

```swift
extension View {
    func motion(_ animation: Animation, reduce: Bool, fallback: Animation? = .smooth(duration: 0.25)) -> some View {
        self.animation(reduce ? fallback : animation, value: UUID()) // see note
    }
}

// Practical inline pattern:
.animation(reduceMotion ? .smooth(duration: 0.2) : .bouncy(duration: 0.6), value: step)

// Swap the transition itself
.transition(reduceMotion ? .opacity : .hatchPop)
```

Degradation map for Yolkling:
- **Hatch burst:** instead of scale-explode + shards flying, cross-fade egg → creature (`.opacity`), keep the haptic + a small `.snappy` scale (≤1.05). The *meaning* survives, the vestibular trigger doesn't.
- **Confetti / particle storm:** skip the Canvas particle field entirely (or render a single static "✨ congrats" frame). Don't run a 200-particle storm.
- **Ambient drift / shaders:** pause `TimelineView` (`.animation(paused: reduceMotion)`) or drop to a static gradient.
- **Hero zoom:** `.zoom` transitions are generally fine but consider a plain fade push when reduceMotion is on for the biggest jumps.
- Keep **haptics on** — they aid, not harm, motion-sensitive users, and preserve the "felt" payoff.

Also honor `accessibilityReduceTransparency` if you lean on Liquid Glass / blur, and test with the setting actually on.

Sources: [Hacking with Swift — reduce animations](https://www.hackingwithswift.com/quick-start/swiftui/how-to-reduce-animations-when-requested) · [createwithswift — reduced motion in SwiftUI](https://www.createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/) · [tanaschita — reduced motion](https://tanaschita.com/ios-accessibility-reduced-motion/) · [GetStream — accessible inclusive iOS animations](https://github.com/GetStream/accessible-inclusive-ios-animations)

---

## 8. Performance: hitting 60/120fps

ProMotion devices want **120fps → an 8.3ms frame budget**. Hitches happen when a `body` evaluation overruns the frame deadline. Principles:

**Cheap (do freely):**
- GPU-bound work: Metal shaders, `colorEffect`/`layerEffect`, `Canvas` drawing, blends/opacity, `drawingGroup()` (flattens to one Metal layer).
- Spring/transform animations on a handful of views (scale, offset, rotation, opacity).
- `TimelineView(.animation)` driving math, *if* its body is cheap.

**Expensive (budget carefully):**
- Rendering many independent SwiftUI views per particle → use `Canvas` instead.
- Heavy work inside an animating `body` (formatting dates, decoding, sorting, allocating) — hoist it out; a `body` that animates runs up to 120×/sec.
- Large `blur`/shadow over a big area every frame; offscreen `.shadow` on complex content.
- Recomputing whole subtrees because of poor **view identity** — over-broad `@State`/`@Observable` invalidation re-runs bodies that didn't need to.

**Tactics:**
1. **Stabilize identity.** Give `ForEach` stable ids; don't recreate views. Bad identity = SwiftUI re-lays-out instead of animating, which both hitches *and* breaks `matchedGeometryEffect`.
2. **Scope state.** With `@Observable`, only the views reading a property re-evaluate. Keep the per-frame animation driver (`TimelineView`/`phaseAnimator`) in a *small leaf view* so the whole screen isn't re-rendering each frame.
3. **`.drawingGroup()`** around complex composited content (shaders + many layers) to render once on the GPU. (But don't wrap things that need independent animation — it flattens them.)
4. **Pre-render particles as Canvas symbols** (section 5b) — the single biggest win for confetti.
5. **Throttle ambient loops** with `.animation(minimumInterval:)` when sub-60fps is imperceptible (slow background drift), saving battery/thermals.
6. **Profile with Instruments** — the **SwiftUI** template (new in Xcode 16 / refined in 26) shows long `body` evaluations and "cause of update"; the **Animation Hitches** / **Hangs** instruments pinpoint missed frames. WWDC23 "Demystify SwiftUI performance" and WWDC25 "Optimize SwiftUI performance with Instruments" are the canonical guides.
7. **Avoid `.animation(_:)` with no `value:`** (deprecated, animates everything) — always scope to a `value:`.
8. **Don't stack many simultaneous spring animations** on overlapping properties; prefer one `keyframeAnimator`/`phaseAnimator` that owns the choreography.

Sources: [Apple — Demystify SwiftUI performance (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10160/) · [Jacob Bartlett — SwiftUI Scroll Performance: the 120fps challenge](https://blog.jacobstechtavern.com/p/swiftui-scroll-performance-the-120fps) · [DEV — Optimize SwiftUI Performance with Instruments (WWDC25)](https://dev.to/arshtechpro/wwdc-2025-optimize-swiftui-performance-with-instruments-4o4j) · [Medium — Optimizing SwiftUI Performance](https://medium.com/@garejakirit/optimizing-swiftui-performance-best-practices-93b9cc91c623)

---

## 9. Putting it together: the Yolkling hatch

A reference assembly mapping every beat to a technique. (Sketch — fill in your real views.)

```swift
struct HatchOnboarding: View {
    @Namespace private var hero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Step = .vibe
    @State private var hatchTrigger = 0
    @State private var didHatch = false

    enum Step { case vibe, charge, hatch, reveal, handoff }
    enum HatchBeat { case crackForm, burst, settle, celebrate }
    @State private var beat: HatchBeat = .crackForm

    var body: some View {
        ZStack {
            // (5) Ambient background — TimelineView + shader/Canvas, paused under reduce motion
            if !reduceMotion {
                AmbientSparkles()           // §5b Canvas particle field
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else {
                LinearGradient(/* static */ colors: [], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }

            // (1) Continuous hero — same matchedGeometryEffect id across all beats
            creature
                .matchedGeometryEffect(id: "creature", in: hero)
                .modifier(reduceMotion ? AnyShimmer.none : AnyShimmer.shimmer) // §5c
        }
        // (3) one spring owns the beat-to-beat travel; bouncy because Yolkling is cute
        .animation(reduceMotion ? .smooth(duration: 0.25) : .bouncy(duration: 0.6), value: step)
        // (4) haptics mapped to beats
        .sensoryFeedback(trigger: beat) { _, b in
            switch b {
            case .crackForm: .impact(flexibility: .rigid, intensity: 0.5)
            case .burst:     .impact(weight: .heavy, intensity: 1.0)
            case .settle:    .impact(weight: .medium)
            case .celebrate: .success
            }
        }
        .overlay { if step == .reveal && !reduceMotion { ConfettiCanvas() } } // §5b
    }

    // (2) the creature uses KeyframeAnimator for the cinematic hatch payoff
    private var creature: some View {
        CreatureBlob(/* morphs egg→creature internally */)
            .keyframeAnimator(initialValue: HatchKeyframes(), trigger: hatchTrigger) { c, v in
                c.scaleEffect(v.scale).rotationEffect(v.rotation).offset(y: v.verticalOffset)
            } keyframes: { _ in
                /* §2c tracks: scale squash/stretch, vertical arc, rotation wobble */
                KeyframeTrack(\.scale) { /* ... */ }
            }
            // idle "alive" breathing before hatch — §2b PhaseAnimator loop / §6 .breathe
    }
}
```

Beat → technique cheat sheet:

| Beat | Hero | Choreography | Spring | Haptic | Ambient/FX | SF Symbol |
|---|---|---|---|---|---|---|
| Vibe pick | MGE id starts small | staggered card reveal (§2d) | `.snappy` | `.selection` | gentle motes | `.wiggle` "tap me" |
| Charge | MGE grows, centers | `.phaseAnimator` pulse loop (§2b) | `.bouncy` pulse | escalating `.impact(.light)` | `distortionEffect` heat-haze (§5c) | `.variableColor` meter |
| **Hatch** | MGE biggest | `KeyframeAnimator` payoff (§2c) | `.bouncy`/`.snappy` per track | **`.impact(.heavy)`** | shell dissolve shader + shard `.transition` | `.replace` egg→creature |
| Reveal | MGE settles | staggered name/letters (§2d) | `.bouncy` settle | `.success` | **confetti Canvas** (§5b) | `.bounce` |
| Handoff | MGE / `.zoom` into home (§1) | — | `.smooth` | light tick | particles fade | — |

---

## Quick reference: which API for which job

- **Same little guy across the whole flow** → `matchedGeometryEffect` (same view tree) or `.navigationTransition(.zoom)` + `.matchedTransitionSource` (across nav/sheet, iOS 18+).
- **A sequence of discrete poses, retriggerable** → `PhaseAnimator`.
- **Hand-tuned cinematic beat, properties on independent curves** → `KeyframeAnimator`.
- **Element entering/leaving** → `.transition` with custom `Transition` protocol type.
- **Feel** → `.snappy` for UI, `.bouncy` for hero moments, `.smooth` for calm/reduce-motion, `.interactiveSpring` for gestures.
- **Make it felt** → `.sensoryFeedback` (Core Haptics for crescendos).
- **A world that's alive** → `TimelineView` + `Canvas` (particles) + Metal shaders (shimmer/dissolve/haze).
- **Icon moments** → `.symbolEffect` (`.breathe`/`.wiggle`/`.bounce`/`.replace`).
- **Accessibility** → read `accessibilityReduceMotion`, swap big motion for opacity, keep haptics.
- **iOS 26 bonus** → `@Animatable` macro removes `animatableData` boilerplate for custom animatable shapes/blobs; Liquid Glass `.glassEffect()` for premium chrome.

---

## Primary sources

**Hero / navigation transitions**
- [createwithswift — Using the zoom navigation transition](https://www.createwithswift.com/using-the-zoom-navigation-transition-in-swiftui/)
- [Hacking with Swift — How to create zoom animations between views](https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-zoom-animations-between-views)
- [Peter Friese — SwiftUI Hero Animations with NavigationTransition](https://peterfriese.dev/blog/2024/hero-animation/)
- [AppCoda — Navigation Transition hero animation](https://www.appcoda.com/navigation-transition/)
- [SwiftUI Lab — matchedGeometryEffect Part 1](https://swiftui-lab.com/matchedgeometryeffect-part1/)
- [Apple Developer Forums — zoom transition toolbar quirk (810940)](https://developer.apple.com/forums/thread/810940)

**Phase / Keyframe / transitions**
- [Hacking with Swift — multi-step animations using phase animators](https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-multi-step-animations-using-phase-animators)
- [AppCoda — PhaseAnimator](https://www.appcoda.com/phaseanimator/) · [AppCoda — KeyframeAnimator](https://www.appcoda.com/keyframeanimator/)
- [SwiftUI Lab — Part 7: PhaseAnimator](https://swiftui-lab.com/swiftui-animations-part7/)
- [Better Programming — Exploring SwiftUI Transitions](https://betterprogramming.pub/exploring-swiftui-transitions-85d933d3fa3c)

**Springs**
- [nilcoalescing — SwiftUI animation timing](https://nilcoalescing.com/blog/AnimationTimingInSwiftUI/)
- [Amos Gyamfi — Spring Animation Cheat Sheet](https://medium.com/@amosgyamfi/swiftui-spring-animation-cheat-sheet-for-developers-1411fd80eda4)
- [GetStream — swiftui-spring-animations](https://github.com/GetStream/swiftui-spring-animations)

**Haptics**
- [Use Your Loaf — SwiftUI Sensory Feedback](https://useyourloaf.com/blog/swiftui-sensory-feedback/)
- [BleepingSwift — Sensory Feedback and Haptics](https://bleepingswift.com/blog/sensory-feedback-haptics-swiftui)
- [Hacking with Swift — Adding haptic effects](https://www.hackingwithswift.com/books/ios-swiftui/adding-haptic-effects)

**Ambient / Canvas / Metal**
- [Pavel Zak — Magical Particle Effects with SwiftUI Canvas](https://nerdyak.tech/development/2024/06/27/particle-effects-with-SwiftUI-Canvas.html)
- [Hacking with Swift — Special Effects with SwiftUI](https://www.hackingwithswift.com/articles/246/special-effects-with-swiftui)
- [Vortex — particle effects (twostraws)](https://github.com/twostraws/Vortex) · [Inferno — Metal shaders (twostraws)](https://github.com/twostraws/Inferno)
- [Jacob Bartlett — Metal in SwiftUI: How to Write Shaders](https://blog.jacobstechtavern.com/p/metal-in-swiftui-how-to-write-shaders)
- [Hacking with Swift — Metal shaders via layer effects](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-metal-shaders-to-swiftui-views-using-layer-effects)

**SF Symbols**
- [createwithswift — Animating SF Symbols with symbolEffect](https://www.createwithswift.com/animating-sf-symbols-with-the-symbol-effect-modifier/)
- [Hacking with Swift — How to animate SF Symbols](https://www.hackingwithswift.com/quick-start/swiftui/how-to-animate-sf-symbols)
- [Rudrank — Make SF Symbols Wiggle](https://rudrank.com/exploring-swiftui-make-sf-symbols-wiggle)

**Reduce Motion**
- [Hacking with Swift — reduce animations when requested](https://www.hackingwithswift.com/quick-start/swiftui/how-to-reduce-animations-when-requested)
- [createwithswift — Supporting reduced motion](https://www.createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/)
- [GetStream — accessible inclusive iOS animations](https://github.com/GetStream/accessible-inclusive-ios-animations)

**Performance**
- [Apple — Demystify SwiftUI performance (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10160/)
- [Jacob Bartlett — SwiftUI Scroll Performance: the 120fps challenge](https://blog.jacobstechtavern.com/p/swiftui-scroll-performance-the-120fps)
- [DEV — Optimize SwiftUI Performance with Instruments (WWDC25)](https://dev.to/arshtechpro/wwdc-2025-optimize-swiftui-performance-with-instruments-4o4j)

**iOS 26 / WWDC 2025**
- [Medium — SwiftUI in iOS 26 (WWDC 2025 highlights)](https://medium.com/@himalimarasinghe/swiftui-in-ios-26-whats-new-from-wwdc-2025-be6b4864ce05)
- [Medium — @Animatable & @AnimatableIgnored (WWDC 2025)](https://medium.com/@shubhamsanghavi100/swiftui-gets-smarter-with-animation-say-hello-to-animatable-animatableignored-wwdc-2025-fa58f4db2018)
