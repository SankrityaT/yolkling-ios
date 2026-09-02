# Final pass: everything to do, then submit

Paste the block at the bottom into the browser agent. Read the two decisions first.

## Decision 1: set the release to MANUAL. This is the one that protects you.

Approval and release are separate. If **"Manually release this version"** is selected,
an approved app sits at **Pending Developer Release** and does NOTHING until you press
Release. You can hold it indefinitely, launch on a chosen day, and coordinate it with
whatever else you have planned.

Right now the version is set to **SCHEDULED for Aug 29 2026, 7:00 PM**, a time that has
already passed. Leave that and you lose the control entirely: it can go live the moment
it is approved, which for a new app burns Apple's first-launch boost on a day you did not
choose.

**Change it to "Manually release this version" before submitting.**

## Decision 2: submit build 2, not build 1

Build 1 is what is uploaded, and it is missing two fixes from the first device test:

- Screen Time says access was not granted immediately after you grant it. A reviewer who
  taps the off-phone tile sees a feature that looks broken, which is a Guideline 2.1
  risk.
- A reinstall re-onboards you instead of restoring your creature from the backup.

The second one a reviewer will not hit (they install once). The first one they might. It
costs your friend one `git pull` and about twenty minutes, and a rejection costs days, so
upload build 2 first.

---

## The prompt

You are finishing the App Store Connect setup for "Yolkling" (Apple ID 6804105200) and
then submitting it for review. Work top to bottom. Report what you changed.

**1. Release option.** In the version's Release section, select **"Manually release this
version"**. It is currently set to a scheduled date that has already passed. This is the
most important item on the list: it is what lets us hold an approved app until we choose
to launch.

**2. Sign-In Information.** UNCHECK "Sign-in required". It is currently checked with the
username and password fields empty, which blocks submission. No demo account is needed:
the app uses Sign in with Apple with empty requested scopes, so a reviewer signs in with
their own Apple ID and we never receive a name or email. The App Review notes explain
this and offer a demo account if they want one.

**3. Copyright.** Currently empty. Fill it with the name on the developer account.

**4. App Review notes.** Replace the current notes with the version in
`2-PASTE-THESE-FIELDS.md`. The live text says "one auto-renewable subscription" and names
only the monthly product id, while the listing carries two products and the same text
later refers to "both products". Apple reads this field against the real configuration
and a contradiction is a metadata rejection.

**5. Screenshots.** Replace ALL existing screenshots for both sizes with the new files at
`~/Downloads/yolkling-screenshots/`. Two folders of 8, each to its matching slot:
`6.9-inch/` (1320x2868) and `6.5-inch/` (1284x2778). Do not put all 16 in one slot. The
captions changed: Apple OCRs screenshot captions into search ranking, and the old ones
carried no search terms.

**6. Cross-localization.** Add the localizations in `9-CROSS-LOCALIZATION.md`, in the
order listed. For each: copy the English name, subtitle and description verbatim, paste
that locale's English keyword set, and leave screenshots empty so they inherit. Do as
many as you can; even one is worth having. Do NOT translate the keywords.

**7. Subscription review screenshots.** Both products need one before either can be
submitted. Now possible: the Paid Applications Agreement is Active. Screenshot the paywall
with both plans visible and upload the same image to both products.

**8. Attach the build.** Use **1.0.0 (2)** if it has finished processing. If only 1.0.0
(1) is available, STOP and report it rather than attaching build 1.

**9. In the submit flow**, answer: Export Compliance — the app uses only standard HTTPS
and Apple's own encryption, so NO to non-exempt encryption. Advertising Identifier
(IDFA) — no, the app does not use it. These two questions only appear once a build is
attached, which is why they could not be answered earlier.

**10. Before clicking Submit**, list every remaining warning or error on the page
verbatim and confirm the release option still reads "Manually release this version".
Then submit for review.

Report back: what you changed, how many localizations you added, and the final status.
