import SwiftUI
import SwiftData

/// The game hub. Top bar (streak + Yolks), your creature (tap to pet), today's
/// care actions (which earn Yolks), and the bottom nav. Care actions are stubs
/// for now; each becomes a real feature (mood check-in, focus session, visits).
struct HomeView: View {
    @Environment(\.modelContext) private var context
    private let injected: HatchedCreature?
    private let player: Player?
    @State private var vibeIndex: Int
    @State private var moodIndex: Int
    @State private var reacting = false
    @State private var bounce = false
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
    @State private var showFriends = false
    @State private var placedByZone: [String: String]? = nil
    @State private var health = HealthService()
    @State private var screenTime = ScreenTimeService()
    @State private var waveToken = 0
    @State private var celebrateToken = 0
    @State private var showTutorial = false
    @State private var demoTrust: Double? = nil   // screenshot seam override
    @State private var demoHour: Int? = nil       // screenshot seam override for time-of-day
    @State private var roomThemeID: String
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
        _wallet = State(initialValue: Wallet(
            coins: player?.coins ?? Wallet.welcomeGrant,
            owned: Set(player?.ownedItemIDs ?? [])
        ))
        let store = WardrobeStore()
        store.restore(equippedIDs: player?.equippedItemIDs ?? [])
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
                        creatureHero(min(330, max(232, geo.size.height * 0.46)))   // adapt to screen
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
            CollectionView(discovered: discovered)
                .presentationDetents([.large])
        }
        .fullScreenCover(item: $discoveryReveal) { sp in
            PackRevealView(species: sp)
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
        .onAppear { applyScreenshotSeams(); applyTrustDecay(); restoreHealth(); restoreScreenTime(); pushWalletToServer(); helloWaveIfTrusted(); maybeShowTutorial(); migratePlacedDecorIfNeeded(); maybeShowWidgetNudge() }
        .onChange(of: wallet.coins) { _, _ in persist() }
        .onChange(of: wallet.owned) { _, _ in persist() }
        .onChange(of: wardrobe.equipped) { _, _ in persist() }
        .onChange(of: player?.appleUserID) { _, newID in
            if newID != nil { adoptServerWallet() }   // just signed in → restore + sync
        }
        .overlay {
            if showTutorial { HomeTutorial(name: heading, onDone: finishTutorial) }
        }
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
        player.coins = wallet.coins
        player.ownedItemIDs = Array(wallet.owned)
        player.equippedItemIDs = wardrobe.outfit.map(\.id)
        player.discoveredSpeciesIDs = Array(discovered)
        player.careStreak = careStreak
        player.restTokens = restTokens
        player.lastCareDate = lastCareDate
        player.weekStart = weekStart
        player.weekCareDays = weekCareDays
        player.weeklyClaimed = weeklyClaimed
        player.roomThemeID = roomThemeID
        player.placedDecorByZone = placedByZone
        try? context.save()
        pushWalletToServer()
        publishWidget()
    }

    /// Publish the current yolk look to the App Group so the home-screen widget reflects it.
    private func publishWidget() {
        WidgetPublisher.publish(name: heading, room: mySnapshot())
    }

    /// Mirror the wallet to the server when signed in (durable + cross-device, #11).
    /// Best-effort + fire-and-forget; offline / signed-out play stays fully local.
    private func pushWalletToServer() {
        guard let uid = player?.appleUserID else { return }
        let coins = wallet.coins
        let owned = Array(wallet.owned)
        Task { _ = await SupabaseClient.shared.pushWallet(userID: uid, coins: coins, owned: owned) }
    }

    /// On sign-in (or cross-device), pull the server wallet and merge: keep the higher
    /// coin balance so nothing is lost, union owned items, then push the result back.
    private func adoptServerWallet() {
        guard let uid = player?.appleUserID else { return }
        Task {
            if let s = await SupabaseClient.shared.walletState(userID: uid) {
                wallet.adopt(coins: max(s.coins, wallet.coins), owned: wallet.owned.union(s.owned))
            }
            persist()   // writes locally + pushes the merged state up
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
                Image(systemName: "flame.fill").foregroundStyle(Color(hex: 0xFF8A3D))
                Text("\(careStreak)").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                    .contentTransition(.numericText())
                Text(careStreak == 1 ? "day" : "days").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                if restTokens > 0 {
                    Image(systemName: "leaf.fill").font(.caption2).foregroundStyle(Color(hex: 0x9AC77E))
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
                         outfit: wardrobe.outfit, decor: placedDecor, showCreature: false)
                    .onTapGesture { Haptics.shared.select(); showRoom = true }

                GeometryReader { geo in
                    YolklingView(vibe: vibe, expression: shownExpression,
                                 size: geo.size.height * RoomView.creatureSpot.size,
                                 outfit: wardrobe.outfit, waveToken: waveToken, celebrateToken: celebrateToken)
                        .contentShape(Rectangle())
                        .scaleEffect(bounce ? 1.05 : 1.0)
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

            VStack(spacing: 2) {
                Text(baseMood.label)
                    .font(YolkType.label).tracking(2).textCase(.uppercase)
                    .foregroundStyle(YolkColor.muted)
                Text(dayPhase == .night ? "getting sleepy · wind down too?" : trustStage.label)
                    .font(.caption2)
                    .foregroundStyle(YolkColor.muted.opacity(0.75))
            }
        }
    }

    // MARK: Today's care

    private var todayPanel: some View {
        VStack(alignment: .leading, spacing: YolkSpace.sm) {
            Text("today")
                .font(YolkType.label).tracking(2).textCase(.uppercase)
                .foregroundStyle(YolkColor.muted)
                .padding(.horizontal, YolkSpace.lg)

            HStack(spacing: YolkSpace.sm) {
                careCard("check in", reward: 10, icon: "heart.fill", done: checkedInToday) { showCheckIn = true }
                careCard("focus", reward: 20, icon: "moon.stars.fill") { showFocus = true }
                careCard("visit", reward: 5, icon: "person.2.fill") { showFriends = true }
            }
            .padding(.horizontal, YolkSpace.lg)

            if health.available { livingCard.padding(.horizontal, YolkSpace.lg) }
            weeklyChallengeCard
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
                    livingStat(icon: "figure.walk", value: "\(health.steps)", label: "steps", hit: health.steps >= stepGoal)
                    livingStat(icon: "moon.zzz.fill", value: String(format: "%.1fh", health.sleepHours), label: "sleep", hit: health.sleepHours >= 7)
                    if screenTime.available, let off = screenTime.offScreenHours {
                        livingStat(icon: "iphone", value: String(format: "%.0fh", off), label: "off phone", hit: screenTime.hitGoal)
                    } else {
                        Button { connectScreenTime() } label: { livingStatSoon(icon: "iphone", label: "off phone") }
                            .buttonStyle(.plain)
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

    private func livingStat(icon: String, value: String, label: String, hit: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 15)).foregroundStyle(hit ? YolkColor.mint : YolkColor.muted)
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

    /// A gated pillar (Screen Time): present so the surface is ready the moment the
    /// Family Controls entitlement lands, shown as a gentle "soon" until then.
    private func livingStatSoon(icon: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill").font(.system(size: 12)).foregroundStyle(YolkColor.muted.opacity(0.7))
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
            HStack(spacing: 2) {
                YolkCoin(size: 12, animated: false)
                Text("+\(Rewards.weeklyReward)").font(YolkType.bodySmall)
            }
            .foregroundStyle(YolkColor.muted)
        }
        .padding(.vertical, 11).padding(.horizontal, YolkSpace.md)
        .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, YolkSpace.lg)
    }

    private func careCard(_ title: String, reward: Int, icon: String, done: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: done ? "checkmark.circle.fill" : icon)
                    .font(.title2)
                    .foregroundStyle(done ? Color(hex: 0x73C57A) : YolkColor.ink)
                Text(title).font(YolkType.bodySmall).foregroundStyle(YolkColor.ink)
                if done {
                    Text("done").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                } else {
                    HStack(spacing: 2) {
                        YolkCoin(size: 11, animated: false)
                        Text("+\(reward)").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: Bottom nav

    private var bottomNav: some View {
        HStack(spacing: 0) {
            navItem("house.fill", label: "Home", active: true) { showRoom = true }
            navItem("bag.fill", label: "Shop", active: false) { showWardrobe = true }
            navItem("square.grid.2x2.fill", label: "Dex", active: false) { showCollection = true }
            navItem("person.2.fill", label: "Friends", active: false) { showFriends = true }
            navItem("person.crop.circle.fill", label: "You", active: false) { showProfile = true }
        }
        .padding(.top, YolkSpace.sm)
        .padding(.horizontal, YolkSpace.md)
        .overlay(alignment: .top) {
            Rectangle().fill(YolkColor.line).frame(height: 1)
        }
    }

    private func navItem(_ icon: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(active ? YolkColor.ink : YolkColor.muted)
                Text(label)
                    .font(.system(size: 10, weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? YolkColor.ink : YolkColor.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func pet() {
        Haptics.shared.pet()
        withAnimation(.bouncy(duration: 0.4, extraBounce: 0.5)) {
            reacting = true
            bounce = true
        }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.spring) { bounce = false }
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(.easeInOut(duration: 0.5)) { reacting = false }
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
        if let outfit = env["YOLK_OUTFIT"] {
            for id in outfit.split(separator: ",") {
                if let item = CosmeticCatalog.all.first(where: { $0.id == String(id) }) {
                    wardrobe.toggle(item)
                }
            }
        }
        if env["YOLK_WARDROBE"] != nil { showWardrobe = true }
        if env["YOLK_PROFILE"] != nil { showProfile = true }
        if env["YOLK_CHECKIN"] != nil { showCheckIn = true }
        if env["YOLK_FOCUS"] != nil { showFocus = true }
        if env["YOLK_REFERRAL"] != nil { showReferral = true }
        if env["YOLK_COLLECTION"] != nil { showCollection = true }
        if env["YOLK_ROOM_SHEET"] != nil { showRoom = true }
        if env["YOLK_FRIENDS"] != nil { showFriends = true }
        #if DEBUG
        if let h = env["YOLK_HEALTH"] { health.mock(high: h != "low") }
        if let s = env["YOLK_SCREENTIME"] { screenTime.mock(offHours: s == "low" ? 8 : 21) }
        if env["YOLK_TRUST"] != nil { demoTrust = 1; Task { try? await Task.sleep(for: .seconds(0.5)); waveToken += 1 } }
        if let h = env["YOLK_HOUR"], let hr = Int(h) { demoHour = hr }
        if env["YOLK_TUTORIAL"] != nil { Task { try? await Task.sleep(for: .seconds(0.6)); withAnimation { showTutorial = true } } }
        #endif
    }

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
