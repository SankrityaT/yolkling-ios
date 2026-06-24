# Progress ledger — Yolk Room Widget

Plan: `docs/superpowers/plans/2026-06-21-yolk-room-widget.md`
Mode: subagent-driven, NO GIT (gate = build clean + screenshot/app-group-read; reviewers read changed files; no rollback).
Devices: Yolk-SE `8A2D0BC5-24C2-4AF7-914D-3E2D02866EA1`, Yolk-ProMax `9A3F2A47-5868-4956-B3AB-7531342B9347` (iOS 26.5). NEVER uninstall/erase.
App Group: `group.com.Sankritya.Yolkling` (works in simulator; device needs portal registration = logistics).

## Task status
- [x] Task 1: App Group + plumbing — WidgetSnapshot.swift created, App Group on both targets (app + widget entitlements), renderer dirs added to widget sources. Both targets BUILD GREEN, App Group round-trip "app group OK" verified, temp seam removed. Cross-target exclusions: TypewriterText.swift (CoreHaptics, excluded) ; CustomizeOptions.swift (added for CreaturePalette). Review clean (controller inline).
- [x] Task 2: The widget — YolkRoomWidget.swift (Provider + time-of-day timeline + entry view small/medium + empty state), registered in bundle. Build green (both targets, with+without seam). Screenshot VERIFIED by controller: small/medium dioramas render with real decor/outfit/theme + day/evening/night tints, empty state shows sleepy yolk + "open yolkling". Looks great. Plan corrections: RoomSnapshot.makeVibe(name:) (not .vibe); RoomView.swift added to widget sources (Features/Room). Seam removed.
- [x] Task 3: Publish from app — WidgetPublisher.swift created; publishWidget() called in persist() (l211) + applyColor() (l285); checkIn() routes through persist() so mood refreshes too. Player.widgetNudgeShown added. Build green, App Group readback "snapshot: …, decor 2" confirmed. Review clean (controller inline, all 3 paths verified).
- [x] Task 4: Discoverability — WidgetHowToView.swift (3-step how-to), one-time home nudge in todayPanel (gated by widgetNudgeShown + decor placed), permanent Profile row. Build green, how-to sheet confirmed interactive. Minor: on iPhone SE the nudge sits below the fold (encountered on first scroll). Done (background subagent).

## ALL TASKS COMPLETE. Final build green.

### Widget-update verification (user concern: "widget doesn't change when I change the yolk")
- App Group `group.com.Sankritya.Yolkling` is correctly declared on BOTH targets (app + widget entitlements) + project.yml wired to each. Not the bug.
- Decisive end-to-end test (temp YOLK_WIDGETLIVE seam, removed): published body ff4d6a -> read back ff4d6a -> RED yolk; published 4da6ff -> read back 4da6ff -> BLUE yolk. The publish -> App Group -> WidgetSnapshot.read() -> render loop (the exact path the widget uses) reflects changes every time.
- publishWidget() fires on persist() + applyColor() + checkIn-via-persist + onChange(wallet.owned/wardrobe.equipped/placedDecorByZone) -> all look changes republish.
- Conclusion: works. "Doesn't change" on device = simulator widget caching + stale build (publish hooks landed in Task 3). On a real device a placed widget refreshes within seconds of a change.

## Minor findings (final triage)
- iPhone SE: the one-time widget nudge card sits below the fold (seen on first scroll); larger devices show it without scrolling. Acceptable; revisit if SE conversion matters.
