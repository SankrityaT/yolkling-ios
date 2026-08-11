import SwiftUI

/// The spring bloom set: six grant-only cosmetics that exist only while the season runs.
///
/// Renderers live here rather than in CosmeticView.swift, which is already ~1,500 lines.
/// The switch there gains six arms; the drawing lives beside its own season, so a future
/// season is a new file rather than another thousand lines in the same one.
///
/// These are the first things in the app you cannot buy. Everything else is purchasable
/// by anyone with enough earned Yolks, which means owning it says nothing. Being there
/// while a season ran is the only way to get these — that's what makes them worth
/// wanting, and it's the precondition for trading being a real feature later.
extension CosmeticView {

    // MARK: Hats

    /// A ring of cherry blossoms.
    public var blossomCrown: some View {
        let petal = Color(hex: 0xFFC2D8)
        let deep = Color(hex: 0xF79ABA)
        let heart = Color(hex: 0xFFE9A3)
        return ZStack {
            ForEach(0..<5, id: \.self) { i in
                let angle = Double(i) / 5 * 2 * .pi - .pi / 2
                blossom(petal: petal, deep: deep, heart: heart)
                    .offset(x: cos(angle) * size * 0.21, y: sin(angle) * size * 0.075)
            }
        }
        .offset(y: -size * 0.02)
    }

    private func blossom(petal: Color, deep: Color, heart: Color) -> some View {
        ZStack {
            ForEach(0..<5, id: \.self) { p in
                Ellipse()
                    .fill(petal)
                    .overlay(Ellipse().stroke(deep, lineWidth: size * 0.004))
                    .frame(width: size * 0.045, height: size * 0.062)
                    .offset(y: -size * 0.026)
                    .rotationEffect(.degrees(Double(p) * 72))
            }
            Circle().fill(heart).frame(width: size * 0.022, height: size * 0.022)
        }
    }

    /// A butterfly that has decided to sit there.
    public var butterflyPerch: some View {
        let wing = Color(hex: 0xFFB3E6)
        let wingDeep = Color(hex: 0xE889C8)
        let body = Color(hex: 0x5A4632)
        // Scaled up ~55% from the first pass: at the original size it read as a smudge
        // on the creature's head rather than as a butterfly.
        return ZStack {
            ForEach([-1.0, 1.0], id: \.self) { side in
                ZStack {
                    Ellipse().fill(wing)
                        .overlay(Ellipse().stroke(wingDeep, lineWidth: size * 0.004))
                        .frame(width: size * 0.13, height: size * 0.1)
                        .offset(y: -size * 0.028)
                    Ellipse().fill(wingDeep.opacity(0.9))
                        .frame(width: size * 0.095, height: size * 0.075)
                        .offset(y: size * 0.028)
                }
                .rotationEffect(.degrees(side * 18))
                .offset(x: side * size * 0.07)
            }
            Capsule().fill(body).frame(width: size * 0.022, height: size * 0.115)
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule().fill(body)
                    .frame(width: size * 0.007, height: size * 0.04)
                    .rotationEffect(.degrees(side * 24))
                    .offset(x: side * size * 0.013, y: -size * 0.073)
            }
        }
        .offset(y: -size * 0.055)
    }

    /// A tiny watering can, worn as a hat, for no reason at all.
    public var wateringCan: some View {
        let tin = Color(hex: 0xA8D8C0)
        let deep = Color(hex: 0x7FB79C)
        let water = Color(hex: 0x9FD8F0)
        // Rebuilt: the first pass sat far off-centre with a clipped Circle for the handle
        // that didn't render, so it read as a green blob. The can is now centred on the
        // head with the spout balanced against an arc handle, and it's bigger.
        return ZStack {
            // handle — an arc, drawn behind the can
            WateringHandle()
                .stroke(deep, style: StrokeStyle(lineWidth: size * 0.016, lineCap: .round))
                .frame(width: size * 0.14, height: size * 0.1)
                .offset(x: size * 0.075, y: -size * 0.075)

            // spout
            Capsule().fill(tin)
                .overlay(Capsule().stroke(deep, lineWidth: size * 0.005))
                .frame(width: size * 0.14, height: size * 0.042)
                .rotationEffect(.degrees(-28))
                .offset(x: -size * 0.115, y: -size * 0.035)

            // body
            RoundedRectangle(cornerRadius: size * 0.032)
                .fill(tin)
                .overlay(RoundedRectangle(cornerRadius: size * 0.032).stroke(deep, lineWidth: size * 0.006))
                .frame(width: size * 0.19, height: size * 0.14)

            // water drops falling from the spout
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(water)
                    .frame(width: size * 0.018, height: size * 0.018)
                    .offset(x: -size * (0.175 + Double(i) * 0.012),
                            y: size * (0.012 + Double(i) * 0.032))
            }
        }
        .offset(y: -size * 0.045)
    }

    // MARK: Eyes

    /// Petal lashes — two small blossoms resting at the outer corners.
    public var petalLashes: some View {
        let petal = Color(hex: 0xFFC2D8)
        let deep = Color(hex: 0xF79ABA)
        return ZStack {
            ForEach([-1.0, 1.0], id: \.self) { side in
                ZStack {
                    ForEach(0..<3, id: \.self) { p in
                        Ellipse()
                            .fill(petal)
                            .overlay(Ellipse().stroke(deep, lineWidth: size * 0.003))
                            .frame(width: size * 0.03, height: size * 0.045)
                            .offset(y: -size * 0.02)
                            .rotationEffect(.degrees(Double(p - 1) * 34))
                    }
                }
                .rotationEffect(.degrees(side * 24))
                .offset(x: side * size * 0.27, y: -size * 0.11)
            }
        }
    }

    // MARK: Neck

    /// A thin rain cape, for the showers.
    public var rainCape: some View {
        let sheet = Color(hex: 0xBFE6F5)
        let edge = Color(hex: 0x8FC9E0)
        return ZStack {
            RainCapeShape()
                .fill(sheet.opacity(0.75))
                .overlay(RainCapeShape().stroke(edge, lineWidth: size * 0.006))
                .frame(width: size * 0.66, height: size * 0.42)
            Capsule().fill(edge.opacity(0.9))
                .frame(width: size * 0.3, height: size * 0.028)
                .offset(y: -size * 0.19)
        }
        .offset(y: size * 0.12)
    }

    /// A chain of clovers.
    public var cloverChain: some View {
        let leaf = Color(hex: 0x9AD98C)
        let deep = Color(hex: 0x76B86A)
        return ZStack {
            ForEach(0..<5, id: \.self) { i in
                let t = (Double(i) / 4) * 2 - 1                 // -1 … 1
                clover(leaf: leaf, deep: deep)
                    .offset(x: t * size * 0.2, y: abs(t) * -size * 0.035 + size * 0.02)
            }
        }
        .offset(y: size * 0.07)
    }

    private func clover(leaf: Color, deep: Color) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { l in
                Circle()
                    .fill(leaf)
                    .overlay(Circle().stroke(deep, lineWidth: size * 0.003))
                    .frame(width: size * 0.036, height: size * 0.036)
                    .offset(y: -size * 0.018)
                    .rotationEffect(.degrees(Double(l) * 120))
            }
        }
    }
}

/// The watering can's handle: an arc over the top, open at the bottom.
private struct WateringHandle: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.minY - r.height * 0.35))
        return p
    }
}

/// A simple cape: shoulders in, hem out, slightly rounded.
private struct RainCapeShape: Shape {
    public func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX - r.width * 0.22, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY),
                       control: CGPoint(x: r.minX + r.width * 0.04, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.16))
        p.addQuadCurve(to: CGPoint(x: r.midX + r.width * 0.22, y: r.minY),
                       control: CGPoint(x: r.maxX - r.width * 0.04, y: r.midY))
        p.closeSubpath()
        return p
    }
}
