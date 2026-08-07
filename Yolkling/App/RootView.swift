import SwiftUI
import SwiftData

/// Decides the first surface. A returning player (one saved `Player`) lands on
/// home; a new user gets onboarding, and finishing it saves their creature so
/// onboarding never runs again. The screenshot pipeline (YOLK_VIBE set) skips
/// straight to a demo home for deterministic App Store captures.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var players: [Player]

    // Launch ARGUMENTS as well as env vars: SIMCTL_CHILD_* propagates unreliably through
    // `simctl launch`, while --args always arrives. The App Store screenshot pipeline
    // will want this too.
    private let screenshotMode = ProcessInfo.processInfo.environment["YOLK_VIBE"] != nil
        || CommandLine.arguments.contains("YOLK_VIBE")

    var body: some View {
        Group {
            if ProcessInfo.processInfo.environment["YOLK_SPECIES"] != nil {
                CollectionView(discovered: Set(SpeciesSets.headStart + [
                    "celestial-sunny yolkstar", "garden-clovi", "cozy-mochi",
                    "ocean-pearlpup", "garden-daisette", "celestial-moonpuff"]))
            } else if ProcessInfo.processInfo.environment["YOLK_FOUNDING"] != nil,
                      let sp = SpeciesCatalog.founding(id: "founding-the very first") {
                FoundingRevealView(species: sp, onWear: {})
            } else if ProcessInfo.processInfo.environment["YOLK_FEEDBACK"] != nil {
                FeedbackView(vibe: .bubble, userID: "preview")
            } else if ProcessInfo.processInfo.environment["YOLK_PACK"] != nil,
                      let sp = SpeciesCatalog.all.first(where: { $0.id == "garden-firefleur" }) {
                PackRevealView(species: sp)
            } else if let slot = ProcessInfo.processInfo.environment["YOLK_COSMETICS"] {
                CosmeticPreviewGrid(items: Array(CosmeticCatalog.items(in: CosmeticSlot(rawValue: slot) ?? .hat).reversed()))
            } else if let r = ProcessInfo.processInfo.environment["YOLK_ROOM"] {
                let theme = RoomThemes.all[min(max(Int(r) ?? 0, 0), RoomThemes.all.count - 1)]
                let sample = RoomDecorCatalog.all.filter {
                    ["decor-poster","decor-garland","decor-bookshelf","decor-bed","decor-beanbag",
                     "decor-cactus","decor-lamp","decor-candle","decor-balloons","decor-mushroom"].contains($0.id)
                }
                ScrollView {
                    VStack(spacing: YolkSpace.md) {
                        RoomView(vibe: .matcha, expression: .happy, theme: theme, decor: sample).frame(height: 440)
                        Text("all decor").font(YolkType.label).tracking(2).textCase(.uppercase).foregroundStyle(YolkColor.muted)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: YolkSpace.md) {
                            ForEach(RoomDecorCatalog.all) { d in
                                VStack(spacing: 4) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14).fill(YolkColor.shell2)
                                        RoomDecorView(kind: d.kind).frame(width: 60, height: 60)
                                    }
                                    .frame(height: 76)
                                    Text(d.name).font(.caption2).foregroundStyle(YolkColor.muted).lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(YolkSpace.lg)
                }
                .background(YolkColor.shell.ignoresSafeArea())
            } else if ProcessInfo.processInfo.environment["YOLK_ROOM_TRYON"] != nil {
                RoomTryOnPreview()
            } else if ProcessInfo.processInfo.environment["YOLK_VISIT"] != nil
                        || CommandLine.arguments.contains("YOLK_VISIT") {
                VisitView(subject: .friend(SocialPreview.sunny), store: SocialPreview.store,
                          vibe: .matcha, wallet: Wallet(), onReward: { _ in })
            } else if CommandLine.arguments.contains("YOLK_WANDER") {
                WanderArrival(target: SocialPreview.drifter, vibe: .yolk,
                              store: SocialPreview.store, myName: "Yolky", onReward: { _ in })
            } else if CommandLine.arguments.contains("YOLK_DRIFT") {
                // The stranger side of the same view, for eyeballing what differs.
                VisitView(subject: .stranger(SocialPreview.drifter), store: SocialPreview.store,
                          vibe: .matcha, wallet: Wallet(), onReward: { _ in })
            } else if ProcessInfo.processInfo.environment["YOLK_INBOX"] != nil {
                InboxPreview()
            } else if ProcessInfo.processInfo.environment["YOLK_COLORS"] != nil {
                ColorPreview()
            // Accepts a launch ARGUMENT as well as an env var: `SIMCTL_CHILD_*` env
            // vars propagate unreliably through `simctl launch`, whereas `--args` always
            // arrives. Worth copying to the other seams when the screenshot pipeline
            // gets built.
            } else if ProcessInfo.processInfo.environment["YOLK_CARD"] != nil
                        || CommandLine.arguments.contains("YOLK_CARD") {
                SharePreview()
            } else if ProcessInfo.processInfo.environment["YOLK_PLUS"] != nil {
                PlusView(store: .shared, vibe: .matcha)
            } else if ProcessInfo.processInfo.environment["YOLK_ONB"] != nil {
                // Screenshot seam: render the real onboarding flow even when a
                // saved player exists. OnboardingView's own onAppear reads
                // YOLK_ONB and jumps to the requested step.
                OnboardingView { _ in }
            } else if screenshotMode {
                HomeView()
            } else if let player = players.first {
                HomeView(injected: creature(from: player), player: player)
                    .transition(.opacity)
            } else {
                OnboardingView { creature in
                    withAnimation(.easeInOut(duration: 0.5)) { save(creature) }
                }
                .transition(.opacity)
            }
        }
        // The brand is a single warm light palette; lock the scheme so system
        // colours (text fields, placeholders) never flip to dark and vanish.
        .preferredColorScheme(.light)
        .onAppear { YolkNotifications.reschedule() }
    }

    private func save(_ creature: HatchedCreature) {
        let player = Player(
            name: creature.name,
            colorHex: Int(creature.colorHex),
            styleRaw: creature.vibe.style.rawValue,
            startingMoodRaw: creature.startingMood.rawValue,
            equippedItemIDs: []
        )
        player.discoveredSpeciesIDs = SpeciesSets.headStart
        context.insert(player)
    }

    private func creature(from player: Player) -> HatchedCreature {
        // A worn founding species overrides the normal colour + look identity.
        if let fid = player.activeFoundingID, let sp = SpeciesCatalog.founding(id: fid) {
            return HatchedCreature(
                vibe: sp.vibe,
                startingMood: Mood(rawValue: player.startingMoodRaw) ?? .happy,
                name: player.name,
                colorHex: UInt(sp.bodyHex)
            )
        }
        let hex = UInt(player.colorHex)
        let vibe = Vibe(
            id: "yours",
            name: "yours",
            body: Color(hex: hex),
            deep: Color(hex: CreaturePalette.darker(hex)),
            style: CreatureStyle(rawValue: player.styleRaw) ?? .classic,
            accent: player.accentHex.map { Color(hex: UInt($0)) },
            pattern: BodyPattern(rawValue: player.patternRaw) ?? .none,
            bodyStops: ColorShop.bodyStops(forBody: hex)   // premium finish survives relaunch
        )
        return HatchedCreature(
            vibe: vibe,
            startingMood: Mood(rawValue: player.startingMoodRaw) ?? .happy,
            name: player.name,
            colorHex: hex
        )
    }
}

/// Dev seam wrapper: DecorateView with a stub wallet that owns a few pieces.
private struct RoomTryOnPreview: View {
    @State private var themeID = "room-beach"
    @State private var placed: [String: String]? = ["wallC": "decor-poster", "floorL": "decor-lamp"]
    private let stubWallet = Wallet(coins: 999, owned: ["decor-poster", "decor-lamp", "decor-cactus"])
    var body: some View {
        DecorateView(
            vibe: .matcha,
            expression: .happy,
            outfit: [],
            wallet: stubWallet,
            placed: $placed,
            themeID: $themeID,
            onChange: {}
        )
    }
}

/// Dev seam fixtures for the social screens.
private enum SocialPreview {
    static var sunny: Friend {
        Friend(user_id: "demo-sunny", name: "Sunny",
               snapshot: RoomSnapshot(colorHex: 0xFFC23B, styleRaw: "classic", accentHex: nil,
                                      patternRaw: "none", activeFoundingID: nil, moodRaw: "happy",
                                      themeID: "room-beach",
                                      decorIDs: ["decor-bookshelf", "decor-lamp", "decor-cactus", "decor-balloons"],
                                      outfitIDs: ["crown"]))
    }
    /// A stranger's room, for the drift side of VisitView.
    static var drifter: DriftTarget {
        DriftTarget(user_id: "demo-pip", name: "Pip",
                    snapshot: RoomSnapshot(colorHex: 0xB8E6D5, styleRaw: "sprout", accentHex: nil,
                                           patternRaw: "none", activeFoundingID: nil, moodRaw: "curious",
                                           themeID: "room-cozy",
                                           decorIDs: ["decor-lamp", "decor-cactus"],
                                           outfitIDs: []))
    }
    static var store: SocialStore { SocialStore(userID: "preview", myCode: "YOLK-TEST") }
}

/// Dev seam wrapper: the postcard inbox, loaded from the live backend for this install.
private struct InboxPreview: View {
    @State private var store = SocialStore(userID: InstallID.current, myCode: "")
    var body: some View {
        PostcardInbox(store: store).task { await store.load() }
    }
}

/// Dev seam: the rare colours rendered on the creature, to check the finishes.
private struct ColorPreview: View {
    private let picks = ["color-moltengold", "color-obsidian", "color-peacock", "color-galaxy",
                         "color-amethyst", "color-emerald", "color-ruby", "color-ember"]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 22) {
                ForEach(picks, id: \.self) { id in
                    if let s = ColorShop.all.first(where: { $0.id == id }) {
                        VStack(spacing: 4) {
                            YolklingView(vibe: s.vibe(style: .classic, pattern: .none), expression: .happy, size: 110)
                                .frame(height: 130)
                            Text(s.name).font(.caption).foregroundStyle(YolkColor.inkSoft)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(YolkColor.shell.ignoresSafeArea())
    }
}
