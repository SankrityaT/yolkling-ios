import SwiftUI

// The founding family (docs/species/founding.md): limited-edition, grant-only
// yolklings. A founding creature is a normal Vibe plus a `FoundingFlair` that adds
// reusable "magic" layers: an iridescent body, a soft aura, a halo, a gem crest,
// and twinkling shimmer. All pure SwiftUI shapes + gradients + blur. Grant rules
// (founder-code redeem + referral, both parties) live in docs/species/founding.md.

public enum HaloKind: Hashable, Sendable { case none, ring, thin, opal, double, dawn }
public enum ShimmerKind: Hashable, Sendable { case none, dust, crown, trail, cheeks, single }
public enum CrestKind: Hashable, Sendable { case none, star, teardrop, trio, dawnband, leaflet, feather }

/// The selected special parts a founding yolkling wears. Attaches to `Vibe`.
public struct FoundingFlair: Hashable, Sendable {
    public var bodyStops: [Color]        // 3-stop iridescent body gradient (light -> deep)
    public var aura: [Color]             // one glow colour, or two for an aurora wash
    public var auraScale: CGFloat = 1.15
    public var auraOpacity: Double = 0.32
    public var auraBlur: CGFloat = 0.12
    public var breathes: Bool = false
    public var halo: HaloKind = .none
    public var shimmer: ShimmerKind = .none
    public var crest: CrestKind = .none
    public var accent: Color
}

// MARK: - Aura + halo (drawn BEHIND the body)

public struct FoundingAura: View {
    public let flair: FoundingFlair
    public let size: CGFloat
    public let t: Double
    public var body: some View {
        let breath = flair.breathes ? (1 + 0.04 * sin(2 * .pi * 0.15 * t)) : 1
        ZStack {
            if flair.aura.count > 1 {
                Circle().fill(flair.aura[0].opacity(0.26)).frame(width: size * 1.20 * breath, height: size * 1.20 * breath).blur(radius: size * 0.14)
                Circle().fill(flair.aura[1].opacity(0.26)).frame(width: size * 1.10 * breath, height: size * 1.10 * breath).blur(radius: size * 0.14).offset(x: size * 0.05, y: -size * 0.04)
            } else if let c = flair.aura.first {
                Circle().fill(c.opacity(flair.auraOpacity)).frame(width: size * flair.auraScale * breath, height: size * flair.auraScale * breath).blur(radius: size * flair.auraBlur)
            }
        }
    }
}

public struct FoundingHalo: View {
    public let flair: FoundingFlair
    public let size: CGFloat
    public var body: some View {
        switch flair.halo {
        case .none:
            EmptyView()
        case .ring:
            Ellipse().stroke(Color(hex: 0xFFD98A), lineWidth: size * 0.018).frame(width: size * 0.62, height: size * 0.20)
                .rotationEffect(.degrees(-12)).offset(y: -size * 0.50).blur(radius: size * 0.004)
        case .thin:
            Ellipse().stroke(Color(hex: 0xFFF1CC), lineWidth: size * 0.012).frame(width: size * 0.58, height: size * 0.16)
                .rotationEffect(.degrees(-8)).offset(y: -size * 0.52)
        case .opal:
            Ellipse().stroke(AngularGradient(colors: [Color(hex: 0xFFD6E8), Color(hex: 0xD6F0FF), Color(hex: 0xE8FFD6), Color(hex: 0xFFE8C2), Color(hex: 0xFFD6E8)], center: .center), lineWidth: size * 0.018)
                .frame(width: size * 0.64, height: size * 0.22).rotationEffect(.degrees(-14)).offset(y: -size * 0.49)
        case .double:
            ZStack {
                Ellipse().stroke(Color(hex: 0xFFE3A8).opacity(0.5), lineWidth: size * 0.010).frame(width: size * 0.70, height: size * 0.24)
                Ellipse().stroke(Color(hex: 0xFFE3A8), lineWidth: size * 0.016).frame(width: size * 0.56, height: size * 0.18)
            }
            .rotationEffect(.degrees(-12)).offset(y: -size * 0.50)
        case .dawn:
            Ellipse().stroke(LinearGradient(colors: [Color(hex: 0xFFB7A0), Color(hex: 0xFFE6B0)], startPoint: .leading, endPoint: .trailing), lineWidth: size * 0.018)
                .frame(width: size * 0.62, height: size * 0.20).rotationEffect(.degrees(-10)).offset(y: -size * 0.50)
        }
    }
}

// MARK: - Gem crest (drawn in the topFeature slot, behind the head)

public struct FoundingCrest: View {
    public let flair: FoundingFlair
    public let size: CGFloat
    private var accent: Color { flair.accent }

    public var body: some View {
        switch flair.crest {
        case .none:
            EmptyView()
        case .teardrop:
            teardrop(scale: 1, x: 0, y: -0.56, rot: 0)
        case .trio:
            ZStack {
                teardrop(scale: 0.73, x: -0.12, y: -0.52, rot: -16)
                teardrop(scale: 1, x: 0, y: -0.58, rot: 0)
                teardrop(scale: 0.73, x: 0.12, y: -0.52, rot: 16)
            }
        case .dawnband:
            ZStack {
                Capsule().fill(LinearGradient(colors: [Color(hex: 0xFFCF8A), Color(hex: 0xFFE9C2)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: size * 0.30, height: size * 0.04).offset(y: -size * 0.50)
                Circle().fill(.white.opacity(0.8)).frame(width: size * 0.03, height: size * 0.03).offset(x: -size * 0.08, y: -size * 0.50)
                Circle().fill(.white.opacity(0.8)).frame(width: size * 0.03, height: size * 0.03).offset(y: -size * 0.50)
                Circle().fill(.white.opacity(0.8)).frame(width: size * 0.03, height: size * 0.03).offset(x: size * 0.08, y: -size * 0.50)
            }
        case .leaflet:
            ZStack {
                Capsule().fill(Color(hex: 0xE9C46A)).frame(width: size * 0.035, height: size * 0.16).offset(y: -size * 0.52)
                Ellipse().fill(LinearGradient(colors: [Color(hex: 0xFFE2A0), Color(hex: 0xE9C46A)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.13, height: size * 0.08).rotationEffect(.degrees(-28)).offset(x: size * 0.06, y: -size * 0.58)
                Ellipse().fill(LinearGradient(colors: [Color(hex: 0xFFE2A0), Color(hex: 0xE9C46A)], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.11, height: size * 0.07).rotationEffect(.degrees(30)).offset(x: -size * 0.05, y: -size * 0.56)
                Circle().fill(.white.opacity(0.85)).frame(width: size * 0.03, height: size * 0.03).offset(x: size * 0.10, y: -size * 0.62)
            }
        case .feather:
            ZStack {
                Capsule().fill(Color(hex: 0xE9C46A)).frame(width: size * 0.035, height: size * 0.22).rotationEffect(.degrees(-12)).offset(y: -size * 0.58)
                Ellipse().fill(LinearGradient(colors: flair.bodyStops, startPoint: .top, endPoint: .bottom)).frame(width: size * 0.10, height: size * 0.20).rotationEffect(.degrees(-12)).offset(x: size * 0.01, y: -size * 0.60)
            }
        case .star:
            ZStack {
                Circle().fill(Color(hex: 0xFFD98A).opacity(0.4)).frame(width: size * 0.20, height: size * 0.20).blur(radius: size * 0.04).offset(y: -size * 0.56)
                Capsule().fill(Color(hex: 0xFFE6A8)).frame(width: size * 0.04, height: size * 0.16).offset(y: -size * 0.56)
                Capsule().fill(Color(hex: 0xFFE6A8)).frame(width: size * 0.035, height: size * 0.12).rotationEffect(.degrees(90)).offset(y: -size * 0.56)
                Circle().fill(Color(hex: 0xFFE6A8)).frame(width: size * 0.05, height: size * 0.05).offset(y: -size * 0.56)
            }
        }
    }

    private func teardrop(scale: CGFloat, x: CGFloat, y: CGFloat, rot: Double) -> some View {
        ZStack {
            Circle().fill(Color(hex: 0xFFD98A).opacity(0.3)).frame(width: size * 0.16 * scale, height: size * 0.16 * scale).blur(radius: size * 0.03)
            Ellipse().fill(LinearGradient(colors: [accent.opacity(0.85), accent], startPoint: .top, endPoint: .bottom)).frame(width: size * 0.10 * scale, height: size * 0.14 * scale)
            Circle().fill(.white.opacity(0.8)).frame(width: size * 0.025 * scale, height: size * 0.025 * scale).offset(x: -size * 0.02 * scale, y: -size * 0.03 * scale)
        }
        .rotationEffect(.degrees(rot)).offset(x: size * x, y: size * y)
    }
}

// MARK: - Shimmer (twinkling dots, drawn IN FRONT)

public struct FoundingShimmer: View {
    public let flair: FoundingFlair
    public let size: CGFloat
    public let t: Double

    private struct Dot { let x, y, r: CGFloat; let phase, speed: Double; let tinted: Bool }

    public var body: some View {
        ZStack {
            ForEach(0..<dots.count, id: \.self) { i in
                let d = dots[i]
                Circle().fill(d.tinted ? flair.accent : .white)
                    .frame(width: size * d.r, height: size * d.r)
                    .opacity(0.25 + 0.6 * abs(sin(t * d.speed + d.phase)))
                    .blur(radius: size * 0.004)
                    .offset(x: size * d.x, y: size * d.y)
            }
        }
    }

    private var dots: [Dot] {
        switch flair.shimmer {
        case .none: []
        case .dust: [Dot(x: 0.30, y: -0.30, r: 0.030, phase: 0.0, speed: 1.8, tinted: false),
                     Dot(x: -0.34, y: -0.10, r: 0.022, phase: 0.7, speed: 1.8, tinted: false),
                     Dot(x: 0.18, y: 0.22, r: 0.018, phase: 1.4, speed: 1.8, tinted: false),
                     Dot(x: -0.20, y: 0.30, r: 0.024, phase: 2.1, speed: 1.8, tinted: false)]
        case .crown: [Dot(x: -0.16, y: -0.52, r: 0.028, phase: 0.0, speed: 1.8, tinted: true),
                      Dot(x: 0.0, y: -0.58, r: 0.034, phase: 0.6, speed: 1.8, tinted: true),
                      Dot(x: 0.16, y: -0.52, r: 0.028, phase: 1.2, speed: 1.8, tinted: true)]
        case .trail: [Dot(x: 0.38, y: -0.02, r: 0.026, phase: 0.0, speed: 1.8, tinted: true),
                      Dot(x: 0.30, y: 0.14, r: 0.020, phase: 0.5, speed: 1.8, tinted: true),
                      Dot(x: 0.40, y: 0.26, r: 0.016, phase: 1.0, speed: 1.8, tinted: true)]
        case .cheeks: [Dot(x: -0.30, y: 0.08, r: 0.020, phase: 0.0, speed: 1.8, tinted: false),
                       Dot(x: 0.30, y: 0.08, r: 0.020, phase: 0.9, speed: 1.8, tinted: false)]
        case .single: [Dot(x: 0.22, y: -0.40, r: 0.040, phase: 0.0, speed: 1.0, tinted: false)]
        }
    }
}

// MARK: - The 16 founding species

extension SpeciesCatalog {
    public static let founding: [Species] = [
        f("the very first", (0xFFF3D2, 0xFFDE8E, 0xF6C24B), 0xD99E2C, 0xFFE6A8, .star, [0xFFD98A], breathes: true, halo: .double, shimmer: .crown,
          "the single rarest founding yolkling, the founder's own"),
        f("the og", (0xFFF3D2, 0xFFDE8E, 0xF6C24B), 0xD99E2C, 0xFFD98A, .dawnband, [0xFFD98A], shimmer: .dust,
          "the original gold, the one everyone wishes they had"),
        f("first light", (0xFFF6E6, 0xFFD9A8, 0xFFB48A), 0xE89370, 0xFFE6B0, .none, [0xFFD3B0], halo: .dawn, shimmer: .crown,
          "the first sunrise after a long wait"),
        f("daybreak no. 001", (0xFFF6E6, 0xFFD9A8, 0xFFB48A), 0xE89370, 0xFFD3B0, .dawnband, [0xFFD3B0], shimmer: .cheeks,
          "numbered like a limited print, issued not bought"),
        f("goldenhour", (0xFFF3D2, 0xFFDE8E, 0xF6C24B), 0xD99E2C, 0xFFDE8E, .leaflet, [0xFFD98A], breathes: true, shimmer: .trail,
          "bathed in late-afternoon gold, catching the last light"),
        f("pearl", (0xFFFBF4, 0xFCE9D8, 0xEFD3C2), 0xD8B79C, 0xFFF4E8, .teardrop, [0xFFF4E8], shimmer: .cheeks,
          "a single warm pearl, the quietest founder"),
        f("moonstone", (0xF4F8FF, 0xD8E4F7, 0xBFD0EE), 0x93A7CE, 0xCBD8F2, .teardrop, [0xCBD8F2], halo: .thin, shimmer: .single,
          "cool blue sheen under one slow twinkle"),
        f("rose quartz", (0xFFF0F4, 0xFFD3E0, 0xF3B9CF), 0xDC93B2, 0xFFC2D6, .trio, [0xFFC2D6], shimmer: .cheeks,
          "three blush gems in a gentle arc, tender and soft"),
        f("opaline", (0xFFF3F8, 0xCFE9FF, 0xE6D2FF), 0xB9A6E0, 0xE6D2FF, .teardrop, [0xFFF4E8], halo: .opal, shimmer: .dust,
          "white opal with hidden blue-violet fire"),
        f("aurora", (0xEAFBF0, 0xC9F0E0, 0xCBB9F0), 0x9B86D6, 0xC9B8F0, .none, [0xA8E6CF, 0xC9B8F0], shimmer: .dust,
          "a whole sky of mint-to-lilac aurora"),
        f("dusklight", (0xFBEFFA, 0xE3C9F0, 0xC7A8E8), 0xA083C9, 0xD9C7F0, .feather, [0xD9C7F0], shimmer: .trail,
          "a lilac plume at dusk, one iridescent feather"),
        f("seafoam", (0xEAFBF0, 0xC9F0E0, 0xCBB9F0), 0x9B86D6, 0xBFEBD6, .leaflet, [0xBFEBD6], shimmer: .dust,
          "sea-glass green with a gilded sprout, cozy coastal calm"),
        f("honeyfeather", (0xFFF3D2, 0xFFDE8E, 0xF6C24B), 0xD99E2C, 0xFFE2A0, .feather, [0xFFD98A], shimmer: .crown,
          "a golden iridescent plume, soft and a little proud"),
        f("haloglow", (0xFFFBF4, 0xFCE9D8, 0xEFD3C2), 0xD8B79C, 0xFFD98A, .none, [0xFFD98A], breathes: true, halo: .ring, shimmer: .dust,
          "the purest angel founder, a pearl under a tilted gold ring"),
        f("starling no. 002", (0xF4F8FF, 0xD8E4F7, 0xBFD0EE), 0x93A7CE, 0xFFE6A8, .star, [0xCBD8F2], shimmer: .crown,
          "the second to carry the founder's star, on cool moonstone"),
        f("warmwelcome", (0xFFF6E6, 0xFFD9A8, 0xFFB48A), 0xE89370, 0xFFCF8A, .dawnband, [0xFFD3B0], halo: .dawn, shimmer: .cheeks,
          "granted to a friend you brought in, made to say you belong here"),
    ]

    private static func f(_ name: String, _ iri: (UInt, UInt, UInt), _ deep: UInt, _ accent: UInt,
                          _ crest: CrestKind, _ aura: [UInt], breathes: Bool = false,
                          halo: HaloKind = .none, shimmer: ShimmerKind = .none, _ why: String) -> Species {
        let flair = FoundingFlair(
            bodyStops: [Color(hex: iri.0), Color(hex: iri.1), Color(hex: iri.2)],
            aura: aura.map { Color(hex: $0) }, breathes: breathes, halo: halo, shimmer: shimmer, crest: crest, accent: Color(hex: accent))
        return Species(id: "founding-" + name, name: name, family: "founding", rarity: .founding,
                       bodyHex: iri.0, deepHex: deep, accentHex: accent, style: .classic, pattern: .none, personality: why, flair: flair)
    }
}
