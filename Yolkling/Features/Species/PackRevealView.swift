import SwiftUI

/// The pack-opening ceremony: a cozy egg that wiggles, then cracks open into a
/// newly discovered creature. This is the EARNED variable reward (caring earns the
/// discovery), given a delightful wrapper. No cash ever touches the randomness, so
/// it is a reward of the hunt, never a loot box (see docs/MONETIZATION.md).
struct PackRevealView: View {
    let species: Species
    @Environment(\.dismiss) private var dismiss
    @State private var revealed = false
    @State private var wiggle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            YolkColor.shell.ignoresSafeArea()
            VStack(spacing: YolkSpace.md) {
                Spacer()
                Text(revealed ? "a new friend" : "a little gift")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .tracking(2).textCase(.uppercase).foregroundStyle(YolkColor.muted)

                ZStack {
                    if revealed {
                        SparkleBurst()
                        YolklingView(vibe: species.vibe, expression: .affectionate, size: 200)
                            .frame(height: 250)
                            .transition(.scale(scale: 0.2).combined(with: .opacity))
                    } else {
                        egg
                            .rotationEffect(.degrees(wiggle ? 4 : -4))
                            .onTapGesture { open() }
                    }
                }
                .frame(height: 260)

                if revealed {
                    Text(species.name).font(YolkType.heading).foregroundStyle(YolkColor.ink)
                    Text(species.personality).font(YolkType.body).foregroundStyle(YolkColor.inkSoft)
                        .multilineTextAlignment(.center).padding(.horizontal, YolkSpace.lg)
                } else {
                    Text("tap to open").font(YolkType.body).foregroundStyle(YolkColor.muted)
                }

                Spacer()

                if revealed {
                    Button { dismiss() } label: {
                        Text("love it").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.shell)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(YolkColor.ink, in: Capsule())
                    }
                    .buttonStyle(.plain).padding(.horizontal, YolkSpace.lg).padding(.bottom, YolkSpace.lg)
                }
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { wiggle = true }
            }
            if ProcessInfo.processInfo.environment["YOLK_PACK_OPEN"] != nil { open() }
        }
    }

    private var egg: some View {
        Ellipse()
            .fill(LinearGradient(colors: [Color(hex: 0xFFF7EA), Color(hex: 0xEFE0C6)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 160, height: 210)
            .overlay(Ellipse().stroke(Color(hex: 0xE3D2B6), lineWidth: 2))
            .overlay(speckles.clipShape(Ellipse()))
            .shadow(color: .black.opacity(0.10), radius: 14, y: 8)
    }

    private var speckles: some View {
        ZStack {
            Ellipse().fill(.white.opacity(0.5)).frame(width: 34, height: 50).offset(x: -34, y: -52).blur(radius: 7)
            Circle().fill(Color(hex: 0xE0CDA8)).frame(width: 14, height: 14).offset(x: -28, y: -30)
            Circle().fill(Color(hex: 0xE0CDA8)).frame(width: 10, height: 10).offset(x: 36, y: -6)
            Circle().fill(Color(hex: 0xE0CDA8)).frame(width: 12, height: 12).offset(x: -16, y: 42)
            Circle().fill(Color(hex: 0xE0CDA8)).frame(width: 8, height: 8).offset(x: 28, y: 52)
        }
        .frame(width: 160, height: 210)
    }

    private func open() {
        Haptics.shared.pop()
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            Haptics.shared.reward()
            withAnimation(.spring(duration: 0.55, bounce: 0.55)) { revealed = true }
        }
    }
}

/// A quick radial burst of sparkles for the reveal moment.
private struct SparkleBurst: View {
    @State private var go = false
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) / 8 * 2 * .pi
                StarShape().fill(Color(hex: 0xFFD98A))
                    .frame(width: 18, height: 18)
                    .offset(x: go ? CGFloat(cos(angle)) * 130 : 0, y: go ? CGFloat(sin(angle)) * 130 : 0)
                    .opacity(go ? 0 : 0.9)
                    .scaleEffect(go ? 0.3 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.7)) { go = true } }
    }
}
