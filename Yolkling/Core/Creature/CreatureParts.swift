import SwiftUI

/// A faint warm outline so cream and white parts read against the cream app
/// background (#FBF6EC) instead of vanishing into it.
private let creamOutline = Color(hex: 0xE7D6BC)

/// A knit stitch chevron (a soft V) for the `knitVStitches` pattern.
struct ChevronShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        return p
    }
}

/// An S-curve for the `swirlMarbling` pattern, upper-left to lower-right.
struct MarbleSwirl: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.15, y: r.minY + r.height * 0.3))
        p.addCurve(to: CGPoint(x: r.maxX - r.width * 0.15, y: r.maxY - r.height * 0.3),
                   control1: CGPoint(x: r.midX, y: r.minY),
                   control2: CGPoint(x: r.midX, y: r.maxY))
        return p
    }
}

// Identity parts for a yolkling, all drawn in pure SwiftUI vector shapes. A species
// is a palette (body/deep/accent) + a TOP FEATURE (above the head) + a BODY PATTERN
// (on the belly). Specs live in docs/species/*.md; the boldness here is tuned so
// each feature reads as a distinct silhouette at creature scale (see the proof pass).

/// A 5-point star, outer radius 0.5, inner 0.20 of the frame.
struct StarShape: Shape {
    var points: Int = 5
    var innerRatio: CGFloat = 0.4
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var p = Path()
        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? outer : inner
            let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / CGFloat(points)
            let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// A soft, rounded triangle for fins, crests and shell points. Points up, corners
/// pulled in so nothing reads as sharp.
struct SoftFin: Shape {
    var round: CGFloat = 0.22
    func path(in r: CGRect) -> Path {
        var p = Path()
        let apex = CGPoint(x: r.midX, y: r.minY + r.height * round)
        let bl = CGPoint(x: r.minX + r.width * round, y: r.maxY)
        let br = CGPoint(x: r.maxX - r.width * round, y: r.maxY)
        p.move(to: bl)
        p.addQuadCurve(to: apex, control: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: br, control: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: bl, control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.18))
        p.closeSubpath()
        return p
    }
}

/// The climbing stem for the `vineTrail` pattern, drawn relative to body centre.
struct VinePath: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.move(to: CGPoint(x: c.x + rect.width * 0.18, y: c.y + rect.height * 0.32))
        p.addQuadCurve(to: CGPoint(x: c.x + rect.width * 0.06, y: c.y - rect.height * 0.02),
                       control: CGPoint(x: c.x + rect.width * 0.26, y: c.y + rect.height * 0.14))
        return p
    }
}

/// A single curl of hair for the `tuft` look.
struct TuftShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.minY + rect.height * 0.2),
                       control: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.5),
                       control: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

// MARK: - Top feature (the look above the head)

/// Drawn behind the body so it peeks over the head, exactly like the original
/// ears/sprout/tuft. Pass the species palette; `accent` already resolves to `deep`
/// when a species has no accent (see `Vibe.accentColor`).
struct TopFeatureView: View {
    let style: CreatureStyle
    let bodyColor: Color
    let deep: Color
    let accent: Color
    let size: CGFloat

    var body: some View {
        switch style {
        case .classic:
            EmptyView()
        case .ears:
            ZStack { ear(-1); ear(1) }
        case .sprout:
            sprout
        case .tuft:
            TuftShape().stroke(deep, style: .init(lineWidth: size * 0.03, lineCap: .round))
                .frame(width: size * 0.18, height: size * 0.16).offset(y: -size * 0.5)
        case .starAntenna:
            ZStack {
                Capsule().fill(deep).frame(width: size * 0.03, height: size * 0.18).offset(y: -size * 0.52)
                StarShape().fill(accent).frame(width: size * 0.20, height: size * 0.20).offset(y: -size * 0.66)
                    .shadow(color: deep.opacity(0.25), radius: 1, y: 1)
                Circle().fill(.white.opacity(0.7)).frame(width: size * 0.05, height: size * 0.05)
                    .offset(x: -size * 0.04, y: -size * 0.70)
            }
        case .twinAntennae:
            ForEach([-1.0, 1.0], id: \.self) { side in
                ZStack {
                    Capsule().fill(deep).frame(width: size * 0.022, height: size * 0.16)
                        .rotationEffect(.degrees(side * 16)).offset(x: side * size * 0.12, y: -size * 0.52)
                    StarShape().fill(accent).frame(width: size * 0.13, height: size * 0.13)
                        .rotationEffect(.degrees(side * 12)).offset(x: side * size * 0.19, y: -size * 0.64)
                }
            }
        case .crescentTuft:
            ZStack {
                ZStack {
                    Circle().fill(accent).frame(width: size * 0.30, height: size * 0.30)
                    Circle().fill(.black).frame(width: size * 0.25, height: size * 0.25)
                        .offset(x: size * 0.08, y: -size * 0.03).blendMode(.destinationOut)
                }
                .compositingGroup()
                .rotationEffect(.degrees(-22)).offset(y: -size * 0.54)
                StarShape().fill(accent).frame(width: size * 0.07, height: size * 0.07).offset(x: -size * 0.16, y: -size * 0.44)
            }
        case .ringHalo:
            ZStack {
                Ellipse().stroke(accent, lineWidth: size * 0.045).frame(width: size * 0.7, height: size * 0.24)
                    .rotationEffect(.degrees(-18)).offset(y: -size * 0.44)
                Ellipse().stroke(deep.opacity(0.4), lineWidth: size * 0.018).frame(width: size * 0.56, height: size * 0.18)
                    .rotationEffect(.degrees(-18)).offset(y: -size * 0.44)
            }
        case .sunRays:
            ForEach(0..<11, id: \.self) { i in
                let deg = -75.0 + Double(i) * 15.0
                let rad = deg * .pi / 180
                Capsule().fill(accent).frame(width: size * 0.024, height: size * 0.16)
                    .rotationEffect(.degrees(deg))
                    .offset(x: CGFloat(sin(rad)) * size * 0.52, y: -CGFloat(cos(rad)) * size * 0.52)
            }
        case .comet:
            ZStack {
                Capsule().fill(LinearGradient(colors: [accent, accent.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.07, height: size * 0.28)
                    .rotationEffect(.degrees(52)).offset(x: size * 0.02, y: -size * 0.48)
                Circle().fill(accent).frame(width: size * 0.14, height: size * 0.14).offset(x: size * 0.18, y: -size * 0.56)
                Circle().fill(.white.opacity(0.85)).frame(width: size * 0.04, height: size * 0.04).offset(x: -size * 0.08, y: -size * 0.42)
                Circle().fill(.white.opacity(0.7)).frame(width: size * 0.03, height: size * 0.03).offset(x: -size * 0.14, y: -size * 0.38)
            }
        case .aurora:
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule().fill(LinearGradient(colors: [accent.opacity(0), accent.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.09, height: size * 0.32).blur(radius: size * 0.02)
                    .rotationEffect(.degrees(side * 12)).offset(x: side * size * 0.13, y: -size * 0.52)
            }
        case .constellation:
            ZStack {
                StarShape().fill(accent).frame(width: size * 0.11, height: size * 0.11).offset(x: -size * 0.18, y: -size * 0.50)
                StarShape().fill(accent).frame(width: size * 0.08, height: size * 0.08).offset(y: -size * 0.60)
                StarShape().fill(accent).frame(width: size * 0.11, height: size * 0.11).offset(x: size * 0.18, y: -size * 0.50)
            }
        case .nebula:
            ZStack {
                Ellipse().fill(accent.opacity(0.6)).frame(width: size * 0.34, height: size * 0.22).blur(radius: size * 0.025)
                    .offset(x: -size * 0.05, y: -size * 0.52)
                Ellipse().fill(deep.opacity(0.5)).frame(width: size * 0.26, height: size * 0.17).blur(radius: size * 0.025)
                    .offset(x: size * 0.07, y: -size * 0.48)
                StarShape().fill(.white.opacity(0.9)).frame(width: size * 0.11, height: size * 0.11).offset(x: size * 0.02, y: -size * 0.52)
            }
        case .orbitDot:
            ZStack {
                Ellipse().stroke(deep.opacity(0.6), lineWidth: size * 0.02).frame(width: size * 0.6, height: size * 0.2)
                    .rotationEffect(.degrees(20)).offset(y: -size * 0.46)
                Circle().fill(accent).frame(width: size * 0.09, height: size * 0.09).offset(x: size * 0.27, y: -size * 0.42)
            }
        case .tulipBud:
            ZStack {
                Capsule().fill(Color(hex: 0x77C47E)).frame(width: size * 0.035, height: size * 0.17).offset(y: -size * 0.50)
                Ellipse().fill(Color(hex: 0x86D38C)).frame(width: size * 0.11, height: size * 0.06).rotationEffect(.degrees(30)).offset(x: -size * 0.05, y: -size * 0.47)
                Ellipse().fill(Color(hex: 0x86D38C)).frame(width: size * 0.11, height: size * 0.06).rotationEffect(.degrees(-28)).offset(x: size * 0.06, y: -size * 0.48)
                Ellipse().fill(accent).frame(width: size * 0.16, height: size * 0.20).offset(y: -size * 0.58)
                Ellipse().fill(.white.opacity(0.4)).frame(width: size * 0.10, height: size * 0.18).offset(y: -size * 0.585)
            }
        case .daisyCrown:
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Ellipse().fill(.white).overlay(Ellipse().stroke(Color(hex: 0xE3D3BE), lineWidth: size * 0.005))
                        .frame(width: size * 0.09, height: size * 0.15)
                        .offset(y: -size * 0.085).rotationEffect(.degrees(Double(i) * 72))
                }
                Circle().fill(Color(hex: 0xF7C94B)).frame(width: size * 0.10, height: size * 0.10)
            }
            .offset(y: -size * 0.50)
        case .singlePetalFlower:
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    Ellipse().fill(accent).overlay(Ellipse().stroke(Color(hex: 0xE3D3BE).opacity(0.7), lineWidth: size * 0.005))
                        .frame(width: size * 0.10, height: size * 0.13)
                        .offset(y: -size * 0.07).rotationEffect(.degrees(Double(i) * 90 + 45))
                }
                Circle().fill(Color(hex: 0xFBF1E2)).frame(width: size * 0.09, height: size * 0.09)
            }
            .offset(y: -size * 0.50)
        case .mushroomCap:
            ZStack {
                Capsule().fill(Color(hex: 0xFBF1E2)).frame(width: size * 0.34, height: size * 0.05).offset(y: -size * 0.37)
                Ellipse().fill(accent).frame(width: size * 0.40, height: size * 0.24).offset(y: -size * 0.46)
                Circle().fill(Color(hex: 0xFBF1E2)).frame(width: size * 0.06, height: size * 0.06).offset(x: -size * 0.09, y: -size * 0.49)
                Circle().fill(Color(hex: 0xFBF1E2)).frame(width: size * 0.06, height: size * 0.06).offset(x: size * 0.07, y: -size * 0.46)
                Circle().fill(Color(hex: 0xFBF1E2)).frame(width: size * 0.05, height: size * 0.05).offset(x: -size * 0.01, y: -size * 0.42)
            }
        case .cloverTop:
            ZStack {
                Capsule().fill(Color(hex: 0x5FA86B)).frame(width: size * 0.03, height: size * 0.10).offset(y: -size * 0.42)
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle().fill(Color(hex: 0x7FC98A)).frame(width: size * 0.11, height: size * 0.11)
                            .offset(y: -size * 0.07).rotationEffect(.degrees(Double(i) * 120))
                    }
                }
                .offset(y: -size * 0.50)
            }
        case .antennae:
            ZStack {
                Capsule().fill(deep).frame(width: size * 0.02, height: size * 0.14).rotationEffect(.degrees(-18)).offset(x: -size * 0.10, y: -size * 0.50)
                Capsule().fill(deep).frame(width: size * 0.02, height: size * 0.14).rotationEffect(.degrees(18)).offset(x: size * 0.10, y: -size * 0.50)
                Circle().fill(accent).frame(width: size * 0.06, height: size * 0.06).offset(x: -size * 0.15, y: -size * 0.57)
                Circle().fill(accent).frame(width: size * 0.06, height: size * 0.06).offset(x: size * 0.15, y: -size * 0.57)
            }
        case .beeAntennae:
            ZStack {
                Capsule().fill(Color(hex: 0x5A4632)).frame(width: size * 0.02, height: size * 0.13).rotationEffect(.degrees(-16)).offset(x: -size * 0.09, y: -size * 0.50)
                Capsule().fill(Color(hex: 0x5A4632)).frame(width: size * 0.02, height: size * 0.13).rotationEffect(.degrees(16)).offset(x: size * 0.09, y: -size * 0.50)
                Circle().fill(Color(hex: 0xF7C94B)).frame(width: size * 0.055, height: size * 0.055).offset(x: -size * 0.14, y: -size * 0.56)
                Circle().fill(Color(hex: 0xF7C94B)).frame(width: size * 0.055, height: size * 0.055).offset(x: size * 0.14, y: -size * 0.56)
            }
        case .berryCluster:
            ZStack {
                Ellipse().fill(Color(hex: 0x7FC98A)).frame(width: size * 0.12, height: size * 0.06).rotationEffect(.degrees(-30)).offset(x: size * 0.10, y: -size * 0.57)
                Circle().fill(accent).frame(width: size * 0.10, height: size * 0.10).offset(x: -size * 0.08, y: -size * 0.50)
                Circle().fill(accent).frame(width: size * 0.10, height: size * 0.10).offset(x: size * 0.08, y: -size * 0.50)
                Circle().fill(accent).frame(width: size * 0.10, height: size * 0.10).offset(y: -size * 0.43)
                Circle().fill(.white.opacity(0.5)).frame(width: size * 0.025, height: size * 0.025).offset(x: -size * 0.10, y: -size * 0.53)
            }
        case .leafPair:
            ZStack {
                Ellipse().fill(Color(hex: 0x86D38C)).frame(width: size * 0.10, height: size * 0.22).rotationEffect(.degrees(-18)).offset(x: -size * 0.05, y: -size * 0.52)
                Ellipse().fill(Color(hex: 0x77C47E)).frame(width: size * 0.10, height: size * 0.22).rotationEffect(.degrees(18)).offset(x: size * 0.05, y: -size * 0.52)
                Capsule().fill(Color(hex: 0x5FA86B)).frame(width: size * 0.012, height: size * 0.12).offset(y: -size * 0.50)
            }
        case .bellFlower:
            ZStack {
                Capsule().fill(Color(hex: 0x6FB07A)).frame(width: size * 0.025, height: size * 0.15).offset(x: size * 0.02, y: -size * 0.50)
                Ellipse().fill(accent).frame(width: size * 0.15, height: size * 0.18).rotationEffect(.degrees(12)).offset(x: size * 0.04, y: -size * 0.58)
                Circle().fill(Color(hex: 0xB9CCF0)).frame(width: size * 0.04, height: size * 0.04).offset(x: -size * 0.01, y: -size * 0.51)
                Circle().fill(Color(hex: 0xB9CCF0)).frame(width: size * 0.04, height: size * 0.04).offset(x: size * 0.04, y: -size * 0.51)
                Circle().fill(Color(hex: 0xB9CCF0)).frame(width: size * 0.04, height: size * 0.04).offset(x: size * 0.08, y: -size * 0.51)
            }
        case .sproutTrio:
            ZStack {
                Capsule().fill(Color(hex: 0x77C47E)).frame(width: size * 0.035, height: size * 0.18).offset(y: -size * 0.52)
                Ellipse().fill(Color(hex: 0x86D38C)).frame(width: size * 0.12, height: size * 0.07).rotationEffect(.degrees(34)).offset(x: -size * 0.06, y: -size * 0.55)
                Ellipse().fill(Color(hex: 0x86D38C)).frame(width: size * 0.11, height: size * 0.07).rotationEffect(.degrees(-30)).offset(x: size * 0.06, y: -size * 0.57)
                Ellipse().fill(Color(hex: 0x9BE0A0)).frame(width: size * 0.08, height: size * 0.06).offset(y: -size * 0.61)
            }
        case .acornCap:
            ZStack {
                Ellipse().fill(accent).frame(width: size * 0.18, height: size * 0.20).offset(y: -size * 0.46)
                Ellipse().fill(Color(hex: 0x8A6240)).frame(width: size * 0.20, height: size * 0.11).offset(y: -size * 0.53)
                Capsule().fill(Color(hex: 0x6E4D2F)).frame(width: size * 0.02, height: size * 0.06).offset(y: -size * 0.58)
            }
        case .dorsalFin:
            ZStack {
                SoftFin(round: 0.22).fill(deep).frame(width: size * 0.18, height: size * 0.22).offset(y: -size * 0.5)
                Capsule().fill(bodyColor.opacity(0.45)).frame(width: size * 0.02, height: size * 0.13).rotationEffect(.degrees(-6)).offset(y: -size * 0.5)
            }
        case .seashell:
            ZStack {
                Ellipse().fill(bodyColor).frame(width: size * 0.30, height: size * 0.20).offset(y: -size * 0.47)
                Capsule().fill(deep.opacity(0.35)).frame(width: size * 0.022, height: size * 0.16).rotationEffect(.degrees(-22), anchor: .bottom).offset(y: -size * 0.47)
                Capsule().fill(deep.opacity(0.35)).frame(width: size * 0.022, height: size * 0.16).offset(y: -size * 0.47)
                Capsule().fill(deep.opacity(0.35)).frame(width: size * 0.022, height: size * 0.16).rotationEffect(.degrees(22), anchor: .bottom).offset(y: -size * 0.47)
                Circle().fill(deep).frame(width: size * 0.06, height: size * 0.06).offset(y: -size * 0.39)
            }
        case .bubbleCluster:
            ZStack {
                bubble(size * 0.12, x: -0.05, y: -0.46, op: 0.85)
                bubble(size * 0.085, x: 0.07, y: -0.54, op: 0.8)
                bubble(size * 0.055, x: -0.02, y: -0.6, op: 0.75)
            }
        case .coralSprig:
            ZStack {
                Capsule().fill(Color(hex: 0xF2A6A0)).frame(width: size * 0.035, height: size * 0.16).offset(y: -size * 0.52)
                Capsule().fill(Color(hex: 0xF2A6A0)).frame(width: size * 0.03, height: size * 0.10).rotationEffect(.degrees(-38)).offset(x: -size * 0.05, y: -size * 0.56)
                Capsule().fill(Color(hex: 0xF7B8B0)).frame(width: size * 0.03, height: size * 0.09).rotationEffect(.degrees(34)).offset(x: size * 0.05, y: -size * 0.55)
                Circle().fill(Color(hex: 0xF7C2BB)).frame(width: size * 0.04, height: size * 0.04).offset(y: -size * 0.60)
                Circle().fill(Color(hex: 0xF7C2BB)).frame(width: size * 0.04, height: size * 0.04).offset(x: -size * 0.09, y: -size * 0.61)
                Circle().fill(Color(hex: 0xF7C2BB)).frame(width: size * 0.04, height: size * 0.04).offset(x: size * 0.09, y: -size * 0.59)
            }
        case .waveCrest:
            ZStack {
                TuftShape().stroke(Color(hex: 0x86C7E0), style: .init(lineWidth: size * 0.05, lineCap: .round))
                    .frame(width: size * 0.26, height: size * 0.14).offset(y: -size * 0.49)
                Circle().fill(.white.opacity(0.9)).frame(width: size * 0.05, height: size * 0.05).offset(x: -size * 0.09, y: -size * 0.52)
                Circle().fill(.white.opacity(0.9)).frame(width: size * 0.035, height: size * 0.035).offset(x: -size * 0.12, y: -size * 0.49)
            }
        case .jellyTendrils:
            ZStack {
                Ellipse().fill(Color(hex: 0xD7C2EC).opacity(0.85)).frame(width: size * 0.26, height: size * 0.18).offset(y: -size * 0.5)
                Circle().fill(Color(hex: 0xD7C2EC)).frame(width: size * 0.05, height: size * 0.05).offset(x: -size * 0.07, y: -size * 0.43)
                Circle().fill(Color(hex: 0xD7C2EC)).frame(width: size * 0.05, height: size * 0.05).offset(y: -size * 0.43)
                Circle().fill(Color(hex: 0xD7C2EC)).frame(width: size * 0.05, height: size * 0.05).offset(x: size * 0.07, y: -size * 0.43)
                Capsule().fill(Color(hex: 0xE3D6F2).opacity(0.8)).frame(width: size * 0.018, height: size * 0.12).rotationEffect(.degrees(-8)).offset(x: -size * 0.06, y: -size * 0.36)
                Capsule().fill(Color(hex: 0xE3D6F2).opacity(0.8)).frame(width: size * 0.018, height: size * 0.12).rotationEffect(.degrees(2)).offset(y: -size * 0.36)
                Capsule().fill(Color(hex: 0xE3D6F2).opacity(0.8)).frame(width: size * 0.018, height: size * 0.12).rotationEffect(.degrees(9)).offset(x: size * 0.06, y: -size * 0.36)
            }
        case .starfishCrown:
            ZStack {
                StarShape(innerRatio: 0.5).fill(Color(hex: 0xF6B27A)).frame(width: size * 0.24, height: size * 0.24).offset(y: -size * 0.5)
                Circle().fill(Color(hex: 0xE89A5E)).frame(width: size * 0.02, height: size * 0.02).offset(x: -size * 0.02, y: -size * 0.5)
                Circle().fill(Color(hex: 0xE89A5E)).frame(width: size * 0.02, height: size * 0.02).offset(x: size * 0.03, y: -size * 0.49)
                Circle().fill(Color(hex: 0xE89A5E)).frame(width: size * 0.02, height: size * 0.02).offset(y: -size * 0.46)
            }
        case .pearlTiara:
            ZStack {
                pearl(size * 0.04, x: -0.12, y: -0.42)
                pearl(size * 0.05, x: -0.06, y: -0.46)
                pearl(size * 0.06, x: 0.0, y: -0.48)
                pearl(size * 0.05, x: 0.06, y: -0.46)
                pearl(size * 0.04, x: 0.12, y: -0.42)
            }
        case .anglerLantern:
            ZStack {
                Capsule().fill(deep).frame(width: size * 0.022, height: size * 0.18).rotationEffect(.degrees(-12)).offset(x: -size * 0.02, y: -size * 0.5)
                Circle().fill(Color(hex: 0xFFE08A).opacity(0.35)).frame(width: size * 0.2, height: size * 0.2).blur(radius: size * 0.03).offset(x: -size * 0.08, y: -size * 0.6)
                Circle().fill(RadialGradient(colors: [Color(hex: 0xFFF6C9), Color(hex: 0xFFE08A)], center: .center, startRadius: 0, endRadius: size * 0.07))
                    .frame(width: size * 0.12, height: size * 0.12).offset(x: -size * 0.08, y: -size * 0.6)
            }
        case .finFan:
            ZStack {
                SoftFin(round: 0.3).fill(bodyColor).frame(width: size * 0.34, height: size * 0.14).offset(y: -size * 0.44)
                Capsule().fill(deep.opacity(0.3)).frame(width: size * 0.016, height: size * 0.1).rotationEffect(.degrees(-16), anchor: .bottom).offset(y: -size * 0.44)
                Capsule().fill(deep.opacity(0.3)).frame(width: size * 0.016, height: size * 0.1).offset(y: -size * 0.44)
                Capsule().fill(deep.opacity(0.3)).frame(width: size * 0.016, height: size * 0.1).rotationEffect(.degrees(16), anchor: .bottom).offset(y: -size * 0.44)
            }
        case .creamSwirl:
            ZStack {
                Ellipse().fill(Color(hex: 0xFFF6E8)).overlay(Ellipse().stroke(creamOutline, lineWidth: size * 0.006)).frame(width: size * 0.20, height: size * 0.12).offset(y: -size * 0.46)
                Ellipse().fill(Color(hex: 0xFFFBF2)).overlay(Ellipse().stroke(creamOutline, lineWidth: size * 0.005)).frame(width: size * 0.15, height: size * 0.10).offset(x: size * 0.02, y: -size * 0.53)
                Ellipse().fill(Color(hex: 0xFFF6E8)).overlay(Ellipse().stroke(creamOutline, lineWidth: size * 0.005)).frame(width: size * 0.10, height: size * 0.075).offset(x: -size * 0.015, y: -size * 0.585)
                Circle().fill(Color(hex: 0xFFFDF8)).frame(width: size * 0.045, height: size * 0.045).offset(x: size * 0.01, y: -size * 0.625)
            }
        case .knitBobble:
            ZStack {
                Capsule().fill(deep).frame(width: size * 0.03, height: size * 0.08).offset(y: -size * 0.49)
                Circle().fill(accent).frame(width: size * 0.17, height: size * 0.17).offset(y: -size * 0.57)
                Circle().fill(accent).opacity(0.92).frame(width: size * 0.07, height: size * 0.07).offset(x: -size * 0.07, y: -size * 0.55)
                Circle().fill(accent).opacity(0.92).frame(width: size * 0.07, height: size * 0.07).offset(x: size * 0.07, y: -size * 0.59)
                Circle().fill(accent).opacity(0.92).frame(width: size * 0.06, height: size * 0.06).offset(x: size * 0.02, y: -size * 0.64)
            }
        case .creamDollop:
            ZStack {
                Ellipse().fill(Color(hex: 0xFFFBF2)).overlay(Ellipse().stroke(creamOutline, lineWidth: size * 0.006)).frame(width: size * 0.22, height: size * 0.13).offset(y: -size * 0.47)
                Ellipse().fill(Color(hex: 0xFFFDF8)).overlay(Ellipse().stroke(creamOutline, lineWidth: size * 0.005)).frame(width: size * 0.13, height: size * 0.11).rotationEffect(.degrees(-12)).offset(x: size * 0.03, y: -size * 0.55)
                Circle().fill(.white).overlay(Circle().stroke(creamOutline, lineWidth: size * 0.004)).frame(width: size * 0.05, height: size * 0.05).offset(x: size * 0.06, y: -size * 0.60)
            }
        case .steamWisp:
            ZStack {
                TuftShape().stroke(Color.white.opacity(0.7), style: .init(lineWidth: size * 0.022, lineCap: .round)).frame(width: size * 0.06, height: size * 0.20).offset(x: -size * 0.05, y: -size * 0.55)
                TuftShape().stroke(Color.white.opacity(0.5), style: .init(lineWidth: size * 0.018, lineCap: .round)).frame(width: size * 0.05, height: size * 0.16).scaleEffect(x: -1, y: 1).offset(x: size * 0.05, y: -size * 0.57)
            }
        case .marshmallowTuft:
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.05).fill(Color(hex: 0xFFF7F1)).overlay(RoundedRectangle(cornerRadius: size * 0.05).stroke(creamOutline, lineWidth: size * 0.006)).frame(width: size * 0.15, height: size * 0.12).rotationEffect(.degrees(-8)).offset(x: -size * 0.05, y: -size * 0.50)
                RoundedRectangle(cornerRadius: size * 0.045).fill(Color(hex: 0xFFFDFB)).overlay(RoundedRectangle(cornerRadius: size * 0.045).stroke(creamOutline, lineWidth: size * 0.006)).frame(width: size * 0.13, height: size * 0.11).rotationEffect(.degrees(10)).offset(x: size * 0.06, y: -size * 0.52)
                Ellipse().fill(.white.opacity(0.7)).frame(width: size * 0.06, height: size * 0.03).offset(x: -size * 0.04, y: -size * 0.53)
            }
        case .foldedDoughEars:
            ZStack {
                Ellipse().fill(bodyColor).frame(width: size * 0.17, height: size * 0.22).rotationEffect(.degrees(-16)).offset(x: -size * 0.26, y: -size * 0.43)
                Capsule().fill(deep.opacity(0.35)).frame(width: size * 0.03, height: size * 0.11).rotationEffect(.degrees(-16)).offset(x: -size * 0.26, y: -size * 0.43)
                Ellipse().fill(bodyColor).frame(width: size * 0.17, height: size * 0.22).rotationEffect(.degrees(16)).offset(x: size * 0.26, y: -size * 0.43)
                Capsule().fill(deep.opacity(0.35)).frame(width: size * 0.03, height: size * 0.11).rotationEffect(.degrees(16)).offset(x: size * 0.26, y: -size * 0.43)
            }
        case .cherryOnTop:
            ZStack {
                Capsule().fill(Color(hex: 0x7A9A52)).frame(width: size * 0.02, height: size * 0.10).rotationEffect(.degrees(12)).offset(x: size * 0.01, y: -size * 0.55)
                Circle().fill(Color(hex: 0xE0556B)).frame(width: size * 0.12, height: size * 0.12).offset(y: -size * 0.49)
                Ellipse().fill(.white.opacity(0.75)).frame(width: size * 0.04, height: size * 0.025).offset(x: -size * 0.025, y: -size * 0.51)
            }
        case .honeyDrip:
            ZStack {
                Ellipse().fill(Color(hex: 0xF2B84B)).frame(width: size * 0.20, height: size * 0.10).offset(y: -size * 0.47)
                Ellipse().fill(Color(hex: 0xFBD884).opacity(0.8)).frame(width: size * 0.08, height: size * 0.035).offset(x: -size * 0.04, y: -size * 0.485)
                Circle().fill(Color(hex: 0xF2B84B)).frame(width: size * 0.05, height: size * 0.05).offset(x: size * 0.05, y: -size * 0.42)
            }
        case .teacupSteam:
            ZStack {
                Circle().trim(from: 0, to: 0.5).stroke(.white, style: .init(lineWidth: size * 0.03, lineCap: .round)).frame(width: size * 0.10, height: size * 0.14).rotationEffect(.degrees(-90)).offset(x: size * 0.16, y: -size * 0.40)
                Circle().fill(accent).frame(width: size * 0.04, height: size * 0.04).offset(x: -size * 0.16, y: -size * 0.42)
            }
        case .fuzzyWoolTuft:
            ZStack {
                Circle().fill(Color(hex: 0xF4ECDD)).overlay(Circle().stroke(creamOutline, lineWidth: size * 0.005)).opacity(0.96).frame(width: size * 0.12, height: size * 0.12).offset(x: -size * 0.06, y: -size * 0.50)
                Circle().fill(Color(hex: 0xFBF4E8)).overlay(Circle().stroke(creamOutline, lineWidth: size * 0.005)).opacity(0.96).frame(width: size * 0.14, height: size * 0.14).offset(y: -size * 0.55)
                Circle().fill(Color(hex: 0xF4ECDD)).overlay(Circle().stroke(creamOutline, lineWidth: size * 0.005)).opacity(0.96).frame(width: size * 0.11, height: size * 0.11).offset(x: size * 0.06, y: -size * 0.51)
            }
        }
    }

    private func bubble(_ d: CGFloat, x: CGFloat, y: CGFloat, op: Double) -> some View {
        ZStack {
            Circle().fill(Color(hex: 0xCFEFF4).opacity(op))
                .overlay(Circle().stroke(Color(hex: 0x9FD3DC), lineWidth: size * 0.006))
            Circle().fill(.white.opacity(0.9)).frame(width: d * 0.22, height: d * 0.22).offset(x: -d * 0.22, y: -d * 0.22)
        }
        .frame(width: d, height: d).offset(x: size * x, y: size * y)
    }

    private func pearl(_ d: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle().fill(Color(hex: 0xF7EFE2))
            .overlay(Circle().stroke(Color(hex: 0xE2D4BE), lineWidth: size * 0.005))
            .frame(width: d, height: d).offset(x: size * x, y: size * y)
    }

    private func ear(_ side: CGFloat) -> some View {
        Ellipse().fill(bodyColor).frame(width: size * 0.2, height: size * 0.26)
            .overlay { Ellipse().fill(deep.opacity(0.5)).frame(width: size * 0.09, height: size * 0.14) }
            .rotationEffect(.degrees(Double(side) * 14)).offset(x: side * size * 0.27, y: -size * 0.42)
    }

    private var sprout: some View {
        ZStack {
            Capsule().fill(Color(hex: 0x77C47E)).frame(width: size * 0.035, height: size * 0.16).offset(y: -size * 0.52)
            Ellipse().fill(Color(hex: 0x86D38C)).frame(width: size * 0.13, height: size * 0.08)
                .rotationEffect(.degrees(-28)).offset(x: size * 0.06, y: -size * 0.58)
            Ellipse().fill(Color(hex: 0x86D38C)).frame(width: size * 0.11, height: size * 0.07)
                .rotationEffect(.degrees(30)).offset(x: -size * 0.05, y: -size * 0.56)
        }
    }
}

// MARK: - Body pattern (the marking on the belly)

/// Drawn over the body gradient and clipped to the body `Circle` by the caller.
struct BodyPatternView: View {
    let pattern: BodyPattern
    let bodyColor: Color
    let deep: Color
    let accent: Color
    let size: CGFloat

    var body: some View {
        switch pattern {
        case .none:
            EmptyView()
        case .starFreckles:
            let pts: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (-0.22, -0.10, 0.06, 0), (0.20, -0.04, 0.07, 14), (-0.10, 0.16, 0.05, -10),
                (0.26, 0.16, 0.06, 22), (0.06, 0.26, 0.05, -18), (-0.28, 0.06, 0.055, 8), (0.15, -0.20, 0.045, -6)]
            ZStack {
                ForEach(0..<pts.count, id: \.self) { i in
                    StarShape().fill(.white.opacity(0.85))
                        .frame(width: size * pts[i].2, height: size * pts[i].2)
                        .rotationEffect(.degrees(pts[i].3)).offset(x: size * pts[i].0, y: size * pts[i].1)
                }
            }
        case .galaxySwirl:
            ZStack {
                Circle().fill(.white.opacity(0.45)).frame(width: size * 0.14, height: size * 0.14).blur(radius: size * 0.03)
                    .offset(x: size * 0.05, y: size * 0.05)
                ForEach(0..<9, id: \.self) { i in
                    let a = Double(i) * 0.85
                    let r = size * CGFloat(0.04 + Double(i) * 0.032)
                    let d = size * CGFloat(0.06 - Double(i) * 0.005)
                    Circle().fill(accent.opacity(0.7)).frame(width: d, height: d)
                        .offset(x: size * 0.05 + CGFloat(cos(a)) * r, y: size * 0.05 + CGFloat(sin(a)) * r)
                }
            }
        case .crescentBelly:
            ZStack {
                Ellipse().fill(accent.opacity(0.5)).frame(width: size * 0.62, height: size * 0.5).blur(radius: size * 0.05).offset(y: size * 0.22)
                Ellipse().fill(bodyColor).frame(width: size * 0.5, height: size * 0.42).offset(y: size * 0.13)
            }
        case .twilightBand:
            ZStack {
                Rectangle().fill(LinearGradient(colors: [.clear, accent.opacity(0.6)],
                                                startPoint: UnitPoint(x: 0.5, y: 0.4), endPoint: .bottom))
                Capsule().fill(.white.opacity(0.5)).frame(width: size * 0.54, height: size * 0.014)
            }
        case .orbitRings:
            ZStack {
                Ellipse().stroke(deep.opacity(0.45), lineWidth: size * 0.016).frame(width: size * 0.72, height: size * 0.34)
                    .rotationEffect(.degrees(-16)).offset(y: size * 0.04)
                Ellipse().stroke(accent.opacity(0.55), lineWidth: size * 0.014).frame(width: size * 0.52, height: size * 0.22)
                    .rotationEffect(.degrees(-16)).offset(y: size * 0.04)
                Circle().fill(accent).frame(width: size * 0.05, height: size * 0.05).offset(x: size * 0.31, y: -size * 0.03)
            }
        case .moonDust:
            let pts: [(CGFloat, CGFloat, CGFloat)] = [
                (-0.20, -0.16, 0.022), (0.10, -0.20, 0.018), (0.24, -0.06, 0.024), (-0.30, 0.02, 0.016),
                (-0.12, 0.10, 0.026), (0.18, 0.14, 0.018), (0.04, 0.26, 0.022), (-0.24, 0.18, 0.016),
                (0.30, 0.10, 0.018), (-0.04, -0.04, 0.024), (0.12, 0.02, 0.016), (-0.16, 0.28, 0.022),
                (0.26, 0.24, 0.016), (0.0, 0.18, 0.018)]
            ZStack {
                ForEach(0..<pts.count, id: \.self) { i in
                    Circle().fill(.white.opacity(0.6)).frame(width: size * pts[i].2, height: size * pts[i].2)
                        .offset(x: size * pts[i].0, y: size * pts[i].1)
                }
            }
        case .ladybugSpots:
            let pts: [(CGFloat, CGFloat)] = [(-0.20, 0.06), (0.18, 0.10), (-0.10, 0.22), (0.12, 0.26), (-0.24, 0.20), (0.25, 0.20)]
            ZStack {
                ForEach(0..<pts.count, id: \.self) { i in
                    Circle().fill(deep.opacity(0.85)).frame(width: size * 0.08, height: size * 0.08)
                        .offset(x: size * pts[i].0, y: size * pts[i].1)
                }
            }
        case .beeStripe:
            ZStack {
                Capsule().fill(Color(hex: 0x5A4632).opacity(0.85)).frame(width: size * 0.9, height: size * 0.13).offset(y: size * 0.10)
                Capsule().fill(Color(hex: 0x5A4632).opacity(0.85)).frame(width: size * 0.9, height: size * 0.13).offset(y: size * 0.30)
            }
        case .freckleDots:
            let pts: [(CGFloat, CGFloat)] = [(-0.22, 0.18), (0.22, 0.18), (-0.14, 0.28), (0.14, 0.28), (0, 0.30), (-0.27, 0.10), (0.27, 0.10)]
            ZStack {
                ForEach(0..<pts.count, id: \.self) { i in
                    Circle().fill(deep.opacity(0.45)).frame(width: size * 0.035, height: size * 0.035)
                        .offset(x: size * pts[i].0, y: size * pts[i].1)
                }
            }
        case .leafBelly:
            ZStack {
                Ellipse().fill(.white.opacity(0.45)).frame(width: size * 0.42, height: size * 0.50).offset(y: size * 0.16)
                Capsule().fill(deep.opacity(0.35)).frame(width: size * 0.015, height: size * 0.34).offset(y: size * 0.16)
            }
        case .petalSpeckle:
            let pts: [(CGFloat, CGFloat, Double)] = [
                (-0.22, 0.04, 0), (0.20, 0.08, 20), (-0.08, 0.20, -15), (0.10, 0.24, 35),
                (-0.24, 0.22, -30), (0.25, 0.18, 10), (0, 0.30, -25), (0.14, 0.32, 15)]
            ZStack {
                ForEach(0..<pts.count, id: \.self) { i in
                    Ellipse().fill(accent.opacity(0.55)).frame(width: size * 0.05, height: size * 0.075)
                        .rotationEffect(.degrees(pts[i].2)).offset(x: size * pts[i].0, y: size * pts[i].1)
                }
            }
        case .vineTrail:
            ZStack {
                VinePath().stroke(Color(hex: 0x6FB07A), lineWidth: size * 0.02).frame(width: size, height: size)
                Ellipse().fill(Color(hex: 0x86D38C)).frame(width: size * 0.10, height: size * 0.055).rotationEffect(.degrees(35)).offset(x: size * 0.20, y: size * 0.18)
                Ellipse().fill(Color(hex: 0x86D38C)).frame(width: size * 0.10, height: size * 0.055).rotationEffect(.degrees(-20)).offset(x: size * 0.08, y: size * 0.02)
            }
        case .snailSwirl:
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    let d = size * (0.24 - CGFloat(i) * 0.08)
                    Circle().trim(from: 0, to: 0.75).stroke(deep.opacity(0.7), lineWidth: size * 0.022)
                        .frame(width: d, height: d).rotationEffect(.degrees(Double(i) * 40))
                }
            }
            .offset(x: size * 0.14, y: size * 0.16)
        case .scaleSpeckle:
            ZStack {
                ForEach(0..<9, id: \.self) { i in
                    let row = i / 3, col = i % 3
                    let y = size * (0.1 + CGFloat(row) * 0.12)
                    let x = size * (-0.18 + CGFloat(col) * 0.18) + (row % 2 == 1 ? size * 0.09 : 0)
                    Circle().trim(from: 0.55, to: 0.95).stroke(deep.opacity(0.25), style: .init(lineWidth: size * 0.02, lineCap: .round))
                        .frame(width: size * 0.1, height: size * 0.1).offset(x: x, y: y)
                }
            }
        case .pearlBelly:
            ZStack {
                Ellipse().fill(LinearGradient(colors: [Color(hex: 0xFBF3E6).opacity(0.85), .clear], startPoint: .bottom, endPoint: .top))
                    .frame(width: size * 0.6, height: size * 0.5).offset(y: size * 0.22)
                Capsule().fill(.white.opacity(0.35)).frame(width: size * 0.28, height: size * 0.04).blur(radius: size * 0.02).offset(y: size * 0.12)
            }
        case .bubbleDots:
            let pts: [(CGFloat, CGFloat, CGFloat)] = [
                (-0.22, 0.18, 0.05), (0.2, 0.05, 0.07), (-0.05, 0.3, 0.04), (0.28, 0.26, 0.06),
                (-0.28, -0.02, 0.03), (0.08, -0.12, 0.045), (0.16, 0.34, 0.055)]
            ZStack {
                ForEach(0..<pts.count, id: \.self) { i in
                    Circle().fill(Color(hex: 0xCFEFF4).opacity(0.5))
                        .overlay(Circle().stroke(Color(hex: 0x9FD3DC).opacity(0.5), lineWidth: size * 0.004))
                        .frame(width: size * pts[i].2, height: size * pts[i].2).offset(x: size * pts[i].0, y: size * pts[i].1)
                }
            }
        case .waveStripe:
            ZStack {
                Capsule().fill(deep.opacity(0.18)).frame(width: size * 1.1, height: size * 0.08).rotationEffect(.degrees(-4)).offset(y: size * 0.14)
                Capsule().fill(bodyColor.opacity(0.5)).frame(width: size * 1.0, height: size * 0.02).rotationEffect(.degrees(-4)).offset(y: size * 0.10)
            }
        case .seafoamFreckles:
            let pts: [(CGFloat, CGFloat, CGFloat)] = [
                (-0.24, 0.02, 0.025), (-0.18, 0.06, 0.02), (-0.20, 0.0, 0.018), (-0.14, 0.04, 0.022),
                (0.24, 0.02, 0.025), (0.18, 0.06, 0.02), (0.20, 0.0, 0.018), (0.14, 0.04, 0.022)]
            ZStack {
                ForEach(0..<pts.count, id: \.self) { i in
                    Circle().fill(Color(hex: 0xB7E3D4).opacity(0.6)).frame(width: size * pts[i].2, height: size * pts[i].2).offset(x: size * pts[i].0, y: size * pts[i].1)
                }
            }
        case .tidalGradientBand:
            Rectangle().fill(LinearGradient(colors: [deep.opacity(0.22), .clear], startPoint: .topLeading, endPoint: .center))
                .frame(width: size * 1.4, height: size * 1.4).rotationEffect(.degrees(-18)).offset(y: -size * 0.2)
        case .cocoaFreckles:
            let pts: [(CGFloat, CGFloat)] = [
                (-0.22, 0.10), (-0.16, 0.14), (-0.10, 0.09), (0.10, 0.10), (0.17, 0.13),
                (0.23, 0.08), (-0.04, 0.16), (0.04, 0.15), (0.0, 0.20)]
            ZStack {
                ForEach(0..<pts.count, id: \.self) { i in
                    Circle().fill(deep.opacity(0.5)).frame(width: size * 0.022, height: size * 0.022).offset(x: size * pts[i].0, y: size * pts[i].1)
                }
            }
        case .creamBellyPatch:
            ZStack {
                Ellipse().fill(Color(hex: 0xFFF6E8).opacity(0.9)).frame(width: size * 0.55, height: size * 0.42).offset(y: size * 0.18)
                Ellipse().fill(Color(hex: 0xFFFBF3).opacity(0.8)).frame(width: size * 0.40, height: size * 0.30).offset(y: size * 0.18)
            }
        case .knitVStitches:
            ZStack {
                ForEach(0..<3, id: \.self) { row in
                    ForEach(0..<5, id: \.self) { col in
                        let y = size * (0.06 + CGFloat(row) * 0.10)
                        let x = size * (-0.20 + CGFloat(col) * 0.10) + (row % 2 == 1 ? size * 0.05 : 0)
                        ChevronShape().stroke(deep.opacity(0.35), style: .init(lineWidth: size * 0.018, lineCap: .round))
                            .frame(width: size * 0.07, height: size * 0.05).offset(x: x, y: y)
                    }
                }
            }
        case .sprinkleDots:
            let pts: [(CGFloat, CGFloat, Double, Int)] = [
                (-0.20, -0.10, -30, 0), (-0.12, 0.02, 20, 1), (-0.04, -0.14, -10, 2), (0.05, -0.06, 35, 3),
                (0.14, -0.12, -25, 0), (0.20, 0.0, 15, 1), (0.08, 0.08, -40, 2), (-0.16, 0.10, 25, 3),
                (0.0, 0.0, 10, 0), (-0.08, -0.04, -15, 1)]
            let colors = [Color(hex: 0xF4A6B8), Color(hex: 0xA8D8C0), Color(hex: 0xF4D08A), Color(hex: 0xB6A8E0)]
            ZStack {
                ForEach(0..<pts.count, id: \.self) { i in
                    Capsule().fill(colors[pts[i].3].opacity(0.85)).frame(width: size * 0.012, height: size * 0.04)
                        .rotationEffect(.degrees(pts[i].2)).offset(x: size * pts[i].0, y: size * pts[i].1)
                }
            }
        case .toastyCheeks:
            ZStack {
                Ellipse().fill(RadialGradient(colors: [deep.opacity(0), deep.opacity(0.30)], center: .center, startRadius: 0, endRadius: size * 0.13))
                    .frame(width: size * 0.26, height: size * 0.20).blur(radius: 3).offset(x: -size * 0.30, y: size * 0.06)
                Ellipse().fill(RadialGradient(colors: [deep.opacity(0), deep.opacity(0.30)], center: .center, startRadius: 0, endRadius: size * 0.13))
                    .frame(width: size * 0.26, height: size * 0.20).blur(radius: 3).offset(x: size * 0.30, y: size * 0.06)
            }
        case .swirlMarbling:
            ZStack {
                MarbleSwirl().stroke(deep.opacity(0.22), style: .init(lineWidth: size * 0.05, lineCap: .round)).frame(width: size * 0.7, height: size * 0.7)
                MarbleSwirl().stroke(.white.opacity(0.25), style: .init(lineWidth: size * 0.03, lineCap: .round)).frame(width: size * 0.7, height: size * 0.7).offset(x: size * 0.04, y: -size * 0.03)
            }
        }
    }
}
