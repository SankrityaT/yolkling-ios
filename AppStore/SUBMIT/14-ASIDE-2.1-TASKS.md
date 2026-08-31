# Prompt: resolve the Guideline 2.1 information request

The screen recording is NOT in this list. It has to be made on a physical iPhone and
cannot be delegated to a browser agent. Everything below can be.

---

You are resolving a Guideline 2.1 "Information Needed" rejection for Yolkling (Apple ID
6804105200). Work in order and report what you find at each step, because step 1 may be
the actual cause of the rejection.

**1. FIRST, diagnose the In-App Purchases. Do not skip to step 2.**

Apple's submission guide requires that the In-App Purchases you want reviewed are
submitted, not merely created. Our last audit found both subscriptions sitting at "Prepare
for Submission" with no review screenshot attached, and a product cannot be submitted
without one. If they went to review in that state, the reviewer opened the paywall, found
nothing purchasable, and could not evaluate the purchase flow, which would explain why
they asked us to record it.

For BOTH `com.yolkling.ios.plus.monthly` and `com.yolkling.ios.plus.yearly`, report:
- the current status, verbatim
- whether a review screenshot is attached
- whether the product is attached to THIS version's submission, not just present in the
  products list

**2. Fix whatever step 1 found.** If a review screenshot is missing, upload this file to
BOTH products:

```
/Users/sankiii/Downloads/yolkling-submit/subscription-review-screenshot.png
```

It shows the in-app paywall with both plans and their real prices, which is what the field
is for. Then make sure both products are included in the version submission.

**3. Replace the App Review Information > Notes** with the block from:

```
/Users/sankiii/Downloads/yolkling-submit/13-GUIDELINE-2.1-REPLY.md
```

Use the fenced block under the heading "Paste into App Review Information > Notes". Paste
it verbatim EXCEPT the two device lines at the top, which we will correct separately with
the real test devices. Leave those as they are for now and flag that they need confirming.

**4. Confirm these have not been lost**, and report each:
- Release option still reads "Manually release this version"
- "Sign-in required" remains UNCHECKED (there are no credentials; the app provides a
  demonstration mode instead, which is what Apple's guide asks for)
- Copyright is filled
- Privacy Policy URL is set in App Privacy
- Support URL is filled for every localization, including French, Russian, Portuguese
  (Brazil) and Korean

**5. Do NOT reply to App Review yet and do NOT resubmit.** A screen recording has to be
attached to the reply and it is being made separately on a physical device. Report
everything back first.

Report: the two product statuses before and after, anything you changed, and any remaining
warning or error on the version page, verbatim.
