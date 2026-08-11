import SwiftUI

/// A complete, interpolatable facial + body pose for a yolkling.
///
/// This is the EMOTION layer, deliberately separate from `Vibe` (the IDENTITY:
/// colour, body, patterns). Every mood is a static preset; the rendered face is
/// an interpolation between presets, so transitions are free and smooth. A pure,
/// `Sendable` value type with no UI and no IO, so it is trivially testable.
///
/// Architecture is blend-shape / morph-target: a neutral base plus named target
/// poses, blended by interpolating each channel. See
/// `docs/research/07-creature-expression.md`. (Named `YolkExpression` to avoid
/// colliding with Foundation's generic `Expression`.)
public struct YolkExpression: Equatable, Sendable {

    // MARK: Eyes
    public var eyeOpenness: Double      // 0 closed ... 1 wide
    public var eyeShape: EyeShape       // discrete token layered on openness

    /// A wink: how far the creature's RIGHT eye is closed, independently of the left.
    /// 0 both eyes as `eyeShape` says, 1 fully winking.
    ///
    /// The only asymmetric thing on the face, and it needs its own field because
    /// `eyeShape` and `eyeOpenness` are shared by both eyes by design — the whole
    /// expression system is "one pose, applied twice", which is what keeps 14 moods
    /// cheap. A wink is the one gesture that cannot be expressed that way, so rather
    /// than splitting every eye field in two it gets a single scalar that overrides one
    /// side. Lerps continuously, so a wink opens and closes smoothly like any other pose
    /// change.
    public var wink: Double = 0
    public var pupilX: Double           // -1 ... 1 gaze left/right
    public var pupilY: Double           // -1 ... 1 gaze down/up
    public var pupilScale: Double       // 0.6 dilated-pin ... 1.3 wide
    public var catchlight: Double       // 0 ... 1 specular life-dot opacity

    // MARK: Brow (subtle; carried mostly by eyes + mouth + body in v1)
    public var browAngle: Double        // -1 worried/inner-up ... 0 neutral ... +1 down

    // MARK: Mouth
    public var mouthCurve: Double       // -1 frown ... 0 flat ... +1 big smile
    var mouthOpen: Double        // 0 closed ... 1 wide open ("o"/grin/yawn)
    public var mouthWidth: Double       // 0.7 narrow ... 1.2 wide
    public var mouthAsymmetry: Double   // -1 ... 1 smirk / wink side (charm)

    // MARK: Cheeks / blush
    public var blush: Double            // 0 ... 1 intensity
    public var blushHue: BlushHue       // warm pink | pale | unwell green

    // MARK: Body posture
    public var squashStretch: Double    // -1 deflated & wide (low) ... +1 tall & proud
    public var bodyLean: Double         // -1 ... 1 lean toward friend/user
    public var headTilt: Double         // degrees, small (curiosity, affection)
    public var bounce: Double           // 0 ... 1 idle bounce height
    public var energy: Double           // 0 ... 1 master tempo (breath/blink/spring)

    // MARK: Accent
    public var particle: Particle       // single dominant effect, chosen by priority

    public enum EyeShape: Sendable, Equatable { case round, happyArc, heart, sparkle, sleepy }
    public enum BlushHue: Sendable, Equatable { case pink, pale, green }
    public enum Particle: Sendable, Equatable { case none, sparkles, hearts, zzz }

    /// One designated initialiser whose defaults ARE the `content` resting pose,
    /// so each preset only states what differs from "warm and at ease".
    public init(
        eyeOpenness: Double = 0.62,
        eyeShape: EyeShape = .round,
        wink: Double = 0,
        pupilX: Double = 0,
        pupilY: Double = 0,
        pupilScale: Double = 1,
        catchlight: Double = 1,
        browAngle: Double = 0,
        mouthCurve: Double = 0.4,
        mouthOpen: Double = 0,
        mouthWidth: Double = 1,
        mouthAsymmetry: Double = 0.1,
        blush: Double = 0.3,
        blushHue: BlushHue = .pink,
        squashStretch: Double = 0,
        bodyLean: Double = 0,
        headTilt: Double = 0,
        bounce: Double = 0.12,
        energy: Double = 0.5,
        particle: Particle = .none
    ) {
        self.eyeOpenness = eyeOpenness
        self.eyeShape = eyeShape
        self.wink = wink
        self.pupilX = pupilX
        self.pupilY = pupilY
        self.pupilScale = pupilScale
        self.catchlight = catchlight
        self.browAngle = browAngle
        self.mouthCurve = mouthCurve
        self.mouthOpen = mouthOpen
        self.mouthWidth = mouthWidth
        self.mouthAsymmetry = mouthAsymmetry
        self.blush = blush
        self.blushHue = blushHue
        self.squashStretch = squashStretch
        self.bodyLean = bodyLean
        self.headTilt = headTilt
        self.bounce = bounce
        self.energy = energy
        self.particle = particle
    }
}

// MARK: - Presets (one per mood, numbers from research §3)

extension YolkExpression {
    public static let content = YolkExpression()

    public static let happy = YolkExpression(
        eyeOpenness: 0.5, eyeShape: .happyArc, pupilY: 0.1,
        mouthCurve: 0.85, mouthOpen: 0.2, blush: 0.5,
        bounce: 0.24, energy: 0.7, particle: .sparkles
    )

    public static let excited = YolkExpression(
        eyeOpenness: 0.95, eyeShape: .sparkle, pupilScale: 1.2,
        mouthCurve: 0.9, mouthOpen: 0.6, mouthWidth: 1.12, blush: 0.6,
        squashStretch: 0.12, bounce: 0.5, energy: 1.0, particle: .sparkles
    )

    public static let proud = YolkExpression(
        eyeOpenness: 0.55, pupilY: 0.08,
        mouthCurve: 0.62, mouthAsymmetry: 0.3, blush: 0.4,
        squashStretch: 0.5, energy: 0.45
    )

    public static let affectionate = YolkExpression(
        eyeOpenness: 0.5, eyeShape: .heart,
        mouthCurve: 0.5, blush: 0.8,
        bodyLean: 0.16, headTilt: 5, energy: 0.4, particle: .hearts
    )

    /// A heart-eyed wink. The "yes, this one" face.
    ///
    /// One heart eye and one closed, which is why `wink` had to exist: it is the only pose
    /// in the set where the two eyes disagree. Blush is at maximum and the head tilts into
    /// it, so it reads as delighted rather than merely smug.
    public static let smitten = YolkExpression(
        eyeOpenness: 0.55, eyeShape: .heart, wink: 1,
        mouthCurve: 0.8, mouthOpen: 0.15, mouthAsymmetry: 0.35, blush: 0.95,
        squashStretch: 0.1, bodyLean: 0.1, headTilt: 7,
        bounce: 0.22, energy: 0.6, particle: .hearts
    )

    public static let curious = YolkExpression(
        eyeOpenness: 0.82, pupilX: 0.4,
        browAngle: -0.05, mouthCurve: 0.2, mouthOpen: 0.3, blush: 0.2,
        headTilt: 9, bounce: 0.1, energy: 0.6
    )

    public static let surprised = YolkExpression(
        eyeOpenness: 1.0, pupilScale: 0.8,
        mouthCurve: 0, mouthOpen: 0.7, blush: 0.3,
        squashStretch: 0.2, bounce: 0, energy: 0.85
    )

    public static let sleepy = YolkExpression(
        eyeOpenness: 0.24, eyeShape: .sleepy, pupilY: -0.2, catchlight: 0.5,
        browAngle: -0.1, mouthCurve: 0.1, mouthOpen: 0.15, blush: 0.2,
        squashStretch: -0.12, bounce: 0.05, energy: 0.15, particle: .zzz
    )

    public static let calm = YolkExpression(
        eyeOpenness: 0.42, eyeShape: .happyArc,
        mouthCurve: 0.35, blush: 0.3, bounce: 0.08, energy: 0.3
    )

    public static let playful = YolkExpression(
        eyeOpenness: 0.6, pupilX: 0.3,
        mouthCurve: 0.6, mouthOpen: 0.2, mouthAsymmetry: 0.45, blush: 0.4,
        bounce: 0.3, energy: 0.8, particle: .sparkles
    )

    // Gentle low-energy moods — sympathetic, never guilt-tripping (research §6).
    public static let low = YolkExpression(
        eyeOpenness: 0.4, pupilY: -0.3,
        browAngle: -0.4, mouthCurve: -0.3, blush: 0.12, blushHue: .pale,
        squashStretch: -0.35, bounce: 0.04, energy: 0.2
    )

    public static let tired = YolkExpression(
        eyeOpenness: 0.3, eyeShape: .sleepy, pupilY: -0.2, catchlight: 0.5,
        browAngle: -0.15, mouthCurve: -0.08, blush: 0.12,
        squashStretch: -0.2, bounce: 0.04, energy: 0.2
    )

    public static let unwell = YolkExpression(
        eyeOpenness: 0.35, pupilX: 0.1,
        browAngle: -0.2, mouthCurve: -0.08, mouthOpen: 0.1,
        blush: 0.2, blushHue: .green,
        squashStretch: -0.2, bounce: 0.04, energy: 0.2
    )

    /// The "neglected" state, reframed as patient waiting (Finch model): looking
    /// toward the edge for you to come back, calm, never pining or accusing.
    public static let waiting = YolkExpression(
        eyeOpenness: 0.46, pupilX: 0.5,
        browAngle: -0.05, mouthCurve: 0.06, blush: 0.2,
        bounce: 0.06, energy: 0.35
    )

    // MARK: Vocabulary
    //
    // Six more poses. The blend-shape system was always capable of far more than the
    // fourteen it shipped with — every channel already lerps, `browAngle` already renders,
    // and adding a pose is adding numbers. The bottleneck was never the machinery, it was
    // that nobody had written the poses down.
    //
    // Each of these changes at least THREE channels away from its nearest neighbour.
    // Anything less and it reads as the same face slightly adjusted, which is worse than
    // not having it: a mood the player cannot name is noise.

    /// Working something out. Gaze up and off to one side, one brow raised, mouth small.
    ///
    /// The gaze is the whole pose. Looking UP AND AWAY is what humans read as thought
    /// rather than attention — a creature thinking at you is just staring.
    public static let thinking = YolkExpression(
        eyeOpenness: 0.66, pupilX: -0.55, pupilY: 0.45, pupilScale: 0.9,
        browAngle: 0.28, mouthCurve: 0.12, mouthWidth: 0.78,
        headTilt: -7, bounce: 0.06, energy: 0.4
    )

    /// A big waking stretch. Tall, eyes squeezed shut, mouth open.
    ///
    /// `squashStretch` at its ceiling — the only pose that uses the top of that range, so
    /// it is unmistakable in silhouette alone, which is what a stretch has to be.
    public static let stretching = YolkExpression(
        eyeOpenness: 0.12, eyeShape: .happyArc,
        mouthCurve: 0.5, mouthOpen: 0.75, mouthWidth: 0.9, blush: 0.4,
        squashStretch: 0.95, bounce: 0, energy: 0.55
    )

    /// Caught being pleased. Looking down and away, blushing hard, tilted in.
    ///
    /// Blush is at 1.0, higher than `affectionate`, because shyness is the one state where
    /// the cheeks ARE the expression: the eyes are hiding and the mouth is doing very
    /// little, so nothing else is carrying it.
    public static let shy = YolkExpression(
        eyeOpenness: 0.34, pupilX: 0.4, pupilY: -0.45, catchlight: 0.8,
        browAngle: -0.2, mouthCurve: 0.42, mouthWidth: 0.75, blush: 1.0,
        squashStretch: -0.1, bodyLean: -0.12, headTilt: 12,
        bounce: 0.08, energy: 0.35
    )

    /// Up to something. Narrowed eyes, one side of the mouth well up.
    ///
    /// `mouthAsymmetry` at 0.8, roughly double `playful`. A symmetric smile cannot be
    /// mischievous — it reads as delight. The lopsidedness IS the mischief.
    public static let mischief = YolkExpression(
        eyeOpenness: 0.32, pupilX: 0.25, pupilScale: 0.85,
        browAngle: 0.45, mouthCurve: 0.55, mouthOpen: 0.12,
        mouthWidth: 1.08, mouthAsymmetry: 0.8, blush: 0.45,
        bodyLean: 0.1, headTilt: -5, bounce: 0.18, energy: 0.7
    )

    /// The breath out after something was fine after all. Eyes shut, shoulders down.
    ///
    /// Deliberately NEGATIVE squash: relief is a deflation, and every other happy pose in
    /// the set is neutral or tall. That contrast is what stops it reading as `calm`.
    public static let relieved = YolkExpression(
        eyeOpenness: 0.16, eyeShape: .happyArc,
        browAngle: -0.12, mouthCurve: 0.6, mouthOpen: 0.3, blush: 0.45,
        squashStretch: -0.4, bounce: 0.05, energy: 0.3
    )

    /// Braced and ready. Brows down, small firm mouth, squared up.
    ///
    /// The only pose with a positive `browAngle` AND a level mouth. Determination and
    /// annoyance share a brow, so the mouth has to do the disambiguating: a flat-but-not-
    /// frowning line reads as resolve, and any downward curve at all reads as cross.
    public static let determined = YolkExpression(
        eyeOpenness: 0.5, pupilScale: 0.88, catchlight: 1,
        browAngle: 0.6, mouthCurve: 0.05, mouthWidth: 0.85, blush: 0.3,
        squashStretch: 0.3, bodyLean: 0.14, bounce: 0.1, energy: 0.65
    )

    /// Every pose, for the preview seam. Order is roughly calm to lively so the grid reads
    /// as a range rather than a bag.
    public static let all: [(String, YolkExpression)] = [
        ("content", .content), ("calm", .calm), ("sleepy", .sleepy), ("tired", .tired),
        ("low", .low), ("unwell", .unwell), ("waiting", .waiting), ("relieved", .relieved),
        ("shy", .shy), ("thinking", .thinking), ("curious", .curious), ("happy", .happy),
        ("proud", .proud), ("determined", .determined), ("playful", .playful),
        ("mischief", .mischief), ("stretching", .stretching), ("surprised", .surprised),
        ("excited", .excited), ("affectionate", .affectionate), ("smitten", .smitten),
    ]
}

// MARK: - Interpolation

extension YolkExpression {
    /// Linear blend of two poses, for crossfades and partial intensities.
    /// Continuous channels lerp; discrete tokens snap at the midpoint.
    public static func lerp(_ a: YolkExpression, _ b: YolkExpression, _ t: Double) -> YolkExpression {
        let t = min(1, max(0, t))
        func m(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
        return YolkExpression(
            eyeOpenness: m(a.eyeOpenness, b.eyeOpenness),
            eyeShape: t < 0.5 ? a.eyeShape : b.eyeShape,
            wink: m(a.wink, b.wink),
            pupilX: m(a.pupilX, b.pupilX),
            pupilY: m(a.pupilY, b.pupilY),
            pupilScale: m(a.pupilScale, b.pupilScale),
            catchlight: m(a.catchlight, b.catchlight),
            browAngle: m(a.browAngle, b.browAngle),
            mouthCurve: m(a.mouthCurve, b.mouthCurve),
            mouthOpen: m(a.mouthOpen, b.mouthOpen),
            mouthWidth: m(a.mouthWidth, b.mouthWidth),
            mouthAsymmetry: m(a.mouthAsymmetry, b.mouthAsymmetry),
            blush: m(a.blush, b.blush),
            blushHue: t < 0.5 ? a.blushHue : b.blushHue,
            squashStretch: m(a.squashStretch, b.squashStretch),
            bodyLean: m(a.bodyLean, b.bodyLean),
            headTilt: m(a.headTilt, b.headTilt),
            bounce: m(a.bounce, b.bounce),
            energy: m(a.energy, b.energy),
            particle: t < 0.5 ? a.particle : b.particle
        )
    }
}

extension YolkExpression {
    /// Layer real-life vitality (0..1, from steps + sleep) onto an emotional pose:
    /// lively and sparkly when you've moved + rested well, a touch sleepy when you
    /// haven't. This is the creature visibly reflecting how you're living. Gentle by
    /// design, the low end reads as cozy-tired, never sad.
    public func energized(by vitality: Double) -> YolkExpression {
        var e = self
        if vitality >= 0.7 {
            e.energy = max(e.energy, 0.85)
            e.bounce = max(e.bounce, 0.3)
            e.blush = max(e.blush, 0.5)
            e.squashStretch = max(e.squashStretch, 0.25)
            if e.mouthCurve > 0 { e.mouthCurve = min(1, e.mouthCurve + 0.2) }
            if e.eyeShape == .round { e.eyeShape = .happyArc }
            if e.particle == .none { e.particle = .sparkles }
        } else if vitality < 0.35 {
            e.energy = min(e.energy, 0.28)
            e.bounce = min(e.bounce, 0.05)
            e.squashStretch = min(e.squashStretch, -0.15)
            e.eyeShape = .sleepy
            e.eyeOpenness = min(e.eyeOpenness, 0.4)
            if e.particle == .none { e.particle = .zzz }
        }
        return e
    }

    /// The yolk lives on a daily rhythm: fresh in the morning (brighter after good
    /// sleep), easy through the day, winding down in the evening, and genuinely drowsy
    /// late at night, when it nudges YOU to sleep too. See docs/RELATIONSHIP.md.
    public enum DayPhase { case morning, day, evening, night }

    public static func phase(forHour h: Int) -> DayPhase {
        switch h {
        case 22, 23, 0, 1, 2, 3, 4: return .night
        case 5...10:                return .morning
        case 18...21:               return .evening
        default:                    return .day
        }
    }

    public func atPhase(_ phase: DayPhase, sleptWell: Bool) -> YolkExpression {
        var e = self
        switch phase {
        case .night:
            e.energy = min(e.energy, 0.2)
            e.bounce = min(e.bounce, 0.04)
            e.eyeShape = .sleepy
            e.eyeOpenness = min(e.eyeOpenness, 0.32)
            e.mouthOpen = max(e.mouthOpen, 0.22)        // a soft yawn
            if e.particle == .none || e.particle == .sparkles { e.particle = .zzz }
        case .evening:
            e.energy = min(e.energy, 0.45)
            e.bounce = min(e.bounce, 0.1)
        case .morning:
            if sleptWell {
                e.energy = max(e.energy, 0.72)
                e.blush = min(1, e.blush + 0.15)
                if e.particle == .none { e.particle = .sparkles }
            }
        case .day:
            break
        }
        return e
    }

    /// Layer relationship trust (0..1) onto a pose. Trust rises only when you take
    /// care of YOURSELF, so a trusting yolk leans toward you, blushes, and meets your
    /// eyes; a yolk that barely knows you is a touch shy and reserved. Gentle.
    public func warmed(by trust: Double) -> YolkExpression {
        var e = self
        e.blush = min(1, max(0, e.blush + (trust - 0.3) * 0.45))
        e.eyeOpenness = min(1, max(0.2, e.eyeOpenness + (trust - 0.5) * 0.12))
        e.bodyLean = max(-1, min(1, e.bodyLean + (trust - 0.3) * 0.3))
        e.catchlight = min(1, e.catchlight + trust * 0.2)
        if trust < 0.2 { e.headTilt -= 4; e.pupilY -= 0.04 }   // a little shy
        return e
    }
}
