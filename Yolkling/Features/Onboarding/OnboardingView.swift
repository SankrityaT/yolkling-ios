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

    /// The namespace the hero creature travels through.
    ///
    /// Onboarding builds ten separate `YolklingView`s, one per step, and used to crossfade
    /// between them — so the creature the player is making blinked out of existence and a
    /// new one faded in at every single step. Tagging each step's creature with the same
    /// `matchedGeometryEffect` id makes SwiftUI drive the frame from one layout to the
    /// next, so it travels and resizes instead of dying. It is the same object the whole
    /// way through, which is the entire point of a flow where you are making something.
    @Namespace private var hero

    var body: some View {
        ZStack {
            OnboardingBackdrop(tint: model.vibe.body)

            Group {
                switch model.step {
                case .welcome:
                    WelcomeView(hero: hero) {
                        withAnimation(.onboardingStep) { model.begin() }
                    }
                    .transition(.onboardingStep)

                case .quiz:
                    VibeQuizView(model: model, hero: hero) {
                        withAnimation(.onboardingStep) { model.goToCustomize() }
                    }
                    .transition(.onboardingStep)

                case .customize:
                    CustomizeView(hero: hero, model: model) {
                        withAnimation(.onboardingStep) { model.goToHatching() }
                    }
                    .transition(.onboardingStep)

                case .hatching:
                    HatchRevealView(hero: hero, vibe: model.vibe) {
                        withAnimation(.onboardingStep) { model.goToNaming() }
                    }
                    .transition(.onboardingStep)

                case .naming:
                    NamingView(
                        hero: hero,
                        vibe: model.vibe,
                        suggestions: model.nameSuggestions,
                        onName: { name in withAnimation(.onboardingStep) { _ = model.name(name) } }
                    )
                    .transition(.onboardingStep)

                case .gift:
                    GiftView(hero: hero, vibe: model.vibe) {
                        withAnimation(.onboardingStep) { model.goToHealth() }
                    }
                    .transition(.onboardingStep)

                case .health:
                    HealthPrimingView(hero: hero, vibe: model.vibe) { granted in
                        model.recordHealth(granted)
                        withAnimation(.onboardingStep) { model.goToFocus() }
                    }
                    .transition(.onboardingStep)

                case .focus:
                    FocusPrimingView(hero: hero, vibe: model.vibe) {
                        withAnimation(.onboardingStep) { model.goToScreenTime() }
                    }
                    .transition(.onboardingStep)

                case .screenTime:
                    ScreenTimePrimingView(hero: hero, vibe: model.vibe) { granted in
                        model.recordScreenTime(granted)
                        withAnimation(.onboardingStep) { model.goToIntro() }
                    }
                    .transition(.onboardingStep)

                case .intro:
                    ClosetIntroView(hero: hero, vibe: model.vibe) {
                        if let creature = model.finalCreature { onFinish(creature) }
                    }
                    .transition(.onboardingStep)
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
    let hero: Namespace.ID
    let model: HatchModel
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: YolkSpace.md) {
                TypewriterText(text: "make your yolkling", font: YolkType.heading, color: YolkColor.ink)
                    .padding(.top, YolkSpace.md)

                // **The creature, live — not an egg.**
                //
                // This screen is called "make your yolkling" and offers eight different
                // looks, and it used to preview an egg. You picked a look and the only
                // thing that changed was a 44pt thumbnail; the subject of the screen was
                // opaque, literally. That is the whole reason it did not feel intuitive.
                //
                // The egg was here to protect the hatch reveal, but the quiz one screen
                // earlier already shows the creature forming as you answer — so the
                // secret was spent before this screen was ever reached. It cost the
                // creation screen its feedback loop and protected nothing.
                //
                // The reveal is now where it belongs: the hatch is a *ceremony*, not an
                // information reveal. You know what is in the egg. Watching it come out
                // is still the payoff, the same way you know what is in a wrapped present.
                YolklingView(vibe: model.vibe, expression: .happy, size: 165)
                    .frame(height: 200)
                    .matchedGeometryEffect(id: OnboardingHero.id, in: hero)

                // The label carries the current pick's name. With 58 unlabelled
                // thumbnails, "which one am I on" was otherwise a question you could only
                // answer by hunting for the ring.
                HStack(alignment: .firstTextBaseline) {
                    sectionLabel("pick a look")
                    Text(model.style.label)
                        .font(YolkType.bodySmall)
                        .foregroundStyle(YolkColor.inkSoft)
                        .padding(.top, YolkSpace.xs)
                        .contentTransition(.opacity)
                }

                // Horizontal, because there are dozens of looks — a grid of them pushed
                // the colour picker clean off the bottom of the screen, which is worse
                // than the problem it was trying to fix.
                //
                // What made this unintuitive was the hard clip at the right edge: a
                // creature sliced in half by the screen reads as a layout bug, not as
                // "there is more this way". The fade says the row continues.
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: YolkSpace.sm) {
                            ForEach(CreatureStyle.allCases) { style in
                                StyleButton(style: style, color: model.vibe.body, selected: model.style == style) {
                                    Haptics.shared.select()
                                    withAnimation(.bouncy(duration: 0.5, extraBounce: 0.3)) { model.selectStyle(style) }
                                }
                                .id(style)
                            }
                        }
                        // Vertical room so the bouncy select animation (which overshoots
                        // past 1.0) isn't clipped by the ScrollView's bounds.
                        .padding(.horizontal, 2)
                        .padding(.vertical, 8)
                    }
                    .mask(
                        LinearGradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.04),
                            .init(color: .black, location: 0.90),
                            .init(color: .clear, location: 1),
                        ], startPoint: .leading, endPoint: .trailing)
                    )
                    // Keep the selection on screen.
                    //
                    // The quiz picks a look for you, so this screen frequently opened
                    // scrolled to the start with the actual selection somewhere off to
                    // the right — the row showed a ring on nothing and there was no way
                    // to tell what you had without swiping through 58 items looking for
                    // it. Centring on appear is the fix; centring on change matters too,
                    // because the edge fade would otherwise leave a freshly tapped item
                    // half-faded at the boundary.
                    .onAppear { proxy.scrollTo(model.style, anchor: .center) }
                    .onChange(of: model.style) { _, style in
                        withAnimation(.easeInOut(duration: 0.35)) {
                            proxy.scrollTo(style, anchor: .center)
                        }
                    }
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
                .background(selected ? YolkColor.shell2 : .clear, in: RoundedRectangle(cornerRadius: 18))
                // Same ring weight as the colour swatch below. Two selection grammars on
                // one screen makes the player learn the control twice.
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(YolkColor.ink, lineWidth: selected ? 3 : 0))
                .scaleEffect(selected ? 1.04 : 1)
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
    let hero: Namespace.ID
    let vibe: Vibe
    var onContinue: () -> Void

    @State private var showButton = false

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer(minLength: 0)

            ZStack {
                if showButton { SparkleBurst(size: 260) }
                HatchCeremony(vibe: vibe, size: 215) {
                    // Landed on the frame the shell actually gives, not guessed at.
                    Haptics.shared.pop()
                    withAnimation(.easeOut(duration: 0.45).delay(0.55)) { showButton = true }
                }
                .matchedGeometryEffect(id: OnboardingHero.id, in: hero)
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
                YolkGlyph(kind: .markSparkle, size: size * 0.085)
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
    let hero: Namespace.ID
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
                .matchedGeometryEffect(id: OnboardingHero.id, in: hero)
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
    let hero: Namespace.ID
    let vibe: Vibe
    var onContinue: () -> Void
    @State private var pop = false

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .excited, size: 175)
                .matchedGeometryEffect(id: OnboardingHero.id, in: hero)
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
    let hero: Namespace.ID
    let vibe: Vibe
    var onDone: () -> Void

    private var teaser: [Cosmetic] {
        CosmeticCatalog.all.filter { ["beanie", "glasses"].contains($0.id) }
    }

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .happy, size: 165, outfit: teaser)
                .matchedGeometryEffect(id: OnboardingHero.id, in: hero)
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
    let hero: Namespace.ID
    var onBegin: () -> Void

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: .yolk, expression: .happy, size: 150)
                .frame(height: 185)
                .matchedGeometryEffect(id: OnboardingHero.id, in: hero)
            TypewriterText(text: "meet yolkling", font: YolkType.title, color: YolkColor.ink)
            // The four promises arrive one at a time rather than as a block, so the eye
            // reads them in the order they were written. `after:` holds the sequence back
            // until the title has finished typing itself out — a stagger that races the
            // headline just looks like a slow layout.
            VStack(alignment: .leading, spacing: YolkSpace.md) {
                point("heart.fill", "a one of a kind creature that warms up to you when you take care of YOURSELF")
                    .yolkEntrance(0, after: 0.35)
                point("figure.walk", "your steps and sleep earn its trust")
                    .yolkEntrance(1, after: 0.35)
                point("hand.wave.fill", "care for yourself and it learns to wave, celebrates your wins, becomes truly yours")
                    .yolkEntrance(2, after: 0.35)
                point("person.2.fill", "and your creatures visit each other")
                    .yolkEntrance(3, after: 0.35)
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
    let hero: Namespace.ID
    let vibe: Vibe
    /// Reports whether Health was actually granted.
    var onContinue: (Bool) -> Void

    @State private var health = HealthService()
    @State private var asking = false

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .happy, size: 150)
                .matchedGeometryEffect(id: OnboardingHero.id, in: hero)
                .frame(height: 185)
            TypewriterText(text: "your real life earns their trust", font: YolkType.heading, color: YolkColor.ink)
            TypewriterText(text: "your steps and sleep are how your yolkling learns to trust you. connect Health so it can feel your day and grow with you. your steps and sleep stay on your device. we never send them anywhere.",
                           color: YolkColor.muted, startDelay: 0.8)
            Spacer()
        }
        .padding(.horizontal, YolkSpace.lg)
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                VStack(spacing: YolkSpace.xs) {
                    // This used to call `onContinue` — the same closure as "maybe later".
                    // The screen asked for Health and then simply moved on without ever
                    // requesting it; the real prompt did not appear until the player
                    // found the card on the home screen days later.
                    HatchButton(asking ? "asking…" : "connect health") {
                        guard !asking else { return }
                        asking = true
                        Task {
                            let ok = await health.connect()
                            asking = false
                            // Continue either way. A declined permission is an answer,
                            // not a dead end, and onboarding must never trap anyone.
                            onContinue(ok)
                        }
                    }
                    .disabled(asking)
                    SecondaryButton("maybe later") { onContinue(false) }
                }
            }
        }
    }
}

private struct FocusPrimingView: View {
    let hero: Namespace.ID
    let vibe: Vibe
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .calm, size: 150)
                .matchedGeometryEffect(id: OnboardingHero.id, in: hero)
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

private struct ScreenTimePrimingView: View {
    let hero: Namespace.ID
    let vibe: Vibe
    /// Reports whether Screen Time was actually granted.
    var onContinue: (Bool) -> Void

    @State private var screenTime = ScreenTimeService()
    @State private var asking = false

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Spacer()
            YolklingView(vibe: vibe, expression: .content, size: 150)
                .matchedGeometryEffect(id: OnboardingHero.id, in: hero)
                .frame(height: 185)
            TypewriterText(text: "time away is time well spent", font: YolkType.heading, color: YolkColor.ink)
            TypewriterText(text: "let your yolkling feel the hours you spend off your phone, and it grows a little livelier. it only ever sees how long, never what you were doing. turn it on now or later, from home.",
                           color: YolkColor.muted, startDelay: 0.85)
            Spacer()
        }
        .padding(.horizontal, YolkSpace.lg)
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                VStack(spacing: YolkSpace.xs) {
                    HatchButton(asking ? "asking…" : "turn it on") {
                        guard !asking else { return }
                        asking = true
                        Task {
                            // Fails gracefully on the simulator and without the
                            // entitlement — `connect()` returns false and the flow carries
                            // on with the off-phone pillar left in its locked state.
                            let ok = await screenTime.connect()
                            asking = false
                            onContinue(ok)
                        }
                    }
                    .disabled(asking)
                    SecondaryButton("maybe later") { onContinue(false) }
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
