import SwiftUI
import YolklingCore

/// Snap-to-zones room editor. The live diorama stays on top; tapping a zone opens a
/// tray of pieces that fit it (owned -> place, unowned -> buy-in-place, plus clear).
/// A compact theme strip switches the room theme. One piece per zone (RoomZones.capacity).
struct DecorateView: View {
    let vibe: Vibe
    let expression: YolkExpression
    let outfit: [Cosmetic]
    @Bindable var wallet: Wallet
    @Binding var placed: [String: String]?   // zone.rawValue -> decor id
    @Binding var themeID: String
    var onChange: () -> Void

    @State private var activeZone: RoomDecor.Zone? = nil
    @State private var tryOn: TryOnItem? = nil
    @State private var dialog: YolkDialog? = nil
    @Environment(\.dismiss) private var dismiss

    // MARK: Computed helpers

    private var theme: RoomTheme {
        RoomThemes.all.first { $0.id == themeID } ?? RoomThemes.cozy
    }

    private var placedPieces: [RoomDecor] {
        (placed ?? [:]).compactMap { RoomDecorCatalog.byID($0.value) }
    }

    // MARK: Zone anchors (fractional x/y over the room frame)

    private static let zoneAnchor: [RoomDecor.Zone: CGPoint] = [
        .hanging: .init(x: 0.45, y: 0.14),
        .wallL:   .init(x: 0.22, y: 0.30),
        .wallC:   .init(x: 0.54, y: 0.17),
        .wallR:   .init(x: 0.85, y: 0.22),
        .floorL:  .init(x: 0.24, y: 0.78),
        .floorC:  .init(x: 0.50, y: 0.78),
        .floorR:  .init(x: 0.82, y: 0.76),
    ]

    // MARK: TryOn item (theme or decor)

    private enum TryOnItem {
        case theme(RoomTheme)
        case decor(RoomDecor)
        var name: String {
            switch self {
            case .theme(let t): return t.name
            case .decor(let d): return d.name
            }
        }
        var cost: Int {
            switch self {
            case .theme(let t): return t.cost
            case .decor(let d): return d.cost
            }
        }
        var id: String {
            switch self {
            case .theme(let t): return t.id
            case .decor(let d): return d.id
            }
        }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            header

            // Live room with tappable zone targets overlaid.
            GeometryReader { geo in
                ZStack {
                    RoomView(
                        vibe: vibe,
                        expression: expression,
                        theme: tryOnDisplayTheme,
                        outfit: outfit,
                        decor: tryOnDisplayDecor,
                        showCreature: true
                    )
                    zoneTargets(in: geo.size)
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, YolkSpace.md)
            .padding(.top, YolkSpace.sm)

            themeStrip

            if let z = activeZone {
                zoneTray(z)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let item = tryOn {
                tryOnBar(item)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(YolkColor.shell.ignoresSafeArea())
        .yolkDialog($dialog)
        .animation(.easeInOut(duration: 0.25), value: activeZone)
        .animation(.easeInOut(duration: 0.2), value: tryOn?.id)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("decorate").font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Spacer()
            HStack(spacing: 5) {
                YolkCoin(size: 17)
                Text("\(wallet.coins)").font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                Text(Currency.name).font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(YolkColor.shell2, in: Capsule())
            Button {
                Haptics.shared.select()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(YolkColor.inkSoft)
                    .padding(10)
                    .background(YolkColor.shell2, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, YolkSpace.lg)
        .padding(.vertical, YolkSpace.md)
    }

    // MARK: Zone targets overlay

    private func zoneTargets(in size: CGSize) -> some View {
        ZStack {
            ForEach(RoomZones.displayOrder, id: \.self) { zone in
                let anchor = Self.zoneAnchor[zone] ?? .init(x: 0.5, y: 0.5)
                let isActive = activeZone == zone
                let hasPlaced = placed?[zone.rawValue] != nil
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if activeZone == zone {
                            activeZone = nil
                        } else {
                            activeZone = zone
                            tryOn = nil
                        }
                    }
                    Haptics.shared.select()
                } label: {
                    // A clearly tappable marker: + for an empty spot, pencil for a filled
                    // one, check when open. Solid disc + shadow so it reads as a button.
                    ZStack {
                        Circle()
                            .fill(isActive ? YolkColor.ink : YolkColor.shell.opacity(0.9))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().strokeBorder(
                                    isActive ? Color.clear : YolkColor.ink.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 1.5, dash: hasPlaced ? [] : [3])
                                )
                            )
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                        Image(systemName: isActive ? "checkmark" : (hasPlaced ? "pencil" : "plus"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isActive ? YolkColor.shell : YolkColor.inkSoft)
                    }
                    .overlay(alignment: .top) {
                        if isActive {
                            Text(zone.label)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(YolkColor.ink)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(YolkColor.shell.opacity(0.95), in: Capsule())
                                .fixedSize()
                                .offset(y: -24)
                        }
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .position(
                    x: size.width * anchor.x,
                    y: size.height * anchor.y
                )
            }
        }
    }

    // MARK: Theme strip

    private var themeStrip: some View {
        VStack(spacing: YolkSpace.xs) {
            HStack {
                Text("themes").font(YolkType.label).tracking(1.5).textCase(.uppercase)
                    .foregroundStyle(YolkColor.muted)
                Spacer()
            }
            .padding(.horizontal, YolkSpace.lg)
            .padding(.top, YolkSpace.sm)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: YolkSpace.sm) {
                    ForEach(RoomThemes.all) { t in
                        themeChip(t)
                    }
                }
                .padding(.horizontal, YolkSpace.lg)
                .padding(.vertical, 10)
            }
        }
    }

    private func themeChip(_ t: RoomTheme) -> some View {
        let isOwned = t.cost == 0 || wallet.has(t.id)
        let isActive = themeID == t.id
        return Button { tapTheme(t) } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [Color(hex: t.wallTop), Color(hex: t.wallBottom)],
                            startPoint: .top, endPoint: .bottom
                        )
                        Color(hex: t.floor).frame(height: 18)
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(YolkColor.ink, lineWidth: isActive ? 2.5 : 0))
                    Circle()
                        .fill(Color(hex: t.accent))
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        .padding(5)
                }
                Text(t.name).font(YolkType.bodySmall).foregroundStyle(YolkColor.ink).lineLimit(1)
                priceLabel(owned: isOwned, inUse: isActive, cost: t.cost)
            }
            .frame(width: 64)
        }
        .buttonStyle(.plain)
    }

    // MARK: Zone tray

    private func zoneTray(_ zone: RoomDecor.Zone) -> some View {
        let pieces = RoomDecorCatalog.all.filter { $0.zone == zone }
        let placedID = placed?[zone.rawValue]
        return VStack(spacing: YolkSpace.xs) {
            HStack {
                Text(zone.label).font(YolkType.label).tracking(1.5).textCase(.uppercase)
                    .foregroundStyle(YolkColor.muted)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { activeZone = nil }
                    Haptics.shared.select()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(YolkColor.muted)
                        .padding(8)
                        .background(YolkColor.shell2, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, YolkSpace.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: YolkSpace.sm) {
                    // Clear chip
                    Button {
                        place(nil, in: zone)
                        withAnimation { activeZone = nil }
                    } label: {
                        VStack(spacing: 5) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(YolkColor.shell2)
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(YolkColor.muted)
                            }
                            .frame(width: 68, height: 68)
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(YolkColor.line, lineWidth: 1))
                            Text("clear").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted).lineLimit(1)
                            Text(" ").font(.caption2)   // spacer to match price label height
                        }
                        .frame(width: 68)
                    }
                    .buttonStyle(.plain)

                    ForEach(pieces) { piece in
                        let owned = wallet.has(piece.id)
                        let isPlaced = placedID == piece.id
                        Button { tapPiece(piece, in: zone) } label: {
                            VStack(spacing: 5) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14).fill(YolkColor.shell2)
                                    RoomDecorView(kind: piece.kind)
                                        .frame(width: 52, height: 52)
                                }
                                .frame(width: 68, height: 68)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(isPlaced ? YolkColor.ink : Color.clear, lineWidth: 2.5)
                                )
                                Text(piece.name).font(YolkType.bodySmall).foregroundStyle(YolkColor.ink).lineLimit(1)
                                priceLabel(owned: owned, inUse: isPlaced, cost: piece.cost, ownedWord: "placed")
                            }
                            .frame(width: 68)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, YolkSpace.lg)
                .padding(.vertical, 10)
            }
        }
        .padding(.bottom, YolkSpace.xs)
        .background(YolkColor.shell)
    }

    // MARK: Try-on bar

    private func tryOnBar(_ item: TryOnItem) -> some View {
        let canAfford = wallet.coins >= item.cost
        return VStack(spacing: YolkSpace.sm) {
            Text("trying on the \(item.name)")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.muted)
            HStack(spacing: YolkSpace.sm) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { tryOn = nil }
                    Haptics.shared.select()
                } label: {
                    Text("not now")
                        .font(YolkType.body.weight(.medium))
                        .foregroundStyle(YolkColor.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(YolkColor.shell2, in: Capsule())
                }
                .buttonStyle(.plain)

                Button { confirmBuy(item) } label: {
                    HStack(spacing: 6) {
                        YolkCoin(size: 16, animated: false)
                        Text("buy \(item.cost)")
                            .font(YolkType.body.weight(.semibold))
                    }
                    .foregroundStyle(YolkColor.shell)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(YolkColor.ink.opacity(canAfford ? 1 : 0.3), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, YolkSpace.lg)
        .padding(.bottom, YolkSpace.md)
        .padding(.top, YolkSpace.sm)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: Display helpers (theme + decor try-on overlay)

    private var tryOnDisplayTheme: RoomTheme {
        if case .theme(let t) = tryOn { return t }
        return theme
    }

    private var tryOnDisplayDecor: [RoomDecor] {
        var pieces = placedPieces
        if case .decor(let d) = tryOn, !pieces.contains(where: { $0.id == d.id }) {
            pieces.append(d)
        }
        return pieces
    }

    // MARK: Price label

    private func priceLabel(owned: Bool, inUse: Bool, cost: Int, ownedWord: String = "owned") -> some View {
        Group {
            if owned {
                Text(inUse ? ownedWord : "owned")
                    .font(.caption2)
                    .foregroundStyle(inUse ? YolkColor.ink : YolkColor.muted)
            } else {
                HStack(spacing: 3) {
                    YolkCoin(size: 11, animated: false)
                    Text("\(cost)").font(.caption2)
                }
                .foregroundStyle(wallet.coins >= cost ? YolkColor.inkSoft : YolkColor.muted.opacity(0.55))
            }
        }
    }

    // MARK: Actions

    private func tapTheme(_ t: RoomTheme) {
        let owned = t.cost == 0 || wallet.has(t.id)
        if owned {
            withAnimation(.easeInOut(duration: 0.3)) {
                themeID = t.id
                tryOn = nil
            }
            onChange()
            Haptics.shared.select()
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { tryOn = .theme(t) }
            Haptics.shared.select()
        }
    }

    private func tapPiece(_ piece: RoomDecor, in zone: RoomDecor.Zone) {
        let owned = wallet.has(piece.id)
        let placedID = placed?[zone.rawValue]
        if owned {
            if placedID == piece.id {
                // already placed -> tap to clear
                place(nil, in: zone)
            } else {
                place(piece.id, in: zone)
            }
        } else {
            // not owned -> try-on path
            withAnimation(.easeInOut(duration: 0.25)) { tryOn = .decor(piece) }
            Haptics.shared.select()
        }
    }

    private func place(_ id: String?, in zone: RoomDecor.Zone) {
        var dict = placed ?? [:]
        if let id {
            dict[zone.rawValue] = id
        } else {
            dict.removeValue(forKey: zone.rawValue)
        }
        placed = dict
        onChange()
        Haptics.shared.select()
    }

    private func confirmBuy(_ item: TryOnItem) {
        guard wallet.coins >= item.cost else {
            Haptics.shared.warn()
            dialog = YolkDialog(
                icon: .creature(vibe, .curious),
                title: "not yet!",
                message: "the \(item.name) costs \(item.cost) \(Currency.name), and you have \(wallet.coins). keep caring to earn more.",
                primaryTitle: "okay"
            )
            return
        }
        wallet.purchase(id: item.id, cost: item.cost)
        Haptics.shared.reward()
        withAnimation(.easeInOut(duration: 0.3)) {
            switch item {
            case .theme(let t):
                themeID = t.id
                onChange()
                tryOn = nil
            case .decor(let d):
                place(d.id, in: d.zone)
                tryOn = nil
            }
        }
    }
}

// MARK: Zone label helper

private extension RoomDecor.Zone {
    var label: String {
        switch self {
        case .hanging: return "hanging"
        case .wallL:   return "wall left"
        case .wallC:   return "wall center"
        case .wallR:   return "wall right"
        case .floorL:  return "floor left"
        case .floorC:  return "floor center"
        case .floorR:  return "floor right"
        }
    }
}
