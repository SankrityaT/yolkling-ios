# Replying to the Guideline 2.1(a) beta rejection

Apple could not get into the app. Sign in with Apple is the only method, there are no
credentials to hand over, and the gate had no way past it. Two fixes: one is text, one
shipped in build 3.

---

## The prompt for the browser agent

You are resolving a Guideline 2.1(a) rejection of the Yolkling TestFlight beta (Apple ID
6804105200). Apple could not access the app because it asks for sign-in and no demo
credentials were provided. Do these in order and report what you changed.

**1. Fill the Beta App Review Information notes.** This is a SEPARATE field from the App
Store version's App Review Information, and it is currently empty, which is why the
reviewer had no explanation at all.

Go to the app > **TestFlight** tab > **Test Information** > scroll to **Beta App Review
Information**. Leave "Sign-in required" UNCHECKED (there are genuinely no credentials to
enter; checking it with empty fields is what blocks submission). Paste this into the
notes / review notes field there:

```
Yolkling uses Sign in with Apple as its only sign-in method, so there is no user name or password to provide and no demo account exists.

There are two ways to get in, both giving full access to every feature:

1. Tap "look around for a day first" on the first screen. This opens the entire app immediately with no account at all.
2. Or tap "Sign in with Apple" and use any Apple ID, including your own test account. The app requests no name and no email (requestedScopes is empty) and receives only the stable user identifier.

Sign-in is required to keep a creature beyond the first day, because the creature is backed up to the account and the friend graph is keyed on it.

If the Sign in with Apple sheet does not appear, please confirm an Apple ID is signed in under Settings, as Sign in with Apple cannot present without one. The "look around for a day first" option works regardless.
```

**2. Reply in the Resolution Center** to Apple's message, with the same text plus this
first line:

```
Thank you for the review. Build 3 adds a "look around for a day first" option on the first screen that opens the whole app with no account, so no credentials are needed.
```

**3. Update the version's App Review Information notes too.** Replace the current text
with the version in `/Users/sankiii/Downloads/yolkling-submit/2-PASTE-THESE-FIELDS.md`.
It now opens by stating no demo account exists and how to get in. This is a different
field from step 1 and both need to be right.

**4. Confirm** the version's Release option still reads "Manually release this version",
then report back. Do not submit anything yet: build 3 has to finish processing first.

---

## Text for the account holder

Sent separately. He needs to pull and upload build 3.
