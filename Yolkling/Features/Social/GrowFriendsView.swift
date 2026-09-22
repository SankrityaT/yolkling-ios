import SwiftUI
import YolklingCore

/// The "grow your circle" section: add by code, share invite link, show QR,
/// scan a friend's QR, and an invite nudge. Lives inside the redesigned Friends tab.
struct GrowFriendsView: View {
    let store: SocialStore
    let myCode: String
    let vibe: Vibe
    let onAdded: () -> Void

    @Environment(Router.self) private var router
    @State private var addCode = ""
    /// Owned by FriendsView so results show over the whole screen. This section sits at
    /// the bottom of a scrolling list; a dialog attached here was confined to the section
    /// and, once you had a few friends, landed below the fold where nobody saw it.
    @Binding var dialog: YolkDialog?
    @State private var showQR = false
    @State private var showScanner = false

    /// Redeem a code that arrived via a tapped invite link.
    ///
    /// Redemption lives here rather than in HomeView so there's exactly one code path
    /// for "become friends" — typed, scanned, or linked all land on `store.addFriend`
    /// and the same result dialog.
    private func redeemPendingLink() async {
        guard case .addFriend(let code) = router.pending else { return }
        router.consume()   // consume first: a failed redeem must not replay forever
        let r = await store.addFriend(code: code)
        handleResult(r, clearCode: false)
    }

    private var inviteURL: URL {
        URL(string: "https://yolkling.com/add/\(myCode)")!
    }

    var body: some View {
        VStack(spacing: YolkSpace.md) {
            // 1. Add-by-code field
            addRow

            // 2. Share invite link
            ShareLink(item: inviteURL) {
                Text("share invite link")
                    .font(YolkType.body.weight(.medium))
                    .foregroundStyle(YolkColor.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(YolkColor.shell2, in: Capsule())
            }
            .buttonStyle(.plain)

            // 3. Show my QR / Scan a friend (side by side)
            HStack(spacing: YolkSpace.sm) {
                Button { showQR = true } label: {
                    Text("show my QR")
                        .font(YolkType.bodySmall.weight(.medium))
                        .foregroundStyle(YolkColor.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(YolkColor.shell2, in: Capsule())
                }
                .buttonStyle(.plain)

                Button { showScanner = true } label: {
                    Text("scan a friend")
                        .font(YolkType.bodySmall.weight(.medium))
                        .foregroundStyle(YolkColor.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(YolkColor.shell2, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            // 5. +50 invite nudge
            Text("invite a friend and you both get +50 yolks")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // 6. Always-true nudge (the empty state itself lives in FriendsView)
            Text("add a friend by their code, or share yours")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.muted)
                .multilineTextAlignment(.center)
                .padding(.top, YolkSpace.xs)
                .fixedSize(horizontal: false, vertical: true)
        }
        // 3a. QR sheet
        .sheet(isPresented: $showQR) {
            QRSheet(myCode: myCode)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        // 4. Scanner sheet
        .sheet(isPresented: $showScanner) {
            QRScannerView { code in
                showScanner = false
                Task { await addFriendFromScan(code) }
            }
            .ignoresSafeArea()
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task { await redeemPendingLink() }
        // Friends may already be open when a second link arrives; `.task` only runs once.
        .onChange(of: router.pending) { _, link in if link != nil { Task { await redeemPendingLink() } } }
    }

    // MARK: - Subviews

    private var addRow: some View {
        HStack(spacing: YolkSpace.sm) {
            TextField("a friend's code", text: $addCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(YolkType.body)
                .foregroundStyle(YolkColor.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(YolkColor.shell2, in: Capsule())

            Button { addByCode() } label: {
                Text("add")
                    .font(YolkType.body.weight(.semibold))
                    .foregroundStyle(YolkColor.shell)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        YolkColor.ink.opacity(addCode.trimmingCharacters(in: .whitespaces).isEmpty ? 0.3 : 1),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
            .disabled(addCode.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Actions

    private func addByCode() {
        let code = addCode.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return }
        Task {
            let r = await store.addFriend(code: code)
            handleResult(r, clearCode: true)
        }
    }

    private func addFriendFromScan(_ code: String) async {
        let r = await store.addFriend(code: code)
        handleResult(r, clearCode: false)
    }

    private func handleResult(_ r: AddFriendResult, clearCode: Bool) {
        if r.ok {
            Haptics.shared.reward()
            if clearCode { addCode = "" }
            onAdded()
            dialog = YolkDialog(
                icon: .creature(vibe, .affectionate),
                title: "new friend!",
                message: "you and \(r.name ?? "your friend") are connected. say hi with a kind note.",
                primaryTitle: "yay"
            )
        } else {
            Haptics.shared.warn()
            let msg: String
            switch r.reason {
            case "thats_you":    msg = "that's your own code, silly."
            case "invalid_code": msg = "that code didn't match anyone. double-check it?"
            default:             msg = "couldn't reach the server. try again in a sec."
            }
            dialog = YolkDialog(
                icon: .creature(vibe, .curious),
                title: "hmm",
                message: msg,
                primaryTitle: "okay"
            )
        }
    }
}

// MARK: - QR Sheet

/// A simple sheet that shows the user's own QR code centred on a warm background.
private struct QRSheet: View {
    let myCode: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Text("your code")
                .font(YolkType.label)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(YolkColor.muted)

            QRCodeView(text: "https://yolkling.com/add/\(myCode)")
                .padding(YolkSpace.md)
                .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 20))

            Text(myCode)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(YolkColor.ink)

            Text("let a friend scan this to add you")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("done") { dismiss() }
                .font(YolkType.body.weight(.semibold))
                .foregroundStyle(YolkColor.shell)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(YolkColor.ink, in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(YolkSpace.lg)
        .frame(maxWidth: .infinity)
        .background(YolkColor.shell.ignoresSafeArea())
    }
}
