# Focus sessions: architecture

The fantasy: you start a session, put the phone down, and your yolkling rests and
glows while you're away. Finish it and you earn Yolks. The honest core of "thrives
when you put your phone down."

## The one hard problem: knowing the phone is actually down
Without a special entitlement, an app cannot see what other apps you use. So the
whole design hinges on how we detect "off your phone." Three tiers:

### Tier 1 (ship now, no entitlement): an honest heuristic from public APIs
We can actually do a decent job with two signals:
- **`scenePhase`** — is our app foreground or background.
- **`protectedDataWill/DidBecomeUnavailable`** notifications — fire when the
  device **locks** (data protection kicks in).

Combine them into a session state:
- App **foreground** (you're looking at the calm creature, not scrolling) -> **focusing**.
- App backgrounded **and device locked** (phone genuinely down) -> **focusing**.
- App backgrounded **without a lock** (you switched to another app) -> **distracted**.

So "lock the phone and walk away" or "watch your creature rest" both count; "leave to
scroll Instagram" does not. Not bulletproof, but honest and real, with zero entitlement.

### Tier 2 (later, gated): Family Controls
The bulletproof version: `FamilyControls` + `ManagedSettings` + `DeviceActivity` to
actually **shield** distracting apps during the session. Needs Apple's
Family Controls entitlement (a request + approval). Pursue, never depend on it.

### Brand rule: reward presence, never punish
Leaving early isn't a failure with guilt. The session just ends and you don't get the
Yolks. The creature waits, never shames (WELLBEING.md).

## The session model (a state machine, suspension-proof)
A session is **end-date based**, never a ticking counter, so backgrounding/suspension
can't drift it:
- `FocusSession { id, startDate, durationMinutes, state }`, persisted (SwiftData) so a
  killed app can resume/finish it.
- `endDate = startDate + duration`. On any foreground, `remaining = endDate - now`.
- States: `running -> completed` (now >= endDate while focused) · `running -> failed`
  (went distracted) · `running -> cancelled` (user taps end).
- A **local notification** scheduled at `endDate` so you're nudged when it's done while
  the phone is away (permission primed contextually).

## Live Activity (Dynamic Island + lock screen) — fast-follow
A live countdown on the lock screen / Dynamic Island so you see progress *without*
unlocking (reinforces phone-down). Needs a **Widget Extension target** (ActivityKit) —
a real project addition, so it's a fast-follow, not v1.

## Reward
- Yolks scale with completed minutes (e.g. ~1/min), with a **daily cap** (anti-grind,
  like the check-in). Client-guarded now; **server-authoritative** when Supabase sync
  lands (same as the check-in — the server validates and grants).

## The creature during a session
- Enters a **resting/glowing** state (calm/sleepy expression + a soft glow, slow breath).
- On completion: **proud/happy** + the Yolks reward.

## v1 scope (no entitlement, no new target)
1. `FocusView`: pick a duration (15 / 25 / 45 / custom) -> start.
2. Big end-date countdown + the resting, glowing creature.
3. Tier-1 detection (foreground-or-locked = focusing; app-switch = session ends gently).
4. Local notification at the end.
5. Persist the active session; resume correctly after backgrounding/relaunch.
6. Reward on completion (scaled + daily cap).

## Build order
1. v1 above (the "focus" TODAY card goes live).
2. Live Activity (add the Widget Extension target).
3. Server-authoritative reward (with Supabase sync).
4. Family Controls shielding (with the entitlement).
