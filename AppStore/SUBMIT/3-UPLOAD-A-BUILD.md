# Uploading a build (for the account holder)

You are the Account Holder on an **Individual** Apple Developer enrolment. Apple only
lets Organization accounts add people to the signing team, so certificates and
provisioning profiles stay with you. That is why the build has to come from your Mac.
Nothing is misconfigured and there is no setting that changes it.

The code is on **`main`** and is ready: it compiles in Release, all 70 tests pass, and
the project already points at team `94277H98XP`.

---

## Do these two FIRST, before touching Xcode

Both are on the Apple website, both take two minutes, and both will waste your evening
if you skip them.

### 1. Paid Applications Agreement

App Store Connect > **Business** (or Agreements, Tax, and Banking). If "Paid
Applications" is anything other than Active, accept it and fill in the tax and banking
forms.

Only the Account Holder can do this, which is you. Until it is Active, the two
subscriptions cannot be submitted and the paywall inside the app shows "the supporter
tier isn't available right now" to everyone, including Apple's reviewer.

### 2. Check the Family Controls entitlement. This is the one that bites.

developer.apple.com > Certificates, Identifiers & Profiles > **Identifiers** >
`com.yolkling.ios` > look for **Family Controls** in the capability list.

The app uses Screen Time, which needs this entitlement, and Apple does NOT grant it
automatically. It is a separate request with a review that takes a couple of weeks.

- **If it is enabled:** carry on, everything below will work.
- **If it is missing or greyed out:** stop and tell Sankritya before archiving. Xcode
  will fail to build a distribution profile and the error will be confusing. There is a
  decision to make (request it and wait, or ship 1.0 without the Screen Time piece and
  add it in 1.1) and it is quicker to make that call than to fight the error.

Also confirm these are ticked on `com.yolkling.ios` while you are there: **Sign in with
Apple**, **HealthKit**, **App Groups**, **Associated Domains**. Those are all standard
and need no approval, they just need to be on.

---

## One time setup

1. **Install Xcode** from the Mac App Store. It is large, start the download first.
2. **Accept the agreement.** Sign in at developer.apple.com. If a banner about the Apple
   Developer Program License Agreement appears, accept it.
3. **Sign in to Xcode.** Xcode > Settings > Accounts > **+** > Apple ID, using the same
   Apple ID as your developer account.
4. **Get the code.** You are already a collaborator on `yolkling-ios`. In Terminal:

   ```
   git clone https://github.com/SankrityaT/yolkling-ios.git
   cd yolkling-ios
   ```

   `main` is the right branch and is what you get by default. You do not need to install
   anything else: the Xcode project file is committed, so there is no build tooling to
   set up.

---

## Making the build

1. Open `Yolkling.xcodeproj` (double click it in the `yolkling-ios` folder).
2. At the top of the window, set the run destination to **Any iOS Device (arm64)**.
   This matters. Archive stays greyed out while a simulator is selected.
3. Menu bar: **Product > Archive**. Takes a few minutes.
4. The Organizer window opens with the archive listed. Click **Distribute App**.
5. Choose **App Store Connect**, then **Upload**, then Next through the defaults. Let it
   manage signing automatically.
6. It uploads, then says processing. That is Apple's side, 5 to 30 minutes.

When processing finishes the build appears in App Store Connect under TestFlight, and can
be attached to the 1.0 submission.

---

## If something goes wrong

**"Archive" is greyed out.** The destination is still a simulator. Set it to Any iOS
Device (arm64).

**"Provisioning profile doesn't include the com.apple.developer.family-controls
entitlement"** or Xcode cannot create a profile. This is the Family Controls thing from
step 2. Stop and check that before doing anything else.

**"No account for team 94277H98XP"** or signing errors mentioning the team. Xcode is not
signed in. Xcode > Settings > Accounts, add the Apple ID, then let it Download Manual
Profiles from the same screen.

**Upload rejected for a missing icon or an icon with transparency.** Should not happen,
the icon is 1024x1024 RGB with no alpha and was checked. If it does, send the exact
message over.

**Anything else.** Screenshot the whole Xcode window, including the left sidebar, and
send it. The error text alone is usually not enough to tell what happened.

---

## What you do NOT need to do

- No need to install xcodegen, CocoaPods, Homebrew or anything else.
- No need to edit any code, version number or build number. 1.0.0 build 1 is set.
- No need to create the App Store listing. It is already filled in.
- No need to touch the screenshots. Already uploaded.
