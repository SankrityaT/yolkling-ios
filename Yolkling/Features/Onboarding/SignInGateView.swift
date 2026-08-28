import SwiftUI
import AuthenticationServices
import YolklingCore

/// The sign-in gate.
///
/// Yolkling was built local-first: everything worked with no network and no account, and
/// signing in was an optional upgrade you found later in Profile. That is a kinder
/// default, but it left one thing permanently broken. Cloud backup only ever writes for
/// a signed-in user, so an anonymous player has no `player_state` row - and the nightly
/// wander reads `lastCareDate` out of exactly that row. Anonymous players could never
/// become eligible for the server-side wander at all. The live table has zero rows.
///
/// An account also makes the creature survivable. `InstallID` lives in UserDefaults and
/// dies with the app, so "it can't truly die" was only true for people who had happened
/// to sign in.
///
/// **Nothing but the stable user id is requested.** `requestedScopes = []` means no name
/// and no email, which is the least Apple will let an app ask for and all this needs.
struct SignInGateView: View {
    /// Called with the stable Apple user id once sign-in succeeds.
    var onSignedIn: (String) -> Void

    /// What went wrong, if anything. Typed rather than a string, because the two cases
    /// need different UI: one is fixable in Settings and the other is worth retrying.
    private enum Failure: Equatable {
        /// No Apple Account on the device. Nothing to retry; they have to go to Settings.
        case noAppleAccount
        /// Anything else. Usually transient.
        case failed
    }

    /// What went wrong, kept even while the card is hidden.
    @State private var failure: Failure?
    /// Whether the card is on screen. Separate from `failure` on purpose: dismissing
    /// should put the card away without forgetting what happened, so it can be summoned
    /// back without making the person fail the sign-in a second time to see it again.
    @State private var showFailure = false
    @State private var signingIn = false

    var body: some View {
        ZStack {
            OnboardingBackdrop(tint: YolkColor.yolk)

            VStack(spacing: YolkSpace.lg) {
                Spacer()

                YolklingView(vibe: .yolk, expression: .happy, size: 150)
                    .frame(height: 185)

                VStack(spacing: YolkSpace.sm) {
                    Text("first, so they can't get lost")
                        .font(YolkType.title)
                        .foregroundStyle(YolkColor.ink)
                        .multilineTextAlignment(.center)
                        // Without `fixedSize` a Text in a height-constrained stack
                        // truncates rather than wraps: on an SE this headline came out as
                        // "first, so they can…", which is a worse first impression than
                        // no headline at all.
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.8)
                        .yolkEntrance(0)

                    Text("your yolkling lives on your phone, and signing in keeps a copy safe so they survive a new phone, a reinstall, or a bad day. it is also how friends find you.")
                        .font(YolkType.body)
                        .foregroundStyle(YolkColor.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .yolkEntrance(1)
                }
                .padding(.horizontal, YolkSpace.lg)

                Text("we only ever ask for a sign-in id. no name, no email.")
                    .font(YolkType.bodySmall)
                    .foregroundStyle(YolkColor.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, YolkSpace.lg)
                    .yolkEntrance(2)

                if let failure, showFailure {
                    errorCard(failure)
                        .padding(.horizontal, YolkSpace.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if failure != nil {
                    // Dismissed, not forgotten. Quiet enough to ignore, findable when the
                    // sign-in fails again and the person wants to know why.
                    Button {
                        Haptics.shared.tick()
                        withAnimation(.snappy) { showFailure = true }
                    } label: {
                        Text("having trouble?")
                            .font(YolkType.bodySmall)
                            .foregroundStyle(YolkColor.muted)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                Spacer()
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: YolkSpace.xs) {
                    SignInWithAppleButton(.signIn) { request in
                        // Only the stable user id. No name, no email.
                        request.requestedScopes = []
                        // Nonced so the identity token cannot be replayed into our
                        // backend from somewhere else. Apple gets the hash, Supabase
                        // gets the raw value to check it against.
                        request.nonce = SupabaseAuth.shared.beginNonce()
                    } onCompletion: { result in
                        handle(result)
                    }
                    // Always black. The app pins itself to light mode at the root, but
                    // `colorScheme` here still reports the SYSTEM setting, so on a device
                    // in dark mode this resolved to the white button - white on cream,
                    // nearly invisible, as the single most important control on screen.
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, YolkSpace.lg)
                .padding(.bottom, YolkSpace.lg)
            }
        }
    }

    /// The failure, presented as something a person can act on.
    ///
    /// Was a line of red text containing Apple's `localizedDescription`, which for the
    /// commonest failure reads "com.apple.AuthenticationServices.AuthorizationError
    /// error 1000." — a string that names no problem and offers no way out, shown at the
    /// exact moment someone is deciding whether this app is worth their time.
    ///
    /// A dead end is the real bug here, not the wording: this screen is the only way
    /// into the app, so a person who cannot sign in has nowhere to go. The Settings
    /// button is the way out.
    @ViewBuilder
    private func errorCard(_ failure: Failure) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(failure == .noAppleAccount
                     ? "no Apple Account on this phone"
                     : "that didn't go through")
                    .font(YolkType.body.weight(.semibold))
                    .foregroundStyle(YolkColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: YolkSpace.sm)
                Button {
                    Haptics.shared.tick()
                    withAnimation(.snappy) { showFailure = false }
                } label: {
                    YolkGlyph(kind: .close, size: 11, weight: 0.14)
                        .foregroundStyle(YolkColor.muted)
                        .frame(width: 11, height: 11)
                        .padding(7)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("dismiss")
            }

            Text(failure == .noAppleAccount
                 ? "tap your name at the top of Settings to add one."
                 : "give it another go.")
                .font(YolkType.bodySmall)
                .foregroundStyle(YolkColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            if failure == .noAppleAccount {
                Button {
                    Haptics.shared.tick()
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("open Settings")
                        .font(YolkType.bodySmall.weight(.semibold))
                        .foregroundStyle(YolkColor.shell)
                        .padding(.horizontal, YolkSpace.md).padding(.vertical, 8)
                        .background(YolkColor.ink, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, YolkSpace.md)
        .padding(.vertical, YolkSpace.sm)
        .background(YolkColor.shell2, in: RoundedRectangle(cornerRadius: 18))
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        signingIn = false
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                withAnimation(.snappy) { failure = .failed; showFailure = true }
                return
            }
            Haptics.shared.reward()
            withAnimation(.snappy) { failure = nil; showFailure = false }

            // Trade the Apple token for a real Supabase session, so backend calls carry
            // a verifiable identity instead of asserting one. Deliberately not awaited
            // before continuing: a server hiccup must not stand between someone and
            // their creature. Everything works locally without it, and the next launch
            // retries.
            if let tokenData = credential.identityToken,
               let token = String(data: tokenData, encoding: .utf8) {
                Task { await SupabaseAuth.shared.signIn(appleIdentityToken: token) }
            }
            onSignedIn(credential.user)
        case .failure(let err):
            // A cancellation is not an error worth shouting about; the person simply
            // changed their mind and the button is still right there.
            let code = (err as NSError).code
            if code == ASAuthorizationError.canceled.rawValue {
                withAnimation(.snappy) { failure = nil; showFailure = false }
                return
            }
            Haptics.shared.warn()
            withAnimation(.snappy) {
                failure = code == ASAuthorizationError.unknown.rawValue ? .noAppleAccount : .failed
                // A fresh failure always surfaces, even if the last one was dismissed.
                showFailure = true
            }
        }
    }
}
