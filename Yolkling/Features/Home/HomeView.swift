import SwiftUI
import SwiftData

/// The game hub. Top bar (streak + Yolks), your creature (tap to pet), today's
/// care actions (which earn Yolks), and the bottom nav. Care actions are stubs
/// for now; each becomes a real feature (mood check-in, focus session, visits).
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    /// `YOLK_PROBE=<itemID>` — draws the ownership probe overlay. Debug-only seam.
    @State private var probeID: String?
    /// Our own menu rather than a native one, so the rows can be drawn. See `visitMenu`.
    @State private var showVisitMenu = false
    private let injected: HatchedCreature?
    private let player: Player?
    @State private var vibeIndex: Int
    @State private var moodIndex: Int
    @State private var reacting = false
    @State private var wardrobe: WardrobeStore
    @State private var wallet: Wallet
    @State private var showWardrobe = false
    @State private var showProfile = false
    @State private var showCheckIn = false
    @State private var showFocus = false
    @State private var showReferral = false
    @State private var showCollection = false
    @State private var lastCheckIn: Date?
    @State private var focusEarnedToday = 0
    @State private var focusEarnedDate: Date?
    @State private var dialog: YolkDialog?
    @State private var careStreak: Int
    @State private var restTokens: Int
    @State private var lastCareDate: Date?
    @State private var weekStart: Date?
    @State private var weekCareDays: Int
    @State private var weeklyClaimed: Bool
    @State private var discovered: Set<String>
    @State private var discoveryReveal: Species?
    @State private var colorVibe: Vibe?
    @State private var showRoom = false
    @Environment(Router.self) private var router
    @State private var showFriends = false
    @State private var showDrift = false
    /// Owned here rather than per-screen so one refresh populates SeasonWindows for
    /// everything that reads it — including SpeciesSet, which the widget also compiles.
    @State private var events = EventStore()
    /// Where the yolkling got to on its own, if anywhere.
    @State private var wandered: DriftTarget?
    @AppStorage("yolk.healthPromptDismissed") private var healthPromptDismissed = false
    @State private var placedByZone: [String: String]? = nil
    @State private var health = HealthService()
    @State private var screenTime = ScreenTimeService()
    @State private var waveToken = 0
    @State private var celebrateToken = 0
    @State private var petToken = 0
    @State private var showTutorial = false
    @State private var demoTrust: Double? = nil   // screenshot seam override
    @State private var demoHour: Int? = nil       // screenshot seam override for time-of-day
    @State private var roomThemeID: String
    /// Who is round at yours, if anyone. A display choice, not a second creature.
    @State private var guestSpeciesID: String?
    @State private var showWidgetNudge = false
    @State private var showWidgetHowTo = false

    private let focusDailyCap = 60

    init(injected: HatchedCreature? = nil, player: Player? = nil) {
        self.injected = injected
        self.player = player
        let env = ProcessInfo.processInfo.environment
        let v = Int(env["YOLK_VIBE"] ?? "0") ?? 0
        _vibeIndex = State(initialValue: min(max(v, 0), Vibe.all.count - 1))
        let startMood: Int
        if let creature = injected {
            startMood = Mood.allCases.firstIndex(of: creature.startingMood) ?? 0
        } else {
            startMood = Int(env["YOLK_MOOD"] ?? "0") ?? 0
        }
        _moodIndex = State(initialValue: min(max(startMood, 0), Mood.allCases.count - 1))

        // Restore wallet + outfit from the saved player (or defaults for demo).
        let w = Wallet(
            coins: player?.coins ?? Wallet.welcomeGrant,
            owned: Set(player?.ownedItemIDs ?? []),
            synced: Set(player?.syncedItemIDs ?? [])
        )
        _wallet = State(initialValue: w)
        let store = WardrobeStore()
        // Built after the wallet, because restoring an outfit is ownership-gated now:
        // you can trade away a hat while wearing it, and it must not come back on at
        // launch just because the id is still in `equippedItemIDs`.
        store.restore(equippedIDs: player?.equippedItemIDs ?? [], owns: w.owns)
        _wardrobe = State(initialValue: store)
        _lastCheckIn = State(initialValue: player?.lastCheckInDate)
        _focusEarnedToday = State(initialValue: player?.focusEarnedToday ?? 0)
        _focusEarnedDate = State(initialValue: player?.focusEarnedDate)
        _careStreak = State(initialValue: player?.careStreak ?? 0)
        _restTokens = State(initialValue: player?.restTokens ?? 2)
        _lastCareDate = State(initialValue: player?.lastCareDate)
        _weekStart = State(initialValue: player?.weekStart)
        _weekCareDays = State(initialValue: player?.weekCareDays ?? 0)
        _weeklyClaimed = State(initialValue: player?.weeklyClaimed ?? false)
        _discovered = State(initialValue: Set(player?.discoveredSpeciesIDs ?? SpeciesSets.headStart))
        _roomThemeID = State(initialValue: player?.roomThemeID ?? "room-cozy")
        _guestSpeciesID = State(initialValue: player?.guestSpeciesID)
        _placedByZone = State(initialValue: player?.placedDecorByZone)
    }

    private var vibe: Vibe { colorVibe ?? injected?.vibe ?? Vibe.all[vibeIndex] }
    private var originalBodyHex: Int { player?.colorHex ?? Int(injected?.colorHex ?? 0xFFC23B) }
    private var baseMood: Mood { Mood.allCases[moodIndex] }
    /// The relationship, earned only by taking care of yourself (docs/RELATIONSHIP.md).
    private var trust: Double { demoTrust ?? player?.trust ?? 0 }
    private var trustStage: TrustStage { TrustStage.from(trust: trust) }

    private var currentHour: Int { demoHour ?? Calendar.current.component(.hour, from: Date()) }
    private var dayPhase: YolkExpression.DayPhase { YolkExpression.phase(forHour: currentHour) }

    /// Liveliness fed by real life: Health (steps + sleep) and, additively, time off
    /// the phone. Screen Time can only RAISE vitality, never lower it, so a heavy
    /// screen day never reads as "sick" (WELLBEING.md: sleepy, never sick).
    private var livingVitality: Double {
        var v = health.authorized ? health.vitality : 0.5
        if screenTime.available { v = min(1, v + 0.15 * screenTime.offScreenProgress) }
        return v
    }

    private var shownExpression: YolkExpression {
        if reacting { return .affectionate }
        var e = baseMood.expression
        if health.authorized || screenTime.available { e = e.energized(by: livingVitality) }
        e = e.warmed(by: trust)
        return e.atPhase(dayPhase, sleptWell: health.authorized && health.sleepHours >= 7)
    }
    private var heading: String { injected?.name ?? "your little guy" }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        // More of the frame for the creature: it's the product, and the
                        // panel below it is support, not a peer.
                        creatureHero(min(380, max(256, geo.size.height * 0.54)))
                        Spacer(minLength: 0)
                        todayPanel
                    }
                    .frame(minHeight: geo.size.height)   // center when it fits, scroll when it doesn't
                }
            }
            bottomNav
        }
        .background(YolkColor.shell.ignoresSafeArea())
        .background {
            // Hidden host: mounting it runs the DeviceActivityReport extension, which
            // writes today's off-phone figure to the App Group for us to read back.
            if screenTime.status == .approved { ScreenTimeReportHost() }
        }
        .sheet(isPresented: $showWardrobe) {
            ShopHomeView(vibe: vibe, store: wardrobe, wallet: wallet,
                         originalBodyHex: originalBodyHex, originalAccentHex: player?.accentHex,
                         onColor: applyColor)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(vibe: vibe, name: heading, player: player)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showReferral) {
            ReferralView(vibe: vibe, player: player) { bonus in
                wallet.earn(bonus)
                persist()
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showCollection) {
            CollectionView(discovered: discovered, events: events, vibe: vibe,
                           onGranted: { ids in wallet.grant(ids); persist() },
                           inviteCode: player?.referralCode ?? "",
                           guestID: guestSpeciesID,
                           onSetGuest: { id in
                               withAnimation(.snappy) { guestSpeciesID = id }
                               player?.guestSpeciesID = id
                               persist()
                           })
                .presentationDetents([.large])
        }
        .fullScreenCover(item: $discoveryReveal) { sp in
            // The creature walks it home rather than the card just materialising. Same
            // discovery, same scratch, but now something went and got it — which is the
            // one moment in this app where the creature acts without being asked, and it
            // used to be completely invisible.
            WanderHomeView(
                vibe: vibe,
                name: heading,
                face: .species(sp,
                               discovered: .now,
                               number: SpeciesSets.dexNumber(of: sp.id),
                               outOf: SpeciesSets.dexTotal)
            )
        }
        .sheet(isPresented: $showRoom) {
            DecorateView(vibe: vibe, expression: shownExpression, outfit: wardrobe.outfit,
                         wallet: wallet, placed: $placedByZone, themeID: $roomThemeID,
                         onChange: { player?.placedDecorByZone = placedByZone; persist() })
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showFriends) {
            FriendsView(store: SocialStore(userID: backendUserID, myCode: player?.referralCode ?? ""),
                        vibe: vibe, player: player, myName: heading, mySnapshot: mySnapshot(),
                        wallet: wallet,
                        onReward: { amt in wallet.earn(amt); persist() })
                .presentationDetents([.large])
        }
        .sheet(item: $wandered) { target in
            WanderArrival(target: target, vibe: vibe,
                          store: SocialStore(userID: backendUserID, myCode: player?.referralCode ?? ""),
                          myName: heading,
                          onReward: { amt in wallet.earn(amt); persist() })
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showDrift) {
            DriftSheet(store: SocialStore(userID: backendUserID, myCode: player?.referralCode ?? ""),
                       vibe: vibe, myName: heading, mySnapshot: mySnapshot(), wallet: wallet,
                       onReward: { amt in wallet.earn(amt); persist() })
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showWidgetHowTo) {
            WidgetHowToView {
                player?.widgetNudgeShown = true
                showWidgetNudge = false
                persist()
            }
            .presentationDetents([.medium])
        }
        .onChange(of: roomThemeID) { _, _ in persist() }
        .sheet(isPresented: $showCheckIn) {
            MoodCheckInView(vibe: vibe, alreadyToday: checkedInToday, onPick: checkIn)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
        .fullScreenCover(isPresented: $showFocus) {
            FocusView(vibe: vibe, name: heading, colorHex: Int(injected?.colorHex ?? 0xFFC23B)) { minutes in
                rewardFocus(minutes)
            }
        }
        .yolkDialog($dialog)
        .onAppear { onAppearWork() }
        // The proposer learns nothing when the other side accepts — `respond_trade` tells
        // only the responder. Without a foreground pull, A keeps and re-uploads an item
        // they gave away, forever. This is the half of the fix the trade sheet can't do.
        .onChange(of: scenePhase) { _, phase in if phase == .active { reconcileWallet() } }
        .onChange(of: wallet.coins) { _, _ in persist() }
        .onChange(of: wallet.owned) { _, _ in persist() }
        .onChange(of: wardrobe.equipped) { _, _ in persist() }
        .onChange(of: player?.appleUserID) { _, newID in
            guard let newID else { return }
            reconcileWallet()   // just signed in → restore + sync
            Task { await offerRestore(appleUserID: newID) }
            // Alias RevenueCat's anonymous user onto the Apple id in the SAME place, so
            // exactly one seam knows about the signed-out → signed-in transition.
            Task { await SubscriptionStore.shared.identify(newID) }
        }
        // A tapped invite link. `.task` covers the cold-start case (the link was
        // buffered before a Player existed and Router restored it at init, so no
        // change ever fires); `.onChange` covers a link arriving while running.
        .task {
            events.userID = backendUserID
            await events.refresh()

            // Did it go anywhere on its own? Rolls once a day, on first open — which is
            // when a surprise is worth the most and when "while you were away" is
            // literally true. Deliberately after the season refresh so a slow network
            // can't hold up the moment.
            //
            // Gated on having actually looked after yourself recently, for two reasons.
            //
            // The design one: the creature going out is supposed to be EARNED. Care for
            // yourself, your creature has a good day, it comes home with something. An
            // ungated roll fired the instant onboarding finished, so a brand-new player
            // was told their yolkling "wandered off" before they had done a single thing
            // — which makes "while you were away" a lie and buries the first run under a
            // modal.
            //
            // The correctness one: the server's nightly roll (roll_nightly_drifts) gates
            // on lastCareDate inside drift_care_window(). The client rolling on a looser
            // rule than the server means the two disagree about who is eligible.
            if wandered == nil, hasCaredRecently {
                let social = SocialStore(userID: backendUserID, myCode: player?.referralCode ?? "")
                wandered = await social.wanderIfDue()
            }

            // Credit any Yolks RevenueCat has granted since we last looked. Idempotent:
            // the high-water mark only moves after a successful credit, so a crash
            // between the two costs the player nothing.
            let stipend = await SubscriptionStore.shared.claimStipend()
            if stipend > 0 {
                wallet.earn(stipend)
                persist()
                dialog = YolkDialog(
                    icon: .coins, title: "thank you",
                    message: "\(stipend) \(Currency.name) landed, for keeping this going.",
                    primaryTitle: "lovely"
                )
            }
        }
        .task { if router.pending != nil { showFriends = true } }
        .onChange(of: router.pending) { _, link in if link != nil { showFriends = true } }
        .overlay {
            if showTutorial { HomeTutorial(name: heading, onDone: finishTutorial) }
        }
        .overlay(alignment: .top) { probeOverlay }
        .yolkMenu(isPresented: $showVisitMenu, alignment: .bottom, anchor: .top) {
            visitMenu.padding(.bottom, YolkSpace.lg)
        }
    }

    /// One card, two destinations. Wandering is the once-a-day ritual and it goes first;
    /// friends are always there.
    private var visitMenu: some View {
        YolkMenu {
            YolkMenuRow(glyph: .wander, title: "let it wander",
                        detail: "somewhere new, once a day") {
                Haptics.shared.select()
                showVisitMenu = false
                showDrift = true
            }
            YolkMenuDivider()
            YolkMenuRow(glyph: .friends, title: "visit a friend",
                        detail: "see their room") {
                Haptics.shared.select()
                showVisitMenu = false
                showFriends = true
            }
        }
    }

    /// One screenshot-legible line answering the only questions that matter for the
    /// ownership fixes: does the client think you own it, does it believe the SERVER
    /// thinks so, and are you still wearing it.
    ///
    /// `owned` vs `synced` is the whole distinction `Wallet.syncedIDs` exists for, and
    /// seeing both is what separates "the server removed this" from "the server never
    /// heard of it" without attaching a debugger.
    @ViewBuilder private var probeOverlay: some View {
        #if DEBUG
        if let probeID {
            let cosmetic = CosmeticCatalog.all.first { $0.id == probeID }
            Text("\(probeID)  owned=\(wallet.owned.contains(probeID) ? "Y" : "N")"
                 + "  synced=\(wallet.syncedIDs.contains(probeID) ? "Y" : "N")"
                 + "  worn=\(wardrobe.outfit.contains { $0.id == probeID } ? "Y" : "N")"
                 + "  owns=\(cosmetic.map { wallet.owns($0) ? "Y" : "N" } ?? "-")")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(.black).foregroundStyle(.white)
                .allowsHitTesting(false)
        }
        #endif
    }

    private func maybeShowTutorial() {
        guard let p = player, !p.tutorialSeen else { return }
        Task { try? await Task.sleep(for: .seconds(0.6)); withAnimation { showTutorial = true } }
    }

    private func maybeShowWidgetNudge() {
        guard let p = player, !p.widgetNudgeShown, !placedDecor.isEmpty else { return }
        showWidgetNudge = true
    }

    private func finishTutorial() {
        withAnimation { showTutorial = false }
        player?.tutorialSeen = true
        try? context.save()
    }

    /// Write the live wallet + outfit back to the saved player.
    private func persist() {
        guard let player else { return }
        // FIRST, before anything reads the outfit. persist() fires on nearly every
        // interaction, which makes it the one write barrier a prune cannot be forgotten
        // at — and it stops a traded-away item reaching `equippedItemIDs`, the widget, or
        // `mySnapshot().outfitIDs`, which is what friends see.
        wardrobe.prune(owns: wallet.owns)
        player.coins = wallet.coins
        player.ownedItemIDs = Array(wallet.owned)
        player.syncedItemIDs = Array(wallet.syncedIDs)
        player.equippedItemIDs = wardrobe.outfit.map(\.id)
        player.discoveredSpeciesIDs = Array(discovered)
        player.careStreak = careStreak
        player.restTokens = restTokens
        player.lastCareDate = lastCareDate
        player.weekStart = weekStart
        player.weekCareDays = weekCareDays
        player.weeklyClaimed = weeklyClaimed
        player.roomThemeID = roomThemeID
        player.guestSpeciesID = guestSpeciesID
        player.placedDecorByZone = placedByZone
        try? context.save()
        pushWalletToServer()
        publishWidget()
        // Cloud backup, throttled to once every few minutes inside PlayerBackup — this
        // fires on nearly every interaction and the creature changes meaningfully a few
        // times a day, not a few times a second.
        if let uid = player.appleUserID {
            Task { await PlayerBackup.push(player, appleUserID: uid) }
        }
    }

    /// Publish the current yolk look to the App Group so the home-screen widget reflects it.
    private func publishWidget() {
        WidgetPublisher.publish(name: heading, room: mySnapshot())
    }

    /// Everything that runs once when home appears.
    ///
    /// Extracted from an inline `.onAppear` closure because `body`'s modifier chain had
    /// grown past what the type-checker will solve in reasonable time — adding one more
    /// `.onChange` tipped it over. Eight calls in a trailing closure are eight more
    /// expressions to infer; a single method call is one.
    ///
    /// Note `reconcileWallet()` REPLACES the bare `pushWalletToServer()` that used to be
    /// here. If both ran, the push would re-insert a traded-away item before the pull
    /// could read it — the duplication bug, restaged.
    private func onAppearWork() {
        applyScreenshotSeams()
        applyTrustDecay()
        restoreHealth()
        restoreScreenTime()
        reconcileWallet()
        helloWaveIfTrusted()
        maybeShowTutorial()
        migratePlacedDecorIfNeeded()
        maybeShowWidgetNudge()
    }

    /// Mirror the wallet to the server when signed in (durable + cross-device, #11).
    /// Best-effort + fire-and-forget; offline / signed-out play stays fully local.
    private func pushWalletToServer() {
        guard let uid = player?.appleUserID else { return }
        let coins = wallet.coins
        let owned = Array(wallet.owned)
        Task {
            guard let s = await SupabaseClient.shared.pushWallet(userID: uid, coins: coins, owned: owned)
            else { return }
            // Only a CONFIRMED push may mark ids synced. A dropped request has to leave
            // them unsynced, or the next reconcile reads the server's silence about them
            // as a removal and deletes a purchase that never landed.
            wallet.markSynced(Set(s.owned))
            player?.syncedItemIDs = s.owned
            try? context.save()
        }
    }

    /// Adopt the server's inventory as the record of **what** you own.
    ///
    /// Replaces the old `adoptServerWallet`, which unioned — and a union cannot express a
    /// removal. `respond_trade` deletes the row for an item you traded away, but the
    /// client never saw it, so the next `push_wallet` (insert-only) put it straight back
    /// and both players ended up owning it.
    ///
    /// **Gated on `appleUserID`, exactly like `pushWalletToServer`.** A signed-out player
    /// has never pushed, so their server inventory is empty; adopting it would delete
    /// everything they have. This guard is the difference between a fix and a disaster.
    ///
    /// Coins are merged rather than replaced — `gift_yolks` writes them server-side, so
    /// taking the lower of the two could destroy a gift that just arrived.
    private func reconcileWallet() {
        guard let uid = player?.appleUserID else { return }
        Task {
            if let s = await SupabaseClient.shared.walletState(userID: uid) {
                wallet.reconcile(serverOwned: Set(s.owned))
                if s.coins > wallet.coins {
                    wallet.adopt(coins: s.coins, owned: wallet.owned)
                }
            }
            persist()   // prunes the outfit, writes locally, pushes the settled state up
        }
    }

    private var checkedInToday: Bool {
        guard let date = lastCheckIn else { return false }
        return Calendar.current.isDateInToday(date)
    }

    /// Apply a mood check-in: set the creature's mood, and award Yolks once a day.
    /// The once-a-day cap holds with or without a saved player (no spamming).
    private func checkIn(_ mood: Mood) {
        showCheckIn = false
        let first = !checkedInToday
        withAnimation(.easeInOut(duration: 0.4)) {
            moodIndex = Mood.allCases.firstIndex(of: mood) ?? moodIndex
        }
        player?.startingMoodRaw = mood.rawValue
        if first {
            Haptics.shared.reward()
            wallet.earn(10)
            lastCheckIn = .now
            player?.lastCheckInDate = .now
            advanceStreak()
            careForSelf()   // caring for yourself earns the yolk's trust (once/day)
            // The chase payoff: caring discovers a new friend for the collection.
            if let id = DiscoveryEngine.pickNext(discovered: discovered),
               let sp = SpeciesCatalog.all.first(where: { $0.id == id }) {
                discovered.insert(id)
                player?.discoveredSpeciesIDs = Array(discovered)
                // let the check-in sheet dismiss, then open the pack ceremony
                Task {
                    try? await Task.sleep(for: .seconds(0.4))
                    discoveryReveal = sp
                }
            } else {
                dialog = YolkDialog(icon: .coins, title: "checked in",
                                    message: "+10 Yolks. your yolkling feels you.", primaryTitle: "nice")
            }
        }
        persist()
    }

    /// Apply a rare colour from the shop: recolour live + persist to the player.
    private func applyColor(_ v: Vibe, _ bodyHex: Int, _ accentHex: Int?) {
        withAnimation(.spring) { colorVibe = v }
        player?.colorHex = bodyHex
        player?.accentHex = accentHex
        try? context.save()
        publishWidget()
    }

    /// Advance the kind streak for the first care of the day, and pay streak
    /// milestone + weekly-challenge bonuses (earning speeds up by doing more).
    private func advanceStreak() {
        let firstToday = lastCareDate.map { !Calendar.current.isDateInToday($0) } ?? true
        let r = StreakEngine.recordCare(streak: careStreak, lastCare: lastCareDate, restTokens: restTokens)
        withAnimation(.snappy) { careStreak = r.streak }
        restTokens = r.restTokens
        lastCareDate = .now
        player?.careStreak = r.streak
        player?.restTokens = r.restTokens
        player?.lastCareDate = .now
        // Lifetime count, incremented once per day on the first care of that day. This is
        // the number the bond card carries: `careStreak` resets on a gap, so it can only
        // ever say how you are doing lately, never how long you have been here.
        if firstToday { player?.totalCareDays += 1 }

        guard firstToday else { persist(); return }

        var bonus = 0
        var notes: [String] = []
        if let b = Rewards.streakBonus(for: r.streak) {
            bonus += b
            notes.append("\(r.streak)-day streak, +\(b)")
        }
        rolloverWeekIfNeeded()
        weekCareDays += 1
        if weekCareDays >= Rewards.weeklyTarget && !weeklyClaimed {
            weeklyClaimed = true
            bonus += Rewards.weeklyReward
            notes.append("weekly challenge done, +\(Rewards.weeklyReward)")
        }
        if bonus > 0 {
            wallet.earn(bonus)
            Haptics.shared.reward()
            dialog = YolkDialog(icon: .coins, title: "nice work",
                                message: notes.joined(separator: ", and ") + " Yolks. keep going.", primaryTitle: "love it")
        }
        persist()
    }

    /// Reset the weekly challenge when a new calendar week starts.
    private func rolloverWeekIfNeeded() {
        let cal = Calendar.current
        let thisWeek = cal.dateInterval(of: .weekOfYear, for: .now)?.start
        if weekStart == nil || (thisWeek != nil && !cal.isDate(weekStart!, equalTo: thisWeek!, toGranularity: .day)) {
            weekStart = thisWeek
            weekCareDays = 0
            weeklyClaimed = false
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            pill {
                YolkGlyph(kind: .streak, size: 16, weight: 0.115).foregroundStyle(Color(hex: 0xFF8A3D))
                if careStreak == 0 {
                    // A brand-new player used to be greeted by "0 days" — a scoreboard
                    // opening at nil. Endowed progress (MONETIZATION.md lever 3) says
                    // never start anyone at zero; "day one" is the same fact, told as a
                    // beginning rather than a deficit.
                    Text("day one").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                } else {
                    Text("\(careStreak)").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                        .contentTransition(.numericText())
                    Text(careStreak == 1 ? "day" : "days").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                }
                if restTokens > 0 {
                    YolkGlyph(kind: .leaf, size: 13, weight: 0.115).foregroundStyle(Color(hex: 0x9AC77E))
                }
            }
            Spacer()
            pill {
                YolkCoin(size: 17)
                Text("\(wallet.coins)").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                    .contentTransition(.numericText())
                Text(Currency.name).font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            }
        }
        .padding(.horizontal, YolkSpace.lg)
        .padding(.top, YolkSpace.sm)
    }

    private func pill<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        HStack(spacing: 5, content: content)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(YolkColor.shell2, in: Capsule())
    }

    // MARK: Creature

    /// The room scene shown on home: the player's applied theme + the decor they own.
    /// Whoever is round at yours. Resolved from the id rather than stored as a `Species`,
    /// so a species that leaves the catalog cannot strand a dangling guest.
    private var guest: Species? {
        guard let guestSpeciesID else { return nil }
        return SpeciesCatalog.all.first { $0.id == guestSpeciesID }
    }

    private var homeTheme: RoomTheme { RoomThemes.all.first { $0.id == roomThemeID } ?? RoomThemes.cozy }

    /// Pure read: the placed pieces in display order. No mutation here.
    private var placedDecor: [RoomDecor] {
        let owned = wallet.owned
        guard let dict = placedByZone else {
            // pre-migration fallback (migration runs in onAppear): show owned, capped
            return Array(RoomDecorCatalog.all.filter { owned.contains($0.id) }.prefix(7))
        }
        return RoomZones.displayOrder.compactMap { zone in
            guard let id = dict[zone.rawValue], owned.contains(id) else { return nil }
            return RoomDecorCatalog.byID(id)
        }
    }

    /// Runs once in onAppear: migrates placedDecorByZone on first launch after the update.
    private func migratePlacedDecorIfNeeded() {
        guard let p = player, p.placedDecorByZone == nil else { return }
        _ = p.placedDecor(ownedIDs: wallet.owned)   // migrates + persists into the model
        placedByZone = p.placedDecorByZone
        try? context.save()
    }

    /// Stable id for backend calls (Apple id once signed in, else the install id).
    private var backendUserID: String { player?.backendUserID ?? InstallID.current }

    /// The player's creature + room, packaged for friends to visit (publish_room).
    private func mySnapshot() -> RoomSnapshot {
        RoomSnapshot(
            colorHex: player?.colorHex ?? Int(injected?.colorHex ?? 0xFFC23B),
            styleRaw: player?.styleRaw ?? vibe.style.rawValue,
            accentHex: player?.accentHex,
            patternRaw: player?.patternRaw ?? vibe.pattern.rawValue,
            activeFoundingID: player?.activeFoundingID,
            moodRaw: baseMood.rawValue,
            themeID: roomThemeID,
            decorIDs: placedDecor.map { $0.id },
            outfitIDs: wardrobe.outfit.map { $0.id },
            streak: careStreak,
            hour: Calendar.current.component(.hour, from: Date())
        )
    }

    private func creatureHero(_ heroHeight: CGFloat) -> some View {
        VStack(spacing: YolkSpace.sm) {
            Text(heading)
                .font(YolkType.heading)
                .foregroundStyle(YolkColor.ink)

            // The yolk lives in its decorated room right on home. Tap the yolk to
            // pet it; tap anywhere else in the room to open it full-screen.
            ZStack {
                RoomView(vibe: vibe, expression: shownExpression, theme: homeTheme,
                         outfit: wardrobe.outfit, decor: placedDecor, showCreature: false,
                         guest: guest)
                    .onTapGesture { Haptics.shared.select(); showRoom = true }

                GeometryReader { geo in
                    YolklingView(vibe: vibe, expression: shownExpression,
                                 size: geo.size.height * RoomView.creatureSpot.size,
                                 outfit: wardrobe.outfit, waveToken: waveToken,
                                 celebrateToken: celebrateToken, petToken: petToken)
                        .contentShape(Rectangle())
                        .position(x: geo.size.width * RoomView.creatureSpot.x,
                                  y: geo.size.height * RoomView.creatureSpot.y)
                        .onTapGesture { pet() }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button { Haptics.shared.select(); showRoom = true } label: {
                    Label("Decorate", systemImage: "pencil")
                        .font(YolkType.bodySmall.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(YolkColor.ink)
                }
                .buttonStyle(.plain).padding(YolkSpace.md)
            }
            .frame(height: heroHeight)
            .padding(.horizontal, YolkSpace.lg)

            // The creature's own line, promoted to be the thing you actually read.
            //
            // It used to sit in caption2 at 75% opacity BELOW a letterspaced caps mood
            // label — so the loudest text on screen named a mood the face was already
            // showing, and the warmest thing in the app was the faintest. The label is
            // gone: the creature says it better than a caption can.
            Text(dayPhase == .night ? "getting sleepy · wind down too?" : trustStage.label)
                .font(YolkType.body)
                .foregroundStyle(YolkColor.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, YolkSpace.lg)
        }
    }

    // MARK: Today's care

    private var todayPanel: some View {
        VStack(alignment: .leading, spacing: YolkSpace.sm) {
            // Sentence case, not letterspaced caps. The caps idiom read as a system
            // label — a section header in a settings app, not something a warm creature
            // would put above three small kindnesses.
            Text("today")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.muted)
                .padding(.horizontal, YolkSpace.lg)

            HStack(spacing: YolkSpace.sm) {
                careCard("check in", reward: 10, icon: .trust, done: checkedInToday) { showCheckIn = true }
                careCard("focus", reward: 20, icon: .focus) { showFocus = true }
                // One card, two destinations, rather than adding a fourth card to a
                // screen that already has too many. Wandering is the once-a-day ritual;
                // friends are always there.
                Button {
                    Haptics.shared.tick()
                    withAnimation(.snappy(duration: 0.24)) { showVisitMenu = true }
                } label: {
                    careCardLabel("visit", reward: 5, icon: .friends, done: false)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, YolkSpace.lg)

            // Three kinds of thing used to stack here as equal-weight cards: things you
            // DO, a thing to SET UP, and passive STATUS. That flat hierarchy is what made
            // the panel read as a dashboard. Now they're separated by kind and by weight.
            if health.available, health.authorized {
                livingCard.padding(.horizontal, YolkSpace.lg)   // real data, earns a card
            } else if health.available, shouldOfferHealth {
                healthPrompt.padding(.horizontal, YolkSpace.lg) // earned, and dismissible
            }
            weeklyLine
            if showWidgetNudge { widgetNudgeCard }
        }
        .padding(.bottom, YolkSpace.md)
    }

    private var widgetNudgeCard: some View {
        HStack(spacing: YolkSpace.sm) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.title3)
                .foregroundStyle(YolkColor.ink)
            VStack(alignment: .leading, spacing: 2) {
                Text("put your yolk on your home screen")
                    .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                Button { showWidgetHowTo = true } label: {
                    Text("see how")
                        .font(YolkType.bodySmall.weight(.semibold)).foregroundStyle(YolkColor.shell)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(YolkColor.ink, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Button {
                withAnimation { showWidgetNudge = false }
                player?.widgetNudgeShown = true
                persist()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(YolkColor.muted)
                    .padding(8)
                    .background(YolkColor.shell2, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 11).padding(.horizontal, YolkSpace.md)
        .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, YolkSpace.lg)
    }

    // MARK: Grow by living (HealthKit)

    private var stepGoal: Int { 5000 }
    private var claimedLivingToday: Bool { player?.livingClaimDate.map { Calendar.current.isDateInToday($0) } ?? false }
    private var livingHasReward: Bool { !claimedLivingToday && (health.steps >= stepGoal || health.sleepHours >= 7) }

    @ViewBuilder private var livingCard: some View {
        if health.authorized {
            VStack(alignment: .leading, spacing: YolkSpace.sm) {
                HStack {
                    Text("today, by living").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                    Spacer()
                    if claimedLivingToday {
                        Text("collected").font(.caption2).foregroundStyle(YolkColor.muted)
                    }
                }
                HStack(spacing: YolkSpace.sm) {
                    LivingTile(glyph: .steps,
                               value: health.steps > 0 ? "\(health.steps)" : nil,
                               label: "steps",
                               progress: Double(health.steps) / Double(stepGoal),
                               hit: health.steps >= stepGoal,
                               emptyWord: "let's go",
                               tint: YolkColor.mint)

                    LivingTile(glyph: .sleep,
                               value: health.sleepHours > 0 ? String(format: "%.1fh", health.sleepHours) : nil,
                               label: "sleep",
                               progress: health.sleepHours / 7,
                               hit: health.sleepHours >= 7,
                               emptyWord: "tonight",
                               tint: YolkColor.sky)

                    // Three states, not two. `available` needs BOTH approval AND a figure
                    // from the report extension, so someone who had just granted Screen
                    // Time landed in the same branch as someone never asked: a padlock,
                    // the word "soon", and a button that re-requested a permission they
                    // had already given and then visibly did nothing.
                    if screenTime.available, let off = screenTime.offScreenHours {
                        // Below half an hour there is no figure worth printing: early in
                        // the day "off phone" is legitimately near zero, and "0.0h" under
                        // a success outline celebrates nothing while reading as a fault.
                        // The budget is still intact, so the tile stays warm and waits.
                        LivingTile(glyph: .phone,
                                   value: off >= 0.5 ? String(format: "%.1fh", off) : nil,
                                   label: "off phone",
                                   progress: screenTime.offScreenProgress,
                                   hit: screenTime.hitGoal && off >= 1,
                                   emptyWord: "counting",
                                   tint: YolkColor.grape)
                    } else if screenTime.status == .approved {
                        // Approved, but no figure yet. Deliberately not tappable: there
                        // is nothing left to ask for, and a button that does nothing is
                        // the bug being fixed.
                        LivingTile(glyph: .phone, value: nil, label: "off phone",
                                   progress: 0, hit: false,
                                   emptyWord: "counting", tint: YolkColor.grape)
                    } else {
                        LivingTile(glyph: .phone, value: nil, label: "off phone",
                                   progress: 0, hit: false,
                                   emptyWord: "turn on", tint: YolkColor.grape,
                                   onTap: { connectScreenTime() })
                    }
                }
                if livingHasReward {
                    Button { claimLiving() } label: {
                        Text("collect your day").font(YolkType.bodySmall.weight(.semibold)).foregroundStyle(YolkColor.shell)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(YolkColor.ink, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(YolkSpace.md)
            .background(YolkColor.shell2.opacity(0.7), in: RoundedRectangle(cornerRadius: 20))
        } else {
            Button { connectHealth() } label: {
                HStack(spacing: YolkSpace.sm) {
                    Image(systemName: "heart.text.square.fill").font(.system(size: 22)).foregroundStyle(YolkColor.pink)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("grow by living").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                        Text("let your steps + sleep feed your yolk").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                    }
                    Spacer()
                    Text("connect").font(YolkType.bodySmall.weight(.semibold)).foregroundStyle(YolkColor.shell)
                        .padding(.horizontal, 14).padding(.vertical, 8).background(YolkColor.ink, in: Capsule())
                }
                .padding(YolkSpace.md)
                .background(YolkColor.shell2.opacity(0.7), in: RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        }
    }

    private func livingStat(icon: YolkGlyph.Kind, value: String, label: String, hit: Bool) -> some View {
        HStack(spacing: 8) {
            YolkGlyph(kind: icon, size: 17, weight: 0.1)
                .foregroundStyle(hit ? YolkColor.mint : YolkColor.muted)
                .frame(width: 17, height: 17)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                Text(label).font(.caption2).foregroundStyle(YolkColor.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(YolkColor.shell, in: RoundedRectangle(cornerRadius: 14))
    }

    /// Authorised, but no figure yet.
    ///
    /// Distinct from the "soon" pillar on purpose. That one means "you have not turned
    /// this on"; this one means "you have, and it is counting". The first off-phone
    /// figure cannot exist until the report extension has had a day to produce one, so
    /// the copy says that rather than leaving someone tapping a padlock wondering what
    /// they got wrong.
    private func livingStatWaiting(label: String) -> some View {
        HStack(spacing: 8) {
            YolkGlyph(kind: .phone, size: 15, weight: 0.1)
                .foregroundStyle(YolkColor.muted)
                .frame(width: 15, height: 15)
            VStack(alignment: .leading, spacing: 0) {
                Text("counting").font(YolkType.bodySmall.weight(.semibold)).foregroundStyle(YolkColor.inkSoft)
                Text(label).font(.caption2).foregroundStyle(YolkColor.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(YolkColor.shell, in: RoundedRectangle(cornerRadius: 14))
    }

    /// A gated pillar (Screen Time): present so the surface is ready the moment the
    /// Family Controls entitlement lands, shown as a gentle "soon" until then.
    private func livingStatSoon(icon: YolkGlyph.Kind, label: String) -> some View {
        HStack(spacing: 8) {
            YolkGlyph(kind: .lock, size: 15, weight: 0.1)
                .foregroundStyle(YolkColor.muted.opacity(0.7))
                .frame(width: 15, height: 15)
            VStack(alignment: .leading, spacing: 0) {
                Text("soon").font(YolkType.bodySmall.weight(.semibold)).foregroundStyle(YolkColor.muted)
                Text(label).font(.caption2).foregroundStyle(YolkColor.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(YolkColor.shell.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
    }

    private func connectHealth() {
        Task {
            let ok = await health.connect()
            if ok {
                player?.healthConnected = true
                persist()
            } else {
                dialog = YolkDialog(icon: .creature(vibe, .curious), title: "hmm",
                                    message: "couldn't reach Health. you can connect it later from here.", primaryTitle: "okay")
            }
        }
    }

    private func connectScreenTime() {
        Task {
            let ok = await screenTime.connect()
            if ok {
                player?.screenTimeConnected = true
                persist()
                screenTime.refresh()
            } else {
                dialog = YolkDialog(icon: .creature(vibe, .curious), title: "not yet",
                                    message: "time off your phone needs Screen Time access, and a real device. you can turn it on later from here.", primaryTitle: "okay")
            }
        }
    }

    private func claimLiving() {
        guard !claimedLivingToday else { return }
        var earned = 0
        var gotRest = false
        if health.steps >= stepGoal { earned += 10 }
        if health.sleepHours >= 7 { player?.restTokens = (player?.restTokens ?? 0) + 1; gotRest = true }
        if earned > 0 { wallet.earn(earned) }
        player?.livingClaimDate = Date()
        careForSelf()   // living well is how the yolk learns to trust you (once/day)
        if trustStage.celebrates { celebrateToken += 1 }   // an earned behaviour
        persist()
        Haptics.shared.reward()
        var msg = "your yolk grew from your day."
        if earned > 0 { msg = "\(health.steps) steps today, +\(earned) \(Currency.name)." }
        if gotRest { msg += earned > 0 ? " a good night's sleep also restored a rest token." : " a good night's sleep restored a rest token." }
        dialog = YolkDialog(icon: .creature(vibe, .proud), title: "by living", message: msg, primaryTitle: "lovely")
    }

    /// Showing up for yourself eases trust UP toward devotion, diminishing as it rises
    /// (responsive early, a slow burn near the top → ~2 weeks to devoted if daily).
    /// CONSISTENCY model: only the FIRST self-care action each day counts, so it can't
    /// be crammed. The first time the yolk becomes a Friend, it waves hello.
    private func careForSelf() {
        guard let p = player else { return }
        if let last = p.lastTrustDate, Calendar.current.isDateInToday(last) { return }  // once/day
        let beforeStage = TrustStage.from(trust: p.trust)
        p.trust = min(1, p.trust + 0.15 * (1 - p.trust))   // ease toward 1.0
        p.lastTrustDate = Date()
        let afterStage = TrustStage.from(trust: p.trust)
        if !beforeStage.waves, afterStage.waves, !p.firstWaveShown {
            p.firstWaveShown = true
            waveToken += 1
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                dialog = YolkDialog(icon: .creature(vibe, .affectionate), title: "\(heading) waved at you!",
                                    message: "taking care of yourself is earning their trust. keep it up and they'll open right up.",
                                    primaryTitle: "aw")
            }
        }
        try? context.save()
    }

    /// On opening the app, a yolk that sees you as a friend waves hello.
    private func helloWaveIfTrusted() {
        guard trustStage.waves else { return }
        Task { try? await Task.sleep(for: .seconds(0.6)); waveToken += 1 }
    }

    /// Whether the player has cared for themselves inside the drift window.
    ///
    /// Mirrors `drift_care_window()` in docs/sql/drift_cron.sql, which is 2 days. A
    /// player who has never cared has no `lastCareDate` at all and is not eligible,
    /// which is what keeps the wander from firing the moment onboarding ends.
    private var hasCaredRecently: Bool {
        guard let last = player?.lastCareDate else { return false }
        return Date().timeIntervalSince(last) < 2 * 24 * 60 * 60
    }

    /// Trust eases back when you drift from caring for YOURSELF. Deliberately gentle:
    /// a one-day grace, slow decay (far slower than it's earned), a floor so it never
    /// forgets you, and rest tokens absorb covered days. No guilt, just a shyer yolk
    /// that perks back up the moment you show up for yourself. (docs/RELATIONSHIP.md)
    private func applyTrustDecay() {
        let floor = 0.12
        guard let p = player, p.trust > floor else { return }
        if let last = p.lastTrustDate, Calendar.current.isDateInToday(last) { return }  // cared today
        let lastCare = [p.lastCheckInDate, p.livingClaimDate, p.lastCareDate, p.lastTrustDate].compactMap { $0 }.max()
        guard let lastCare else { return }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: lastCare), to: cal.startOfDay(for: Date())).day ?? 0
        let neglected = max(0, days - 1 - p.restTokens)   // 1-day grace + rest tokens cover days
        guard neglected > 0 else { return }
        // Ease toward the floor (slower than it's earned, so returning is forgiving).
        let eased = floor + (p.trust - floor) * pow(0.94, Double(neglected))
        if eased < p.trust {
            p.trust = eased
            try? context.save()
        }
    }

    // MARK: Health priming

    /// Whether to ask for HealthKit yet.
    ///
    /// The old version was a permanent banner — the heaviest element on the screen,
    /// louder than any actual action, sitting there forever until someone connected. A
    /// permission prompt is not content. Apple's own guidance is to prime at the moment
    /// of relevance, so this waits until someone has actually shown up a few times, and
    /// then it can be dismissed for good (it still lives in the You tab).
    private var shouldOfferHealth: Bool {
        !healthPromptDismissed && careStreak >= 2
    }

    private var healthPrompt: some View {
        HStack(spacing: YolkSpace.sm) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 20)).foregroundStyle(YolkColor.pink)
            VStack(alignment: .leading, spacing: 2) {
                // References what they've already done, rather than pitching cold.
                Text("you've shown up \(careStreak) days")
                    .font(YolkType.bodySmall.weight(.semibold)).foregroundStyle(YolkColor.ink)
                Text("want your yolk to notice your sleep too?")
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            }
            Spacer(minLength: 0)
            Button { connectHealth() } label: {
                Text("sure").font(YolkType.bodySmall.weight(.semibold)).foregroundStyle(YolkColor.shell)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(YolkColor.ink, in: Capsule())
            }
            .buttonStyle(.plain)
            Button { healthPromptDismissed = true } label: {
                Image(systemName: "xmark").font(.caption2.weight(.semibold))
                    .foregroundStyle(YolkColor.muted).padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10).padding(.horizontal, YolkSpace.md)
        .background(YolkColor.shell2.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: This week

    /// Status, not an action — so it's a line, not a card.
    ///
    /// Hidden entirely at zero. An empty progress bar for a challenge you haven't started
    /// is the least motivating thing a screen can show, and it was greeting every new
    /// player. Once there's something real to report it appears, which also makes the
    /// first check-in reveal it.
    @ViewBuilder private var weeklyLine: some View {
        if weekCareDays > 0 || weeklyClaimed {
            weeklyChallengeCard
        }
    }

    private var weeklyChallengeCard: some View {
        let target = Rewards.weeklyTarget
        let done = min(weekCareDays, target)
        return HStack(spacing: YolkSpace.sm) {
            Image(systemName: weeklyClaimed ? "checkmark.seal.fill" : "target")
                .font(.title3)
                .foregroundStyle(weeklyClaimed ? Color(hex: 0xC9A24B) : YolkColor.ink)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("this week").font(YolkType.bodySmall).foregroundStyle(YolkColor.ink)
                    Spacer()
                    Text(weeklyClaimed ? "done" : "\(done)/\(target) cozy days")
                        .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(YolkColor.shell).frame(height: 6)
                        Capsule().fill(weeklyClaimed ? Color(hex: 0xC9A24B) : YolkColor.ink)
                            .frame(width: geo.size.width * CGFloat(done) / CGFloat(target), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        // No card fill. Status shouldn't carry the same visual weight as an action —
        // that flatness was half of why the panel read as a dashboard.
        .padding(.vertical, 4)
        .padding(.horizontal, YolkSpace.lg)
    }

    private func careCard(_ title: String, reward: Int, icon: YolkGlyph.Kind, done: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) { careCardLabel(title, reward: reward, icon: icon, done: done) }
            .buttonStyle(.plain)
    }

    /// The card face, split out so a Menu can wear it too.
    ///
    /// The `+N Yolks` tag is deliberately gone. Every action used to carry a price at the
    /// same visual weight as the verb, so the screen read as "four ways to earn currency"
    /// — which trains people to optimise for Yolks, not for living well, and contradicts
    /// MONETIZATION.md's own line that "the easy path and the healthy path are the same
    /// path". The Yolks still arrive; they're just a consequence of caring rather than
    /// the reason printed next to it. `reward` stays in the signature because the caller
    /// still uses it to credit the wallet.
    private func careCardLabel(_ title: String, reward: Int, icon: YolkGlyph.Kind, done: Bool) -> some View {
        VStack(spacing: 8) {
            YolkGlyph(kind: done ? .check : icon, size: 26, weight: 0.1)
                .foregroundStyle(done ? Color(hex: 0x73C57A) : YolkColor.ink)
                .frame(width: 26, height: 26)
            Text(done ? "done" : title)
                .font(YolkType.bodySmall)
                .foregroundStyle(done ? YolkColor.muted : YolkColor.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: Bottom nav

    private var bottomNav: some View {
        HStack(spacing: 0) {
            navItem(.home, label: "Home", active: true) { showRoom = true }
            navItem(.shop, label: "Shop", active: false) { showWardrobe = true }
            navItem(.grid, label: "Dex", active: false) { showCollection = true }
            navItem(.friends, label: "Friends", active: false) { showFriends = true }
            navItem(.person, label: "You", active: false) { showProfile = true }
        }
        .padding(.top, YolkSpace.sm)
        .padding(.horizontal, YolkSpace.md)
        .overlay(alignment: .top) {
            Rectangle().fill(YolkColor.line).frame(height: 1)
        }
    }

    private func navItem(_ icon: YolkGlyph.Kind, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                // Slightly heavier stroke when active. A tab bar cannot use fill-vs-outline
                // to show selection the way SF Symbols do, so weight and colour carry it.
                YolkGlyph(kind: icon, size: 22, weight: active ? 0.105 : 0.085)
                    .foregroundStyle(active ? YolkColor.ink : YolkColor.muted)
                    .frame(width: 22, height: 22)
                Text(label)
                    .font(.system(size: 10, weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? YolkColor.ink : YolkColor.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: Cloud backup

    /// Ask before restoring. Never silently.
    ///
    /// Signing in on a device that already has a creature is the dangerous case: the
    /// backup might be an older, better-developed yolkling, or it might be a stale one
    /// from a phone you stopped using. Only the person can know which. So a restore that
    /// would overwrite anything real is offered, not performed — and a backup of a
    /// barely-started creature isn't worth interrupting anyone for at all.
    private func offerRestore(appleUserID: String) async {
        guard let player, let snapshot = await PlayerBackup.pull(appleUserID: appleUserID) else { return }
        guard snapshot.isWorthRestoring else { return }

        // Nothing here worth keeping → just restore, no question to answer.
        let localIsFresh = player.careStreak == 0 && player.discoveredSpeciesIDs.count <= 3
        if localIsFresh {
            restore(snapshot, into: player)
            dialog = YolkDialog(icon: .creature(vibe, .affectionate), title: "welcome back",
                                message: "\(snapshot.name) was waiting for you.", primaryTitle: "hello again")
            return
        }

        dialog = YolkDialog(
            icon: .creature(vibe, .curious),
            title: "there's another yolkling",
            message: "\(snapshot.name) is saved to this Apple ID, \(snapshot.careStreak) days along. bring them back? \(player.name) here would be replaced.",
            primaryTitle: "bring \(snapshot.name) back",
            primaryAction: { restore(snapshot, into: player) },
            secondaryTitle: "keep \(player.name)"
        )
    }

    /// Apply a backup to the model AND to the in-memory state that mirrors it.
    ///
    /// Deliberately does NOT call `persist()`. persist() copies the CURRENT wallet,
    /// wardrobe and @State into the player — so calling it after a restore would
    /// immediately overwrite everything just restored with the pre-restore values. The
    /// @State here is seeded once in `init`, so it has to be moved forward by hand.
    private func restore(_ snapshot: PlayerSnapshot, into player: Player) {
        snapshot.apply(to: player)

        careStreak = player.careStreak
        restTokens = player.restTokens
        lastCareDate = player.lastCareDate
        weekStart = player.weekStart
        weekCareDays = player.weekCareDays
        weeklyClaimed = player.weeklyClaimed
        discovered = Set(player.discoveredSpeciesIDs)
        roomThemeID = player.roomThemeID
        placedByZone = player.placedDecorByZone

        wallet.adopt(coins: player.coins, owned: Set(player.ownedItemIDs))
        wardrobe.restore(equippedIDs: player.equippedItemIDs, owns: wallet.owns)

        try? context.save()
        publishWidget()
        // A backup snapshot UNIONS owned ids (`PlayerSnapshot.apply`), so a restore is a
        // third channel that can resurrect something already traded away. Pull the
        // server's real inventory straight afterwards and let it prune the difference.
        reconcileWallet()
        Haptics.shared.reward()
    }

    // MARK: Actions

    private func pet() {
        Haptics.shared.pet()
        // The squash runs on the creature's own clock rather than an external
        // `withAnimation` scaleEffect, which used to fight the idle loop. `reacting`
        // only shifts the POSE; YolklingView tweens that internally, so no animation
        // wrapper is needed here either.
        petToken += 1
        reacting = true
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            reacting = false
        }
    }

    private func comingSoon(_ title: String, _ message: String) {
        dialog = YolkDialog(icon: .creature(vibe, .curious), title: title, message: message, primaryTitle: "can't wait")
    }

    /// Award focus Yolks, capped per day so it can't be farmed.
    private func rewardFocus(_ minutes: Int) {
        if let date = focusEarnedDate, !Calendar.current.isDateInToday(date) {
            focusEarnedToday = 0   // new day, reset the tally
        }
        // Counted BEFORE the daily cap, and outside the `award > 0` branch: the cap limits
        // what a focus session pays, not whether it happened. A card that stopped counting
        // your focus once you hit the day's Yolk ceiling would be lying about the hour you
        // actually sat there.
        player?.totalFocusMinutes += max(0, minutes)

        let award = min(minutes, max(0, focusDailyCap - focusEarnedToday))
        if award > 0 {
            Haptics.shared.reward()
            wallet.earn(award)
            focusEarnedToday += award
            focusEarnedDate = .now
            player?.focusEarnedToday = focusEarnedToday
            player?.focusEarnedDate = focusEarnedDate
            advanceStreak()
            dialog = YolkDialog(icon: .coins, title: "focus complete",
                                message: "+\(award) Yolks. \(heading) feels calmer with you.", primaryTitle: "nice")
        } else {
            Haptics.shared.tick()
            dialog = YolkDialog(icon: .creature(vibe, .proud), title: "nice focus",
                                message: "you've hit today's focus reward, but \(heading) loved the company.", primaryTitle: "okay")
        }
        persist()
    }

    private func applyScreenshotSeams() {
        let env = ProcessInfo.processInfo.environment
        // Accept a launch ARGUMENT as well as an env var: SIMCTL_CHILD_* env vars
        // propagate unreliably through `simctl launch`, while --args always arrives.
        // The screenshot pipeline needs a deterministic way onto each screen.
        func seam(_ key: String) -> Bool {
            env[key] != nil || CommandLine.arguments.contains(key)
        }
        #if DEBUG
        // BEFORE the outfit seam. Equipping is ownership-gated now, so seeding has to
        // happen first or `persist()`'s prune correctly takes the item straight back off
        // and `YOLK_OUTFIT` looks broken.
        applyOwnershipSeams(env, seam: seam)
        #endif
        // Reads a launch ARGUMENT too, not just the env var. Same reason as `seam(_:)`
        // above — and this one bit during verification: `YOLK_OUTFIT=crown` passed to
        // `simctl launch` silently did nothing, which looked like the new ownership prune
        // eating the item.
        let outfitSpec = env["YOLK_OUTFIT"] ?? CommandLine.arguments
            .first { $0.hasPrefix("YOLK_OUTFIT=") }
            .map { String($0.dropFirst("YOLK_OUTFIT=".count)) }
        if let outfitSpec {
            for id in outfitSpec.split(separator: ",") {
                if let item = CosmeticCatalog.all.first(where: { $0.id == String(id) }) {
                    wardrobe.toggle(item)
                }
            }
        }
        if seam("YOLK_WARDROBE") { showWardrobe = true }
        if seam("YOLK_PROFILE") { showProfile = true }
        if seam("YOLK_CHECKIN") { showCheckIn = true }
        if seam("YOLK_FOCUS") { showFocus = true }
        if seam("YOLK_REFERRAL") { showReferral = true }
        if seam("YOLK_COLLECTION") { showCollection = true }
        if seam("YOLK_ROOM_SHEET") { showRoom = true }
        if env["YOLK_FRIENDS"] != nil { showFriends = true }
        #if DEBUG
        // Value seams read a launch ARGUMENT as well as an env var. `SIMCTL_CHILD_*`
        // propagates unreliably through `simctl launch`, so an env-only seam silently
        // does nothing and you end up "verifying" a state you never actually rendered.
        func seamValue(_ key: String) -> String? {
            if let v = env[key] { return v }
            return CommandLine.arguments
                .first { $0.hasPrefix("\(key)=") }
                .map { String($0.dropFirst(key.count + 1)) }
        }
        if let h = seamValue("YOLK_HEALTH") { health.mock(high: h != "low") }
        if let s = seamValue("YOLK_SCREENTIME") {
            // A number is taken literally, so any fill level can be rendered.
            screenTime.mock(usedHours: Double(s) ?? (s == "low" ? 6 : 1.5))
        }
        if let st = seamValue("YOLK_STEPS"), let n = Int(st) { health.mockSteps(n) }
        if env["YOLK_TRUST"] != nil { demoTrust = 1; Task { try? await Task.sleep(for: .seconds(0.5)); waveToken += 1 } }
        if let h = env["YOLK_HOUR"], let hr = Int(h) { demoHour = hr }
        if env["YOLK_TUTORIAL"] != nil { Task { try? await Task.sleep(for: .seconds(0.6)); withAnimation { showTutorial = true } } }
        #endif
    }

    #if DEBUG
    /// Seams for verifying the ownership fixes. There is no test target (docs/CONVENTIONS),
    /// so a screenshot has to be able to answer "who owns this, and does the client agree
    /// with the server" — hence the probe overlay these feed.
    ///
    /// `arg(_:)` reads a `KEY=value` launch argument as well as an env var, because
    /// `SIMCTL_CHILD_*` propagates unreliably through `simctl launch` while `--args`
    /// always arrives.
    private func applyOwnershipSeams(_ env: [String: String], seam: (String) -> Bool) {
        func arg(_ key: String) -> String? {
            if let v = env[key] { return v }
            return CommandLine.arguments
                .first { $0.hasPrefix(key + "=") }
                .map { String($0.dropFirst(key.count + 1)) }
        }

        // Makes a simulator a distinct SIGNED-IN account without real Sign in with Apple.
        // The enabling seam for the whole two-account trade test — and note it fires the
        // existing `.onChange(of: player?.appleUserID)`, which is the behaviour under test.
        if let id = arg("YOLK_APPLE_ID"), player?.appleUserID != id {
            player?.appleUserID = id
            try? context.save()
        }
        // Put items in the wallet without earning them. Uses `grant`, so they land
        // unsynced — which is also what makes seam-seeded items a valid stand-in for an
        // offline purchase in the race test.
        if let ids = arg("YOLK_SEED_OWNED") {
            wallet.grant(ids.split(separator: ",").map(String.init))
            persist()
        }
        if let id = arg("YOLK_PROBE") { probeID = id }
        if let id = arg("YOLK_GUEST") { guestSpeciesID = id }
        // Reconcile immediately, so a test doesn't have to background and foreground.
        if seam("YOLK_RECONCILE") { reconcileWallet() }
    }
    #endif

    /// Re-enable Health reads for a player who connected on a previous launch.
    private func restoreHealth() {
        if player?.healthConnected == true { Task { await health.resume() } }
    }

    /// Re-read Screen Time status + the latest off-phone figure without prompting.
    private func restoreScreenTime() {
        if player?.screenTimeConnected == true { screenTime.resume() }
    }
}

#Preview {
    HomeView()
}
