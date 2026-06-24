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
struct YolkExpression: Equatable, Sendable {

    // MARK: Eyes
    var eyeOpenness: Double      // 0 closed ... 1 wide
    var eyeShape: EyeShape       // discrete token layered on openness
    var pupilX: Double           // -1 ... 1 gaze left/right
    var pupilY: Double           // -1 ... 1 gaze down/up
    var pupilScale: Double       // 0.6 dilated-pin ... 1.3 wide
    var catchlight: Double       // 0 ... 1 specular life-dot opacity

    // MARK: Brow (subtle; carried mostly by eyes + mouth + body in v1)
    var browAngle: Double        // -1 worried/inner-up ... 0 neutral ... +1 down

    // MARK: Mouth
    var mouthCurve: Double       // -1 frown ... 0 flat ... +1 big smile
    var mouthOpen: Double        // 0 closed ... 1 wide open ("o"/grin/yawn)
    var mouthWidth: Double       // 0.7 narrow ... 1.2 wide
    var mouthAsymmetry: Double   // -1 ... 1 smirk / wink side (charm)

    // MARK: Cheeks / blush
    var blush: Double            // 0 ... 1 intensity
    var blushHue: BlushHue       // warm pink | pale | unwell green

    // MARK: Body posture
    var squashStretch: Double    // -1 deflated & wide (low) ... +1 tall & proud
    var bodyLean: Double         // -1 ... 1 lean toward friend/user
    var headTilt: Double         // degrees, small (curiosity, affection)
    var bounce: Double           // 0 ... 1 idle bounce height
    var energy: Double           // 0 ... 1 master tempo (breath/blink/spring)

    // MARK: Accent
    var particle: Particle       // single dominant effect, chosen by priority

    enum EyeShape: Sendable, Equatable { case round, happyArc, heart, sparkle, sleepy }
    enum BlushHue: Sendable, Equatable { case pink, pale, green }
    enum Particle: Sendable, Equatable { case none, sparkles, hearts, zzz }

    /// One designated initialiser whose defaults ARE the `content` resting pose,
    /// so each preset only states what differs from "warm and at ease".
    init(
        eyeOpenness: Double = 0.62,
        eyeShape: EyeShape = .round,
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
    static let content = YolkExpression()

    static let happy = YolkExpression(
        eyeOpenness: 0.5, eyeShape: .happyArc, pupilY: 0.1,
        mouthCurve: 0.85, mouthOpen: 0.2, blush: 0.5,
        bounce: 0.24, energy: 0.7, particle: .sparkles
    )

    static let excited = YolkExpression(
        eyeOpenness: 0.95, eyeShape: .sparkle, pupilScale: 1.2,
        mouthCurve: 0.9, mouthOpen: 0.6, mouthWidth: 1.12, blush: 0.6,
        squashStretch: 0.12, bounce: 0.5, energy: 1.0, particle: .sparkles
    )

    static let proud = YolkExpression(
        eyeOpenness: 0.55, pupilY: 0.08,
        mouthCurve: 0.62, mouthAsymmetry: 0.3, blush: 0.4,
        squashStretch: 0.5, energy: 0.45
    )

    static let affectionate = YolkExpression(
        eyeOpenness: 0.5, eyeShape: .heart,
        mouthCurve: 0.5, blush: 0.8,
        bodyLean: 0.16, headTilt: 5, energy: 0.4, particle: .hearts
    )

    static let curious = YolkExpression(
        eyeOpenness: 0.82, pupilX: 0.4,
        browAngle: -0.05, mouthCurve: 0.2, mouthOpen: 0.3, blush: 0.2,
        headTilt: 9, bounce: 0.1, energy: 0.6
    )

    static let surprised = YolkExpression(
        eyeOpenness: 1.0, pupilScale: 0.8,
        mouthCurve: 0, mouthOpen: 0.7, blush: 0.3,
        squashStretch: 0.2, bounce: 0, energy: 0.85
    )

    static let sleepy = YolkExpression(
        eyeOpenness: 0.24, eyeShape: .sleepy, pupilY: -0.2, catchlight: 0.5,
        browAngle: -0.1, mouthCurve: 0.1, mouthOpen: 0.15, blush: 0.2,
        squashStretch: -0.12, bounce: 0.05, energy: 0.15, particle: .zzz
    )

    static let calm = YolkExpression(
        eyeOpenness: 0.42, eyeShape: .happyArc,
        mouthCurve: 0.35, blush: 0.3, bounce: 0.08, energy: 0.3
    )

    static let playful = YolkExpression(
        eyeOpenness: 0.6, pupilX: 0.3,
        mouthCurve: 0.6, mouthOpen: 0.2, mouthAsymmetry: 0.45, blush: 0.4,
        bounce: 0.3, energy: 0.8, particle: .sparkles
    )

    // Gentle low-energy moods — sympathetic, never guilt-tripping (research §6).
    static let low = YolkExpression(
        eyeOpenness: 0.4, pupilY: -0.3,
        browAngle: -0.4, mouthCurve: -0.3, blush: 0.12, blushHue: .pale,
        squashStretch: -0.35, bounce: 0.04, energy: 0.2
    )

    static let tired = YolkExpression(
        eyeOpenness: 0.3, eyeShape: .sleepy, pupilY: -0.2, catchlight: 0.5,
        browAngle: -0.15, mouthCurve: -0.08, blush: 0.12,
        squashStretch: -0.2, bounce: 0.04, energy: 0.2
    )

    static let unwell = YolkExpression(
        eyeOpenness: 0.35, pupilX: 0.1,
        browAngle: -0.2, mouthCurve: -0.08, mouthOpen: 0.1,
        blush: 0.2, blushHue: .green,
        squashStretch: -0.2, bounce: 0.04, energy: 0.2
    )

    /// The "neglected" state, reframed as patient waiting (Finch model): looking
    /// toward the edge for you to come back, calm, never pining or accusing.
    static let waiting = YolkExpression(
        eyeOpenness: 0.46, pupilX: 0.5,
        browAngle: -0.05, mouthCurve: 0.06, blush: 0.2,
        bounce: 0.06, energy: 0.35
    )
}

// MARK: - Interpolation

extension YolkExpression {
    /// Linear blend of two poses, for crossfades and partial intensities.
    /// Continuous channels lerp; discrete tokens snap at the midpoint.
    static func lerp(_ a: YolkExpression, _ b: YolkExpression, _ t: Double) -> YolkExpression {
        let t = min(1, max(0, t))
        func m(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
        return YolkExpression(
            eyeOpenness: m(a.eyeOpenness, b.eyeOpenness),
            eyeShape: t < 0.5 ? a.eyeShape : b.eyeShape,
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
    func energized(by vitality: Double) -> YolkExpression {
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
    enum DayPhase { case morning, day, evening, night }

    static func phase(forHour h: Int) -> DayPhase {
        switch h {
        case 22, 23, 0, 1, 2, 3, 4: return .night
        case 5...10:                return .morning
        case 18...21:               return .evening
        default:                    return .day
        }
    }

    func atPhase(_ phase: DayPhase, sleptWell: Bool) -> YolkExpression {
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
    func warmed(by trust: Double) -> YolkExpression {
        var e = self
        e.blush = min(1, max(0, e.blush + (trust - 0.3) * 0.45))
        e.eyeOpenness = min(1, max(0.2, e.eyeOpenness + (trust - 0.5) * 0.12))
        e.bodyLean = max(-1, min(1, e.bodyLean + (trust - 0.3) * 0.3))
        e.catchlight = min(1, e.catchlight + trust * 0.2)
        if trust < 0.2 { e.headTilt -= 4; e.pupilY -= 0.04 }   // a little shy
        return e
    }
}
