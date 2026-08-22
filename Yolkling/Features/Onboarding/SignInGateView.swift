import SwiftUI
import AuthenticationServices

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

    @State private var error: String?

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
                    .padding(.horizontal, YolkSpace.lg)
                    .yolkEntrance(2)

                if let error {
                    Text(error)
                        .font(YolkType.bodySmall)
                        .foregroundStyle(Color(hex: 0xE05A6E))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, YolkSpace.lg)
                }

                Spacer()
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: YolkSpace.xs) {
                    SignInWithAppleButton(.signIn) { request in
                        // Only the stable user id. No name, no email.
                        request.requestedScopes = []
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

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                error = "sign in didn't complete. please try again."
                return
            }
            Haptics.shared.reward()
            error = nil
            onSignedIn(credential.user)
        case .failure(let err):
            // A cancellation is not an error worth shouting about; the person simply
            // changed their mind and the button is still right there.
            if (err as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            Haptics.shared.warn()
            error = "sign in didn't complete. \(err.localizedDescription)"
        }
    }
}
