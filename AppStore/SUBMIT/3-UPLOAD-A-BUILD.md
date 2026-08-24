# Uploading a build (for the account holder)

You are the Account Holder on an **Individual** Apple Developer enrolment. Apple only
lets Organization accounts add people to the signing team, so certificates and
provisioning profiles stay with you. That is why the build has to be archived from your
Mac. Nothing is wrong with the setup and there is no setting that changes it.

Everything else is already done. The bundle IDs, the App Group and the app record all
exist under your team, the project already points at team `94277H98XP`, and the app
compiles cleanly in Release.

## One time setup

1. **Install Xcode** from the Mac App Store. It is large, start it before anything else.
2. **Accept the agreement.** Sign in at developer.apple.com. If there is a banner about
   the Apple Developer Program License Agreement, accept it. Nothing can be uploaded
   until you do.
3. **Get the code.** You will be invited to the `yolkling-ios` repo on GitHub. Clone it,
   or download the ZIP if that is easier.
4. **Sign in to Xcode.** Xcode > Settings > Accounts > **+** > Apple ID > sign in with
   the same Apple ID as your developer account.

## Making a build

1. Open `Yolkling.xcodeproj`.
2. At the top of the window, set the run destination to **Any iOS Device (arm64)**.
   This matters. Archive is greyed out while a simulator is selected.
3. Menu bar: **Product > Archive**. It takes a few minutes.
4. The Organizer window opens with the archive listed. Click **Distribute App**.
5. Choose **App Store Connect**, then **Upload**, then keep clicking Next and accept the
   defaults. Let it manage signing automatically.
6. It uploads, then says processing. That part is Apple's side and takes 5 to 30 minutes.

Once it finishes processing, the build appears in App Store Connect under TestFlight, and
it can be attached to the 1.0 submission.

## If something goes wrong

**"Archive" is greyed out** - the destination is still a simulator. Set it to Any iOS
Device.

**"No account for team" or "no profiles found"** - Xcode is not signed in, or it is signed
in with a different Apple ID than the developer account. Check Xcode > Settings >
Accounts.

**"Cannot be used with this account"** - the License Agreement is still unaccepted. Go
back to step 2.

**It uploads but never appears** - processing genuinely can take half an hour, and Apple
emails you if it fails. Give it that long before assuming anything.

## What NOT to change

Do not change the bundle identifier, the version number, or the team in the project.
They are already correct and matched to the App Store Connect record. Just Archive and
upload.
