import SwiftUI
import SwiftData
import AuthenticationServices

/// The profile sheet: your creature, and Sign in with Apple to save + sync
/// across devices. The flow is wired and ready; it only *completes* once the
/// Sign in with Apple capability + app signing are enabled (a dev account).
struct ProfileView: View {
    let vibe: Vibe
    let name: String
    let player: Player?

    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var signInError: String?
    @State private var showDeleteConfirm = false
    @State private var deleting = false
    @State private var showFeedback = false
    @State private var showPlus = false
    @State private var showHowTo = false
    @State private var subs = SubscriptionStore()
    @State private var notifyOn = YolkNotifications.isEnabled
    @State private var notifyTime = Calendar.current.date(
        from: DateComponents(hour: YolkNotifications.hour, minute: YolkNotifications.minute)) ?? Date()

    private var isSignedIn: Bool { player?.appleUserID != nil }

    var body: some View {
        VStack(spacing: YolkSpace.lg) {
            Capsule().fill(YolkColor.line).frame(width: 40, height: 5).padding(.top, YolkSpace.sm)

            YolklingView(vibe: vibe, expression: .happy, size: 130)
                .frame(height: 160)
            Text(name)
                .font(YolkType.heading)
                .foregroundStyle(YolkColor.ink)

            if isSignedIn {
                Label("saved with Apple", systemImage: "checkmark.seal.fill")
                    .font(YolkType.body)
                    .foregroundStyle(YolkColor.inkSoft)
            } else {
                VStack(spacing: YolkSpace.sm) {
                    Text("save \(name) forever, and sync across your devices.")
                        .font(YolkType.body)
                        .foregroundStyle(YolkColor.muted)
                        .multilineTextAlignment(.center)

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = []   // only the stable user id; no name/email (privacy)
                    } onCompletion: { result in
                        handle(result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 50)
                    .clipShape(Capsule())

                    // Was "end to end encrypted. even we can't read your data." — the
                    // crypto layer isn't built yet (docs/CLAIMS.md), so that was a false
                    // security claim. This says only what's actually true today.
                    Text("your journal stays on your device. we never ask for your name or email.")
                        .font(YolkType.bodySmall)
                        .foregroundStyle(YolkColor.muted)
                }
                .padding(.horizontal, YolkSpace.lg)
            }

            if let signInError {
                Text(signInError)
                    .font(YolkType.bodySmall)
                    .foregroundStyle(Color(hex: 0xE05A6E))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, YolkSpace.lg)
            }

            plusRow

            widgetRow

            dailyHello

            Spacer()

            Button { showFeedback = true } label: {
                Label("share a thought", systemImage: "bubble.left.fill")
                    .font(YolkType.body).foregroundStyle(YolkColor.inkSoft)
            }
            .buttonStyle(.plain)

            // App Store Guideline 5.1.1(v): an app that lets you create an account must
            // let you delete it in-app. Its absence is a rejection.
            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Text(deleting ? "deleting…" : "delete my account")
                    .font(YolkType.bodySmall)
                    .foregroundStyle(Color(hex: 0xE05A6E))
            }
            .buttonStyle(.plain)
            .disabled(deleting)
            .padding(.bottom, YolkSpace.lg)
        }
        .confirmationDialog("delete your account?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("delete everything", role: .destructive) { deleteAccount() }
            Button("keep \(name)", role: .cancel) { }
        } message: {
            Text("this removes \(name), your collection, your Yolks and your friends, on this device and on our server. it can't be undone.")
        }
        .frame(maxWidth: .infinity)
        .background(YolkColor.shell)
        .sheet(isPresented: $showFeedback) {
            FeedbackView(vibe: vibe, userID: player?.backendUserID ?? InstallID.current)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPlus) {
            PlusView(store: subs, vibe: vibe).presentationDetents([.large])
        }
        .sheet(isPresented: $showHowTo) {
            WidgetHowToView().presentationDetents([.medium])
        }
    }

    private var widgetRow: some View {
        Button { showHowTo = true } label: {
            HStack(spacing: YolkSpace.md) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.title3).foregroundStyle(YolkColor.ink).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("home screen widget")
                        .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                    Text("put your yolk right on your home screen")
                        .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(YolkColor.muted)
            }
            .padding(YolkSpace.md)
            .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, YolkSpace.lg)
        }
        .buttonStyle(.plain)
    }

    private var plusRow: some View {
        Button { showPlus = true } label: {
            HStack(spacing: YolkSpace.md) {
                Image(systemName: subs.isPlus ? "heart.fill" : "sparkles")
                    .font(.title3).foregroundStyle(YolkColor.yolkDeep).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(subs.isPlus ? "you're a supporter ♥" : "yolkling+")
                        .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                    Text(subs.isPlus ? "thank you for keeping us alive" : "keep the lights on, only if you love it")
                        .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(YolkColor.muted)
            }
            .padding(YolkSpace.md)
            .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, YolkSpace.lg)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var dailyHello: some View {
        VStack(spacing: YolkSpace.sm) {
            Toggle(isOn: $notifyOn) {
                Label("a gentle daily hello", systemImage: "bell.fill")
                    .font(YolkType.body).foregroundStyle(YolkColor.ink)
            }
            .tint(Color(hex: 0xF2B84B))
            if notifyOn {
                HStack {
                    Text("at").font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                    DatePicker("", selection: $notifyTime, displayedComponents: .hourAndMinute).labelsHidden()
                    Spacer()
                }
            }
            Text("one soft nudge a day. no badges, no nagging.")
                .font(.footnote).foregroundStyle(YolkColor.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, YolkSpace.lg)
        .onChange(of: notifyOn) { _, on in handleNotify(on: on) }
        .onChange(of: notifyTime) { _, _ in if notifyOn { handleNotify(on: true) } }
    }

    /// Delete the account server-side, then wipe everything local.
    ///
    /// The local wipe happens even if the server call fails: the user asked to be gone,
    /// and a flaky network must not trap them in an account they've asked to delete.
    /// The server row is idempotently deletable, so a retry costs nothing.
    private func deleteAccount() {
        deleting = true
        Task {
            let uid = player?.backendUserID ?? InstallID.current
            _ = await SupabaseClient.shared.deleteAccount(userID: uid)

            YolkNotifications.disable()
            if let player { context.delete(player) }
            try? context.save()
            InstallID.reset()   // otherwise the "deleted" player returns as the same user

            deleting = false
            Haptics.shared.warn()
            dismiss()
        }
    }

    private func handleNotify(on: Bool) {
        Task {
            if on {
                let c = Calendar.current.dateComponents([.hour, .minute], from: notifyTime)
                let ok = await YolkNotifications.enable(hour: c.hour ?? 9, minute: c.minute ?? 0)
                if !ok { notifyOn = false }
            } else {
                YolkNotifications.disable()
            }
        }
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                player?.appleUserID = credential.user
                try? context.save()
                signInError = nil
            }
        case .failure(let error):
            signInError = "sign in didn't complete. \(error.localizedDescription)"
        }
    }
}
