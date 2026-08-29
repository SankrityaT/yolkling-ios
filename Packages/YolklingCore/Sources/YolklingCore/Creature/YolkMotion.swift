import Foundation

/// Every time-varying value the creature needs for a single frame, derived purely
/// from `t` (seconds on the creature's clock).
///
/// This is deliberately a pure, `Sendable` value type with no UI and no state: the
/// live view, the frozen share-card render, WidgetKit and snapshot tests all call
/// the same functions and get identical results for identical inputs. That property
/// is what makes `YolklingView.frozenAt` trustworthy.
///
/// Note the split from `YolkExpression`: expression is *what the creature feels*
/// (interpolated, semantic); motion is *what the clock is doing to it* (continuous,
/// stateless). Blink lives here rather than being folded into `eyeOpenness` because
/// every eye shape blinks differently — see `blink`.
public struct YolkMotion: Sendable, Equatable {

    /// Signed respiration, -1 fully exhaled … +1 fully inhaled.
    public var breath: Double

    /// Eyelid multiplier, 1 fully open … ~0.15 shut. Applied per eye shape by the
    /// renderer: it scales openness on round eyes and flattens the arc on lid eyes.
    public var blink: Double

    /// Wave envelope, 0 rest … ~1 fully up.
    public var wave: Double
    /// Signed side-to-side wiggle of the wave, -1 … 1.
    public var waveWiggle: Double
    /// Celebrate envelope, 0 rest … ~1 arms up mid-hop.
    public var celebrate: Double
    /// Signed pet response, -1 fully compressed … +1 fully stretched.
    public var pet: Double

    /// Retained so trailing parts can resample the body's past positions.
    private var t: Double
    private var bounce: Double
    private var reduceMotion: Bool
    private var celebrateStartT: Double?
    private var petStartT: Double?

    /// Resolve every channel for one instant.
    ///
    /// - Parameters:
    ///   - bounce: the pose's idle bounce height, needed to know how far the body
    ///     actually travels this frame (a still creature has nothing to trail).
    ///   - reduceMotion: when true, continuous travel is damped and trailing is
    ///     disabled outright. Blinking is deliberately preserved — it costs no screen
    ///     travel, and a creature that never blinks reads as dead, which helps nobody.
    public static func at(t: Double,
                   bounce: Double = 0,
                   waveStartT: Double? = nil,
                   celebrateStartT: Double? = nil,
                   petStartT: Double? = nil,
                   reduceMotion: Bool = false) -> YolkMotion {
        // Reduce Motion keeps every *pose* — expression is communication, not decoration —
        // but suppresses travel: no hop, no wave arc, no squash, damped breath.
        YolkMotion(
            breath: breath(t: t) * (reduceMotion ? 0.35 : 1),
            blink: blink(t: t),
            wave: reduceMotion ? 0 : waveEnvelope(t: t, start: waveStartT),
            waveWiggle: reduceMotion ? 0 : waveWiggleValue(t: t, start: waveStartT),
            celebrate: reduceMotion ? 0 : celebrateEnvelope(t: t, start: celebrateStartT),
            pet: reduceMotion ? 0 : petEnvelope(t: t, start: petStartT),
            t: t,
            bounce: bounce,
            reduceMotion: reduceMotion,
            celebrateStartT: reduceMotion ? nil : celebrateStartT,
            petStartT: reduceMotion ? nil : petStartT
        )
    }

    // MARK: One-shot envelopes
    //
    // These are pure functions of `t` rather than `Date` on purpose: `trail` has to
    // resample them at t−lag, which a wall-clock start date can't support. It also
    // means one-shots survive `frozenAt` and snapshot tests.

    /// Wave envelope (0 rest … ~1 fully up), ramping in and out over ~1.7s.
    public static func waveEnvelope(t: Double, start: Double?) -> Double {
        #if DEBUG
        if ProcessInfo.processInfo.environment["YOLK_WAVE_FREEZE"] != nil { return 0.92 }
        #endif
        guard let start else { return 0 }
        let el = t - start
        guard el >= 0, el <= 1.7 else { return 0 }
        return min(1, el / 0.22) * min(1, max(0, (1.7 - el) / 0.32))
    }

    /// Signed side-to-side wiggle (-1…1) of the wave.
    public static func waveWiggleValue(t: Double, start: Double?) -> Double {
        #if DEBUG
        if ProcessInfo.processInfo.environment["YOLK_WAVE_FREEZE"] != nil { return 0.6 }
        #endif
        guard let start else { return 0 }
        return sin(2 * .pi * 2.7 * (t - start))
    }

    /// Celebrate envelope (0 rest … ~1 arms up + mid-hop) over ~1.2s.
    public static func celebrateEnvelope(t: Double, start: Double?) -> Double {
        #if DEBUG
        if ProcessInfo.processInfo.environment["YOLK_CELEBRATE_FREEZE"] != nil { return 0.95 }
        #endif
        guard let start else { return 0 }
        let el = t - start
        guard el >= 0, el <= 1.2 else { return 0 }
        return min(1, el / 0.18) * min(1, max(0, (1.2 - el) / 0.3))
    }

    /// Signed pet response, -1 fully compressed … +1 fully stretched, over ~0.61s.
    ///
    /// Squash-and-stretch, done properly: a brief **anticipation** compress before the
    /// release, then a stretch that overshoots and rings down. The anticipation is what
    /// separates this from a scale-up — it's the oldest trick in character animation and
    /// the reason a pet feels like a reaction rather than a transform.
    public static func petEnvelope(t: Double, start: Double?) -> Double {
        guard let start else { return 0 }
        let el = t - start
        guard el >= 0, el <= 0.61 else { return 0 }
        if el < 0.06 {
            return -sin(.pi * 0.5 * (el / 0.06))          // anticipation: -0 → -1
        }
        let x = el - 0.06
        return -cos(2 * .pi * 5 * x) * exp(-x * 5)        // release +1, then decaying ring
    }

    // MARK: Secondary motion

    /// Vertical body travel at `time`, as a multiple of the creature's `size`.
    /// Mirrors the group offset in `YolklingView` so followers track the real body.
    ///
    /// The celebrate hop is included deliberately. Idle breath alone is a slow ~3.5s
    /// sine, and lagging a slow signal displaces almost nothing (measured: <1px at
    /// 220pt). Secondary motion only reads on fast moves, so the one-shots are where
    /// the effect actually lives.
    private func rise(at time: Double) -> Double {
        let b = Self.breath(t: time) * (reduceMotion ? 0.35 : 1)
        let idle = 0.14 * bounce * (0.5 + 0.5 * b)
        let hop = 0.16 * Self.celebrateEnvelope(t: time, start: celebrateStartT)
        let petLift = 0.05 * Self.petEnvelope(t: time, start: petStartT)
        return idle + hop + petLift
    }

    /// How far a part that trails the body by `lag` seconds should be displaced this
    /// frame, as a multiple of `size`. Positive means "hasn't caught up yet".
    ///
    /// Evaluated **analytically** rather than integrated: because every value is a pure
    /// function of time, "where the body was `lag` ago" is just another sample. No
    /// solver, no stored velocity, frame-rate independent, and deterministic — which is
    /// what lets it survive `frozenAt` and WidgetKit.
    ///
    /// `overshoot` extrapolates the lagged motion forward by its own velocity so the
    /// part sails past and settles instead of snapping. That settle is the difference
    /// between a hat that's glued on and one that's worn.
    public func trail(lag: Double, overshoot: Double = 0.35) -> Double {
        guard !reduceMotion else { return 0 }
        let now = rise(at: t)
        let then = rise(at: t - lag)
        let before = rise(at: t - 2 * lag)
        let follower = then + overshoot * (then - before)
        return now - follower
    }

    /// Current vertical body travel, as a multiple of `size`. Drives the ground shadow.
    public var bodyRise: Double { rise(at: t) }

    /// Suggested lags, in seconds. Heavier / further from the body ⇒ more lag.
    /// `face` is near-rigid on purpose: glasses that trail would slide off the face.
    public enum Lag {
        public static let hat = 0.09
        public static let neck = 0.06
        public static let arm = 0.05
        public static let foot = 0.04
        public static let face = 0.025
    }

    // MARK: Breath

    private static let primaryHz = 0.28
    private static let secondaryHz = 0.11

    /// Respiration, -1 … +1.
    ///
    /// Two things separate this from a plain sine. The phase is **warped** so the
    /// inhale takes 40% of the cycle and the exhale 60% — that asymmetry is most of
    /// the difference between "pulsing" and "breathing". And a second, slower
    /// incommensurate swell is mixed in, so the loop only truly repeats every ~100s
    /// and never reads as a cycle.
    ///
    /// The frequencies are constant on purpose: a mood change must never jump the
    /// breath phase. Liveliness lives in amplitude and bounce, which interpolate.
    public static func breath(t: Double) -> Double {
        let p = (t * primaryHz).truncatingRemainder(dividingBy: 1)
        let inhale = 0.4
        let q = p < inhale
            ? 0.5 * (p / inhale)                       // quick rise
            : 0.5 + 0.5 * ((p - inhale) / (1 - inhale))  // slower fall
        let primary = -cos(2 * .pi * q)                // -1 at rest, +1 at full inhale
        let secondary = sin(2 * .pi * secondaryHz * t)
        return (primary + 0.33 * secondary) / 1.33
    }

    // MARK: Blink

    private static let blinkBase = 3.6      // nominal seconds between blinks
    private static let blinkWindow = 0.16   // how long one blink takes

    /// Eyelid multiplier for `t`, 1 open … 0.15 shut.
    ///
    /// Blinks are scheduled on a nominal 3.6s beat but each one is jittered by a
    /// deterministic hash of its index (−0.9…+1.6s), with an occasional double blink.
    /// Metronomic blinking is the single strongest "this is a machine" tell; irregular
    /// blinking reads as alive. Because the jitter is hashed rather than random, the
    /// schedule is identical on every device and in every snapshot.
    public static func blink(t: Double) -> Double {
        var closed = 0.0
        let i0 = Int(floor(t / blinkBase))
        // Scan neighbours too: jitter can pull a blink across a slot boundary.
        for i in (i0 - 1)...(i0 + 1) {
            let jitter = -0.9 + 2.5 * hash01(i, salt: 0xB1)
            let start = Double(i) * blinkBase + jitter
            closed = max(closed, pulse(t - start))
            if hash01(i, salt: 0x7C) < 0.18 {
                closed = max(closed, pulse(t - (start + 0.22)))   // double blink
            }
        }
        return 1 - 0.85 * closed
    }

    /// A single 0 → 1 → 0 lid sweep over `blinkWindow`.
    private static func pulse(_ dt: Double) -> Double {
        guard dt >= 0, dt < blinkWindow else { return 0 }
        return sin(.pi * dt / blinkWindow)
    }

    /// Deterministic [0,1) hash (SplitMix64 finaliser). Stateless stand-in for a RNG
    /// so motion stays reproducible across devices, renders and test runs.
    private static func hash01(_ i: Int, salt: UInt64) -> Double {
        var x = UInt64(bitPattern: Int64(i)) &+ (salt &* 0x9E37_79B9_7F4A_7C15)
        x ^= x >> 30; x = x &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 27; x = x &* 0x94D0_49BB_1331_11EB
        x ^= x >> 31
        return Double(x >> 11) * (1.0 / 9_007_199_254_740_992.0)   // 2^53
    }
}
