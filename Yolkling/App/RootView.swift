import SwiftUI
import SwiftData
import YolklingCore

/// Decides the first surface. A returning player (one saved `Player`) lands on
/// home; a new user gets onboarding, and finishing it saves their creature so
/// onboarding never runs again. The screenshot pipeline (YOLK_VIBE set) skips
/// straight to a demo home for deterministic App Store captures.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    /// Sorted, because `players.first` decides which creature you wake up to.
    ///
    /// An unsorted `@Query` has no defined order. There is only one code path that
    /// inserts a `Player` (`save(_:)` below) so a second row should be impossible — but
    /// "impossible" here rests on a single `if`, not on a constraint, and if one ever did
    /// appear the app would silently alternate between two creatures across launches.
    /// Sorting makes any extra row inert instead. Deliberately NOT paired with a repair
    /// pass that deletes duplicates: creation order is not necessarily progress order, and
    /// deleting the wrong one destroys somebody's creature.
    @Query(sort: \Player.createdAt, order: .forward) private var players: [Player]

    /// Guards against a double-tap on the onboarding button inserting two Players.
    /// `@Query` does not republish within the same runloop turn, so `players.isEmpty` is
    /// still true on the second call — local state is what actually closes the window.
    @State private var saving = false

    /// The Apple user id from the sign-in gate, held until there is a Player to put it
    /// on. Not persisted separately: the Player is the record, and until one exists
    /// there is nothing to attach an identity to.
    @State private var pendingAppleUserID: String?

    /// Whether we are still looking for a creature this account already owns.
    ///
    /// `.checking` is also the state we STAY in after a successful restore: `@Query` does
    /// not republish within the same runloop turn, so flipping to `.done` here would show
    /// a frame of onboarding before `players.first` takes over. The restore path
    /// deliberately leaves this alone and lets the player branch win.
    private enum RestoreCheck { case idle, checking, done }
    @State private var restoreCheck: RestoreCheck = .idle

    /// Mirrors `TrialAccess.isActive` as state, refreshed when the app comes forward.
    /// Read directly it would be a plain function call that SwiftUI cannot observe, so a
    /// trial expiring while the app sat in the background would not take effect until
    /// something unrelated happened to redraw this view.
    @State private var trialActive = TrialAccess.isActive

    // Launch ARGUMENTS as well as env vars: SIMCTL_CHILD_* propagates unreliably through
    // `simctl launch`, while --args always arrives. The App Store screenshot pipeline
    // will want this too.
    /// Whether the screenshot/demo seams are live. FALSE in Release, as a compile-time
    /// constant, so every `seamsOn` branch below is provably unreachable in a shipped
    /// build and the screens behind them cannot be reached by any launch argument or
    /// environment variable.
    ///
    /// These were never reachable by a real user, since iOS gives no way to set either
    /// on an App Store install. This is about not shipping ~30 branches that bypass
    /// onboarding and the sign-in gate, which is a thing a reviewer should never find
    /// and a thing we should not have to argue about.
    private var seamsOn: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    private var screenshotMode: Bool {
        guard seamsOn else { return false }
        return ProcessInfo.processInfo.environment["YOLK_VIBE"] != nil
            || CommandLine.arguments.contains("YOLK_VIBE")
    }

    var body: some View {
        Group {
            if seamsOn, ProcessInfo.processInfo.environment["YOLK_SPECIES"] != nil {
                CollectionView(discovered: Set(SpeciesSets.headStart + [
                    "celestial-sunny yolkstar", "garden-clovi", "cozy-mochi",
                    "ocean-pearlpup", "garden-daisette", "celestial-moonpuff"]))
            } else if seamsOn, ProcessInfo.processInfo.environment["YOLK_FOUNDING"] != nil,
                      let sp = SpeciesCatalog.founding(id: "founding-the very first") {
                FoundingRevealView(species: sp, onWear: {})
            } else if seamsOn, ProcessInfo.processInfo.environment["YOLK_FEEDBACK"] != nil {
                FeedbackView(vibe: .bubble, userID: "preview")
            } else if seamsOn, ProcessInfo.processInfo.environment["YOLK_PACK"] != nil,
                      let sp = SpeciesCatalog.all.first(where: { $0.id == "garden-firefleur" }) {
                PackRevealView(species: sp)
            } else if seamsOn, let slot = ProcessInfo.processInfo.environment["YOLK_COSMETICS"]
                        ?? CommandLine.arguments.first(where: { $0.hasPrefix("YOLK_COSMETICS=") })
                            .map({ String($0.dropFirst("YOLK_COSMETICS=".count)) }) {
                CosmeticPreviewGrid(items: Array(CosmeticCatalog.items(in: CosmeticSlot(rawValue: slot) ?? .hat).reversed()))
            } else if seamsOn, let r = ProcessInfo.processInfo.environment["YOLK_ROOM"] {
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
            } else if seamsOn, ProcessInfo.processInfo.environment["YOLK_ROOM_TRYON"] != nil {
                RoomTryOnPreview()
            } else if seamsOn, ProcessInfo.processInfo.environment["YOLK_VISIT"] != nil
                        || CommandLine.arguments.contains("YOLK_VISIT") {
                VisitView(subject: .friend(SocialPreview.sunny), store: SocialPreview.store,
                          vibe: .matcha, wallet: Wallet(),
                          myOutfit: SocialPreview.myOutfit,
                          myDiscovered: Set(SpeciesSets.headStart),
                          onReward: { _ in })
            } else if seamsOn, CommandLine.arguments.contains("YOLK_TRADE") {
                TradeSheet(store: SocialPreview.store, friend: SocialPreview.sunny, vibe: .yolk,
                           wallet: Wallet(), myOutfit: SocialPreview.myOutfit)
            } else if seamsOn, CommandLine.arguments.contains("YOLK_WANDER") {
                WanderArrival(target: SocialPreview.drifter, vibe: .yolk,
                              store: SocialPreview.store, myName: "Yolky", onReward: { _ in })
            } else if seamsOn, CommandLine.arguments.contains("YOLK_DRIFT") {
                // The stranger side of the same view, for eyeballing what differs.
                VisitView(subject: .stranger(SocialPreview.drifter), store: SocialPreview.store,
                          vibe: .matcha, wallet: Wallet(),
                          myOutfit: SocialPreview.myOutfit, onReward: { _ in })
            } else if seamsOn, CommandLine.arguments.contains("YOLK_HOLO") {
                HoloPreview()
            } else if seamsOn, CommandLine.arguments.contains("YOLK_MOODS") {
                MoodGridPreview()
            } else if seamsOn, ProcessInfo.processInfo.environment["YOLK_INBOX"] != nil {
                InboxPreview()
            } else if seamsOn, ProcessInfo.processInfo.environment["YOLK_COLORS"] != nil {
                ColorPreview()
            // Accepts a launch ARGUMENT as well as an env var: `SIMCTL_CHILD_*` env
            // vars propagate unreliably through `simctl launch`, whereas `--args` always
            // arrives. Worth copying to the other seams when the screenshot pipeline
            // gets built.
            } else if seamsOn, ProcessInfo.processInfo.environment["YOLK_CARD"] != nil
                        || CommandLine.arguments.contains("YOLK_CARD") {
                SharePreview()
            } else if seamsOn, ProcessInfo.processInfo.environment["YOLK_PLUS"] != nil {
                PlusView(store: .shared, vibe: .matcha)
            } else if seamsOn, ProcessInfo.processInfo.environment["YOLK_ONB"] != nil {
                // Screenshot seam: render the real onboarding flow even when a
                // saved player exists. OnboardingView's own onAppear reads
                // YOLK_ONB and jumps to the requested step.
                OnboardingView { _ in }
            } else if screenshotMode {
                HomeView()
            } else if let player = players.first,
                      player.appleUserID != nil || trialActive {
                // An existing creature is never held hostage. Someone who made one on a
                // build where sign-in was optional keeps their yolkling and is asked in
                // Profile instead — locking them out of something they already made,
                // to enforce a rule added afterwards, would be the worst thing this app
                // could do to a person.
                HomeView(injected: creature(from: player), player: player)
                    .transition(.opacity)
            } else if pendingAppleUserID == nil && !trialActive {
                SignInGateView(
                    onSignedIn: { userID in
                        // A creature already exists when the trial has run out. ADOPT it
                        // onto the account rather than falling through to onboarding,
                        // which would build a second one on top of the one they just
                        // spent a day with. This is the single most important line on
                        // this screen.
                        withAnimation(.easeInOut(duration: 0.4)) {
                            pendingAppleUserID = userID
                            restoreCheck = .checking
                        }
                        if let existing = players.first {
                            // A trial creature exists. Before adopting it onto the account
                            // — which the next persist() would push over any cloud backup
                            // — check whether a REAL creature is already saved to this
                            // Apple ID. If so, bring it back rather than letting the
                            // throwaway overwrite it. This runs while RestoringView is up,
                            // BEFORE HomeView mounts and can push, so the correct creature
                            // is in place before anything reaches the server. Without it,
                            // a returning user who took the 24h trial on a fresh install
                            // lost their real creature the instant they signed in.
                            Task { await adoptOrRestore(userID, existing) }
                        } else {
                            Task { await restoreIfPossible(userID) }
                        }
                    },
                    // Offered once. `hasStarted` never goes back to false, so deleting
                    // the creature does not buy another day.
                    onSkip: TrialAccess.hasStarted ? nil : {
                        TrialAccess.begin()
                        withAnimation(.easeInOut(duration: 0.4)) { trialActive = true }
                    },
                    trialExpired: players.first != nil
                )
                .transition(.opacity)
            } else if restoreCheck == .checking {
                RestoringView()
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
        // The trial can lapse while the app is backgrounded, so re-read it on the way
        // forward rather than trusting the value this view was built with.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { trialActive = TrialAccess.isActive }
        }
        .onAppear {
            YolkNotifications.reschedule()
            #if DEBUG
            // Screenshot seam: wind the look-around clock past its end so the expiry
            // screen can be verified without waiting a day. DEBUG only, like every
            // other seam, and inert in Release (see `seamsOn`).
            if ProcessInfo.processInfo.environment["YOLK_TRIAL_EXPIRED"] != nil {
                TrialAccess.expireNow()
                trialActive = false
            }
            #endif
        }
        .overlay(alignment: .bottom) { playerCountOverlay }
    }

    /// `YOLK_PLAYERS` — proves the uniqueness fix without a debugger.
    ///
    /// Two things have to hold: the count stays 1 however hard the onboarding button is
    /// hammered, and `first` names the SAME creature on every launch. The second is what
    /// the `@Query` sort buys, and it is invisible unless something prints it.
    @ViewBuilder private var playerCountOverlay: some View {
        #if DEBUG
        if seamsOn, ProcessInfo.processInfo.environment["YOLK_PLAYERS"] != nil
            || CommandLine.arguments.contains("YOLK_PLAYERS") {
            Text("players=\(players.count)  first=\(players.first?.name ?? "-")")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(.black).foregroundStyle(.white)
                .allowsHitTesting(false)
        }
        #endif
    }

    /// Bring back the creature this Apple id already owns, if there is one.
    ///
    /// Runs BEFORE onboarding, which is the whole point: `HomeView`'s restore cannot help
    /// a fresh install because it needs a `Player` that does not exist yet.
    ///
    /// Falls through to onboarding on every failure, which is exactly the old behaviour,
    /// so the worst case here is the status quo rather than a person stuck on a spinner.
    /// A trial creature exists locally and the person just signed in. Decide between
    /// keeping it (they invested in it) and bringing back a real creature already saved
    /// to this Apple ID (the trial was a throwaway). Runs before HomeView mounts, so the
    /// decision is settled before any backup push can overwrite the cloud creature.
    private func adoptOrRestore(_ userID: String, _ existing: Player) async {
        existing.appleUserID = userID
        try? context.save()

        // No session, or no backup worth restoring → adopt the trial creature as-is.
        // HomeView will back it up. This is the ordinary "first creature on this account".
        guard await waitForSession(upTo: 6),
              let snapshot = await PlayerBackup.pull(appleUserID: userID),
              snapshot.isWorthRestoring
        else { restoreCheck = .done; return }

        // A real creature is saved under this id. Only auto-replace when the local one is
        // an untouched trial — no streak, barely any Dex, welcome grant unspent. If they
        // actually invested in the trial creature, keep it (apply's max/union merge means
        // signing in still can't cost them coins or items either way).
        let localIsThrowaway = existing.careStreak == 0
            && existing.discoveredSpeciesIDs.count <= SpeciesSets.headStart.count
            && existing.coins <= Wallet.welcomeGrant
        if localIsThrowaway {
            snapshot.apply(to: existing)
            try? context.save()
        }
        restoreCheck = .done
    }

    private func restoreIfPossible(_ userID: String) async {
        // The gate fires `onSignedIn` without awaiting the Supabase exchange, on purpose:
        // a server hiccup must not stand between someone and their creature. But the
        // backup RPC authenticates from that session (it ignores any client-supplied id,
        // which is what closed the IDOR), so a restore genuinely cannot happen until the
        // session lands. Wait briefly, then give up rather than block.
        guard await waitForSession(upTo: 6) else { restoreCheck = .done; return }

        guard let snapshot = await PlayerBackup.pull(appleUserID: userID),
              snapshot.isWorthRestoring,
              players.isEmpty, !saving
        else { restoreCheck = .done; return }

        saving = true
        // createdAt comes from the snapshot, not `.now`. It is the creature's birthday and
        // the dateline on its card; a restore that resets it quietly rewrites how long
        // someone has had their yolkling.
        let player = Player(
            name: snapshot.name,
            colorHex: snapshot.colorHex,
            styleRaw: snapshot.styleRaw,
            startingMoodRaw: snapshot.startingMoodRaw,
            appleUserID: userID,
            createdAt: snapshot.createdAt
        )
        snapshot.apply(to: player)
        context.insert(player)
        // Explicit, unlike `save(_:)` below. A restored creature that is lost to a
        // not-yet-flushed autosave would send the person straight back into onboarding,
        // which is the exact bug this method exists to fix.
        try? context.save()
        // restoreCheck stays `.checking`; the `players.first` branch takes over.
    }

    /// Poll for the Supabase session rather than awaiting the sign-in task directly,
    /// because the gate owns that task and deliberately does not hand it back.
    private func waitForSession(upTo seconds: Double) async -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if SupabaseAuth.shared.isSignedIn { return true }
            try? await Task.sleep(for: .milliseconds(150))
        }
        return SupabaseAuth.shared.isSignedIn
    }

    private func save(_ creature: HatchedCreature) {
        guard !saving, players.isEmpty else { return }
        saving = true
        let player = Player(
            name: creature.name,
            colorHex: Int(creature.colorHex),
            styleRaw: creature.vibe.style.rawValue,
            startingMoodRaw: creature.startingMood.rawValue,
            equippedItemIDs: []
        )
        player.discoveredSpeciesIDs = SpeciesSets.headStart
        // The identity from the gate. Set at creation so the very first `persist()`
        // pushes a backup, rather than the creature existing unbacked until the player
        // happens to wander into Profile.
        player.appleUserID = pendingAppleUserID
        // Carried from the priming steps, which now actually request these rather than
        // just talking about them. Without this the home screen would show "connect
        // health" to somebody who had just granted it thirty seconds earlier.
        player.healthConnected = creature.healthConnected
        player.screenTimeConnected = creature.screenTimeConnected
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
                                      outfitIDs: ["crown"]),
               found: ["celestial-stardrop", "garden-sprig", "ocean-guppy", "cozy-mochi",
                       "celestial-ringling", "garden-daisette", "ocean-pearlpup",
                       "cozy-marshmallow", "celestial-galaxia"],
               trust_band: "companion")
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

    /// A stand-in for "what I'm wearing", so the swap preview has something to swap
    /// against in the dev seams. One item per slot, matching `WardrobeStore`.
    static var myOutfit: [Cosmetic] {
        ["flower", "glasses", "scarf"].compactMap { id in
            CosmeticCatalog.all.first { $0.id == id }
        }
    }
}

/// Dev seam: the holo card, one rarity at a time, so each laminate can be judged on its
/// own. The simulator has no gyroscope, so drag the card to tilt it there.
private struct HoloPreview: View {
    private let rarities = Species.Rarity.allCases
    @State private var pick = 1

    /// Flip the whole thing over, so the back can be judged per rarity too.
    @State private var flipped = false
    /// The bond card, which has no rarity and takes its finish from trust instead.
    @State private var bond = false
    @State private var trust: Double = 0.95
    /// Scratch mode. `scratchID` is bumped to hand `CardScratchView` a fresh identity so
    /// toggling it off and on again gives you an unscratched card instead of the one you
    /// already cleared.
    @State private var scratch = false
    @State private var scratchID = 0

    private var bondFace: YolkCardFace {
        .bond(name: "Yolky", vibe: .yolk,
              outfit: ["flower", "scarf"].compactMap { id in
                  CosmeticCatalog.all.first { $0.id == id }
              },
              trust: trust, careDays: 128, focusMinutes: 1284,
              speciesFound: 24, createdAt: .now)
    }

    private var face: YolkCardFace {
        let r = rarities[pick]
        // A real species per rarity where one exists, so the palettes are the ones that
        // will actually ship rather than a swatch. Founding species live in their own
        // array, so `all` has none — hence the explicit rarity override below, without
        // which the founding tab silently showed a common card under a pearl finish.
        let s = SpeciesCatalog.all.first { $0.rarity == r } ?? SpeciesCatalog.all[0]
        var f = YolkCardFace.species(s, discovered: .now, number: 42, outOf: 912)
        f.rarity = r
        f.stats = [
            .init(label: "streak", value: "12", icon: .streak),
            .init(label: "trust", value: "84%", icon: .trust),
            .init(label: "cared", value: "47", icon: .cared),
            .init(label: "focus", value: "9h", icon: .focus),
        ]
        f.outfit = ["flower", "scarf"].compactMap { id in
            CosmeticCatalog.all.first { $0.id == id }
        }
        return f
    }

    /// What the label under the card should say: the laminate name, and where it came
    /// from. Worth printing, because "trust picked this one" is the whole point of the
    /// bond card and is otherwise invisible.
    private var caption: String {
        if bond {
            let stage = TrustStage.from(trust: trust)
            return "\(bondFace.material.label)  ·  trust \(Int(trust * 100))%  ·  \(stage.label)"
        }
        return HoloMaterial.forRarity(rarities[pick]).label
    }

    var body: some View {
        VStack(spacing: YolkSpace.md) {
            Spacer()
            if scratch {
                CardScratchView(face: bond ? bondFace : face, width: 300)
                    .id(scratchID)
            } else if flipped {
                YolkCardBack(rarity: bond ? nil : rarities[pick],
                             width: 300, pose: YolkCard.posed)
            } else {
                YolkCard(face: bond ? bondFace : face, width: 300)
            }
            Spacer()

            Text(caption)
                .font(YolkType.label).foregroundStyle(YolkColor.muted)
                .lineLimit(1).minimumScaleFactor(0.7)

            if bond {
                // The finish ladder, walked by hand. Five trust bands, five laminates.
                Slider(value: $trust, in: 0...1)
                    .padding(.horizontal, YolkSpace.lg)
            } else {
                // Project rule: `YolkSegmented`, never the system segmented control.
                // Dev seams are still screens somebody looks at, and this one exists
                // specifically to judge how things look.
                YolkSegmented(selection: $pick,
                              options: Array(rarities.indices),
                              label: { rarities[$0].rawValue })
                    .padding(.horizontal, YolkSpace.lg)
            }

            HStack(spacing: YolkSpace.sm) {
                Toggle("bond card", isOn: $bond)
                Toggle("face down", isOn: $flipped)
                Toggle("scratch", isOn: $scratch)
            }
            .toggleStyle(.button)
            .font(YolkType.bodySmall)
            .padding(.bottom, YolkSpace.lg)
            // A scratched card stays scratched, so changing what is UNDER it has to hand
            // the view a new identity or you keep looking at the one you already cleared.
            .onChange(of: scratch) { _, _ in scratchID += 1 }
            .onChange(of: pick) { _, _ in scratchID += 1 }
            .onChange(of: bond) { _, _ in scratchID += 1 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(YolkColor.shell.ignoresSafeArea())
    }
}

/// Dev seam: every expression at once, so a new pose can be checked against the ones it
/// has to be distinguishable FROM rather than judged on its own.
///
/// Rendered `frozenAt` so the grid is one deterministic frame — twenty-one live clocks
/// would be pointless here, and a still is what makes two similar poses comparable.
private struct MoodGridPreview: View {
    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 4)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: YolkSpace.md) {
                ForEach(YolkExpression.all, id: \.0) { name, pose in
                    VStack(spacing: 2) {
                        YolklingView(vibe: .yolk, expression: pose, size: 76,
                                     frozenAt: YolklingView.posedT)
                            .frame(height: 112)
                        Text(name).font(.caption2.weight(.medium))
                            .foregroundStyle(YolkColor.inkSoft).lineLimit(1)
                    }
                }
            }
            .padding(YolkSpace.md)
        }
        .background(YolkColor.shell.ignoresSafeArea())
    }
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
