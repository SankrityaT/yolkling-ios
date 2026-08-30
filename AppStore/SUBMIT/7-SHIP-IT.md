# Ship 1.0: the shortest path to being on the App Store

Everything below is what is left. Nothing else blocks. Ordered so that no step waits on
a later one.

## What changed to make this fast

**The watch app is built and merged, but NOT embedded in 1.0.** Embedding it turns a
first submission into a two-platform one: a new App ID to register, Apple Watch
screenshots we do not have, and a ~4GB watchOS download on whichever Mac archives. It is
one commented line in `project.yml` and goes into 1.1.

**Build number is now 2.** Build 1 is already uploaded and App Store Connect refuses a
duplicate, so a second upload at build 1 would have failed at the last step.

---

## 1. Your friend: archive and upload (about 20 minutes)

```
cd yolkling-ios
git pull
```

Then open `Yolkling.xcodeproj`, set the destination to **Any iOS Device (arm64)**, and
**Product > Archive > Distribute App > App Store Connect > Upload**.

He does NOT need the watchOS platform for this build. That was only true while the watch
app was embedded.

Wait for it to finish processing (5 to 30 minutes) and appear in TestFlight as **1.0.0
(2)**.

## 2. You, in parallel: the three form fields that block Submit

These do not depend on the build, so do them while it uploads.

- **Paid Applications Agreement** must be Active. App Store Connect > Business. Account
  Holder only. Nothing paid can be submitted until it is.
- **Export Compliance** for the version: the app uses only standard HTTPS and Apple's own
  encryption, so answer NO to non-exempt encryption.
- **Advertising Identifier (IDFA)**: no. The app does not use it.

## 3. Subscription review screenshots (needs the build)

Both products need one before either can be submitted. Once 1.0.0 (2) is in TestFlight:
install it, open **You > yolkling+**, and screenshot the paywall with both plans visible.
Upload the same image to both products.

If the paywall says "the supporter tier isn't available right now", stop: that is
RevenueCat configuration, and `5-REVENUECAT-CHECKLIST.md` lists the causes in order of
likelihood. The top two are an offering not marked Current, and package identifiers that
are not exactly `$rc_monthly` and `$rc_annual`.

## 4. Re-paste the App Review notes

They were corrected: the old text said "one auto-renewable subscription" while the
listing carries two, and contradicted itself later by referring to "both products". Copy
the current version from `2-PASTE-THESE-FIELDS.md`.

## 5. Attach build 1.0.0 (2) to the version, and Submit.

---

## What is deliberately NOT in 1.0

Not blockers. All of it is ready and waiting for 1.1.

| item | where |
|---|---|
| Apple Watch app | merged, one commented line in `project.yml` |
| Spanish (Mexico) localization | `4-SPANISH-LOCALIZATION.md` |
| App preview video | `APP-PREVIEW-SCRIPT.md` |
| Paywall placement in the Shop | `../GROWTH-PASS.md` item 4 |
| Rest-day visibility | `../GROWTH-PASS.md` item 6 |

## Known and accepted for 1.0

- **Screen Time and the restore path are fixed but unverified on hardware.** Neither runs
  in the simulator. The reasoning is in commit f2c94e3. Worth ten minutes on the device
  once build 2 is installed: sign in on a fresh install and confirm your creature comes
  back instead of onboarding, and grant Screen Time and confirm it does not say "not yet".
- **Creature names are filtered client-side only.** The anon key ships in the binary, so
  a determined person can write a name straight to the RPC. Block, report and account
  deletion all ship. Moving the check into `ensure_user` is the follow-up.
