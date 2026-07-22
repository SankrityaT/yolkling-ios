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
    @State private var showFeedback = false
    @State private var showHowTo = false
    @State private var showDeleteConfirm = false
    @State private var deleting = false
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

                    Text("we only keep a private sign-in id. no name, no email.")
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

            widgetRow

            dailyHello

            Spacer()

            Button { showFeedback = true } label: {
                Label("share a thought", systemImage: "bubble.left.fill")
                    .font(YolkType.body).foregroundStyle(YolkColor.inkSoft)
            }
            .buttonStyle(.plain)

            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Text(deleting ? "deleting..." : "delete my account")
                    .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
            }
            .buttonStyle(.plain)
            .disabled(deleting)
            .padding(.bottom, YolkSpace.lg)
        }
        .alert("delete your account?", isPresented: $showDeleteConfirm) {
            Button("cancel", role: .cancel) {}
            Button("delete", role: .destructive) { deleteAccount() }
        } message: {
            Text("this erases \(name), your collection, your friends, and everything you've saved, on this device and our server. it can't be undone.")
        }
        .frame(maxWidth: .infinity)
        .background(YolkColor.shell)
        .sheet(isPresented: $showFeedback) {
            FeedbackView(vibe: vibe, userID: player?.backendUserID ?? InstallID.current)
                .presentationDetents([.medium, .large])
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

    /// Full account deletion (App Store 5.1.1(v)): erase the server rows, then wipe
    /// the local creature so the app returns to a clean onboarding.
    private func deleteAccount() {
        guard !deleting else { return }
        deleting = true
        let backendID = player?.backendUserID ?? InstallID.current
        Task {
            _ = await SupabaseClient.shared.deleteAccount(userID: backendID)
            if let player { context.delete(player) }
            try? context.save()
            deleting = false
            dismiss()
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
