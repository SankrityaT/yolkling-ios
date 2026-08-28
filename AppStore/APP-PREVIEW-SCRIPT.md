# App preview video: shot list

Apple's app preview, the video that autoplays on the listing. Not the Shipaton demo
video, which is a separate, longer, narrated thing.

## Constraints (Apple's, not preferences)

- **15 to 30 seconds.** No exceptions; the upload rejects outside that range.
- **Captured on device**, not a simulator recording and not an After Effects mockup.
  Apple rejects synthetic footage that never ran on hardware.
- **Portrait**, matching the screenshot sizes already uploaded.
- **No price, no "download now", no Apple hardware shown**, no third-party marks.
- **Autoplays MUTED.** Whatever the video says, it has to say without sound. Treat music
  as decoration and never put information in it.
- Same rule as the Shipaton video: **only flows reachable from a fresh install.** The
  `YOLK_*` seams are now Release-gated, so a Release build physically cannot show them.
  Record from a Release build and the constraint enforces itself.

## The 30 seconds

The first three seconds decide whether anyone watches the rest, so the creature is on
screen immediately. No logo card. Nobody has ever installed an app because of a logo card.

| t | shot | why |
|---|---|---|
| 0.0 - 3.0 | The egg cracking in `HatchCeremony`, ending on the creature appearing | The single most charming three seconds in the app. It is also the promise: something is about to be yours. |
| 3.0 - 6.0 | Customize: colour scrubbing along the picker, creature recolouring live | Establishes "one of a kind" without a caption saying so. |
| 6.0 - 11.0 | Home. Tap the creature, it reacts. Streak chip and Yolks visible. | This is the screen someone will actually live in. Show it early and honestly. |
| 11.0 - 16.0 | Health connect, then steps ticking into growth | The differentiator. This is the entire "grow by living" claim in one shot. |
| 16.0 - 21.0 | Focus session starting, creature resting and glowing, Live Activity on the lock screen | "The only app that wants you off your phone", shown rather than said. The lock-screen beat is the one nobody else has. |
| 21.0 - 26.0 | Dex scrolling through discovered species, then one card opening | Collection depth. Answers "is there anything here after a week". |
| 26.0 - 30.0 | A friend's room visit, creature waving | Ends on other people, which is the reason to tell someone about it. |

## Caption overlays

Muted autoplay means these carry the whole message. Match the screenshot captions so the
listing reads as one thing.

- 0.5s: `a little yolk that's yours`
- 11.5s: `it grows when you look after yourself`
- 16.5s: `steps, sleep, time off your phone`
- 26.5s: `and your friends can visit`

Lowercase throughout, matching the app's voice. No exclamation marks anywhere.

## Recording notes

- Record on the **6.9" device** (the 1320x2868 slot) and let Apple scale down.
- Use a **Release build** so the seams are inert and nothing dev-only can leak in.
- Fresh install, then play forward normally. Do not stage state that a new user could
  not reach in the first session.
- The hatch is the one beat worth several takes. Everything else is forgiving.
