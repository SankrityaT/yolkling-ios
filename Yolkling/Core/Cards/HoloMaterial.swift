import SwiftUI

/// The foils — the maths and the materials behind a card that catches the light.
///
/// Four ideas carry the whole thing, and they are the same four that make a real foil
/// card work:
///
///   **One input shape.** Device tilt and a finger drag are completely different signals,
///   so both normalise to the same `CGPoint` in −1…1 before anything reads them (see
///   ``CardTilt``). Tilt, foil position, glare and sheen all derive from that one pair.
///
///   **The foil lags the card.** Real laminate has mass: the surface catches up to the
///   card rather than moving with it. Two followers at different stiffnesses is what turns
///   "a gradient that tracks your finger" into a material.
///
///   **The print never changes.** The card is the creature's own colour and it stays that
///   colour under every material. Only the foil above it moves. A material that re-prints
///   the card is a different card; one that changes the foil is the same card under a
///   different laminate, which is the thing worth showing.
///
///   **Materials are data, not view code.** Every material is a list of generic layers
///   whose entire paint — pattern, scale, travel rate, blend, filter, opacity curve — is
///   a value. ``YolkCard`` never knows which material is mounted, so adding one is adding
///   an entry to the array at the bottom of this file.
///
/// Widget note: this whole directory is app-target only. It has no business in a widget,
/// which cannot animate and has no motion sensor.
struct HoloMaterial: Sendable, Identifiable {
    let id: String
    let label: String
    var layers: [HoloLayer]

    /// How far the whole sheet slides per unit of tilt, as a fraction of the card.
    ///
    /// **The most important number here.** A sheet that tracks 1:1 reads as a gradient
    /// following your finger; one that barely moves reads as a layer of laminate sitting
    /// above the print. Small values are what sell it.
    var parallax: Double

    /// How hard the material comes up as the card turns off face-on.
    var bloom: Double

    /// Strength of the specular highlight that tracks the input directly.
    var glare: Double
}

/// One layer of a material.
///
/// Every field is exposed because materials differ almost entirely in these numbers
/// rather than in structure — one stacks plates at three scales, another fades a layer
/// *out* as a second fades in. Fixing any of them in the view would collapse five
/// materials into one with different colours.
struct HoloLayer: Sendable {
    var paint: Paint

    /// How much larger than the card this layer is drawn.
    ///
    /// Mismatched scales across layers are what give depth: a layer drawn at 4× and one
    /// at 2× move at visibly different apparent rates for the same offset.
    var scale: Double

    /// Travel per unit of tilt, as a multiplier on the sheet's own travel.
    ///
    /// **Negative runs it against the tilt**, which is how two layers of the same material
    /// come apart as the card turns. Two layers travelling together are just one thicker
    /// layer; the disagreement is the shimmer.
    var rate: Double

    var blend: BlendMode

    /// The crush. Contrast up, saturation shaped, is what turns a soft ramp into hard
    /// bands you can name. `brightness` is SwiftUI's *additive* shift, not CSS's
    /// multiplier — hence the small numbers.
    var brightness: Double = 0
    var contrast: Double = 1
    var saturation: Double = 1

    /// Opacity face-on.
    var base: Double

    /// Opacity **added** at full tilt. Negative fades the layer out as the card turns,
    /// which lets a material hand off between its layers instead of piling both on.
    var gain: Double

    /// What this layer actually paints. Everything is drawn — no image assets, no data
    /// URIs — so a material costs nothing but arithmetic and survives any resolution.
    enum Paint: Sendable {
        /// A repeating spectral ramp at an angle. The workhorse; most layers are this.
        case spectrum(angle: Double, cycles: Int, hues: [Color])
        /// The spectrum wrapped around a point instead of running across it, so tilting
        /// **spins** the colour rather than sliding it. Reads completely differently.
        ///
        /// `spin` scales — and can reverse — how fast it turns, which is the conic's
        /// equivalent of `rate`. Two conics turning against each other is the only way to
        /// get interference out of a shape that has no direction of travel.
        case conic(hues: [Color], spin: Double)
        /// Fine diffraction lines. Real foil is iridescent *because* it is physically
        /// ridged; without any structure the colour reads as a filter over the card
        /// rather than as light coming off a surface.
        case lines(angle: Double, pitch: Double)
        /// Scattered four-point sparkles. Drawn as two plates at slightly different
        /// scales — one plate is a static field, two beating against each other twinkle.
        case glitter(count: Int)
        /// A dense star field for the deep-space material.
        case stars(count: Int)
        /// Fine monochrome noise, so the flatter materials read as a printed surface
        /// rather than a clean gradient.
        case grain(count: Int)
    }
}

// MARK: - Palette

extension HoloMaterial {
    /// The six spectral hues the foil runs through. High value, high saturation: every
    /// layer's contrast crushes them hard, so starting from anything muted leaves nothing
    /// to crush.
    static let spectral: [Color] = [
        Color(hue: 0.006, saturation: 0.62, brightness: 1.00),
        Color(hue: 0.147, saturation: 0.60, brightness: 1.00),
        Color(hue: 0.258, saturation: 0.55, brightness: 0.98),
        Color(hue: 0.489, saturation: 0.48, brightness: 1.00),
        Color(hue: 0.633, saturation: 0.52, brightness: 1.00),
        Color(hue: 0.786, saturation: 0.55, brightness: 1.00),
    ]

    /// Cool spectrum for the ice-adjacent materials.
    static let glacial: [Color] = [
        Color(hue: 0.528, saturation: 0.42, brightness: 1.00),
        Color(hue: 0.583, saturation: 0.38, brightness: 1.00),
        Color(hue: 0.639, saturation: 0.36, brightness: 0.99),
        Color(hue: 0.694, saturation: 0.34, brightness: 1.00),
        Color(hue: 0.556, saturation: 0.40, brightness: 1.00),
        Color(hue: 0.486, saturation: 0.38, brightness: 1.00),
    ]

    /// Near-neutral, for the restrained material. The one that flatters the creature
    /// rather than competing with it.
    static let pearl: [Color] = [
        Color(hue: 0.083, saturation: 0.16, brightness: 0.98),
        Color(hue: 0.556, saturation: 0.13, brightness: 0.99),
        Color(hue: 0.722, saturation: 0.11, brightness: 0.98),
        Color(hue: 0.500, saturation: 0.11, brightness: 1.00),
        Color(hue: 0.111, saturation: 0.13, brightness: 0.99),
        Color(hue: 0.611, saturation: 0.11, brightness: 0.98),
    ]
}

// MARK: - The materials

extension HoloMaterial {
    /// **Pearl** — the restrained one. A fine near-neutral pitch that only barely shifts.
    /// Reach for it when the card has to be *read* rather than admired.
    static let pearl_: HoloMaterial = .init(
        id: "pearl", label: "pearl",
        layers: [
            // `overlay`, not `softLight`. At soft-light this material was invisible — a
            // common card looked like it had no finish at all, which is not "restrained",
            // it is broken. Understated still has to be *present*.
            HoloLayer(paint: .spectrum(angle: 94, cycles: 9, hues: pearl),
                      scale: 2.6, rate: 0.8, blend: .overlay,
                      brightness: 0.02, contrast: 1.8, saturation: 0.7,
                      base: 0.40, gain: 0.34),
            // A very fine ridge so even the plainest card has structure to catch on.
            HoloLayer(paint: .lines(angle: 88, pitch: 170),
                      scale: 1.5, rate: 0.9, blend: .overlay,
                      contrast: 1.2, base: 0.09, gain: 0.13),
            HoloLayer(paint: .grain(count: 900),
                      scale: 1.0, rate: 0.3, blend: .overlay,
                      contrast: 1.1, base: 0.10, gain: 0.14),
        ],
        parallax: 0.13, bloom: 0.32, glare: 0.34
    )

    /// **Holo** — the default, and the one most people picture. Three layers rather than
    /// one: a single desaturated sheet reads as a *sheen*, where a real holo has actual
    /// colour in it — bands you can name, moving against each other as the angle changes.
    static let holo: HoloMaterial = .init(
        id: "holo", label: "holo",
        layers: [
            // The main spectral sheet. Saturation stays up: on a pale print there is
            // nothing to overwhelm, and pulling it down leaves the card grey.
            HoloLayer(paint: .spectrum(angle: 10, cycles: 10, hues: spectral),
                      scale: 3.0, rate: 1.0, blend: .overlay,
                      brightness: 0.02, contrast: 1.8, saturation: 1.4,
                      base: 0.24, gain: 0.30),
            // A second sheet at a crossing angle, a coarser pitch, running BACKWARDS.
            // Where the two disagree they beat against each other, which is what produces
            // the shifting oily quality a single sheet cannot — one sheet only ever
            // slides; two interfere.
            //
            // `colorDodge` is the loudest blend in the set and the one that whited the
            // card out at the opacities this started on. It earns its place — nothing else
            // gives that sharp metallic catch — but it has to stay thin.
            HoloLayer(paint: .spectrum(angle: 104, cycles: 4, hues: spectral),
                      scale: 3.0, rate: -0.7, blend: .colorDodge,
                      brightness: -0.10, contrast: 1.8, saturation: 1.6,
                      base: 0.06, gain: 0.13),
            // Diffraction ridges — the structure that makes the colour read as light off
            // a surface rather than a filter over one. The pitch has to be FINE: at a
            // dozen bands across the card these read as stripes, not as a surface.
            HoloLayer(paint: .lines(angle: 96, pitch: 130),
                      scale: 1.6, rate: 1.8, blend: .overlay,
                      contrast: 1.3, base: 0.10, gain: 0.16),
        ],
        parallax: 0.26, bloom: 0.55, glare: 0.55
    )

    /// **Prism** — crossed ramps that cancel where they agree and light up where they
    /// disagree, so the crossings sparkle with no colour in the layer at all.
    static let prism: HoloMaterial = .init(
        id: "prism", label: "prism",
        layers: [
            // The pitch has to be FINE. At 46 bands the two crossed plates read as a
            // gingham picnic blanket — genuinely cute, entirely wrong. Past roughly 150
            // they stop resolving as individual lines and start interfering, which is the
            // shimmer this material is for.
            HoloLayer(paint: .lines(angle: 38, pitch: 190),
                      scale: 2.1, rate: 1.5, blend: .overlay,
                      brightness: -0.04, contrast: 1.9, saturation: 1.4,
                      base: 0.22, gain: 0.26),
            // `exclusion` INVERTS what is under it, and running it against the first ramp
            // is this material's whole character: where the two agree they cancel toward
            // black, where they disagree they light up, so the crossings sparkle with no
            // colour in either layer.
            // Deliberately NOT −38. Perfectly opposed angles cross into a square grid,
            // and a grid reads as woven fabric no matter how fine it gets. Off-square, the
            // two plates beat into moiré instead — which is the effect.
            HoloLayer(paint: .lines(angle: -57, pitch: 223),
                      scale: 1.9, rate: -1.2, blend: .exclusion,
                      brightness: -0.06, contrast: 1.8, saturation: 1.0,
                      base: 0.08, gain: 0.13),
            // Epic's colour. With both line plates now reading as interference rather
            // than as weave, this is what makes it an *epic* rather than a grey shimmer.
            HoloLayer(paint: .spectrum(angle: 55, cycles: 8, hues: spectral),
                      scale: 3.4, rate: -2.5, blend: .overlay,
                      brightness: -0.04, contrast: 1.9, saturation: 1.7,
                      base: 0.22, gain: 0.30),
        ],
        parallax: 0.24, bloom: 0.55, glare: 0.52
    )

    /// **Glitter** — almost no gradient at all. The material *is* the sparkle field, and
    /// the two plates at different scales are what make it twinkle rather than sit still.
    static let glitter: HoloMaterial = .init(
        id: "glitter", label: "glitter",
        layers: [
            HoloLayer(paint: .glitter(count: 46),
                      scale: 1.5, rate: 0.5, blend: .plusLighter,
                      brightness: 0.02, contrast: 1.4, saturation: 1.2,
                      base: 0.26, gain: 0.34),
            HoloLayer(paint: .glitter(count: 30),
                      scale: 2.2, rate: -0.9, blend: .plusLighter,
                      contrast: 1.3, base: 0.14, gain: 0.24),
            HoloLayer(paint: .spectrum(angle: 122, cycles: 4, hues: spectral),
                      scale: 3.2, rate: 1.4, blend: .overlay,
                      contrast: 1.7, saturation: 0.9,
                      base: 0.20, gain: 0.26),
        ],
        parallax: 0.30, bloom: 0.60, glare: 0.60
    )

    /// **Cosmos** — three star plates at different scales and rates over a wide spectrum.
    /// The rate spread is the whole effect: near stars sweep, far stars barely move, and
    /// the card gains real depth.
    static let cosmos: HoloMaterial = .init(
        id: "cosmos", label: "cosmos",
        layers: [
            HoloLayer(paint: .spectrum(angle: 82, cycles: 6, hues: spectral),
                      scale: 4.2, rate: 0.35, blend: .overlay,
                      brightness: -0.02, contrast: 1.6, saturation: 1.0,
                      base: 0.26, gain: 0.30),
            HoloLayer(paint: .stars(count: 110),
                      scale: 1.4, rate: 1.6, blend: .plusLighter,
                      brightness: 0.04, contrast: 1.5,
                      base: 0.30, gain: 0.34),
            HoloLayer(paint: .stars(count: 70),
                      scale: 2.6, rate: 2.6, blend: .plusLighter,
                      brightness: 0.02, contrast: 1.4,
                      base: 0.18, gain: 0.24),
        ],
        parallax: 0.34, bloom: 0.55, glare: 0.46
    )

    /// **Aurora** — a conic spectrum, so tilting spins the colour instead of sliding it,
    /// with glitter riding over the top. Kept for the rarest things in the app.
    static let aurora: HoloMaterial = .init(
        id: "aurora", label: "aurora",
        layers: [
            HoloLayer(paint: .conic(hues: spectral, spin: 1),
                      scale: 1.7, rate: 0, blend: .overlay,
                      brightness: -0.04, contrast: 1.6, saturation: 2.0,
                      base: 0.36, gain: 0.36),
            // A second conic turning BACKWARDS and off-pitch. Where the two disagree the
            // colour tears, which is what makes this read as an aurora rather than as a
            // colour wheel. Founding is the rarest thing in the app; it has to be
            // unmistakable from across a table.
            HoloLayer(paint: .conic(hues: glacial, spin: -0.55),
                      scale: 2.4, rate: 0, blend: .colorDodge,
                      brightness: -0.16, contrast: 1.7, saturation: 1.8,
                      base: 0.10, gain: 0.16),
            HoloLayer(paint: .glitter(count: 44),
                      scale: 1.8, rate: 0.7, blend: .plusLighter,
                      brightness: 0.02, contrast: 1.4,
                      base: 0.26, gain: 0.36),
        ],
        parallax: 0.22, bloom: 0.62, glare: 0.58
    )

    static let all: [HoloMaterial] = [pearl_, holo, prism, glitter, cosmos, aurora]

    /// Rarity picks the laminate. This is the entire reason the card system is worth
    /// building: rarity stops being a word in the corner and becomes something you can
    /// see from across a room, which is exactly how a real card does it.
    static func forRarity(_ r: Species.Rarity) -> HoloMaterial {
        switch r {
        case .common:    pearl_
        case .rare:      holo
        case .epic:      prism
        case .legendary: cosmos
        case .founding:  aurora
        }
    }

    /// The cosmetic ladder is shorter, so it maps onto the middle of the same set —
    /// a common cosmetic should not out-shine a legendary species.
    static func forRarity(_ r: Rarity) -> HoloMaterial {
        switch r {
        case .common: pearl_
        case .rare:   holo
        case .epic:   prism
        }
    }

    /// **The finish that cannot be bought.**
    ///
    /// Your own creature's card has no rarity — it is not a species you found, it is the
    /// one you made. So its laminate comes from `trust` instead, and that is the whole
    /// argument this app makes about money in one object: the best-looking card in here
    /// has no price on it.
    ///
    /// Trust is the right source and the only honest one. It rises *only* when you look
    /// after yourself (a check-in, the grow-by-living bonus) and never from petting the
    /// creature, it moves at most once a day so it cannot be crammed, and it decays when
    /// you stop showing up. That last part matters: the finish is a live reading of the
    /// relationship, not a trophy you keep after you have stopped.
    ///
    /// The five `TrustStage` cases already partition 0...1 into exactly five bands, so
    /// this reuses them rather than inventing a second set of thresholds that would
    /// immediately drift out of step with the label under the creature.
    static func forTrust(_ trust: Double) -> HoloMaterial {
        switch TrustStage.from(trust: trust) {
        case .stranger:  pearl_
        case .warming:   holo
        case .friend:    prism
        case .companion: cosmos
        case .devoted:   aurora
        }
    }
}

// MARK: - Shared maths

enum Holo {
    /// Maximum tilt at the card's edge, degrees.
    ///
    /// Small on purpose: past roughly 16° the perspective distortion starts to read as a
    /// fold rather than a tilt, and the card stops looking like a solid object.
    static let maxTilt: Double = 13

    /// Where the material aligns and goes brilliant.
    ///
    /// Real foil has one angle where the whole surface lines up, and hunting for it is
    /// most of why anyone keeps turning a card over. It sits off-centre deliberately —
    /// the middle is where the card rests, and a bloom you get for free is not worth
    /// finding. The falloff is tight so you sweep past it, notice, and come back.
    static let sweetSpot = CGPoint(x: -0.42, y: -0.36)
    static let sweetSpotRadius: Double = 0.34

    static func remap(_ v: Double, _ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
        c + (d - c) * (v - a) / (b - a)
    }

    static func clamp(_ v: Double, _ lo: Double = -1, _ hi: Double = 1) -> Double {
        min(max(v, lo), hi)
    }

    static func smoothstep(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }

    /// Distance from face-on, 0…1 — and the card's whole decoration budget.
    ///
    /// It is a *distance*, so it is symmetric: tilting left and tilting right give the
    /// same value and the decoration comes up the same way whichever way you move.
    /// Driving it from a signed axis instead lights one side and leaves the other dead.
    static func offAxis(_ p: CGPoint) -> Double {
        min(1, hypot(p.x, p.y))
    }

    /// How aligned the sheet is with the sweet spot, 0…1.
    static func spot(_ sheet: CGPoint) -> Double {
        let d = hypot(sheet.x - sweetSpot.x, sheet.y - sweetSpot.y)
        return smoothstep(max(0, 1 - d / sweetSpotRadius))
    }

    /// Deterministic [0,1) hash — the same SplitMix64 finaliser as `YolkMotion` and
    /// `RarityAura`, so a sparkle sits in the same place on every device and in every
    /// snapshot. Stateless randomness is the house pattern; a seeded RNG here would make
    /// the card un-reproducible in an `ImageRenderer` pass.
    static func hash01(_ i: Int, salt: UInt64) -> Double {
        var x = UInt64(bitPattern: Int64(i)) &+ (salt &* 0x9E37_79B9_7F4A_7C15)
        x ^= x >> 30; x = x &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 27; x = x &* 0x94D0_49BB_1331_11EB
        x ^= x >> 31
        return Double(x >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    /// A repeating spectral ramp expressed as gradient stops.
    ///
    /// SwiftUI has no repeating-linear-gradient, so the repeats are materialised: `cycles`
    /// copies of the hue list laid end to end, closing on the first hue so the ramp is
    /// seamless when it slides.
    static func stops(_ hues: [Color], cycles: Int) -> [Gradient.Stop] {
        let n = cycles * hues.count
        return (0...n).map { i in
            .init(color: hues[i % hues.count], location: Double(i) / Double(n))
        }
    }

    /// Angle in degrees → the start/end unit points of a `LinearGradient`.
    static func ends(_ degrees: Double) -> (UnitPoint, UnitPoint) {
        let r = degrees * .pi / 180
        let dx = cos(r) / 2, dy = sin(r) / 2
        return (UnitPoint(x: 0.5 - dx, y: 0.5 - dy), UnitPoint(x: 0.5 + dx, y: 0.5 + dy))
    }
}
