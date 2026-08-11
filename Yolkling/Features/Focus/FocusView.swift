import SwiftUI
import UIKit
import YolklingCore

/// The focus session screen. Pick a duration, then your yolkling rests and glows
/// while you put the phone down. Finish it and earn Yolks. Leaving for another app
/// ends it gently (no guilt). See docs/FOCUS.md.
struct FocusView: View {
    let vibe: Vibe
    let name: String
    var colorHex: Int = 0xFFC23B
    var onComplete: (Int) -> Void

    @State private var store = FocusSessionStore()
    /// Screenshot seam: `YOLK_FOCUS_CUSTOM` opens straight onto the custom stepper.
    @State private var showCustom = CommandLine.arguments.contains("YOLK_FOCUS_CUSTOM")
    @State private var customMinutes = 30
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    private let durations = [15, 25, 45]

    var body: some View {
        ZStack {
            YolkColor.shell.ignoresSafeArea()
            content
                .padding(.horizontal, YolkSpace.lg)
        }
        // This is a fullScreenCover, so there is no swipe-to-dismiss and no nav bar. The
        // setup screen had no exit at all — tapping "focus" trapped you until you either
        // started a session or force-quit the app. Every other phase has its own way out
        // ("end session" / "close"), so the escape hatch is only needed here.
        .overlay(alignment: .topTrailing) {
            if store.phase == .idle {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(YolkColor.inkSoft)
                        .padding(10).background(YolkColor.shell2, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.top, YolkSpace.sm)
                .padding(.trailing, YolkSpace.lg)
                .accessibilityLabel("close")
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.sceneBecameActive() }
            else if phase == .background { store.sceneBackgrounded() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)) { _ in
            store.setLocked(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)) { _ in
            store.setLocked(false)
        }
    }

    @ViewBuilder private var content: some View {
        switch store.phase {
        case .idle:      setup
        case .running:   running
        case .completed: completed
        case .ended:     ended
        }
    }

    // MARK: Setup

    private var setup: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .calm, size: 165).frame(height: 205)
            Text("focus session")
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Text("put your phone down. \(name) rests and glows while you're away.")
                .font(YolkType.body).foregroundStyle(YolkColor.muted).multilineTextAlignment(.center)
            HStack(spacing: YolkSpace.sm) {
                ForEach(durations, id: \.self) { m in
                    chip("\(m)m", selected: !showCustom && store.durationMinutes == m) {
                        showCustom = false
                        store.durationMinutes = m
                    }
                }
                chip("custom", selected: showCustom) {
                    showCustom = true
                    store.durationMinutes = customMinutes
                }
            }
            if showCustom { customStepper }
            Spacer()
            primary("start") {
                store.creatureName = name
                store.creatureColorHex = colorHex
                store.start(store.durationMinutes)
            }
        }
    }

    /// Custom duration, in the same capsule idiom as the preset chips.
    ///
    /// This was a `.wheel` Picker — a heavy system control with its own chrome, dropped
    /// into an app that has no other system controls anywhere. It didn't read as a field
    /// so much as a visitor from another app, which is why it wasn't obvious it was even
    /// the input. A stepper is also just faster: two taps to adjust rather than a scroll.
    private var customStepper: some View {
        HStack(spacing: YolkSpace.md) {
            stepButton("minus", enabled: customMinutes > 5) { setCustom(customMinutes - 5) }

            VStack(spacing: 0) {
                Text("\(customMinutes)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(YolkColor.ink)
                Text("minutes").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            }
            .frame(minWidth: 96)

            stepButton("plus", enabled: customMinutes < 120) { setCustom(customMinutes + 5) }
        }
        .padding(.vertical, YolkSpace.sm).padding(.horizontal, YolkSpace.lg)
        .background(YolkColor.shell2, in: Capsule())
    }

    private func stepButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(enabled ? YolkColor.ink : YolkColor.muted.opacity(0.4))
                .frame(width: 44, height: 44)          // full 44pt touch target
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func setCustom(_ m: Int) {
        let clamped = min(120, max(5, m))
        guard clamped != customMinutes else { return }
        withAnimation(.snappy(duration: 0.18)) { customMinutes = clamped }
        store.durationMinutes = clamped
        Haptics.shared.tick()
    }

    // MARK: Running

    private var running: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            ZStack {
                Circle().fill(vibe.body).blur(radius: 45).opacity(0.4).frame(width: 230, height: 230)
                YolklingView(vibe: vibe, expression: .sleepy, size: 185)
            }
            .frame(height: 250)
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                Text(timeString(store.remaining(at: ctx.date)))
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(YolkColor.ink)
            }
            Text("stay off your phone")
                .font(YolkType.body).foregroundStyle(YolkColor.muted)
            Spacer()
            secondary("end session") { store.cancel() }
        }
        .task(id: store.endDate) {
            guard store.phase == .running, let end = store.endDate else { return }
            let wait = end.timeIntervalSinceNow
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            store.complete()
        }
    }

    // MARK: Completed

    private var completed: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .proud, size: 185).frame(height: 240)
            Text("nice focus")
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Text("you focused for \(store.durationMinutes) minutes. \(name) rested the whole time.")
                .font(YolkType.body).foregroundStyle(YolkColor.muted).multilineTextAlignment(.center)
            HStack(spacing: 6) {
                YolkCoin(size: 22)
                Text("+\(store.durationMinutes) \(Currency.name)")
                    .font(YolkType.title).foregroundStyle(YolkColor.ink)
            }
            Spacer()
            primary("collect") {
                onComplete(store.durationMinutes)
                dismiss()
            }
        }
    }

    // MARK: Ended (gentle)

    private var ended: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .content, size: 165).frame(height: 205)
            Text("session ended")
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Text("looks like you left the app. no worries and no guilt. try again whenever you're ready.")
                .font(YolkType.body).foregroundStyle(YolkColor.muted).multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: YolkSpace.sm) {
                primary("try again") { store.reset() }
                secondary("close") { dismiss() }
            }
        }
    }

    // MARK: Pieces

    private func timeString(_ seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded(.up))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(YolkType.body.weight(.semibold))
                .foregroundStyle(selected ? YolkColor.shell : YolkColor.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selected ? YolkColor.ink : YolkColor.shell2, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(YolkType.body.weight(.semibold))
                .foregroundStyle(YolkColor.shell)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(YolkColor.ink, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.bottom, YolkSpace.lg)
    }

    private func secondary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(YolkType.body)
                .foregroundStyle(YolkColor.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
