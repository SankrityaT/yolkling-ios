import SwiftUI
import SwiftData
import UIKit
import YolklingCore

/// Bring a friend: share your code, redeem a friend's (or your founder) code.
/// Both parties get Yolks via the live backend (docs/sql/rewards.sql).
struct ReferralView: View {
    let vibe: Vibe
    let player: Player?
    var onReward: (Int) -> Void

    @Environment(\.modelContext) private var context
    @State private var myCode: String?
    @State private var redeemInput = ""
    @State private var working = false
    @State private var dialog: YolkDialog?
    @State private var foundingReveal: Species?

    private var trimmedCode: String {
        redeemInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Capsule().fill(YolkColor.line).frame(width: 40, height: 5).padding(.top, YolkSpace.sm)

            YolklingView(vibe: vibe, expression: .affectionate, size: 120)
                .frame(height: 150)
            Text("bring a friend")
                .font(YolkType.heading).foregroundStyle(YolkColor.ink)
            Text("you both get Yolks when they hatch with your code.")
                .font(YolkType.body).foregroundStyle(YolkColor.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, YolkSpace.lg)

            yourCode

            Divider().padding(.horizontal, YolkSpace.lg)

            VStack(spacing: YolkSpace.sm) {
                Text("have a code?")
                    .font(YolkType.label).tracking(2).textCase(.uppercase)
                    .foregroundStyle(YolkColor.muted)
                HStack(spacing: YolkSpace.sm) {
                    TextField("YOLK-XXXX", text: $redeemInput)
                        .font(YolkType.body).foregroundStyle(YolkColor.ink).tint(YolkColor.ink)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.vertical, 12).padding(.horizontal, 16)
                        .background(YolkColor.shell2, in: Capsule())
                    Button { Task { await redeem() } } label: {
                        Text(working ? "..." : "redeem")
                            .font(YolkType.body.weight(.semibold))
                            .foregroundStyle(YolkColor.shell)
                            .padding(.vertical, 12).padding(.horizontal, 18)
                            .background(YolkColor.ink.opacity(trimmedCode.isEmpty ? 0.3 : 1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(trimmedCode.isEmpty || working)
                }
            }
            .padding(.horizontal, YolkSpace.lg)

            Spacer()
        }
        .background(YolkColor.shell)
        .task { await loadCode() }
        .yolkDialog($dialog)
        .sheet(item: $foundingReveal) { sp in
            FoundingRevealView(species: sp) { wear(sp) }
        }
    }

    @ViewBuilder private var yourCode: some View {
        if let code = myCode {
            VStack(spacing: YolkSpace.sm) {
                Text("your code")
                    .font(YolkType.label).tracking(2).textCase(.uppercase)
                    .foregroundStyle(YolkColor.muted)
                HStack(spacing: YolkSpace.md) {
                    Text(code)
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                        .foregroundStyle(YolkColor.ink)
                    Button {
                        UIPasteboard.general.string = code
                        Haptics.shared.select()
                    } label: {
                        Image(systemName: "doc.on.doc").foregroundStyle(YolkColor.inkSoft)
                    }
                    .buttonStyle(.plain)
                    // The link, not the bare domain. This shared "use my code X ...
                    // yolkling.com", which dropped the recipient on the homepage and
                    // asked them to retype a code by hand. GrowFriendsView has shared a
                    // real https://yolkling.com/add/<code> deep link all along, so the
                    // HIGHER-value loop (both people get a founding species) had strictly
                    // more friction than the ordinary one. The AASA file is deployed, so
                    // this opens the app straight into add-a-friend.
                    ShareLink(item: URL(string: "https://yolkling.com/add/\(code)")!,
                              message: Text("hatch a yolkling with me. we both get a founding species.")) {
                        Image(systemName: "square.and.arrow.up").foregroundStyle(YolkColor.inkSoft)
                    }
                }
                .padding(.vertical, 12).padding(.horizontal, 20)
                .background(Color(hex: 0xFFF6E0), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: 0xF0D98A), lineWidth: 1))
            }
        } else {
            ProgressView().tint(YolkColor.muted).frame(height: 60)
        }
    }

    private var userID: String { player?.backendUserID ?? InstallID.current }

    private func loadCode() async {
        if let cached = player?.referralCode {
            myCode = cached
        } else if let code = await SupabaseClient.shared.ensureUser(userID) {
            player?.referralCode = code
            if player != nil { try? context.save() }
            myCode = code
        }
        await syncFounding()
    }

    /// Surface a founding grant the user earned as a referrer (offline when their
    /// friend redeemed). Reveals the newest one they have not seen locally.
    private func syncFounding() async {
        guard let player else { return }
        let server = await SupabaseClient.shared.myFounding(userID)
        let fresh = server.filter { !player.foundingOwnedIDs.contains($0) }
        guard !fresh.isEmpty else { return }
        player.foundingOwnedIDs.append(contentsOf: fresh)
        try? context.save()
        if let newest = fresh.last, let sp = SpeciesCatalog.founding(id: newest) {
            foundingReveal = sp
        }
    }

    private func own(_ sp: Species) {
        guard let player else { return }
        if !player.foundingOwnedIDs.contains(sp.id) { player.foundingOwnedIDs.append(sp.id) }
        try? context.save()
    }

    private func wear(_ sp: Species) {
        guard let player else { return }
        player.activeFoundingID = sp.id
        try? context.save()
    }

    private func redeem() async {
        guard !trimmedCode.isEmpty, !working else { return }
        working = true
        let result = await SupabaseClient.shared.redeem(code: trimmedCode, userID: userID)
        working = false
        if result.ok {
            Haptics.shared.reward()
            onReward(result.bonus)
            redeemInput = ""
            if let fid = result.founding, let sp = SpeciesCatalog.founding(id: fid) {
                own(sp)
                foundingReveal = sp
            } else {
                let extra = result.kind == "early_bird" ? "thanks for being here early." : "your friend got some too."
                dialog = YolkDialog(icon: .coins, title: "redeemed!",
                                    message: "+\(result.bonus) Yolks. \(extra)", primaryTitle: "love it")
            }
        } else {
            Haptics.shared.warn()
            dialog = YolkDialog(icon: .creature(vibe, .curious), title: "hmm",
                                message: reasonText(result.reason), primaryTitle: "okay")
        }
    }

    private func reasonText(_ reason: String?) -> String {
        switch reason {
        case "already_redeemed": "you've already redeemed a code."
        case "invalid_or_used": "that code isn't valid, or it's already been used."
        default: "couldn't reach the server. try again in a bit."
        }
    }
}
