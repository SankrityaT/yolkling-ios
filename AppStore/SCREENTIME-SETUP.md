# Screen Time / Family Controls — what YOU need to do

The code is done. Screen Time (time off your phone feeding the creature) is fully
built: authorization, a `DeviceActivityReport` extension that reads usage
privacy-blind, the App-Group handoff, the Home "off phone" pillar, the onboarding
opt-in step, and the additive vitality wiring. The entitlement is already declared
in `Yolkling/Yolkling.entitlements` and `ScreenTimeReport/ScreenTimeReport.entitlements`.

What remains is an **Apple-side approval + a real-device test** — only you can do these,
because they need your Apple Developer account and a physical iPhone.

## 1. Request the Family Controls (Distribution) entitlement — DO THIS FIRST
This is the long pole. It is a manual Apple review that can take days to weeks, and
**you cannot ship Screen Time to the App Store until it's granted.**

- Go to: https://developer.apple.com/contact/request/family-controls-distribution
- Sign in with the account that owns `com.Sankritya.Yolkling`.
- Describe the use honestly, e.g.: "Yolkling is a cozy wellbeing app. With the user's
  opt-in, it reads their aggregate daily screen time (total time only, never which
  apps or content) to gently encourage time off the phone — a virtual pet grows a
  little livelier on lower-usage days. Uses DeviceActivityReport for the aggregate;
  no shielding, no monitoring of others."
- Submit and wait for the approval email.

## 2. While you wait — nothing blocks you
The app ships correctly without the entitlement: the feature self-gates to a soft
"soon" state, so you can build, test, and even submit the rest of the app. (You chose
to build Screen Time now and wait for the grant, so just file the request early.)

## 3. After Apple grants it — test on a REAL device
Family Controls does NOT work in the iOS Simulator. On a physical iPhone:
1. Xcode → your iPhone as the run destination. With automatic signing, once your
   account has the entitlement Xcode provisions the Development variant automatically.
2. Run the app, go through onboarding to the "time away is time well spent" step (or
   tap the "off phone" pillar on Home) → the system Screen Time permission sheet
   appears → approve.
3. Confirm the "off phone" pillar on Home fills in with real hours (cross-check
   against Settings → Screen Time for the same day; allow for window differences).
4. Background the app and return — the number refreshes on foreground.

## 4. At submission
In App Store Connect → App Review notes, add a line about the Family Controls usage
so the reviewer expects the Screen Time permission prompt, e.g.:
"Screen Time (Family Controls) is optional and opt-in. With permission, the app reads
only the total daily screen-time duration (never app identities or content) to
encourage time off the phone. The app is fully usable without it."

## Reference (already in the repo)
- `Yolkling/Core/Health/ScreenTimeService.swift` — authorization + reads the shared figure
- `Yolkling/Core/Health/ScreenTimeReportHost.swift` — hidden host that runs the extension
- `ScreenTimeReport/` — the DeviceActivityReport extension (reads usage privacy-blind)
- `Yolkling/Core/Health/ScreenTimeShare.swift` — App-Group contract
- `Yolkling/Features/Home/HomeView.swift` — the "off phone" pillar + additive vitality
- `Yolkling/Features/Onboarding/OnboardingView.swift` — the priming/opt-in step
