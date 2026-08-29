# Audit prompt for the AI browser

Paste the block below. It is a READ-ONLY audit by default: it reports, it does not
change things, except for the three explicitly listed safe fixes.

---

You are auditing two dashboards to confirm the iOS app "Yolkling" is ready to submit for
App Store review. Do NOT change anything except the three items listed under SAFE FIXES.
Everything else: report it, do not fix it.

Report back as a checklist with PASS / FAIL / UNSURE per item, and quote the exact value
you saw. If you cannot find something, say UNSURE rather than guessing.

## Part 1: RevenueCat (account sankeydadev@gmail.com)

These values come from the app's source code. A mismatch fails SILENTLY at runtime, so
check the literal strings, not just "something that looks right".

1. **Offering is Current.** Find the offering used for the iOS app. Confirm it is the one
   marked "Current". Report its identifier. An offering that exists but is not Current
   makes the app's paywall show "the supporter tier isn't available right now".

2. **Package identifiers are the reserved ones.** Inside that offering, the two packages
   must have identifiers EXACTLY:
   - `$rc_monthly`
   - `$rc_annual`
   Report the actual identifiers you see. If they are anything else (monthly, yearly,
   plus_annual, custom names), that is a FAIL: the app reads `offering.monthly` and
   `offering.annual`, which only resolve those two reserved ids, and any other name makes
   the plan invisible in the paywall with no error anywhere.

3. **Entitlement identifier is exactly `Yolkling Plus`** - two words, capital Y, capital
   P, one space. Report exactly what is there. Confirm BOTH products (monthly and annual)
   are attached to it. A product not attached means a customer pays and receives nothing.

4. **Virtual currency `YLK` exists**, and confirm whether a monthly grant of it is
   configured on the Yolkling Plus subscription. Report the amount granted and how often.

5. **App Store Connect credentials are uploaded** under the iOS app's settings:
   - an In-App Purchase Key (.p8) is present
   - an App-Specific Shared Secret is present
   Report present/absent for each. Do not reveal or copy the values.

6. **Public SDK key.** Confirm the iOS app's public SDK key begins with `appl_`. It should
   match `appl_cVMmKZMwBkjbJQwwFIdHgNhQVdu`. If it begins with `test_`, that is a critical
   FAIL, report immediately.

7. **Bundle id** on the RevenueCat app is `com.yolkling.ios`.

## Part 2: App Store Connect

8. **Paid Applications Agreement.** Business (or Agreements, Tax, and Banking) - is "Paid
   Applications" ACTIVE? Report the exact status. If it is not Active, nothing else on
   this list can be submitted; say so loudly at the top of your report.

9. **Both subscription products.** Report each one's status (Ready to Submit / Missing
   Metadata / Waiting for Review / Approved), its product id, its price, and whether it
   has a **review screenshot** attached. A missing review screenshot blocks submission.

10. **Subscription group.** Confirm both products are in the same group and on the same
    level, and that the group has a localization (display name + description).

11. **Build.** Is a build attached to the 1.0 version? Report the version and build number
    you see, and whether it finished processing.

12. **App Review Information.** Confirm the Notes field is filled and the contact name,
    email and phone are set. Then READ the notes and confirm they describe TWO
    subscription options (monthly and annual). If the notes mention only one
    subscription, report it as a FAIL - Apple reads this against the actual configuration
    and a contradiction is a metadata rejection.

13. **Export Compliance.** Has the encryption question been answered for this version?
    This is easy to miss and blocks submission. Report the answer given.

14. **Content Rights and Advertising Identifier (IDFA).** Report what is currently
    selected. The app uses no IDFA and contains no third-party content.

15. **App Privacy** is published, showing exactly two data types (User ID, Other User
    Content), both linked to identity, both used for App Functionality, neither used for
    tracking.

16. **Age rating** shows 9+.

17. **Screenshots** present for 6.9" and 6.5".

18. **Anything showing a red or amber warning triangle** anywhere on the version page.
    List every one, verbatim. These are the actual blockers.

## SAFE FIXES (only these, nothing else)

- If Export Compliance is unanswered: the app uses only standard HTTPS and Apple's own
  encryption, so answer that it does NOT use non-exempt encryption.
- If the Advertising Identifier question is set to "yes": the app does not use IDFA, set
  it to no.
- If Content Rights asks about third-party content: it contains none.

Anything else that is wrong, STOP and report it. Do not create products, do not change
prices, do not change the entitlement or package identifiers, and do not submit the app.

## Finally

End your report with a single line: **READY TO SUBMIT** or **NOT READY: <the blocking
items>**.
