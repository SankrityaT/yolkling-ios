import SwiftUI

/// A soft, breathing egg in the chosen colour. Shown while the user picks, so
/// the creature inside is still a reveal at hatch. Pure SwiftUI, no assets.
struct EggView: View {
    var color: Color
    var size: CGFloat = 180
    var gathering: Bool = false   // pre-hatch anticipation: glow + shiver

    @State private var breathe = false
    @State private var shiver = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(color)
                .frame(width: size * 0.82, height: size)
                .blur(radius: gathering ? 26 : 14)
                .opacity(gathering ? 0.55 : 0.3)

            EggShape().fill(color)
                .overlay(highlight)
                .overlay(shade)
                .overlay(speckles)
                .clipShape(EggShape())
                .overlay(EggShape().stroke(.white.opacity(0.3), lineWidth: 1).blendMode(.overlay))
                .frame(width: size * 0.82, height: size)
                .scaleEffect(x: breathe ? 1.02 : 0.99, y: breathe ? 0.99 : 1.02, anchor: .bottom)
                .rotationEffect(.degrees(shiver ? 2.2 : -2.2))
                .shadow(color: color.opacity(0.35), radius: size * 0.07, y: size * 0.05)
        }
        .frame(width: size, height: size * 1.15)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { breathe = true }
        }
        .onChange(of: gathering) { _, on in
            if on {
                withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) { shiver = true }
            }
        }
        .animation(.spring(duration: 0.6), value: color)
    }

    private var highlight: some View {
        RadialGradient(colors: [.white.opacity(0.55), .clear],
                       center: UnitPoint(x: 0.36, y: 0.28),
                       startRadius: size * 0.02, endRadius: size * 0.5)
    }

    private var shade: some View {
        RadialGradient(colors: [.clear, .black.opacity(0.14)],
                       center: UnitPoint(x: 0.5, y: 0.66),
                       startRadius: size * 0.28, endRadius: size * 0.6)
    }

    private var speckles: some View {
        ZStack {
            speck(x: -0.12, y: -0.10, d: 0.06)
            speck(x: 0.16, y: 0.04, d: 0.05)
            speck(x: -0.04, y: 0.20, d: 0.045)
            speck(x: 0.08, y: -0.22, d: 0.035)
        }
    }

    private func speck(x: CGFloat, y: CGFloat, d: CGFloat) -> some View {
        Ellipse()
            .fill(.white.opacity(0.35))
            .frame(width: size * d, height: size * d * 0.8)
            .offset(x: x * size, y: y * size)
    }
}

/// A classic egg outline: an ellipse that tapers narrower toward the top.
struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX
        p.move(to: CGPoint(x: cx, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.62),
                   control1: CGPoint(x: cx + w * 0.34, y: rect.minY),
                   control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.30))
        p.addCurve(to: CGPoint(x: cx, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.86),
                   control2: CGPoint(x: cx + w * 0.30, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.62),
                   control1: CGPoint(x: cx - w * 0.30, y: rect.maxY),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.86))
        p.addCurve(to: CGPoint(x: cx, y: rect.minY),
                   control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.30),
                   control2: CGPoint(x: cx - w * 0.34, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
