import SwiftUI

/// Creation, kept short and direct: pick a colour, pick a base look, then a
/// little hatch reveal, then name it. The creature stays hidden in the egg so
/// the hatch is a real payoff. Sign-in and permissions come later, contextually.
///
/// Every screen is a ScrollView with the primary button pinned in the bottom
/// safe-area inset, so the button floats above the keyboard and the content
/// never overflows on small phones.
struct OnboardingView: View {
    var onFinish: (HatchedCreature) -> Void
    @State private var model = HatchModel()

    var body: some View {
        ZStack {
            YolkColor.shell.ignoresSafeArea()

            Group {
                switch model.step {
                case .welcome:
                    WelcomeView {
                        withAnimation(.easeInOut(duration: 0.4)) { model.begin() }
                    }
                    .transition(.opacity)

                case .quiz:
                    VibeQuizView(model: model) {
                        withAnimation(.easeInOut(duration: 0.4)) { model.goToCustomize() }
                    }
                    .transition(.opacity)

                case .customize:
                    CustomizeView(model: model) {
                        withAnimation(.easeInOut(duration: 0.4)) { model.goToHatching() }
                    }
                    .transition(.opacity)

                case .hatching:
                    HatchRevealView(vibe: model.vibe) {
                        withAnimation(.easeInOut(duration: 0.4)) { model.goToNaming() }
                    }
                    .transition(.opacity)

                case .naming:
                    NamingView(
                        vibe: model.vibe,
                        suggestions: model.nameSuggestions,
                        onName: { name in withAnimation(.easeInOut(duration: 0.4)) { _ = model.name(name) } }
                    )
                    .transition(.opacity)

                case .gift:
                    GiftView(vibe: model.vibe) {
                        withAnimation(.easeInOut(duration: 0.4)) { model.goToHealth() }
                    }
                    .transition(.opacity)

                case .health:
                    HealthPrimingView(vibe: model.vibe) {
                        withAnimation(.easeInOut(duration: 0.4)) { model.goToFocus() }
                    }
                    .transition(.opacity)

                case .focus:
                    FocusPrimingView(vibe: model.vibe) {
                        withAnimation(.easeInOut(duration: 0.4)) { model.goToIntro() }
                    }
                    .transition(.opacity)

                case .intro:
                    ClosetIntroView(vibe: model.vibe) {
                        if let creature = model.finalCreature { onFinish(creature) }
                    }
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            // Launch args as well as env vars — SIMCTL_CHILD_* propagates unreliably.
            if let demo = ProcessInfo.processInfo.environment["YOLK_ONB"] {
                model.jumpForDemo(demo)
            } else if let arg = CommandLine.arguments.first(where: { $0.hasPrefix("YOLK_ONB=") }) {
                model.jumpForDemo(String(arg.dropFirst("YOLK_ONB=".count)))
            }
        }
    }
}

// MARK: - Customize (the one creation screen)

private struct CustomizeView: View {
    let model: HatchModel
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: YolkSpace.md) {
                TypewriterText(text: "make your yolkling", font: YolkType.heading, color: YolkColor.ink)
                    .padding(.top, YolkSpace.md)

                // An egg in the chosen colour — the creature stays a reveal.
                EggView(color: model.vibe.body, size: 165)
                    .frame(height: 200)

                sectionLabel("pick a look")
                // The eight base looks are wider than a phone row. Give them their own
                // horizontal scroll context so the row's intrinsic width is bounded to
                // the viewport and can never poison the colour grid + labels below it.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: YolkSpace.sm) {
                        ForEach(CreatureStyle.allCases) { style in
                            StyleButton(style: style, color: model.vibe.body, selected: model.style == style) {
                                Haptics.shared.select()
                                withAnimation(.bouncy(duration: 0.5, extraBounce: 0.3)) { model.selectStyle(style) }
                            }
                        }
                    }
                    // Vertical room so the bouncy select animation (which overshoots
                    // past 1.0) isn't clipped by the ScrollView's bounds.
                    .padding(.horizontal, 2)
                    .padding(.vertical, 8)
                }

                sectionLabel("pick a color")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 14) {
                    ForEach(CreaturePalette.colors, id: \.self) { hex in
                        Swatch(hex: hex, selected: model.colorHex == hex) {
                            Haptics.shared.select()
                            withAnimation(.spring(duration: 0.4)) { model.selectColor(hex) }
                        }
                    }
                }
            }
            .padding(.horizontal, YolkSpace.lg)
            .padding(.bottom, YolkSpace.md)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            BottomBar { HatchButton("continue", action: onContinue) }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(YolkType.label)
            .tracking(2)
            .textCase(.uppercase)
            .foregroundStyle(YolkColor.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, YolkSpace.xs)
    }
}

/// A small live preview of one base look.
private struct StyleButton: View {
    let style: CreatureStyle
    let color: Color
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            YolklingView(vibe: Vibe(id: style.id, name: style.label, body: color, deep: color, style: style),
                         expression: .content, size: 44)
                .frame(width: 64, height: 84)
                .background(selected ? YolkColor.shell2 : .clear, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(YolkColor.ink, lineWidth: selected ? 2.5 : 0))
        }
        .buttonStyle(.plain)
    }
}

private struct Swatch: View {
    let hex: UInt
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(YolkColor.ink, lineWidth: selected ? 3 : 0).padding(selected ? -3 : 0))
                .shadow(color: Color(hex: hex).opacity(0.4), radius: selected ? 6 : 0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - The hatch reveal

private struct HatchRevealView: View {
    let vibe: Vibe
    var onContinue: () -> Void

    @State private var hatched = false
    @State private var gathering = false
    @State private var eggSquash = false
    @State private var sparkle = false
    @State private var showButton = false
    @State private var expr: YolkExpression = .surprised

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer(minLength: 0)

            ZStack {
                if hatched {
                    if sparkle { SparkleBurst(size: 260) }
                    YolklingView(vibe: vibe, expression: expr, size: 215)
                        .transition(.scale(scale: 0.15).combined(with: .opacity))
                } else {
                    EggView(color: vibe.body, size: 195, gathering: gathering)
                        .scaleEffect(x: eggSquash ? 1.12 : 1, y: eggSquash ? 0.82 : 1, anchor: .bottom)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 300)

            Text("say hi to your little one")
                .font(YolkType.body)
                .foregroundStyle(YolkColor.muted)
                .opacity(showButton ? 1 : 0)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, YolkSpace.lg)
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                HatchButton("meet them", action: onContinue).opacity(showButton ? 1 : 0)
            }
        }
        .task { await choreograph() }
    }

    private func choreograph() async {
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.easeInOut(duration: 0.5)) { gathering = true }
        try? await Task.sleep(for: .seconds(0.9))
        withAnimation(.easeIn(duration: 0.16)) { eggSquash = true }
        try? await Task.sleep(for: .seconds(0.16))
        sparkle = true
        Haptics.shared.pop()
        withAnimation(.bouncy(duration: 0.7, extraBounce: 0.42)) { hatched = true }
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.66)) { expr = .happy }
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.easeOut(duration: 0.4)) { showButton = true }
    }
}

/// A one-shot ring of sparkles bursting outward at the hatch.
private struct SparkleBurst: View {
    let size: CGFloat
    @State private var go = false
    private let count = 8

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 2 * .pi
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.08))
                    .foregroundStyle(YolkColor.yolk)
                    .offset(x: go ? cos(angle) * size * 0.5 : 0, y: go ? sin(angle) * size * 0.5 : 0)
                    .opacity(go ? 0 : 1)
                    .scaleEffect(go ? 1.3 : 0.2)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.85)) { go = true } }
    }
}

// MARK: - Naming ritual

private struct NamingView: View {
    let vibe: Vibe
    let suggestions: [String]
    var onName: (String) -> Void

    @State private var name = ""
    @State private var expr: YolkExpression = .curious
    @FocusState private var fieldFocused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ScrollView {
            VStack(spacing: YolkSpace.lg) {
                YolklingView(vibe: vibe, expression: expr, size: 170)
                    .frame(height: 210)

                TypewriterText(text: "what will you call them?", font: YolkType.heading, color: YolkColor.ink)

                HStack(spacing: YolkSpace.sm) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            withAnimation(.spring) { name = suggestion }
                        }
                        .font(YolkType.bodySmall)
                        .foregroundStyle(YolkColor.inkSoft)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(YolkColor.shell2, in: Capsule())
                        .buttonStyle(.plain)
                    }
                }

                TextField("type a name", text: $name)
                    .font(YolkType.body)
                    .foregroundStyle(YolkColor.ink)
                    .tint(YolkColor.ink)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .background(YolkColor.shell2, in: Capsule())
                    .focused($fieldFocused)
                    .submitLabel(.done)
                    .onSubmit(commit)
            }
            .padding(.horizontal, YolkSpace.lg)
            .padding(.top, YolkSpace.lg)
            .padding(.bottom, YolkSpace.md)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                HatchButton("that's the one", enabled: !trimmed.isEmpty, action: commit)
            }
        }
    }

    private func commit() {
        guard !trimmed.isEmpty else { return }
        Haptics.shared.reward()
        fieldFocused = false
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.45)) { expr = .happy }
        onName(trimmed)
    }
}

// MARK: - Welcome gift (Yolks)

private struct GiftView: View {
    let vibe: Vibe
    var onContinue: () -> Void
    @State private var pop = false

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .excited, size: 175)
                .frame(height: 225)
            VStack(spacing: YolkSpace.sm) {
                TypewriterText(text: "a welcome gift", font: YolkType.heading, color: YolkColor.ink)
                HStack(spacing: 8) {
                    YolkCoin(size: 30)
                    Text("\(Wallet.welcomeGrant) \(Currency.name)")
                        .font(YolkType.title)
                        .foregroundStyle(YolkColor.ink)
                }
                .scaleEffect(pop ? 1 : 0.6)
                .opacity(pop ? 1 : 0)
                TypewriterText(text: "to get you started. earn more by caring for your yolkling every day.",
                               color: YolkColor.muted, startDelay: 0.7)
            }
            Spacer()
        }
        .padding(.horizontal, YolkSpace.lg)
        .safeAreaInset(edge: .bottom) {
            BottomBar { HatchButton("sweet", action: onContinue) }
        }
        .task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.bouncy(duration: 0.6, extraBounce: 0.5)) { pop = true }
        }
    }
}

// MARK: - Closet intro (how to customize)

private struct ClosetIntroView: View {
    let vibe: Vibe
    var onDone: () -> Void

    private var teaser: [Cosmetic] {
        CosmeticCatalog.all.filter { ["beanie", "glasses"].contains($0.id) }
    }

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .happy, size: 165, outfit: teaser)
                .frame(height: 215)
            VStack(spacing: YolkSpace.md) {
                TypewriterText(text: "make them yours", font: YolkType.heading, color: YolkColor.ink)
                TypewriterText(text: "tap the closet to dress up your yolkling with hats, glasses, scarves and more. find it in the bar at the bottom.",
                               color: YolkColor.muted, startDelay: 0.55)
                HStack(spacing: YolkSpace.sm) {
                    Image(systemName: "tshirt.fill")
                        .font(.title3).foregroundStyle(YolkColor.ink)
                        .padding(10).background(YolkColor.shell2, in: Circle())
                    Text("look for this").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                }
                .padding(.top, YolkSpace.xs)
            }
            Spacer()
        }
        .padding(.horizontal, YolkSpace.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            BottomBar { HatchButton("let's go", action: onDone) }
        }
    }
}

// MARK: - Welcome / how it works

private struct WelcomeView: View {
    var onBegin: () -> Void

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: .yolk, expression: .happy, size: 150)
                .frame(height: 185)
            TypewriterText(text: "meet yolkling", font: YolkType.title, color: YolkColor.ink)
            VStack(alignment: .leading, spacing: YolkSpace.md) {
                point("heart.fill", "a one of a kind creature that warms up to you when you take care of YOURSELF")
                point("figure.walk", "your steps and sleep earn its trust")
                point("hand.wave.fill", "care for yourself and it learns to wave, celebrates your wins, becomes truly yours")
                point("person.2.fill", "and your creatures visit each other")
            }
            Spacer()
        }
        .padding(.horizontal, YolkSpace.lg)
        .safeAreaInset(edge: .bottom) {
            BottomBar { HatchButton("begin", action: onBegin) }
        }
    }

    private func point(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: YolkSpace.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(YolkColor.yolkDeep)
                .frame(width: 30)
            Text(text)
                .font(YolkType.body)
                .foregroundStyle(YolkColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Permission priming (warm pre-permission, never a cold prompt)

private struct HealthPrimingView: View {
    let vibe: Vibe
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .happy, size: 150)
                .frame(height: 185)
            TypewriterText(text: "your real life earns their trust", font: YolkType.heading, color: YolkColor.ink)
            TypewriterText(text: "your steps and sleep are how your yolkling learns to trust you. connect Health so it can feel your day and grow with you. your data stays private, end to end encrypted, even we can't read it.",
                           color: YolkColor.muted, startDelay: 0.8)
            Spacer()
        }
        .padding(.horizontal, YolkSpace.lg)
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                VStack(spacing: YolkSpace.xs) {
                    HatchButton("connect health", action: onContinue)
                    SecondaryButton("maybe later", action: onContinue)
                }
            }
        }
    }
}

private struct FocusPrimingView: View {
    let vibe: Vibe
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .calm, size: 150)
                .frame(height: 185)
            TypewriterText(text: "off your phone, on with life", font: YolkType.heading, color: YolkColor.ink)
            TypewriterText(text: "start a focus session and your yolkling rests and glows while you're away. the less you scroll, the more they thrive. miss a day and they just wait for you, never guilt.",
                           color: YolkColor.muted, startDelay: 0.85)
            Spacer()
        }
        .padding(.horizontal, YolkSpace.lg)
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                VStack(spacing: YolkSpace.xs) {
                    HatchButton("sounds good", action: onContinue)
                    SecondaryButton("maybe later", action: onContinue)
                }
            }
        }
    }
}

private struct SecondaryButton: View {
    let title: String
    var action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(YolkType.body)
                .foregroundStyle(YolkColor.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared pieces

/// Pins its content to the bottom, full-width, over an opaque backing so
/// scrolled content can't show through. Sits above the keyboard automatically.
private struct BottomBar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, YolkSpace.lg)
            .padding(.top, YolkSpace.sm)
            .padding(.bottom, YolkSpace.xs)
            .frame(maxWidth: .infinity)
            .background(YolkColor.shell)
    }
}

/// The single, fixed-style continue button (Finch lesson: never move it).
private struct HatchButton: View {
    let title: String
    var enabled: Bool = true
    var action: () -> Void

    init(_ title: String, enabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.enabled = enabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(YolkType.body.weight(.semibold))
                .foregroundStyle(YolkColor.shell)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(YolkColor.ink.opacity(enabled ? 1 : 0.25), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
