# Yolkling — App Store submission runbook

An ordered, do-this-in-order checklist to take Yolkling 1.0.0 from repo to
submitted. Paste all listing fields from `AppStore/metadata/APP-STORE-LISTING.md`.

> Do the "WHAT ONLY YOU (the human) CAN DO" section FIRST. One item there
> (the Family Controls entitlement request) gates submission and has a lead time.

---

## 0. WHAT ONLY YOU (the human) CAN DO

These require your Apple Developer account, your identity, or your signing certs.
Nobody and no agent can do them for you.

- [ ] **File the Family Controls (Distribution) entitlement request** in the Apple
  Developer account. This gates submission for the Screen Time direction and takes
  Apple time to approve, so do it FIRST, before anything else. Even though Screen
  Time measurement is not in 1.0, request it now so it is ready when it ships.
- [ ] Confirm `https://yolkling.com/privacy` is live and reachable.
- [ ] Confirm a UGC / content-policy page is live (covers friend postcards, block,
  report, and account deletion).
- [ ] Archive and submit with YOUR signing identity (see section 4 and 5).

---

## 1. Pre-flight (code)

- [ ] Version string is **1.0.0** and build number is set (project.yml / target).
- [ ] **Subscription / paywall removed** — no StoreKit products, no IAP, no paywall
  surfaces. The app is 100% free.
- [ ] **`PrivacyInfo.xcprivacy` present** in the app target and included in the
  build, and its declarations match the App Privacy table in the listing doc.
- [ ] **Account deletion** shipped and reachable in-app (Profile/Settings).
- [x] **Block / report** shipped for postcards + **account deletion** shipped (client wired; `docs/sql/moderation.sql` DEPLOYED to the live Supabase project and verified end-to-end 2026-07-17).
- [ ] **E2E copy softened** — no "end-to-end encrypted" claim anywhere in-app or in
  metadata, since the crypto layer is not shipped. Say "your data stays on your
  device" / "private by design" instead.
- [ ] Tests green (`xcodebuild test` or your CI job passes).
- [ ] Backend verified: Supabase reachable, RLS policies enforced (friend graph,
  inventory, redeem_code), founding/referral grant one-time and server-validated.
- [ ] DEBUG-only seams (e.g. `seedSampleDay`, `YOLK_ONB`, `SIMCTL_CHILD_YOLK_VIBE`)
  are compiled out of Release.

---

## 2. Assets

- [ ] **8 marketing screenshots @ 1320 x 2868** (6.9" iPhone) generated. Order tells
  the story: hero creature, hatch moment, grow by living, put the phone down (focus
  Live Activity), check in, shop/closet, friend visit + postcard, the Dex.
- [ ] Screenshots produced via the pipeline: raw capture then HTML/CSS composite
  (see `AppStore/README.md` and `AppStore/screenshots/`).
- [ ] **App icon present** — real designed yolk at 1024 x 1024, no alpha, no
  placeholder. (Done.)

---

## 3. App Store Connect record

- [ ] Create the 1.0.0 version record for `com.Sankritya.Yolkling`.
- [ ] Paste **App Name**, **Subtitle**, **Promotional Text**, **Description**,
  **Keywords**, **What's New** from the listing doc.
- [ ] Enter **Support URL**, **Marketing URL**, **Privacy Policy URL** — verify each
  byte-matches (privacy URL must equal the in-app link exactly).
- [ ] Set **Primary category: Lifestyle**, **Secondary: Health & Fitness**.
- [ ] Complete the **Age Rating** questionnaire per the listing doc (result: 4+).
- [ ] Complete **App Privacy** answers per the listing doc; confirm they match
  `PrivacyInfo.xcprivacy`.
- [ ] Upload the **8 screenshots** in story order.
- [ ] Paste the **App Review notes** from the listing doc.

---

## 4. Build

- [ ] Archive in **Release** configuration (Xcode > Product > Archive).
- [ ] **Validate** the archive in the Organizer (catches missing entitlements,
  privacy manifest issues, icon problems before upload).
- [ ] **Upload** via Xcode Organizer or Transporter with your signing identity.
- [ ] Wait for processing, then do a **TestFlight device smoke test** on a real
  device:
  - [ ] hatch a creature (pick color + look, reveal)
  - [ ] HealthKit: add Steps/Sleep in Health app, confirm grow-by-living reads it;
        confirm app still works if Health is declined
  - [ ] focus session shows a **Live Activity** on the lock screen
  - [ ] **home-screen widget** renders
  - [ ] add a friend by **share code / QR**
  - [ ] send and receive a **postcard**
  - [ ] **delete account** works
  - [ ] **block / report** works

---

## 5. Submit

- [ ] Attach the processed build to the 1.0.0 version.
- [ ] **Export compliance**: uses only standard encryption (HTTPS) → **exempt**.
- [ ] **Content rights**: contains third-party content? Answer per your assets →
  **Yes**, you have the rights (postcards are user-generated; catalog art is yours /
  open-source per COSMETICS.md).
- [ ] **Advertising identifier (IDFA)**: **No**.
- [ ] Submit for review.

---

## 6. Post-launch

- [ ] Confirm `https://yolkling.com` and `https://yolkling.com/privacy` are live.
- [ ] Confirm the UGC / content-policy page is live.
- [ ] Fix any diverged landing-page copy so yolkling.com and the app agree (see
  CLAIMS.md): the "three silly questions" onboarding line, any literal "912 species"
  count vs the shipped 219 named species, autonomous wandering / auto-postcards,
  cosmetic trading, and any E2E-encryption wording.
