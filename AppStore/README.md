# App Store assets + submission notes

Keep the App Store submission turnkey. Update as features land.

## screenshots
Captured at **iPhone 16 Pro Max, 6.9", 1320 x 2868**, the size App Store Connect requires (it scales down for smaller iPhones, so this one size covers every iPhone).
- `screenshots/home-vibe-0..4.png` — the home creature in all five vibes (one of a kind, recolorable). 5 shots.

As more screens ship (the hatch onboarding, care/today, friends + visits, the store), capture those too for a fuller 3 to 10 shot set that tells the story. Best-practice order: hero creature, the hatch moment, "grows when you live well", a friend visit + postcard, the store.

### regenerate the screenshots (one command)
The app has a screenshot seam, `SIMCTL_CHILD_YOLK_VIBE` picks the starting vibe. To recapture after a build:
```bash
DEVICE=$(xcrun simctl list devices | grep "Yolk-ProMax" | head -1 | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')
xcrun simctl boot "$DEVICE"
APP=$(find ~/Library/Developer/Xcode/DerivedData/Yolkling-*/Build/Products/Debug-iphonesimulator -name "Yolkling.app" | head -1)
xcrun simctl install "$DEVICE" "$APP"
for i in 0 1 2 3 4; do
  xcrun simctl terminate "$DEVICE" com.Sankritya.Yolkling 2>/dev/null
  SIMCTL_CHILD_YOLK_VIBE=$i xcrun simctl launch "$DEVICE" com.Sankritya.Yolkling
  sleep 3
  xcrun simctl io "$DEVICE" screenshot AppStore/screenshots/home-vibe-$i.png
done
```

## required screenshot sizes (2026)
- **6.9" iPhone (16/17 Pro Max): 1320 x 2868** — required, this is what we capture, covers all iPhone.
- 13" iPad: only if we ship iPad later.

## metadata checklist (App Store Connect)
- App name: **Yolkling**
- Subtitle: e.g. "a little creature that's secretly you"
- Description: from the landing-page voice, honest, every claim must map to a shipped feature (see CLAIMS.md)
- Keywords: virtual pet, creature, cozy, self care, tamagotchi, wellbeing, screen time, companion, pet
- Support URL: https://yolkling.com
- Marketing URL: https://yolkling.com
- **Privacy Policy URL: https://yolkling.com/privacy** (must match the in-app link, App Review rejects mismatches)
- Category: Lifestyle or Health & Fitness (decide closer to launch)
- Age rating: 4+
- Privacy nutrition label: minimal, no tracking, no ATT (see docs/research/02-security-privacy.md)
- Bundle id: com.Sankritya.Yolkling

## still needed before submission
- A real 1024 x 1024 app icon (the yolk). Currently a placeholder.
- Screenshots of the remaining feature screens as they ship.
- The privacy nutrition label answers + PrivacyInfo.xcprivacy in the build.
