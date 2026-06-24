import ActivityKit
import WidgetKit
import SwiftUI

/// The focus Live Activity: lock screen banner + Dynamic Island. The timer auto
/// counts down from `endDate`. Shows a static yolkling face (widgets can't run
/// the animated renderer, but a drawn face is fine).
struct FocusLiveActivity: Widget {
    private let ink = Color(hex: 0x2A241B)
    private let inkSoft = Color(hex: 0x6E5C49)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock screen — cream background, so dark text.
            HStack(spacing: 12) {
                MiniYolk(colorHex: context.attributes.colorHex, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(context.attributes.creatureName) is resting")
                        .font(.headline).foregroundStyle(ink)
                    Text("stay off your phone")
                        .font(.caption).foregroundStyle(inkSoft)
                }
                Spacer()
                countdown(context, width: 92, font: .title, color: ink)
            }
            .padding()
            .activityBackgroundTint(Color(hex: 0xFBF6EC))
            .activitySystemActionForegroundColor(ink)
        } dynamicIsland: { context in
            // Dynamic Island — black background, so LIGHT text.
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MiniYolk(colorHex: context.attributes.colorHex, size: 34)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context, width: 76, font: .title2, color: .white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.attributes.creatureName) is resting. stay off your phone.")
                        .font(.caption).foregroundStyle(.white.opacity(0.8))
                }
            } compactLeading: {
                MiniYolk(colorHex: context.attributes.colorHex, size: 22, showFace: false)
            } compactTrailing: {
                countdown(context, width: 46, font: .caption2, color: .white)
            } minimal: {
                MiniYolk(colorHex: context.attributes.colorHex, size: 18, showFace: false)
            }
        }
    }

    private func countdown(_ context: ActivityViewContext<FocusActivityAttributes>, width: CGFloat, font: Font, color: Color) -> some View {
        Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
            .font(font.weight(.bold))
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .foregroundStyle(color)
            .frame(width: width)
    }
}

/// A static yolkling face for the widget (no animation in widgets).
struct MiniYolk: View {
    let colorHex: Int
    var size: CGFloat = 44
    var showFace: Bool = true

    var body: some View {
        let hex = UInt(max(0, colorHex))
        ZStack {
            Circle().fill(
                RadialGradient(
                    colors: [Color(hex: lighten(hex, 0.28)), Color(hex: hex), Color(hex: darken(hex, 0.78))],
                    center: UnitPoint(x: 0.36, y: 0.30),
                    startRadius: 0, endRadius: size * 0.62))
            if showFace {
                HStack(spacing: size * 0.14) {
                    eye
                    eye
                }
                .offset(y: -size * 0.03)
                SmileArc()
                    .stroke(Color(hex: 0x2A241B), style: StrokeStyle(lineWidth: max(1.2, size * 0.05), lineCap: .round))
                    .frame(width: size * 0.30, height: size * 0.16)
                    .offset(y: size * 0.19)
            }
        }
        .frame(width: size, height: size)
    }

    private var eye: some View {
        ZStack {
            Capsule().fill(.white).frame(width: size * 0.15, height: size * 0.20)
            Circle().fill(Color(hex: 0x2A241B)).frame(width: size * 0.09, height: size * 0.09)
        }
    }
}

private struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 1.7))
        return p
    }
}

private func darken(_ h: UInt, _ f: Double) -> UInt {
    let r = UInt(Double((h >> 16) & 0xFF) * f)
    let g = UInt(Double((h >> 8) & 0xFF) * f)
    let b = UInt(Double(h & 0xFF) * f)
    return (r << 16) | (g << 8) | b
}

private func lighten(_ h: UInt, _ t: Double) -> UInt {
    let r = UInt(min(255, Double((h >> 16) & 0xFF) + (255 - Double((h >> 16) & 0xFF)) * t))
    let g = UInt(min(255, Double((h >> 8) & 0xFF) + (255 - Double((h >> 8) & 0xFF)) * t))
    let b = UInt(min(255, Double(h & 0xFF) + (255 - Double(h & 0xFF)) * t))
    return (r << 16) | (g << 8) | b
}

private extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}
