# App Store assets + submission notes

Keep the App Store submission turnkey. Update as features land.

## turnkey submission docs (start here)
- **`metadata/APP-STORE-LISTING.md`** — every App Store Connect field, labeled and
  ready to paste, with verified character counts for each limited field.
- **`SUBMISSION-CHECKLIST.md`** — ordered runbook from repo to submitted, including
  the "what only you (the human) can do" items (file the Family Controls entitlement
  first, confirm the privacy + content-policy pages are live, archive + submit with
  your signing identity).

## screenshots
Captured at **iPhone 16 Pro Max, 6.9", 1320 x 2868**, the size App Store Connect requires (it scales down for smaller iPhones, so this one size covers every iPhone).
- `screenshots/home-vibe-0..4.png` — the home creature in all five vibes (one of a kind, recolorable). 5 raw shots.

### marketing set (8 shots: raw capture then composite)
The submission ships an **8-shot marketing set** built in two stages: raw simulator
capture, then an HTML/CSS composite that frames each raw shot with a caption and
background. The compositor and its template are added by a later step:
- `screenshots/compose.mjs` — _(placeholder, to be created)_ takes the raw captures
  and renders the framed 1320 x 2868 marketing shots.
- `screenshots/template/frame.html` — _(placeholder, to be created)_ the HTML/CSS
  frame (caption, device background) the compositor renders.

Story order for the 8: hero creature, the hatch moment, grow by living, put the
phone down (focus Live Activity), check in, shop/closet, a friend visit + postcard,
the Dex.

### regenerate the screenshots (one command)
The app has a screenshot seam, `SIMCTL_CHILD_YOLK_VIBE` picks the starting vibe. To recapture after a build:
```bash
DEVICE=$(xcrun simctl list devices | grep "Yolk-ProMax" | head -1 | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')
xcrun simctl boot "$DEVICE"
APP=$(find ~/Library/Developer/Xcode/DerivedData/Yolkling-*/Build/Products/Debug-iphonesimulator -name "Yolkling.app" | head -1)
xcrun simctl install "$DEVICE" "$APP"
for i in 0 1 2 3 4; do
  xcrun simctl terminate "$DEVICE" com.yolkling.ios 2>/dev/null
  SIMCTL_CHILD_YOLK_VIBE=$i xcrun simctl launch "$DEVICE" com.yolkling.ios
  sleep 3
  xcrun simctl io "$DEVICE" screenshot AppStore/screenshots/home-vibe-$i.png
done
```

## required screenshot sizes (2026)
- **6.9" iPhone (16/17 Pro Max): 1320 x 2868** — required, this is what we capture, covers all iPhone.
- 13" iPad: only if we ship iPad later.

## metadata checklist (App Store Connect)
The canonical, copy-paste values live in **`metadata/APP-STORE-LISTING.md`** (with
verified character counts). Quick reference only:
- App name: **Yolkling** · Subtitle: **a cozy pet that grows with you** (30/30)
- Keywords (no spaces): `virtualpet,creature,cozy,selfcare,tamagotchi,wellbeing,companion,habit,collect,focus,mood,pet,egg` (97/100)
- Category: **Lifestyle** (primary), **Health & Fitness** (secondary)
- Support / Marketing URL: https://yolkling.com · Privacy: https://yolkling.com/privacy
- Age rating: 4+ · Bundle id: com.yolkling.ios
- Full description, What's New, App Review notes, and App Privacy answers: see the
  listing doc.

## still needed before submission
- ✅ **App icon — DONE.** Real designed yolk at 1024 x 1024 (no longer a placeholder).
- The 8-shot marketing set rendered through `screenshots/compose.mjs` (pipeline
  above), plus any remaining feature screens as they ship.
- `PrivacyInfo.xcprivacy` in the build; its declarations must match the App Privacy
  answers in `metadata/APP-STORE-LISTING.md`.
