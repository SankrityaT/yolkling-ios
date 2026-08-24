# App Store Connect submission brief

Everything needed to fill in App Store Connect for Yolkling. Paths are relative to the
repo root: **`/Users/sankiii/iOSLocal/yolkling`** (GitHub: `SankrityaT/yolkling-ios`).

Read `CONTEXT.md` at the repo root first if you need background on what the app is.

---

## The account

| | |
|---|---|
| App Store Connect account | the friend's, org **HAVISHEA SAIRAM VANNEMREDDY** |
| Team ID | `94277H98XP` |
| App record | **Yolkling: Grow by Living** |
| Bundle ID | `com.yolkling.ios` |
| SKU | `yolkling-ios` |

The app record already exists, in "1.0 Prepare for Submission".

The bare name "Yolkling" is unavailable: it is reserved by a never-submitted record on a
different account, and Apple will not delete a record that was never approved. The
home-screen name is unaffected, it comes from `CFBundleDisplayName` and still reads
"Yolkling". Do not try to rename the record.

---

## 1. Subscriptions

Group: **Yolkling Plus**. Two products, both at the **same subscription level** so they
are alternatives rather than an upgrade path.

### Monthly (exists already)

| Field | Value |
|---|---|
| Reference Name | `Yolkling Plus Monthly` |
| Product ID | `com.yolkling.ios.plus.monthly` |
| Duration | 1 Month |
| Price | **$4.99** |

### Yearly (needs creating)

| Field | Value |
|---|---|
| Reference Name | `Yolkling Plus Yearly` |
| Product ID | `com.yolkling.ios.plus.yearly` |
| Duration | 1 Year |
| Price | **$34.99** |

### Localization, English (U.S.) — for BOTH products

Apple limits these hard. Display Name is 30 characters, Description is 45.

Monthly:
```
Display Name:  Yolkling Plus
Description:   Monthly Yolks and supporter cosmetics.
```

Yearly:
```
Display Name:  Yolkling Plus
Description:   A year of Yolks and supporter cosmetics.
```

### Availability — for BOTH

All countries and regions, and it **must include the United States**. This is not
optional: the app is a RevenueCat Shipaton entry and entries not available in the US are
disqualified.

### Review screenshot — for BOTH

A screenshot of the paywall. Subscriptions are rejected without one. If none exists yet,
ask before inventing one; the paywall currently renders an "unavailable" state until the
Paid Applications Agreement clears, and that is not a good review screenshot.

---

## 2. App Store listing copy

**Do not write new copy.** It already exists, is reviewed, and is deliberately worded.
Paste it verbatim from:

```
AppStore/metadata/APP-STORE-LISTING.md
```

That file contains, each with its character count checked: App Name, Subtitle,
Promotional Text, Description, Keywords, What's New, URLs, Category, Age Rating, and the
App Review notes.

**Important:** an older version of this file claimed the app had no in-app purchases,
five times over. That was written for a free-tier branch and is false. The file has been
corrected. If you see "no in-app purchases" anywhere, you are reading a stale copy.

---

## 3. Screenshots

Already generated, both required sizes, 8 shots each:

```
AppStore/screenshots/marketing/6.9-inch/   1320 x 2868
AppStore/screenshots/marketing/6.5-inch/   1284 x 2778
```

Upload the 6.5-inch set to the 6.5" slot and the 6.9-inch set to the 6.9" slot. App
Store Connect scales down from the largest, so both sets cover every iPhone.

Order matters, it tells a story: hero, hatch, health, focus, dex, closet, visit, card.

---

## 4. App Privacy

These answers **must match** `Yolkling/PrivacyInfo.xcprivacy` in the binary. If they
diverge, fix the manifest, not just the form.

**Tracking:** No. No ATT prompt, no cross-app tracking, no data broker sharing.

**Data collected** — exactly two types, both taken from the manifest:

| Data type | Linked to identity | Used for tracking | Purpose |
|---|---|---|---|
| Identifiers → User ID | Yes | No | App Functionality |
| User Content → Other User Content | Yes | No | App Functionality |

**Health & Fitness: NOT collected.** Steps and sleep are read from HealthKit and
processed entirely on device. They never leave the phone and are never uploaded. Do not
tick Health data.

The "Other User Content" entry is the postcards friends send each other.

---

## 5. App Review notes

Paste verbatim from the "App Review notes" section of
`AppStore/metadata/APP-STORE-LISTING.md`. It already covers, and a reviewer will ask
about all of these:

- HealthKit being optional and how to exercise it
- why Sign in with Apple is required, and that only the user identifier is requested
- the Live Activity in focus sessions
- the subscription, that it gates nothing, and that Yolks are never purchasable
- that there is no gacha, no loot box, and no randomised purchase
- where Restore Purchases lives
- user-generated content, and the block / report / account deletion controls

---

## 6. Do not do these

- Do not create any purchasable currency product. Yolks are never for sale at any price.
  No consumable, no pack, no bundle containing Yolks. This is deliberate.
- Do not add a Lifetime tier.
- Do not claim the app has no in-app purchases.
- Do not enable Family Sharing on the subscription. Plus grants a monthly Yolks stipend,
  and one purchase feeding up to six accounts' stipends undermines the economy.

---

## Known blockers, so you do not chase them

- **Paid Applications Agreement + banking.** Until complete, products do not load and the
  paywall shows an unavailable state. Expected, not a bug.
- **Family Controls distribution entitlement.** Requested, 2 to 4 weeks. Screen Time
  cannot ship without it, and the app self-gates correctly meanwhile.
- **A build has never been archived under this team.** Submission needs one.

## Reference

| What | Where |
|---|---|
| What the app is | `CONTEXT.md` |
| What is true vs claimed | `CLAIMS.md` |
| Full submission runbook | `AppStore/SUBMISSION-CHECKLIST.md` |
| Screenshot pipeline | `AppStore/README.md` |
| Privacy manifest | `Yolkling/PrivacyInfo.xcprivacy` |
| RevenueCat config in code | `Yolkling/Core/Subscription/Entitlements.swift` |
