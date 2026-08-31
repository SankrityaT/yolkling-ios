# Prompt: prepare the resubmission after the Guideline 2.1 rejection

Everything here is doable now and none of it waits on the build. Two things are
deliberately NOT in this list: the screen recording (physical device only) and the final
reply and submit (needs the recording attached).

---

You are preparing Yolkling (Apple ID 6804105200) for resubmission after a Guideline 2.1
"Information Needed" rejection. Work in order and report at each step.

**1. Fix the In-App Purchases. This is the likely cause of the rejection.**

Both subscriptions were at "Prepare for Submission" with no review screenshot, and neither
was in the submission: the rejection showed "Items Submitted (1)", the app version alone.
So the reviewer opened the paywall, found nothing purchasable, and could not evaluate the
purchase flow they then asked us to demonstrate.

For BOTH `com.yolkling.ios.plus.monthly` and `com.yolkling.ios.plus.yearly`:

- Upload this file as the review screenshot. It exists and has been verified on disk:
  ```
  /Users/sankiii/Downloads/yolkling-submit/subscription-review-screenshot.png
  ```
  It shows the in-app paywall with both plans at their real prices, which is what the
  field is for.
- Then make sure BOTH products are included in this version's submission, not merely
  present in the products list.
- Report each product's status before and after.

**2. Replace the App Review Information > Notes.**

Use the fenced block under "Paste into App Review Information > Notes" in:
```
/Users/sankiii/Downloads/yolkling-submit/13-GUIDELINE-2.1-REPLY.md
```

It is **3,437 characters**, inside the 4,000 cap. The previous attempt was 5,033 and the
field silently reverted, so after saving, RELOAD the page and confirm the text is actually
there before reporting success. Do not trust the save state.

**3. Confirm nothing has been lost.** Report each:
- Release option still reads "Manually release this version"
- "Sign-in required" still UNCHECKED (no credentials exist; the app ships a demonstration
  mode instead, which is what Apple's submission guide asks for)
- Copyright filled
- Privacy Policy URL set in App Privacy
- Support URL filled for every localization, including French, Russian, Portuguese
  (Brazil) and Korean

**4. Attach the build, once it appears.** A new build, **1.0.0 (4)**, is being uploaded. If
it has finished processing, attach it to the version. If only 1.0.0 (3) is available,
report that and attach nothing.

**5. STOP. Do not reply to App Review and do not submit.**

The reply needs a screen recording attached, which is being made on a physical iPhone and
cannot be delegated. Report everything back and wait.

Report: the two product statuses before and after, whether the notes survived a reload,
which build is attached, and any remaining error or warning on the version page, verbatim.
