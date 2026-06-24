# 07 — Creature Expression: Designing an Expressive Minimal Yolkling

> Research brief for **Yolkling** — a soft round "yolk" creature (circle body, two eyes, a mouth, little arms/feet, blush) rendered **entirely in SwiftUI code (no art assets)**, serving as a wellness + social companion. Its face must react to the user's real-life wellness and to social events (a friend's creature visiting).

## Core Framing: IDENTITY vs EMOTION

**The central architectural insight this document validates:** separate **Identity** from **Emotion**.

- **Identity ("Vibe")** = the *permanent* look of YOUR creature — color, body shape, patterns, freckles. It does not change moment to moment. It is who the creature *is*.
- **Emotion ("Mood" / "Expression")** = the *transient* state it wears *right now* — driven by wellness + events + time of day + interaction. It is how the creature *feels*.

The current code's bug: it bakes a single fixed mood into each color preset, so the face never changes. The fix is to make Expression an independent, interpolatable value type layered on top of a static Identity.

---

## 1. How Abstract / Minimal Characters Convey Rich Emotion

The thesis of every reference below: **maximum emotional impact, minimum visual clutter.** A few dots and a curve, animated and timed well, read as alive. Below, what each reference concretely teaches Yolkling.

### 1.1 The feature hierarchy: eyes > mouth > brow (and how they combine)
- **Eyes carry identity-of-emotion; mouth carries valence; brow carries intensity.** In minimal faces, the mouth alone flips valence with one stroke — `)` reads happy, `(` reads sad — which is why a single mouth-curvature parameter is the cheapest, highest-leverage control you have. Brows brought together + down = displeasure/sadness/worry; this is the single most reliable "negative intensity" signal. ([Manga iconography](https://en.wikipedia.org/wiki/Manga_iconography), [Emoticon](https://en.wikipedia.org/wiki/Emoticon), [Frown](https://en.wikipedia.org/wiki/Frown))
- **Eye shape is symbolic, not just geometric.** Manga/anime codifies eye *shapes* as discrete emotion tokens: heart-shaped eyes = infatuation; star/sparkle eyes = star-struck/excited; spiral/swirl eyes = dizziness/overwhelm; tall round eyes = surprise/alertness; thin upward arcs (`^^`) = warm closed-eye smile. Yolkling should treat **eye shape as an enum** (round, arc/happy-closed, heart, swirl, sleepy-half) layered on a continuous openness value. ([Manga iconography](https://en.wikipedia.org/wiki/Manga_iconography))
- **Catchlights = life.** A small specular highlight in the eye is "only present in living characters." Removing or dimming the catchlight is a cheap, powerful way to read *unwell / low-energy / asleep* without a sad mouth. ([Manga iconography](https://en.wikipedia.org/wiki/Manga_iconography))

### 1.2 What the named references teach
- **Tamagotchi** — "minimalism of design with maximalism of emotional impact": complex states conveyed with "just a few black dots," drawing on Japan's tradition of compact symbolic communication. Lesson: you do not need many pixels; you need *legible, well-timed* ones. ([Japan House LA](https://www.japanhousela.com/articles/how-tamagotchi-changed-digital-design-icon-japanese-tiny-toys-30th-anniversary-bandai/))
- **Pou / Neko Atsume** — simplified rounded bodies + a tiny face; emotion comes from *care-state and motion*, not facial detail. Neko Atsume in particular gets warmth from *passive presence* (the creature is just there, content) rather than constant demands — directly relevant to Yolkling's anti-engagement stance (§6). ([Kore Kawaii history of virtual pets](https://korekawaii.com/blogs/kawaii-lifestyle-blog/the-history-of-virtual-pets-from-tamagotchi-to-neopets-and-beyond))
- **Finch (self-care bird)** — the gold standard for this product. The bird thrives as you do self-care; it has life stages; crucially it delivers "low-pressure wellness support without shame-based motivation" and "missing a day doesn't punish you — your bird waits patiently." Its mood check-in is a 1–5 happy/neutral/sad scale. Lesson: tie expression to wellness, but make the *negative* end *patient and waiting*, never accusatory (see §6). ([Sophie Pilley: Magic of Finch](https://www.sophiepilley.com/post/the-magic-of-finch-where-self-care-meets-enchanted-design), [Medium UX teardown](https://medium.com/@deepthi.aipm/ux-teardown-finch-self-care-app-18122357fae7))
- **Headspace blobs** — the "Headspace Face" is a wide relaxed smile, the brand's "simplest and most direct tool for bringing emotion into any moment," anchored in optimism. Lesson: pick a *default resting expression* that is warm and slightly positive (content, not neutral-blank), because the resting state is what the user sees 90% of the time. ([PopIcon: Headspace brand character](https://popicon.life/headspace-brand-character/))
- **Duolingo's Duo** — a "chicken nugget with a face" that nonetheless expresses "joy, sadness, anger, excitement, and dozens of other emotions," with "large eyes key in showing emotions." Personality shows up in *tiny* ways: a wink on success, a frown on a skipped day. Lesson: large eyes + a big expression library + micro-reactions tied to events. (Caution: Duo's guilt-trip notifications are exactly the dark pattern Yolkling rejects — see §6.) ([Medium: Duolingo-style Rive animation](https://uianimation.medium.com/bringing-mascots-to-life-duolingo-style-character-animation-in-rive-a075d648cf19), [Duolingo design system](https://design.duolingo.com/illustration/duo))
- **Apple Memoji / emoji** — emoji prove that a fixed round head with only eyes/brows/mouth/blush spans the entire emotional gamut; Memoji add blink, gaze, and blush as the live signals. Lesson: blush is a first-class emotional channel (affection, embarrassment, joy), not decoration.

### 1.3 Pixar/Disney "appeal" — what makes a simple shape likable and alive
- **Shape language:** circles/ovals read friendly and approachable; angular shapes read aggressive/villainous. Yolkling's round yolk body is *already* maximally appealing — lean into roundness; never let a negative mood make the silhouette spiky. ([Marissa Louie / ex-Pixar](https://medium.com/@malouie/how-ex-apple-disney-and-pixar-artists-design-compelling-characters-3e4318db63a6))
- **Big expressive eyes + exaggerated cues** are "essential" for joy/curiosity/surprise; "the simplest emotional communication devices are the mouth and eyes." ([Inverse: how Disney/Pixar bring characters to life](https://www.inverse.com/article/13572-a-look-into-how-disney-and-pixar-bring-life-to-their-characters))
- **For non-speaking characters, "the motions are everything."** Small differences in motion turn an object into a person. This is the single most important takeaway for Yolkling: a *static* perfect face is dead; a *breathing, blinking, gaze-shifting* mediocre face is alive. ([Inverse](https://www.inverse.com/article/13572-a-look-into-how-disney-and-pixar-bring-life-to-their-characters), [Pixar "Articulating the Appeal"](https://www.pixar.com/technology-libraries))

### 1.4 The "aliveness" layer — idle motion independent of mood
Even when the creature is "doing nothing," it must move. This is a separate layer from the mood/expression system and runs continuously:
- **Breathing:** a slow body squash/stretch cycle (~0.25–0.33 Hz, i.e. one breath every 3–4 s). This is the base "I am alive" signal.
- **Blinking:** blink every ~3–5 s, ~250 ms duration, with occasional double-blinks; randomize the interval so it never feels metronomic ("blink too evenly… and they begin to feel artificial"). Eye movement should be able to trigger a blink. ([Geniuscrate: idle animations](https://www.geniuscrate.com/the-science-of-idle-animations-and-why-they-matter-in-modern-games), [Medium: why CGI looks dead](https://medium.com/@nazilm.ouhab/why-cgi-characters-still-look-dead-inside-51863f1f8094))
- **Saccades / gaze drift:** tiny involuntary pupil shifts keep eyes from looking dead; occasionally have the creature glance toward a new UI element or toward the user. ([Tripo3D: modeling eyes](https://www.tripo3d.ai/blog/explore/3d-modeling-eyes))
- **Idle fidgets:** rare small posture shifts, a little arm wiggle, a tail/foot tap — context-responsive, low frequency. ([Idle animation (Wikipedia)](https://en.wikipedia.org/wiki/Idle_animation))

**Implementation note:** the aliveness layer is implemented as continuous SwiftUI animations (`PhaseAnimator` for breathing/blink cycles) modulating the *same* parameters the mood presets set — but the mood preset defines the *targets/amplitudes* (e.g. an excited creature breathes faster and bounces; a sleepy one breathes slower and blinks longer).

## 2. Disney's 12 Principles Applied to a Single Soft Body

The yolk is a soft, rubbery, round body — the ideal substrate for these principles. Below, each principle with a *concrete, implementable* application to a breathing round creature, plus the SwiftUI hook.

| Principle | Concrete application to the yolk | SwiftUI hook |
|---|---|---|
| **1. Squash & Stretch** | The core "alive" motion. The breathing cycle is a gentle vertical stretch / horizontal squash. **Preserve volume**: when squashing, *widen* as you flatten; when stretching, *narrow* as you elongate — never just scale uniformly, or it reads as zoom, not breath. Use ~2–5% deformation for resting breath (subtle, "tennis ball"), up to ~15–20% for an excited bounce or a boop reaction (rubbery). A *proud* yolk stretches tall; a *low/sad* yolk squashes down and wide. | A single `squashStretch` parameter `s` mapped to `scale(x: 1 - k·s, y: 1 + k·s)` so width and height trade off (volume ≈ const). `PhaseAnimator` drives the breath. ([CGWire](https://blog.cg-wire.com/squash-stretch-principle/), [RebusFarm](https://rebusfarm.net/blog/squash-and-stretch-in-animation-the-essential-principle-for-lifelike-motion)) |
| **2. Anticipation** | Before any big reaction, do a tiny *opposite* pre-move. Before a happy jump, dip down (squash) for ~80–120 ms, *then* spring up. Before turning to greet a visiting friend, lean slightly away first. This sells weight and intention. | A `KeyframeAnimator` with a brief counter-pose keyframe before the main pose. |
| **3. Staging** | One clear emotion at a time, centered, unobstructed. Don't stack sweat-drop + hearts + Zzz simultaneously — pick the dominant mood (see §5 priority). Resting expression is the "stage" the user reads instantly. | Single dominant `particle` enum at a time; mood priority resolver chooses it. |
| **4. Straight-ahead vs Pose-to-pose** | Use **pose-to-pose**: each mood is a defined key pose (an `Expression` preset). Transitions interpolate between poses. This is exactly the identity/emotion architecture (§4). | Interpolate between two `Expression` presets; SwiftUI `Animatable` does the in-betweens. |
| **5. Follow-through & Overlapping action** | When the body bounces, the *arms, feet, blush position, and any cheek/antenna* lag behind and settle a beat later. The mouth settles last. This secondary settle is what makes a bounce feel squishy rather than rigid. | Stagger child-element spring animations with small increasing `delay`; lower stiffness on appendages than on body. |
| **6. Slow In & Slow Out (easing)** | Never linear. Emotional transitions ease in and out. Use **springs** for playful/positive moves (overshoot = joy) and **smooth ease-out** for calming-down / falling-asleep / low moods (no overshoot = heaviness). | `.animation(.spring(...))` for positive; `.easeInOut`/critically-damped spring for negative/sleepy. |
| **7. Arcs** | Movement follows curved paths, not straight lines. A gaze shift sweeps in a small arc; a happy bounce travels an arc, not a vertical line; arms swing in arcs. | Animate position along a quadratic path or combine x/y offset with phase offset. |
| **8. Secondary Action** | A secondary motion *supporting* the main emotion: blinking while content, a little arm raise while excited, ears/cheeks drooping while sad, a tail/foot tap while curious. Secondary actions add richness without changing the read. | Independent low-amplitude animations layered under the dominant pose. |
| **9. Timing** | Mood = tempo. Excited/happy: fast, snappy, high-frequency bounce. Content: slow, even breath. Sleepy/low: very slow, heavy, long blinks. Tie squash amount to velocity — faster reaction = more squash. | Each `Expression` carries a `tempo`/`breathRate` and `springResponse`. |
| **10. Exaggeration** | Push the key emotion past realism — that's what makes a 200pt circle *readable* at a glance. Surprise = eyes huge + body pops + jumps. Excited = over-the-top bounce + sparkles. But exaggerate the *dominant* feature, keep the rest calm (avoid the "uncanny everything-moving" mess). | Mood presets set deliberately large values on the 1–2 signature parameters. |
| **11. Solid drawing (here: solid *shape* / weight)** | The yolk must always feel like a consistent volume with weight and a light source. Keep a consistent soft drop shadow + a single catchlight in the eyes; both anchor it in space and signal life. Negative moods can dim the catchlight and lower/soften the shadow (sinking). | Consistent `shadow` + eye catchlight overlay; modulate opacity by energy. |
| **12. Appeal** | Roundness, slight asymmetry, big eyes, a warm default. Keep the silhouette round in *every* mood — never spiky, even when upset (upset = droopy/deflated, not jagged). Asymmetry (a slightly tilted mouth, one brow higher) reads as charm and spontaneity vs. robotic symmetry. | Bake small asymmetry into presets (`mouthAsymmetry`, per-eye offsets). ([Pixar appeal](https://www.pixar.com/technology-libraries), [ex-Pixar designer](https://medium.com/@malouie/how-ex-apple-disney-and-pixar-artists-design-compelling-characters-3e4318db63a6)) |

**Mapping emotion onto squash/stretch directly** (this is the cheapest body-language win): "A bold, confident character stretches tall with pride; a shy or nervous one squashes down." So *proud → tall*, *low/unwell → short & wide & deflated*, *excited → fast tall bounces*, *sleepy → slow heavy settle*. ([RebusFarm](https://rebusfarm.net/blog/squash-and-stretch-in-animation-the-essential-principle-for-lifelike-motion))

General UI-animation source confirming these translate to interface motion (button squash on press = squash & stretch; bounce/overshoot = exaggeration; easing = slow-in/slow-out): [IxDF](https://ixdf.org/literature/article/ui-animation-how-to-apply-disney-s-12-principles-of-animation-to-ui-design), [Medium / Design Bootcamp](https://medium.com/design-bootcamp/disneys-12-principles-of-animation-in-everyday-ui-design-71c6592064fe).

## 3. Recommended Mood / Expression Taxonomy for Yolkling

**Grounding:** Ekman's basic-emotion theory gives ~6–7 universal expressions (happiness, surprise, fear, anger, disgust, sadness, neutral). FACS decomposes any expression into ~46 Action Units (brow raiser, lip-corner puller, etc.). We don't need all of them — for a *wellness companion* we deliberately drop fear/anger/disgust (off-brand, can feel hostile) and instead expand the *positive and gentle* end, which is where wellness/social products live. Each Yolkling mood below is effectively a named cluster of Action Units expressed as our parameters (defined in §4). ([Ekman basic emotions / FACS](https://en.wikipedia.org/wiki/Facial_Action_Coding_System), [Emotion classification](https://en.wikipedia.org/wiki/Emotion_classification))

Parameter conventions (full model in §4): values are normalized `0…1` unless noted; `mouthCurve` is signed `-1…1` (down→up); `browAngle` signed `-1…1` (worried/inner-up → angry/down); `bodyLean` signed `-1…1` (left/right); particle is an enum.

### Core moods

| Mood | Eyes (openness / shape / pupil) | Brow | Mouth (curve / open / asym) | Blush | Body posture | Particle |
|---|---|---|---|---|---|---|
| **Content** *(default resting)* | open 0.6, round, pupils centered, slow blink | neutral 0.0 | gentle smile +0.4, closed, slight asym +0.1 | soft 0.3 | slow even breath, upright, no lean | none |
| **Happy** | open 0.5, **happy-arc (`^^`)**, pupils up a touch | up 0.2 | big smile +0.8, slightly open 0.2 | 0.5 | light bounce, tiny lean into camera | occasional sparkle (low) |
| **Excited / Joyful** | open 0.9, round→sparkle eyes, pupils wide | up 0.4 | open grin +0.9, open 0.6 | 0.6 | fast high bounce, squash-stretch big | **sparkles** (high), maybe confetti |
| **Proud** | open 0.55, round, pupils centered, chin-up gaze | up 0.25 | smug closed smile +0.6, asym +0.3 | 0.4 | **stretch tall**, chest-out, slow | small sparkle/shine glint |
| **Affectionate / Love** | open 0.5, **heart eyes** (or soft half-closed), pupils toward target | up 0.15 | soft smile +0.5, closed | **high 0.8** | gentle lean toward friend/user, slow sway | **hearts** floating up |
| **Curious** | open 0.8, round, **pupils tracking / off-center**, one blink | one brow up (asym browAngle) | small o / slight smile +0.2, open 0.3 | 0.2 | **head tilt** (rotation), slight lean forward | "?" (subtle, occasional) |
| **Surprised** | **open 1.0**, very round, pupils small/wide | up 0.6 (high) | open "o" 0.0 curve, open 0.7 | 0.3 | **pop** (quick stretch up) then settle, small recoil | "!" flash, quick |
| **Sleepy / Drowsy** | **half-closed 0.25**, sleepy-lidded, pupils low, long slow blinks | relaxed, slightly inner-up | tiny mouth +0.1, maybe small yawn-open | 0.2 | slow heavy breath, gentle droop/sway, occasional nod | **Zzz** drifting up |
| **Calm / Relaxed** | half-closed 0.4, soft arc, pupils centered | neutral, relaxed | serene smile +0.35, closed | 0.3 | very slow deep breath, settled | optional soft glow / slow particle |
| **Playful / Cheeky** | open 0.6, one eye wink (asym), pupils to side | one up | open smirk +0.6, asym +0.4, tongue optional | 0.4 | quick wiggle, lean, bounce | tiny stars |

### Gentle low-energy moods (handled with care — see §6)

| Mood | Eyes | Brow | Mouth | Blush | Body | Particle |
|---|---|---|---|---|---|---|
| **Low / Down** | open 0.4, slightly droopy, pupils down, slow blink | **inner-up worried** (browAngle −0.4) | gentle frown −0.3, closed, soft | low 0.1, slightly desaturated | **squash down & wide** (deflated), slow heavy breath, gaze down | none (or a single slow sigh puff). **No tears, no rain-cloud.** |
| **Tired / Worn** | half-closed 0.3, dim **catchlight reduced** | relaxed inner-up | flat −0.1 | 0.1 | slumped, slow | optional faint Zzz when very late |
| **Unwell / Under-the-weather** | half-closed 0.35, pupils slightly off | inner-up | small flat −0.1, maybe slight open (queasy) | **cheeks pale/green-tint instead of pink** | slow sway, slight droop | optional small "•••" thinking, NOT a sweat-drop panic |
| **Waiting / Patient** *(neglected state, reframed)* | open 0.45, round, pupils toward door/edge (looking for you) | neutral, faint inner-up | tiny neutral-soft +0.05 | 0.2 | upright, calm, occasional glance to UI edge as if watching for the user | none — *patient, not pitiful* (Finch model) |

**Design rules for the taxonomy:**
1. **Default to Content, not Neutral.** The resting face is warm and slightly positive (Headspace lesson) — a blank neutral reads as "off"/dead.
2. **Eye shape switches are the highest-impact tokens.** Heart eyes, sparkle eyes, happy-arc, sleepy-lid, and swirl are discrete shapes interpolated to/from round.
3. **Negative moods deform the *body* (deflate/droop) more than they uglify the *face*.** Keep the silhouette round and sympathetic (§6).
4. **One particle at a time**, chosen by priority (§5). Particles are accents, never required for the read.
5. **Reaction moods are transient overlays** (Surprised, the boop-giggle, the eating-happy) that play for 1–3 s then return to the underlying mood — distinct from sustained moods.

## 4. The Parametric Facial Parameter Model (Swift `Expression` struct)

**Architecture (validated by industry practice):** this is exactly **blend-shape / morph-target animation** ("shape interpolation"): a neutral base plus named target deformations, smoothly blended by interpolating each parameter. MPEG-4's **Face Animation Parameters** formalize the same idea (displacements/rotations of feature points from a neutral face). So: **every mood is a preset `Expression`; the live face is an interpolation between presets; transitions are free.** This is the fix for the current bug (mood baked into color). ([Morph target animation](https://en.wikipedia.org/wiki/Morph_target_animation), [Face Animation Parameter](https://en.wikipedia.org/wiki/Face_Animation_Parameter), [Parametric animation](https://en.wikipedia.org/wiki/Parametric_animation))

### 4.1 Separation of concerns
- **`Vibe` (Identity, persistent):** `bodyColor`, `bodyShape`, `pattern`, `freckles`, `size`, accessory slots. Stored per-creature; *never* touched by mood logic. This is the thing the current code wrongly fuses with mood.
- **`Expression` (Emotion, transient):** the struct below. Pure value type. Produced by the mood resolver (§5), interpolated over time, and fed to the `Shape`.
- **`AlivenessState` (idle layer, §1.4):** breathing phase, blink phase, saccade offset — continuous, modulated *by* the current Expression's `tempo`/amplitudes but not part of the preset's identity.

### 4.2 The `Expression` value type

```swift
import SwiftUI

/// A complete, interpolatable facial+body pose. Pure, Sendable, value-type.
/// Every Mood is a static preset; the rendered face is `lerp(a, b, t)` between presets.
struct Expression: Equatable, Sendable, Animatable {

    // MARK: Eyes
    var eyeOpenness: Double        // 0 = closed, 1 = wide. Drives lid height.
    var eyeShape: EyeShape         // discrete token, see below (blended via morph weight)
    var eyeShapeWeight: Double     // 0…1 blend from `.round` toward `eyeShape`
    var pupilX: Double             // -1…1 gaze left/right
    var pupilY: Double             // -1…1 gaze down/up
    var pupilScale: Double         // 0.6…1.3 (dilated = excited/affection; pinned = surprise)
    var catchlight: Double         // 0…1 specular life-dot opacity (low = unwell/asleep)

    // MARK: Brow
    var browAngle: Double          // -1 worried/inner-up … 0 neutral … +1 angry/down
    var browRaise: Double          // 0…1 vertical lift (surprise/curiosity)
    var browAsymmetry: Double      // -1…1 (one brow up = curious/skeptical)

    // MARK: Mouth
    var mouthCurve: Double         // -1 frown … 0 flat … +1 big smile
    var mouthOpen: Double          // 0 closed … 1 wide open ("o"/grin/yawn)
    var mouthWidth: Double         // 0.7…1.2 (narrow pucker … wide grin)
    var mouthAsymmetry: Double     // -1…1 smirk/wink-side; charm via asymmetry

    // MARK: Cheeks / Blush
    var blush: Double              // 0…1 intensity
    var blushHue: BlushHue         // .pink (warm) | .pale | .green (unwell)

    // MARK: Body posture (squash/stretch + lean + bounce)
    var squashStretch: Double      // -1 squashed&wide (deflated/low) … 0 … +1 tall&narrow (proud)
    var bodyLean: Double           // -1…1 lean left/right (toward friend/user)
    var headTilt: Angle            // small rotation (curiosity, affection)
    var bounceAmplitude: Double    // 0…1 idle/active vertical bounce height
    var energy: Double             // 0…1 master tempo: breath rate, blink length, spring snappiness

    // MARK: Accent
    var particle: Particle         // single dominant effect, chosen by priority

    enum EyeShape: Sendable { case round, happyArc, heart, sparkle, swirl, sleepy }
    enum BlushHue: Sendable { case pink, pale, green }
    enum Particle: Equatable, Sendable {
        case none, sparkles(Double), hearts(Double), zzz, question, exclaim, confetti, sigh
    }

    // MARK: Animatable conformance — interpolate the continuous channels.
    // (Enums snap at t≈0.5 or cross-fade in the view; everything else lerps.)
    var animatableData: AnimatablePack { /* pack the Doubles; see note */ }
}
```

> **Animatable note:** Bundle all the `Double` channels into `Expression.animatableData` (an `AnimatablePair` chain or an array-backed `VectorArithmetic`) so SwiftUI tweens the whole pose with one `.animation`/`withAnimation`. Discrete enums (`eyeShape`, `particle`, `blushHue`) can't lerp — handle them by (a) cross-fading two eye-shape layers by `eyeShapeWeight`, and (b) fading particles in/out on change. This keeps the struct a clean value type while transitions stay smooth.

### 4.3 Presets and interpolation
```swift
extension Expression {
    static let content: Expression  = .init(/* §3 Content row */)
    static let happy: Expression    = .init(/* … */)
    static let excited: Expression  = .init(/* … */)
    static let proud: Expression
    static let affectionate: Expression
    static let curious: Expression
    static let surprised: Expression
    static let sleepy: Expression
    static let calm: Expression
    static let playful: Expression
    static let low: Expression
    static let tired: Expression
    static let unwell: Expression
    static let waiting: Expression

    /// Linear blend of two presets (for crossfades & partial intensities).
    static func lerp(_ a: Expression, _ b: Expression, _ t: Double) -> Expression { /* per-field */ }
}
```

### 4.4 Driving the Shape
- The yolk body is a `Shape` (or `Canvas`) that reads an `Expression` and draws lids (clipped circles sized by `eyeOpenness`), pupils (offset by `pupilX/Y`, scaled by `pupilScale`), brows (line/arc rotated by `browAngle`+`browRaise`), mouth (a `Path` whose control points come from `mouthCurve/Open/Width/Asymmetry`), blush (two soft circles), and applies `squashStretch`/`bodyLean`/`headTilt` as transforms on the body.
- **Idle layer:** a `TimelineView` or `PhaseAnimator` advances breath/blink/saccade phases; their amplitudes are scaled by the current `Expression.energy`/`bounceAmplitude`. So *the same* breathing code reads "excited" vs "sleepy" purely from the active preset.
- **Transitions:** when the mood resolver picks a new target preset, `withAnimation(.spring(...))` (positive) or `.easeInOut` (negative/sleepy) sets it; `Animatable` interpolates the whole face. Reaction overlays (boop, surprise) use a short `KeyframeAnimator` that returns to the sustained mood.

This makes any mood a data preset, any transition a free interpolation, and the whole thing a pure `Sendable` struct — exactly the brief.

## 5. Mapping Mood from App State (priority / state machine)

The mood is **derived**, never stored. A pure resolver takes the full app state and returns a target `Expression` preset (or a blend). Use a **priority cascade**: transient reactions beat events beat sustained baseline. This is "staging" (§2.3) — one clear emotion at a time.

### 5.1 Inputs
- **Wellness tier** (the sustained baseline): `thriving / good / low / neglected`. Computed from the user's real wellness signals (check-ins, habits, focus minutes), *not* from app-open frequency.
- **Social events** (transient, high salience): `friendVisiting`, `postcardReceived`, `friendBooped`.
- **Focus / session completion** (transient celebration): `focusSessionCompleted`, `streakMilestone`.
- **Direct interaction** (transient, highest): `booped`, `fed`, `pet`, `dressed`.
- **Time of day** (modifier): late night → bias toward `sleepy`; morning → brighter.

### 5.2 Priority cascade (highest wins; transient ones auto-expire back to baseline)
```
1. ACTIVE INTERACTION (just now, <2s)      → boop→giggle/surprise, fed→happy-eat, pet→affectionate
2. SOCIAL EVENT (just arrived, plays once) → friendVisiting→excited/affectionate, postcard→curious→happy
3. ACHIEVEMENT (session/milestone done)    → focusComplete→proud, milestone→excited+confetti
4. TIME-OF-DAY OVERRIDE                     → lateNight & idle → sleepy (overrides baseline only)
5. WELLNESS BASELINE (sustained default):
      thriving   → happy / excited-leaning content
      good       → content   (the warm default)
      low        → low / tired   (gentle, see §6)
      neglected  → waiting   (patient & looking for you — NOT sad/guilt; see §6)
```
Each higher tier is a **temporary overlay** with a duration (interaction ~1–3 s, social/achievement ~3–6 s), after which the face eases back to the wellness baseline (or the time-of-day-modified baseline). Time-of-day biases the baseline (e.g. nudges `energy` down at night) rather than fully replacing it, except the explicit late-night-idle → sleepy case.

### 5.3 State-machine shape (Swift sketch)
```swift
struct MoodResolver {
    func resolve(_ s: AppState, now: Date) -> Expression {
        if let r = s.activeInteraction, r.isFresh(now)      { return r.expression }     // 1
        if let e = s.pendingSocialEvent, e.isPlaying(now)   { return e.expression }     // 2
        if let a = s.recentAchievement, a.isPlaying(now)    { return a.expression }     // 3
        let base = baseline(for: s.wellnessTier)                                        // 5
        if s.isIdle && now.isLateNight { return .lerp(base, .sleepy, 0.7) }             // 4
        return timeOfDay(now).modulate(base)
    }
    func baseline(for tier: WellnessTier) -> Expression {
        switch tier {
        case .thriving: .happy
        case .good:     .content
        case .low:      .low
        case .neglected:.waiting
        }
    }
}
```
- **Determinism + testability:** the resolver is a pure function of `(AppState, Date)` → `Expression`. Easy to unit-test ("neglected at midnight returns waiting blended toward sleepy").
- **Smoothing:** the *view* owns interpolation. The resolver just emits the target; `withAnimation` tweens from the current face to it, so there are never hard cuts.
- **Hysteresis:** wellness-tier transitions should debounce (e.g. require the tier to hold for a few minutes) so the face doesn't flicker between `good` and `low` on a borderline signal.
- **Reaction overlays compose with baseline:** a *thriving* creature that gets booped reads more bouncy/giggly than a *low* one that gets booped (which gives a small, touched smile) — implement by blending the reaction toward the baseline's `energy`, so even celebrations respect how the creature "really" feels.

## 6. Avoiding Dark Patterns & Guilt (sympathetic neglect states)

Yolkling's brand is honest and anti-engagement, so the "neglected/unwell" states are the *highest-risk* design surface — exactly where most pet apps reach for guilt. The research gives a clear ethical line.

### 6.1 The cautionary tales
- **Original Tamagotchi** is the canonical anti-pattern: if not attended to, the pet would **die within half a day**, "causing both emotional distress and requiring users to reset," driving users to carry it everywhere — distraction so severe schools banned it. This is *guilt + loss-aversion as an engagement engine*. Yolkling must never let the creature die, decay irreversibly, or punish absence. ([Tamagotchi (Wikipedia)](https://en.wikipedia.org/wiki/Tamagotchi), [Tamagotchi effect](https://en.wikipedia.org/wiki/Tamagotchi_effect))
- **Guilt-trip notifications** (Duo's "don't make me come after you", a pet looking betrayed) are a literal **guilt trip** — "emotional blackmail intended to manipulate by preying on feelings of guilt," a recognized toxic, well-being-harming pattern, and a **dark pattern** ("a UI crafted to trick users into doing things"). Off-brand for Yolkling. ([Guilt trip](https://en.wikipedia.org/wiki/Guilt_trip), [Dark pattern](https://en.wikipedia.org/wiki/Dark_pattern))

### 6.2 The model to follow: Finch
Finch is the explicit blueprint. Its principles, validated repeatedly across reviews:
- "**Missing a day doesn't punish you — the bird simply waits patiently for your return.** No penalty for an off day, only a small companion glad to see you back."
- "**No negative enforcement** for neglecting tasks, even if you take a week off."
- "Low-pressure wellness support **without shame-based motivation**"; it "**gamifies self-compassion**… showing up for yourself gently rather than optimizing performance aggressively."
- Positive reinforcement that "works *with* the nervous system… **without relying on guilt or punishment**."
([Finch ethical design](https://www.selfpause.com/resources/finch), [Calmevo review](https://calmevo.com/finch-app-review/), [Yoga Journal](https://www.yogajournal.com/lifestyle/finch-self-care-app/), [Sophie Pilley](https://www.sophiepilley.com/post/the-magic-of-finch-where-self-care-meets-enchanted-design))
Neko Atsume reinforces the same: a *passive, content* creature that's simply happy you're around, with no demands. ([Kore Kawaii](https://korekawaii.com/blogs/kawaii-lifestyle-blog/the-history-of-virtual-pets-from-tamagotchi-to-neopets-and-beyond))

### 6.3 Concrete rules for Yolkling's low/unwell/neglected states
1. **"Neglected" = `waiting`, not `sad`.** Reframe absence as *the creature patiently watching for you to come back* (glances toward the edge, calm posture), not crying/pining. This is the single most important reframe — it conveys "I missed you" warmth without "you let me down" guilt.
2. **The creature never dies, never irreversibly decays, never gets sick *because of you*.** "Unwell" should read as the creature having a low-energy day it will recover from — and recovery is gentle and automatic when you return, mirroring Finch's "glad to see you back."
3. **Make negative states sympathetic, not pathetic.** Low/tired = soft, droopy, *cozy* — something you want to comfort, not something accusing you. Keep the round, appealing silhouette (§2.12). No tears streaming, no rain cloud, no betrayed stare.
4. **Recovery is instant and warm on return.** The moment the user shows up, the creature brightens (a `waiting → happy` transition with a little perk-up). Reward presence; never penalize absence.
5. **No guilt notifications.** If you notify, it's an *invitation* ("Yolkling is having a slow day — want to sit together?"), never a threat or a shamed face. Tie notification copy to the same patient/warm tone.
6. **Honest mood ≠ manipulative mood.** The face reflects the user's *real* wellness (the honest part of the brand) — but the *framing* of low wellness is always self-compassionate. The creature is low *with* you (companionship in a hard moment), not low *at* you.
7. **Give the user agency over intensity.** Consider a setting to soften how strongly low moods show, so a struggling user is never confronted by a mirror of their worst day if they don't want it. (Aligns with Finch's "low-pressure" ethos.)

**One-line ethic:** Yolkling's negative states should make the user feel *gently accompanied*, never *indebted*.

---

## Implementation summary (for the SwiftUI engineer)
1. Split `Vibe` (persistent identity) from `Expression` (transient, interpolatable pose) — kill the mood-baked-into-color bug.
2. `Expression` is a pure `Sendable`/`Animatable` struct of normalized scalars + a few enums (§4.2); every mood is a preset; transitions are interpolations.
3. Render via a `Shape`/`Canvas` reading the `Expression`; run a continuous idle layer (breath/blink/saccade) whose amplitudes scale with `energy`.
4. Apply the 12 principles as motion *grammar* (volume-preserving squash/stretch, anticipation dips, overlapping appendage settle, mood-driven tempo, exaggerated signature feature).
5. A pure `MoodResolver(AppState, Date) → Expression` priority cascade picks the target; the view tweens to it.
6. Keep low/neglected states *patient and cozy* (Finch model); never die, shame, or guilt-trip.

## Sources

**Minimal expression & facial-feature roles**
- [Manga iconography — Wikipedia](https://en.wikipedia.org/wiki/Manga_iconography) (sweat drop, blush, heart/star/swirl eyes, Zzz, catchlight = life)
- [Emoticon — Wikipedia](https://en.wikipedia.org/wiki/Emoticon) and [Frown — Wikipedia](https://en.wikipedia.org/wiki/Frown) (mouth = valence, brow = negative intensity)
- [Facial expression — Wikipedia](https://en.wikipedia.org/wiki/Facial_expression)

**Reference companions / mascots**
- [How Tamagotchi Changed Digital Design — Japan House LA](https://www.japanhousela.com/articles/how-tamagotchi-changed-digital-design-icon-japanese-tiny-toys-30th-anniversary-bandai/)
- [History of Virtual Pets — Kore Kawaii](https://korekawaii.com/blogs/kawaii-lifestyle-blog/the-history-of-virtual-pets-from-tamagotchi-to-neopets-and-beyond) (Pou, Neko Atsume)
- [The Magic of Finch — Sophie Pilley](https://www.sophiepilley.com/post/the-magic-of-finch-where-self-care-meets-enchanted-design) and [Finch UX teardown — Medium](https://medium.com/@deepthi.aipm/ux-teardown-finch-self-care-app-18122357fae7)
- [Bringing Mascots to Life: Duolingo-style animation in Rive — Medium](https://uianimation.medium.com/bringing-mascots-to-life-duolingo-style-character-animation-in-rive-a075d648cf19) and [Duolingo design system — Duo](https://design.duolingo.com/illustration/duo)
- [Unlocking Headspace's Inner Brand Character — PopIcon](https://popicon.life/headspace-brand-character/)

**Pixar/Disney appeal & aliveness**
- [Pixar "Articulating the Appeal" (tech libraries)](https://www.pixar.com/technology-libraries)
- [How Disney & Pixar Bring Characters to Life — Inverse](https://www.inverse.com/article/13572-a-look-into-how-disney-and-pixar-bring-life-to-their-characters)
- [How ex-Apple/Disney/Pixar artists design characters — Marissa Louie](https://medium.com/@malouie/how-ex-apple-disney-and-pixar-artists-design-compelling-characters-3e4318db63a6)
- [Science of Idle Animations — Geniuscrate](https://www.geniuscrate.com/the-science-of-idle-animations-and-why-they-matter-in-modern-games), [Idle animation — Wikipedia](https://en.wikipedia.org/wiki/Idle_animation), [Why CGI looks dead — Medium](https://medium.com/@nazilm.ouhab/why-cgi-characters-still-look-dead-inside-51863f1f8094), [3D modeling eyes / saccades — Tripo3D](https://www.tripo3d.ai/blog/explore/3d-modeling-eyes)

**12 principles & squash/stretch**
- [UI Animation — applying Disney's 12 principles — IxDF](https://ixdf.org/literature/article/ui-animation-how-to-apply-disney-s-12-principles-of-animation-to-ui-design)
- [Disney's 12 principles in UI — Medium/Design Bootcamp](https://medium.com/design-bootcamp/disneys-12-principles-of-animation-in-everyday-ui-design-71c6592064fe)
- [Squash & Stretch principle — CGWire](https://blog.cg-wire.com/squash-stretch-principle/) and [RebusFarm](https://rebusfarm.net/blog/squash-and-stretch-in-animation-the-essential-principle-for-lifelike-motion) (volume preservation, emotion via posture)

**Emotion taxonomy & parametric face model**
- [Facial Action Coding System — Wikipedia](https://en.wikipedia.org/wiki/Facial_Action_Coding_System) and [Emotion classification — Wikipedia](https://en.wikipedia.org/wiki/Emotion_classification) (Ekman basic emotions, AUs)
- [Morph target animation — Wikipedia](https://en.wikipedia.org/wiki/Morph_target_animation), [Face Animation Parameter — Wikipedia](https://en.wikipedia.org/wiki/Face_Animation_Parameter), [Parametric animation — Wikipedia](https://en.wikipedia.org/wiki/Parametric_animation) (preset blending = blend shapes / FAPs)

**Ethics / anti-dark-pattern**
- [Finch ethical/gentle design — Selfpause](https://www.selfpause.com/resources/finch), [Calmevo](https://calmevo.com/finch-app-review/), [Yoga Journal](https://www.yogajournal.com/lifestyle/finch-self-care-app/)
- [Tamagotchi — Wikipedia](https://en.wikipedia.org/wiki/Tamagotchi) and [Tamagotchi effect — Wikipedia](https://en.wikipedia.org/wiki/Tamagotchi_effect) (death-within-half-a-day cautionary tale)
- [Guilt trip — Wikipedia](https://en.wikipedia.org/wiki/Guilt_trip), [Dark pattern — Wikipedia](https://en.wikipedia.org/wiki/Dark_pattern)
