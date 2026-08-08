import SwiftUI

/// The unified store: one sheet, three aisles. Colours repaints your yolk,
/// Outfit clips on cosmetics per slot, Room picks themes and decor for your
/// little space. Everything is earned with Yolks (no cash, no gacha).
///
/// Themes decision: option (b). buying a theme marks it owned here, but APPLYING
/// it (choosing which theme is active) lives in DecorateView's theme strip, where
/// the player already goes to arrange the room. This keeps ShopHomeView's signature
/// lean (no themeID binding) and avoids split-ownership confusion.
struct ShopHomeView: View {
    let vibe: Vibe
    let store: WardrobeStore
    let wallet: Wallet
    let originalBodyHex: Int
    let originalAccentHex: Int?
    var onColor: (Vibe, Int, Int?) -> Void

    enum Aisle: String, CaseIterable {
        case colours = "Colours"
        case outfit  = "Outfit"
        case room    = "Room"
    }

    enum TryOn { case cosmetic(Cosmetic); case colour(ColorSwatch); case theme(RoomTheme); case decor(RoomDecor) }

    enum SortOrder: String, CaseIterable, Identifiable {
        case priceAsc  = "price: low to high"
        case priceDesc = "price: high to low"
        case rarity    = "rarity"
        case newest    = "new"
        var id: String { rawValue }
    }

    @State private var aisle: Aisle = .outfit
    @State private var previewVibe: Vibe
    @State private var tryOn: TryOn?
    @State private var dialog: YolkDialog?
    @State private var searchText: String = ""
    @State private var showOwned: Bool = false
    @State private var sortOrder: SortOrder = .newest
    private let baseStyle: CreatureStyle
    private let basePattern: BodyPattern

    init(vibe: Vibe, store: WardrobeStore, wallet: Wallet,
         originalBodyHex: Int, originalAccentHex: Int?,
         onColor: @escaping (Vibe, Int, Int?) -> Void) {
        self.vibe = vibe
        self.store = store
        self.wallet = wallet
        self.originalBodyHex = originalBodyHex
        self.originalAccentHex = originalAccentHex
        self.onColor = onColor
        self.baseStyle = vibe.style
        self.basePattern = vibe.pattern
        _previewVibe = State(initialValue: vibe)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            YolklingView(vibe: displayVibe, expression: .happy, size: 132, outfit: displayOutfit)
                .frame(height: 152)

            YolkSegmented(selection: $aisle, options: Aisle.allCases) { $0.rawValue }
                .padding(.horizontal, YolkSpace.lg)
                .padding(.bottom, YolkSpace.sm)

            utilityRow

            ScrollView {
                VStack(alignment: .leading, spacing: YolkSpace.lg) {
                    if searchText.isEmpty && !showOwned {
                        curatedFront
                    }
                    switch aisle {
                    case .colours: coloursAisle
                    case .outfit:  outfitAisle
                    case .room:    roomAisle
                    }
                }
                .padding(.horizontal, YolkSpace.lg)
                .padding(.bottom, YolkSpace.xl)
            }
        }
        .background(YolkColor.shell)
        .safeAreaInset(edge: .bottom, spacing: 0) { confirmBar }
        .yolkDialog($dialog)
        .onAppear {
            if ProcessInfo.processInfo.environment["YOLK_TRYON"] != nil,
               let item = CosmeticCatalog.all.first(where: { $0.id == "flower" }) {
                tryOn = .cosmetic(item)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("shop").font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Spacer()
            HStack(spacing: 5) {
                YolkCoin(size: 17)
                Text("\(wallet.coins)").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                    .contentTransition(.numericText())
                Text(Currency.name).font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(YolkColor.shell2, in: Capsule())
        }
        .padding(.horizontal, YolkSpace.lg).padding(.top, YolkSpace.md)
    }

    // MARK: Utility row

    private var utilityRow: some View {
        VStack(spacing: YolkSpace.sm) {
            HStack(spacing: YolkSpace.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(YolkColor.muted).font(.subheadline)
                    TextField("search", text: $searchText)
                        .font(YolkType.bodySmall)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(YolkColor.muted).font(.subheadline)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 10))

                Menu {
                    ForEach(SortOrder.allCases) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(YolkColor.ink)
                        .frame(width: 36, height: 32)
                        .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, YolkSpace.lg)

            YolkSegmented(selection: $showOwned, options: [false, true]) { $0 ? "Owned" : "All" }
                .padding(.horizontal, YolkSpace.lg)
        }
        .padding(.bottom, YolkSpace.sm)
        .onChange(of: aisle) { _, _ in searchText = ""; showOwned = false }
    }

    // MARK: Filtered items helpers

    /// Colours: filtered + sorted ColorSwatch list
    private var filteredColours: [ColorSwatch] {
        applySort(
            ColorShop.all
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .filter { !showOwned || wallet.has($0.id) },
            cost: { $0.cost }, rarity: { $0.rarity }
        )
    }

    /// Cosmetics for a given slot: filtered + sorted
    private func filteredCosmetics(for slot: CosmeticSlot) -> [Cosmetic] {
        applySort(
            CosmeticCatalog.items(in: slot)
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .filter { !showOwned || wallet.owns($0) },
            cost: { $0.cost }, rarity: { $0.rarity }
        )
    }

    /// Themes: filtered + sorted
    private var filteredThemes: [RoomTheme] {
        applySort(
            RoomThemes.all
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .filter { !showOwned || wallet.has($0.id) || $0.cost == 0 },
            cost: { $0.cost }, rarity: { $0.rarity }
        )
    }

    /// Decor: filtered + sorted
    private var filteredDecor: [RoomDecor] {
        applySort(
            RoomDecorCatalog.all
                .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                .filter { !showOwned || wallet.has($0.id) },
            cost: { $0.cost }, rarity: { $0.rarity }
        )
    }

    private func applySort<T>(_ items: [T], cost: (T) -> Int, rarity: (T) -> Rarity) -> [T] {
        switch sortOrder {
        case .priceAsc:  return items.sorted { cost($0) < cost($1) }
        case .priceDesc: return items.sorted { cost($0) > cost($1) }
        case .rarity:    return items.sorted { rarity($0).rank > rarity($1).rank }
        case .newest:    return items.reversed()
        }
    }

    // MARK: Curated front

    @ViewBuilder private var curatedFront: some View {
        switch aisle {
        case .colours:
            curatedStrips(
                catalog: ColorShop.all,
                cost: { $0.cost },
                isOwned: { wallet.has($0.id) },
                card: { colourCard($0) }
            )
        case .outfit:
            // Flatten all cosmetics for cross-slot curated strips.
            // Grant-only items are excluded: they're seasonal, unbuyable at any price,
            // and listing them at cost 0 would hand them to everyone and destroy the
            // only scarcity the economy has.
            curatedStrips(
                catalog: CosmeticCatalog.all.filter { !$0.grantOnly },
                cost: { $0.cost },
                isOwned: { wallet.owns($0) },
                card: { cosmeticCard($0) }
            )
        case .room:
            // Room curated: themes + decor merged by index (newest from each)
            roomCuratedFront
        }
    }

    @ViewBuilder private var roomCuratedFront: some View {
        // New themes (last 6 of RoomThemes.all)
        let newThemes = Array(RoomThemes.all.reversed().prefix(6))
        if !newThemes.isEmpty {
            curatedStrip(title: "new") {
                ForEach(newThemes) { themeCard($0) }
            }
        }
        // Under 100 themes
        let cheapThemes = RoomThemes.all.filter { !wallet.has($0.id) && $0.cost > 0 && $0.cost < 100 }
        if !cheapThemes.isEmpty {
            curatedStrip(title: "under 100 yolks") {
                ForEach(cheapThemes) { themeCard($0) }
            }
        }
        // Almost yours themes
        let almostThemes = RoomThemes.all
            .filter { !wallet.has($0.id) && $0.cost > 0 && ($0.cost - wallet.coins) > 0 }
            .sorted { ($0.cost - wallet.coins) < ($1.cost - wallet.coins) }
            .prefix(6)
        if !almostThemes.isEmpty {
            curatedStrip(title: "almost yours") {
                ForEach(Array(almostThemes)) { themeCard($0) }
            }
        }
        // New decor (last 6 of RoomDecorCatalog.all)
        let newDecor = Array(RoomDecorCatalog.all.reversed().prefix(6))
        if !newDecor.isEmpty {
            curatedStrip(title: "new decor") {
                ForEach(newDecor) { decorCard($0) }
            }
        }
        // Under 100 decor
        let cheapDecor = RoomDecorCatalog.all.filter { !wallet.has($0.id) && $0.cost < 100 }
        if !cheapDecor.isEmpty {
            curatedStrip(title: "decor under 100") {
                ForEach(cheapDecor) { decorCard($0) }
            }
        }
        // Almost yours decor
        let almostDecor = RoomDecorCatalog.all
            .filter { !wallet.has($0.id) && ($0.cost - wallet.coins) > 0 }
            .sorted { ($0.cost - wallet.coins) < ($1.cost - wallet.coins) }
            .prefix(6)
        if !almostDecor.isEmpty {
            curatedStrip(title: "almost yours (decor)") {
                ForEach(Array(almostDecor)) { decorCard($0) }
            }
        }
    }

    private func curatedStrips<Item: Identifiable>(
        catalog: [Item],
        cost: @escaping (Item) -> Int,
        isOwned: @escaping (Item) -> Bool,
        card: @escaping (Item) -> some View
    ) -> some View {
        let newItems = Array(catalog.reversed().prefix(6))
        let cheapItems = catalog.filter { !isOwned($0) && cost($0) < 100 }
        let almostItems = Array(
            catalog
                .filter { !isOwned($0) && (cost($0) - wallet.coins) > 0 }
                .sorted { (cost($0) - wallet.coins) < (cost($1) - wallet.coins) }
                .prefix(6)
        )
        return VStack(alignment: .leading, spacing: YolkSpace.lg) {
            if !newItems.isEmpty {
                curatedStrip(title: "new") {
                    ForEach(newItems, id: \.id) { card($0) }
                }
            }
            if !cheapItems.isEmpty {
                curatedStrip(title: "under 100 yolks") {
                    ForEach(cheapItems, id: \.id) { card($0) }
                }
            }
            if !almostItems.isEmpty {
                curatedStrip(title: "almost yours") {
                    ForEach(almostItems, id: \.id) { card($0) }
                }
            }
        }
    }

    private func curatedStrip<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: YolkSpace.sm) {
            sectionTitle(title)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: YolkSpace.sm) {
                    content()
                }
            }
        }
    }

    // MARK: Colours aisle

    private var coloursAisle: some View {
        VStack(alignment: .leading, spacing: YolkSpace.sm) {
            sectionTitle("rare colours")
            Text("recolors your body. a permanent glow-up earned with Yolks.")
                .font(.caption).foregroundStyle(YolkColor.muted)
                .padding(.top, -4)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: YolkSpace.sm)], spacing: YolkSpace.sm) {
                if searchText.isEmpty && !showOwned { originalColour }
                ForEach(filteredColours) { colourCard($0) }
            }
        }
    }

    private var originalColour: some View {
        let on = previewVibe.id != "color-sunset" && ColorShop.all.allSatisfy { previewVibe.id != $0.id }
        return Button {
            let v = Vibe(id: "original", name: "original", body: Color(hex: UInt(originalBodyHex)),
                         deep: Color(hex: CreaturePalette.darker(UInt(originalBodyHex))), style: baseStyle,
                         accent: originalAccentHex.map { Color(hex: UInt($0)) }, pattern: basePattern)
            withAnimation(.spring) { previewVibe = v }
            Haptics.shared.select()
            onColor(v, originalBodyHex, originalAccentHex)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(YolkColor.shell2)
                    Circle().fill(Color(hex: UInt(originalBodyHex))).frame(width: 50, height: 50)
                }
                .frame(width: 84, height: 84)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(YolkColor.ink, lineWidth: on ? 2.5 : 0))
                Text("original").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            }
        }
        .buttonStyle(.plain)
    }

    private func colourCard(_ s: ColorSwatch) -> some View {
        let owned = wallet.has(s.id)
        let on = previewVibe.id == s.id || isTryingOnColour(s)
        return Button { tapColour(s) } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18).fill(YolkColor.shell2)
                    Circle().fill(RadialGradient(colors: s.bodyStops ?? [s.body, s.body, s.deep],
                                                 center: UnitPoint(x: 0.36, y: 0.30), startRadius: 2, endRadius: 36))
                        .frame(width: 50, height: 50).frame(maxWidth: .infinity, maxHeight: .infinity)
                    rarityDot(s.rarity).padding(8)
                }
                .frame(width: 84, height: 84)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(YolkColor.ink, lineWidth: on ? 2.5 : 0))
                itemState(name: s.name, owned: owned, on: on, afford: wallet.coins >= s.cost, cost: s.cost)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Outfit aisle

    private var outfitAisle: some View {
        VStack(alignment: .leading, spacing: YolkSpace.lg) {
            ForEach(CosmeticSlot.allCases) { slot in cosmeticSection(slot) }
        }
    }

    private func cosmeticSection(_ slot: CosmeticSlot) -> some View {
        let items = filteredCosmetics(for: slot)
        return Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: YolkSpace.sm) {
                    sectionTitle(slot.label)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: YolkSpace.sm)], spacing: YolkSpace.sm) {
                        ForEach(items) { cosmeticCard($0) }
                    }
                }
            }
        }
    }

    private func cosmeticCard(_ item: Cosmetic) -> some View {
        let owned = wallet.owns(item)
        let on = store.isEquipped(item) || isTryingOnCosmetic(item)
        return Button { tapCosmetic(item) } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18).fill(YolkColor.shell2)
                    // Rarity was on every item and drawn nowhere — an epic looked like a
                    // common with a different number beside it. The aura makes it felt
                    // before it's read, which is most of why pulling a rare feels good.
                    RarityAura(rarity: item.rarity, size: 84)
                    CosmeticView(kind: item.kind, size: 50).frame(maxWidth: .infinity, maxHeight: .infinity)
                    if item.rarity != .common { rarityDot(item.rarity).padding(8) }
                }
                .frame(width: 84, height: 84)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(YolkColor.ink, lineWidth: on ? 2.5 : 0))
                itemState(name: item.name, owned: owned, on: on, afford: wallet.canAfford(item), cost: item.cost, wearingLabel: true)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Room aisle

    private var roomAisle: some View {
        VStack(alignment: .leading, spacing: YolkSpace.lg) {
            // Themes
            let themes = filteredThemes
            if !themes.isEmpty || (!showOwned && searchText.isEmpty) {
                VStack(alignment: .leading, spacing: YolkSpace.sm) {
                    sectionTitle("themes")
                    Text("sets your room's look. apply the active theme in Decorate.")
                        .font(.caption).foregroundStyle(YolkColor.muted)
                        .padding(.top, -4)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: YolkSpace.sm)], spacing: YolkSpace.sm) {
                        ForEach(themes) { themeCard($0) }
                    }
                }
            }

            // Decor
            let decor = filteredDecor
            if !decor.isEmpty || (!showOwned && searchText.isEmpty) {
                VStack(alignment: .leading, spacing: YolkSpace.sm) {
                    sectionTitle("decor")
                    Text("place pieces in your room from the Decorate sheet.")
                        .font(.caption).foregroundStyle(YolkColor.muted)
                        .padding(.top, -4)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: YolkSpace.sm)], spacing: YolkSpace.sm) {
                        ForEach(decor) { decorCard($0) }
                    }
                }
            }
        }
    }

    private func themeCard(_ theme: RoomTheme) -> some View {
        let owned = wallet.has(theme.id) || theme.cost == 0
        return Button { tapTheme(theme) } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(theme.wall)
                    // small floor swatch at bottom
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle().fill(theme.floorColor).frame(height: 22)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    if theme.rarity != .common { rarityDot(theme.rarity).padding(8) }
                }
                .frame(width: 84, height: 84)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(YolkColor.ink, lineWidth: isTryingOnTheme(theme) ? 2.5 : 0))
                itemState(name: theme.name, owned: owned, on: false, afford: wallet.coins >= theme.cost, cost: theme.cost)
            }
        }
        .buttonStyle(.plain)
    }

    private func decorCard(_ decor: RoomDecor) -> some View {
        let owned = wallet.has(decor.id)
        let trying = isTryingOnDecor(decor)
        return Button { tapDecor(decor) } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18).fill(YolkColor.shell2)
                    RoomDecorView(kind: decor.kind)
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if decor.rarity != .common { rarityDot(decor.rarity).padding(8) }
                }
                .frame(width: 84, height: 84)
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(YolkColor.ink, lineWidth: trying ? 2.5 : 0))
                itemState(name: decor.name, owned: owned, on: false, afford: wallet.coins >= decor.cost, cost: decor.cost)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Shared helpers

    private func sectionTitle(_ t: String) -> some View {
        Text(t).font(YolkType.label).tracking(2).textCase(.uppercase).foregroundStyle(YolkColor.muted)
    }

    @ViewBuilder private func itemState(name: String, owned: Bool, on: Bool, afford: Bool, cost: Int, wearingLabel: Bool = false) -> some View {
        VStack(spacing: 1) {
            Text(name).font(YolkType.bodySmall).foregroundStyle(YolkColor.ink).lineLimit(1)
            if owned {
                let wearing = wearingLabel && on
                Text(wearing ? "wearing" : "owned").font(.caption2).foregroundStyle(wearing ? YolkColor.ink : YolkColor.muted)
            } else {
                HStack(spacing: 3) { YolkCoin(size: 11, animated: false); Text("\(cost)").font(.caption2) }
                    .foregroundStyle(afford ? YolkColor.inkSoft : YolkColor.muted.opacity(0.55))
            }
        }
        .frame(width: 84)
    }

    private func rarityDot(_ r: Rarity) -> some View {
        Circle().fill(rarityColor(r)).frame(width: 10, height: 10)
            .overlay(Circle().stroke(.white, lineWidth: 1.5))
    }
    private func rarityColor(_ r: Rarity) -> Color {
        switch r {
        case .common: YolkColor.muted
        case .rare:   Color(hex: 0x5FA9E0)
        case .epic:   Color(hex: 0x9874C9)
        }
    }

    // MARK: Try-on state

    private var displayVibe: Vibe {
        if case .colour(let s) = tryOn { return s.vibe(style: baseStyle, pattern: basePattern) }
        return previewVibe
    }
    private var displayOutfit: [Cosmetic] {
        if case .cosmetic(let c) = tryOn { return store.outfit.filter { $0.slot != c.slot } + [c] }
        return store.outfit
    }

    private func isTryingOnCosmetic(_ item: Cosmetic) -> Bool {
        if case .cosmetic(let c) = tryOn { return c.id == item.id }; return false
    }
    private func isTryingOnColour(_ s: ColorSwatch) -> Bool {
        if case .colour(let x) = tryOn { return x.id == s.id }; return false
    }
    private func isTryingOnTheme(_ theme: RoomTheme) -> Bool {
        if case .theme(let t) = tryOn { return t.id == theme.id }; return false
    }
    private func isTryingOnDecor(_ decor: RoomDecor) -> Bool {
        if case .decor(let d) = tryOn { return d.id == decor.id }; return false
    }

    // MARK: Tap actions

    private func tapCosmetic(_ item: Cosmetic) {
        if wallet.owns(item) {
            store.toggle(item); Haptics.shared.select()
        } else {
            Haptics.shared.select()
            withAnimation(.spring) { tryOn = .cosmetic(item) }
        }
    }

    private func tapColour(_ s: ColorSwatch) {
        if wallet.has(s.id) {
            applyColour(s)
        } else {
            Haptics.shared.select()
            withAnimation(.spring) { tryOn = .colour(s) }
        }
    }

    private func tapTheme(_ theme: RoomTheme) {
        if wallet.has(theme.id) || theme.cost == 0 {
            // already owned. apply it in DecorateView
            Haptics.shared.tick()
        } else {
            Haptics.shared.select()
            withAnimation(.spring) { tryOn = .theme(theme) }
        }
    }

    private func tapDecor(_ decor: RoomDecor) {
        if wallet.has(decor.id) {
            // already owned. placement happens in DecorateView
            Haptics.shared.tick()
        } else {
            Haptics.shared.select()
            withAnimation(.spring) { tryOn = .decor(decor) }
        }
    }

    private func applyColour(_ s: ColorSwatch) {
        let v = s.vibe(style: baseStyle, pattern: basePattern)
        withAnimation(.spring) { previewVibe = v }
        Haptics.shared.select()
        onColor(v, Int(s.bodyHex), s.accentHex.map { Int($0) })
    }

    // MARK: Confirm bar

    @ViewBuilder private var confirmBar: some View {
        if let t = tryOn {
            let name = tryOnName(t)
            let cost = tryOnCost(t)
            let afford = wallet.coins >= cost
            HStack(spacing: YolkSpace.sm) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("trying on").font(.caption2.weight(.bold)).tracking(1).textCase(.uppercase).foregroundStyle(YolkColor.muted)
                    Text(name).font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                    if !afford {
                        Text("you have \(wallet.coins) \(Currency.name)").font(.caption2).foregroundStyle(YolkColor.muted)
                    }
                }
                Spacer()
                Button { dismissTryOn() } label: {
                    Image(systemName: "xmark").font(.subheadline.weight(.bold)).foregroundStyle(YolkColor.muted)
                        .frame(width: 40, height: 40).background(YolkColor.shell2, in: Circle())
                }
                .buttonStyle(.plain)
                Button { confirmTryOn(t) } label: {
                    HStack(spacing: 4) {
                        YolkCoin(size: 14, animated: false)
                        Text("buy \(cost)").font(YolkType.body.weight(.semibold))
                    }
                    .foregroundStyle(YolkColor.shell).padding(.vertical, 11).padding(.horizontal, 18)
                    .background(YolkColor.ink.opacity(afford ? 1 : 0.3), in: Capsule())
                }
                .buttonStyle(.plain).disabled(!afford)
            }
            .padding(.horizontal, YolkSpace.lg).padding(.vertical, YolkSpace.sm)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) { Rectangle().fill(YolkColor.line).frame(height: 1) }
        }
    }

    private func tryOnName(_ t: TryOn) -> String {
        switch t {
        case .cosmetic(let c): c.name
        case .colour(let s):   s.name
        case .theme(let th):   th.name
        case .decor(let d):    d.name
        }
    }

    private func tryOnCost(_ t: TryOn) -> Int {
        switch t {
        case .cosmetic(let c): c.cost
        case .colour(let s):   s.cost
        case .theme(let th):   th.cost
        case .decor(let d):    d.cost
        }
    }

    private func confirmTryOn(_ t: TryOn) {
        switch t {
        case .cosmetic(let c):
            guard wallet.buy(c) else { Haptics.shared.warn(); return }
            store.toggle(c); Haptics.shared.reward()
        case .colour(let s):
            guard wallet.purchase(id: s.id, cost: s.cost) else { Haptics.shared.warn(); return }
            applyColour(s); Haptics.shared.reward()
        case .theme(let th):
            guard wallet.purchase(id: th.id, cost: th.cost) else { Haptics.shared.warn(); return }
            Haptics.shared.reward()
            // theme is now owned; player selects it via DecorateView's theme strip
        case .decor(let d):
            guard wallet.purchase(id: d.id, cost: d.cost) else { Haptics.shared.warn(); return }
            Haptics.shared.reward()
            // decor is now owned; player places it via DecorateView
        }
        withAnimation(.spring) { tryOn = nil }
    }

    private func dismissTryOn() {
        Haptics.shared.tick()
        withAnimation(.spring) { tryOn = nil }
    }
}
