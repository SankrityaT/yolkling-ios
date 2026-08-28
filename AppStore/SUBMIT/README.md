# Yolkling: App Store Connect submission pack

Everything needed to fill in App Store Connect, in one folder.

## What is here

| File | Use |
|---|---|
| `1-INSTRUCTIONS.md` | Read first. What to do, in order, plus a "do not do these" list. |
| `2-PASTE-THESE-FIELDS.md` | Every listing field, in code blocks, with character counts checked. Paste verbatim. |
| `screenshots/6.9-inch/` | 8 shots, 1320x2868. Upload to the 6.9" slot. |
| `screenshots/6.5-inch/` | 8 shots, 1284x2778. Upload to the 6.5" slot. |
| `privacy-manifest-reference.xcprivacy` | The manifest shipped in the binary. The App Privacy answers must match it. |

## Three things that are easy to get wrong

**The keyword field must go in exactly as written**, with no spaces after the commas. It
is 100/100 characters, so one added space truncates a term off the end.

**The app name needs changing.** The record was created as "Yolkling: Grow by Living".
The listing now says **Yolkling: Self Care Pet**, which is an ASO change, not a typo.
Edit it under App Information. It is editable until the first submission.

**Screenshots upload in filename order.** It is a deliberate sequence: hero, hatch,
health, focus, dex, closet, visit, card.

## Blocked elsewhere, do not wait on these

- The privacy policy and the AASA file on yolkling.com are edited but not deployed.
  Submitting before the privacy policy is live is a Guideline 5.1.3 rejection, because
  the app reads HealthKit and the live policy does not mention health data.
- A build has to be archived and uploaded. That needs signing access to team 94277H98XP.
- The Paid Applications Agreement gates the subscription products loading at all.

## Background, if context is needed

`../../CONTEXT.md` for what the app is. `../../CLAIMS.md` for what is true versus claimed.
