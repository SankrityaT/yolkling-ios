import SwiftUI

/// The Yolks currency coin: an egg-white disc with a domed yolk and a shine,
/// with a glint that sweeps across when `animated`. Reusable at any size — small
/// and static in price tags, larger and animated as a hero (the welcome gift).
struct YolkCoin: View {
    var size: CGFloat = 20
    var animated: Bool = true

    @State private var glint = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            // egg white
            Circle().fill(.white)

            // the yolk, domed
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xFFE08A), YolkColor.yolk, YolkColor.yolkDeep],
                        center: UnitPoint(x: 0.36, y: 0.32),
                        startRadius: 0,
                        endRadius: size * 0.34
                    )
                )
                .frame(width: size * 0.62, height: size * 0.62)

            // specular shine on the yolk
            Circle()
                .fill(.white.opacity(0.85))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: -size * 0.11, y: -size * 0.12)

            if animated {
                // a glint streak that sweeps across, then waits off-coin
                Rectangle()
                    .fill(
                        LinearGradient(colors: [.clear, .white.opacity(0.7), .clear],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: size * 0.4, height: size * 1.7)
                    .rotationEffect(.degrees(22))
                    .offset(x: glint ? size * 1.4 : -size * 1.4)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(YolkColor.ink.opacity(0.1), lineWidth: max(1, size * 0.04)))
        .scaleEffect(animated && pulse ? 1.05 : 1.0)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: false)) { glint = true }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        YolkCoin(size: 24)
        YolkCoin(size: 48)
        YolkCoin(size: 80)
    }
    .padding(40)
    .background(YolkColor.shell)
}
