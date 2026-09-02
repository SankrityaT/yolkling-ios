import SwiftUI
import SwiftData
import AuthenticationServices
import RevenueCatUI
import YolklingCore

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
    @State private var showCustomerCenter = false
    @State private var showDeleteConfirm = false
    @State private var deleting = false
    @State private var showFeedback = false
    @State private var showHowTo = false
    @State private var showPlus = false
    @State private var retrying = false
    @State private var notifyDenied = false
    private var subs: SubscriptionStore { .shared }
    @State private var notifyOn = YolkNotifications.isEnabled
    @State private var notifyTime = Calendar.current.date(
        from: DateComponents(hour: YolkNotifications.hour, minute: YolkNotifications.minute)) ?? Date()

    private var isSignedIn: Bool { player?.appleUserID != nil }

    /// Whether the backend will actually accept us.
    ///
    /// Deliberately NOT `isSignedIn`. Having an Apple id locally says nothing about
    /// whether the server ever agreed: the backend now requires a real session, so a
    /// player can hold an Apple id and still be entirely unbacked. Profile said "saved
    /// with Apple" on the strength of the local field alone, which is a false promise
    /// about someone's data on the exact screen they visit to check it.
    private var hasSession: Bool { SupabaseAuth.shared.isSignedIn }

    private var backupLine: String {
        guard let at = PlayerBackup.lastPushedAt else { return "not backed up yet" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return "backed up " + f.localizedString(for: at, relativeTo: .now)
    }

    var body: some View {
        // The close button lives OUTSIDE the scroll so it is always reachable, and the
        // content scrolls under it. This screen was a plain VStack with a Spacer, which
        // meant that once somebody subscribed and the supporter row appeared, the content
        // grew past the screen: the top slid under the status bar and the close button
        // became untappable. Reported from device testing as being unable to get out of
        // this screen after paying, which is the worst possible place to trap somebody.
        VStack(spacing: 0) {
            HStack {
                YolkCloseButton { dismiss() }
                Spacer(minLength: YolkSpace.lg)
            }
            .padding(.horizontal, YolkSpace.lg)
            .padding(.top, YolkSpace.sm)
            .padding(.bottom, YolkSpace.xs)

            ScrollView {
                VStack(spacing: YolkSpace.lg) {

            YolklingView(vibe: vibe, expression: .happy, size: 130, supporterGlow: subs.isPlus)
                .frame(height: 160)
            Text(name)
                .font(YolkType.heading)
                .foregroundStyle(YolkColor.ink)

            if isSignedIn {
                VStack(spacing: 4) {
                    if hasSession, PlayerBackup.lastPushedAt != nil {
                        Label(backupLine, systemImage: "checkmark.seal.fill")
                            .font(YolkType.body)
                            .foregroundStyle(YolkColor.inkSoft)
                    } else if !hasSession {
                        // Signed in with Apple on THIS device, but the server session was
                        // never established, so every backup is refused before it starts.
                        // This used to fall into the branch below and offer "try again",
                        // which retried the upload rather than the sign-in and could
                        // therefore never succeed. Signing in again is the only thing that
                        // fixes it, so that is what we offer.
                        Label("sign in again to save a copy", systemImage: "exclamationmark.circle")
                            .font(YolkType.body)
                            .foregroundStyle(YolkColor.inkSoft)
                        Text("\(name) is safe on this phone. we lost the connection to your account, so signing in again is what gets a copy saved.")
                            .font(YolkType.bodySmall)
                            .foregroundStyle(YolkColor.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, YolkSpace.lg)

                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = []
                            request.nonce = SupabaseAuth.shared.beginNonce()
                        } onCompletion: { result in
                            handle(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 46)
                        .clipShape(Capsule())
                        .padding(.horizontal, YolkSpace.lg)
                    } else {
                        // Signed in with Apple, but nothing has reached the server. Says
                        // so plainly instead of showing a tick, and offers the one
                        // action that can fix it.
                        Label("not backed up yet", systemImage: "exclamationmark.circle")
                            .font(YolkType.body)
                            .foregroundStyle(YolkColor.inkSoft)
                        Text("your yolkling is safe on this phone. we just haven't been able to save a copy yet.")
                            .font(YolkType.bodySmall)
                            .foregroundStyle(YolkColor.muted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, YolkSpace.lg)
                        Button {
                            Haptics.shared.tick()
                            retryBackup()
                        } label: {
                            Text(retrying ? "trying…" : "try again")
                                .font(YolkType.bodySmall.weight(.semibold))
                                .foregroundStyle(YolkColor.shell)
                                .padding(.horizontal, YolkSpace.md).padding(.vertical, 8)
                                .background(YolkColor.ink, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(retrying)
                        .padding(.top, 2)
                    }
                }
            } else {
                VStack(spacing: YolkSpace.sm) {
                    Text("save \(name) forever, and sync across your devices.")
                        .font(YolkType.body)
                        .foregroundStyle(YolkColor.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = []   // only the stable user id; no name/email (privacy)
                        request.nonce = SupabaseAuth.shared.beginNonce()
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
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, YolkSpace.lg)
            }

            if let signInError {
                Text(signInError)
                    .font(YolkType.bodySmall)
                    .foregroundStyle(Color(hex: 0xE05A6E))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, YolkSpace.lg)
            }

            plusRow

            manageRow

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
                .padding(.bottom, YolkSpace.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .confirmationDialog("delete your account?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("delete everything", role: .destructive) { deleteAccount() }
            Button("keep \(name)", role: .cancel) { }
        } message: {
            Text("this removes \(name), your collection, your Yolks and your friends, on this device and on our server. it can't be undone.")
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .background(YolkColor.shell)
        .sheet(isPresented: $showFeedback) {
            FeedbackView(vibe: vibe, userID: player?.backendUserID ?? InstallID.current)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPlus) {
            PlusView(store: subs, vibe: vibe).presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showHowTo) {
            WidgetHowToView().presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        // Refresh entitlement on dismiss: someone may have just cancelled in here, and
        // the app should reflect that immediately rather than insisting they're still
        // a supporter until the next launch.
        .presentCustomerCenter(isPresented: $showCustomerCenter, onDismiss: {
            showCustomerCenter = false
            Task { await subs.refreshEntitlement() }
        })
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
                        .fixedSize(horizontal: false, vertical: true)
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

    /// Managing a subscription, in-app, in one tap.
    ///
    /// `MONETIZATION.md` warns that billing dark patterns wreck a wellness brand, and
    /// the standard dark pattern is exactly this: make subscribing one tap and cancelling
    /// a scavenger hunt through Settings. Customer Center is the opposite — cancel,
    /// refund, and plan change all live here, one tap from the same row you subscribed
    /// from. It costs a little revenue on purpose. An app about not manipulating people
    /// does not get to manipulate them at the till.
    @ViewBuilder private var manageRow: some View {
        if subs.isPlus {
            Button { showCustomerCenter = true } label: {
                HStack(spacing: YolkSpace.md) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3).foregroundStyle(YolkColor.inkSoft).frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("manage your support")
                            .font(YolkType.body.weight(.semibold)).foregroundStyle(YolkColor.ink)
                        Text("change plan, pause, or cancel, right here")
                            .font(YolkType.bodySmall).foregroundStyle(YolkColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                        .foregroundStyle(YolkColor.muted)
                }
                .padding(YolkSpace.md)
                .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, YolkSpace.lg)
            }
            .buttonStyle(.plain)
        }
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
                        .fixedSize(horizontal: false, vertical: true)
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
            if notifyDenied {
                Text("notifications are off for Yolkling in Settings. turn them on there, then flip this again.")
                    .font(.caption2).foregroundStyle(YolkColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
        guard !deleting else { return }
        deleting = true
        Task {
            let uid = player?.backendUserID ?? InstallID.current
            _ = await SupabaseClient.shared.deleteAccount(userID: uid)

            YolkNotifications.disable()
            // Drop the RevenueCat identity and the legacy migration flag with the account.
            // The stipend high-water mark lives on the Player and dies with it, so a
            // re-onboard under the same Apple ID would otherwise see a lifetime balance
            // against a zero mark and re-credit the lot, repeatably.
            await SubscriptionStore.shared.signOutOfPurchases()
            UserDefaults.standard.removeObject(forKey: "yolk.stipendSeen")
            UserDefaults.standard.removeObject(forKey: "yolk.stipendSeen.migrated")
            SupabaseAuth.shared.signOut()
            // The App Group outlives the SwiftData wipe, so the widget would keep showing
            // the deleted creature by name until something else published over it.
            WidgetSnapshot.clear()
            WidgetPublisher.reload()
            if let player { context.delete(player) }
            try? context.save()
            InstallID.reset()   // otherwise the "deleted" player returns as the same user

            deleting = false
            Haptics.shared.warn()
            dismiss()
        }
    }

    /// Force a backup now, so someone who saw "not backed up yet" can do something
    /// about it rather than waiting and hoping. `force` bypasses the five minute
    /// throttle, which exists to stop a push per tap and would otherwise make this
    /// button appear to do nothing.
    private func retryBackup() {
        guard let player, !retrying else { return }
        retrying = true
        Task {
            await PlayerBackup.push(player, appleUserID: player.appleUserID, force: true)
            retrying = false
        }
    }

    private func handleNotify(on: Bool) {
        Task {
            if on {
                let c = Calendar.current.dateComponents([.hour, .minute], from: notifyTime)
                let ok = await YolkNotifications.enable(hour: c.hour ?? 9, minute: c.minute ?? 0)
                if !ok {
                    // The toggle snapping back on its own with no words looked like a
                    // glitch. iOS only prompts once, so from here the ONLY fix is
                    // Settings — say so.
                    notifyOn = false
                    notifyDenied = true
                }
            } else {
                YolkNotifications.disable()
                notifyDenied = false
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
                if let tokenData = credential.identityToken,
                   let token = String(data: tokenData, encoding: .utf8) {
                    Task {
                        // Awaited, and followed straight by a forced push. Signing in
                        // only establishes the session; without this the screen still
                        // reads "not backed up yet" afterwards and the person has no way
                        // to tell whether it worked. Now the fix is visibly the fix.
                        if await SupabaseAuth.shared.signIn(appleIdentityToken: token) {
                            if let player, let uid = player.appleUserID {
                                // Look BEFORE pushing. A forced push here used to race
                                // HomeView's restore pull, and when the push won it
                                // replaced the cloud creature with this device's one —
                                // then the pull returned the thing it had just
                                // overwritten, `isWorthRestoring` was false, and the
                                // other device's creature was gone with no dialog.
                                // If a real backup exists, leave it alone and let
                                // offerRestore ask; otherwise back this creature up.
                                let existing = await PlayerBackup.pull(appleUserID: uid)
                                if existing?.isWorthRestoring != true {
                                    await PlayerBackup.push(player, appleUserID: uid, force: true)
                                }
                            }
                        } else {
                            signInError = "couldn't reach your account. check your connection and try again."
                        }
                    }
                }
            }
        case .failure(let error):
            signInError = "sign in didn't complete. \(error.localizedDescription)"
        }
    }
}
