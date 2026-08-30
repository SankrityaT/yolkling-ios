# RevenueCat and App Store Connect: what must be true

Derived from the code, not from memory. Every value below is what
`Core/Subscription/` actually asks for at runtime, so a mismatch is a silent
failure, not an error message.

**The one symptom to recognise.** If the paywall says *"the supporter tier isn't
available right now"*, the app reached RevenueCat and got nothing usable back. That
message covers every item on this page. It is deliberately honest rather than a spinner,
but it does not say WHICH thing is wrong. This list is how you find out.

---

## RevenueCat

### 1. Offering must be marked CURRENT

The app calls `Purchases.shared.offerings().current`. An offering that exists but is not
set as **Current** returns nil and the paywall shows "unavailable". This is the single
most common cause and it looks identical to having no offering at all.

RevenueCat > Offerings > the offering > make sure it is the one marked Current.

### 2. Packages MUST use the reserved identifiers

The app reads `offering.monthly` and `offering.annual`. Those are convenience accessors
that ONLY resolve packages whose identifier is exactly:

| plan | package identifier |
|---|---|
| monthly | `$rc_monthly` |
| annual | `$rc_annual` |

A package with a custom identifier (`monthly`, `yearly`, `plus_annual`, anything) is
invisible to those accessors. The offering loads, the paywall renders, and **no plans
appear**. If only one plan shows, this is why.

### 3. Entitlement identifier is `Yolkling Plus`

With the space, capitalised exactly. `Core/Subscription/Entitlements.swift` compares
against this string:

```
static let plusEntitlement = "Yolkling Plus"
```

Both products must be attached to it. If a product is not attached, the purchase
succeeds, the money is taken, and `isPlus` stays false: no supporter glow, no stipend.

### 4. Virtual currency code is `YLK`

`claimStipend()` reads `currencies["YLK"].balance`. The monthly Yolks grant is configured
on the RevenueCat side; if the code differs, the paywall's "a monthly handful of Yolks"
claim silently stops being true, which is a Guideline 3.1.2 problem as well as a lie.

### 5. App Store Connect credentials uploaded to RevenueCat

Under the iOS app in RevenueCat:

- **In-App Purchase Key** (the `.p8` from App Store Connect > Users and Access > Keys >
  In-App Purchase). Without it, RevenueCat cannot validate or refresh subscriptions.
- **App-Specific Shared Secret** (App Store Connect > the app > App Information).

### 6. The public SDK key must be the `appl_` one

Already correct in the code:

```
static let apiKey = "appl_cVMmKZMwBkjbJQwwFIdHgNhQVdu"
```

`isTestStore` is computed from this prefix. A `test_` key would print a loud
**"TEST STORE - purchases here are simulated, not real"** banner across the paywall,
which is the deliberate guard against shipping one. If that banner ever appears in
TestFlight, stop and fix it before submitting.

---

## App Store Connect

### Done

App name, subtitle, categories, promotional text, description, keywords, support and
marketing URLs, App Review notes, age rating (9+), App Privacy (published), both
subscription products priced and localized, screenshots for 6.9" and 6.5", and a build
uploaded.

### Still to do

1. **Paid Applications Agreement must be Active.** Account Holder only. Until it is, the
   products cannot be submitted and the paywall shows "unavailable" to everyone,
   including the reviewer.
2. **Subscription review screenshot, one per product.** Required before either can be
   submitted. Now possible: take it from TestFlight once offerings load. A plain capture
   of the paywall with both plans visible is fine.
3. **Attach the build to the 1.0 version.**
4. **Submit for review.**

### Optional but worth doing

- **Spanish (Mexico) localization** for cross-localization keyword coverage. Ready to
  paste: `AppStore/SUBMIT/4-SPANISH-LOCALIZATION.md`.
- **App preview video.** Shot list: `AppStore/APP-PREVIEW-SCRIPT.md`.

---

## How to confirm it all works, in one test

Install from TestFlight, open the paywall, and check:

- both plans appear, with real prices in your local currency
- the annual one shows a saving percentage
- no "TEST STORE" banner
- no "isn't available right now" message

If all four hold, items 1 through 6 above are correct. If any fail, work down the list in
order; they are ordered by how often each one is the cause.
