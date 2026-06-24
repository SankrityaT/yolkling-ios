# Yolkling — iOS Security & Privacy Best Practices (2026)

Actionable, production-grade guidance for **Yolkling**, a cute social virtual-creature wellness app that collects as little as possible, reads gentle wellness signals, and supports friend connections + sync. The north star: **strong, real privacy that is also an honest marketing point — no overclaiming.**

> Research date: June 2026. Stack assumption: Swift / SwiftUI, SwiftData (or Core Data), Supabase backend, optional HealthKit-derived wellness signals. Sources are linked inline and collected at the end.

---

## TL;DR — The 10 decisions to lock in

1. **Tokens/session → Keychain**, with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` for the refresh token (background sync) and `WhenUnlockedThisDeviceOnly` for anything that only needs foreground access. Always `...ThisDeviceOnly`.
2. **Secure Enclave** holds *keys, not data*. Use it for a hardware-bound P-256 device key (signing / wrapping), gated by biometrics where it adds value. It cannot store your tokens or DB rows.
3. **Embed the Supabase `sb_publishable_` (anon) key in the binary — it is designed to ship.** RLS is what protects data. **Never** ship `sb_secret_` / `service_role`, JWT secret, or DB password.
4. **Leave ATS at its secure defaults.** Do not add exceptions. **Skip certificate pinning** for v1 — for a small app it is more operational risk than security benefit.
5. **Turn on Data Protection** (`NSFileProtectionComplete` where feasible; `...CompleteUntilFirstUserAuthentication` for files that must survive background launch). SwiftData/Core Data get encrypted *via the file-protection class*, not a built-in cipher.
6. **Be honest about E2EE.** You can encrypt *content* end-to-end, but the server must see the *social graph* (who is friends with whom, who visited whom, timing). Market "your data is encrypted and we can't read your private content," not "fully end-to-end encrypted, we see nothing."
7. **Ship `PrivacyInfo.xcprivacy`** declaring required-reason API uses (almost certainly UserDefaults `CA92.1`) and your data types. Required since May 1, 2024.
8. **Aim for the "Data Not Collected" or near-minimal nutrition label.** If you keep wellness data on-device and only sync E2EE content + minimal account data, you can credibly claim near-zero collection.
9. **Avoid App Tracking Transparency entirely** by collecting nothing trackable: no IDFA, no third-party ad/analytics SDKs, no linking first-party data to third-party data.
10. **Privacy-by-design**: no email/phone if you can avoid it (Sign in with Apple + relay), random opaque IDs, on-device wellness processing, friend codes instead of contact upload, delete-on-request, short metadata retention.

---

## 1. Keychain, Secure Enclave — what belongs where, and the right accessibility flags

### What goes where

| Item | Where it lives | Why |
|---|---|---|
| Supabase **access token (JWT)** | Keychain | Short-lived bearer credential; must be retrievable to call the API |
| Supabase **refresh token** | Keychain | Long-lived; needed for silent re-auth and background sync |
| **Sign in with Apple** user identifier | Keychain (or UserDefaults — it's not secret, but Keychain is tidy) | Stable account anchor |
| **Device signing/identity key** (private) | **Secure Enclave** (non-exportable) | Hardware-bound; proves "this device" without a shippable secret |
| **E2EE content keys** (symmetric, per-user/per-conversation) | Keychain item *wrapped* by a Secure-Enclave key, or stored directly in Keychain with `...ThisDeviceOnly` | Enclave can't store the symmetric key itself; it wraps it |
| Wellness readings, creature state, app DB | SwiftData/Core Data file with **Data Protection** (Section 4) | Bulk data; Keychain is the wrong tool for large/structured data |

**Key rule:** The Secure Enclave stores **cryptographic keys only — not arbitrary data.** Only 256-bit elliptic-curve (P-256) keys can be generated and held there; the private key is non-exportable and never leaves the chip. Use `SecKeyCreateRandomKey` with `kSecAttrTokenIDSecureEnclave` (or CryptoKit's `SecureEnclave.P256`). You do **not** put tokens, JSON, or DB rows in the Enclave — you put a key there and use it to sign or to wrap/unwrap other keys that live in the Keychain. ([Apple — The Secure Enclave](https://support.apple.com/guide/security/the-secure-enclave-sec59b0b31ff/web), [CryptoKit SecureEnclave.P256](https://developer.apple.com/documentation/cryptokit/secureenclave/p256), [Gridnev — Secure Enclave-stored keys](https://medium.com/@alx.gridnev/ios-keychain-using-secure-enclave-stored-keys-8f7c81227f4))

### The right Keychain accessibility flags

Use the **most restrictive** `kSecAttrAccessible` class that still lets the app function, and append **`ThisDeviceOnly`** so secrets never migrate to iCloud Keychain, encrypted backups, or a restored/new device. ([NowSecure — Use the Keychain carefully](https://github.com/nowsecure/secure-mobile-development/blob/master/en/ios/use-the-keychain-carefully.md), [Curiosity — iOS security best practices](https://blogs.curiositytech.in/day-21-security-best-practices-for-ios-developers-keychain-encryption-secure-storage/))

| Flag | When it's readable | Use in Yolkling for |
|---|---|---|
| `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | Only while device is unlocked; never leaves device | Access token; anything only used in the foreground (**default choice**) |
| `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` | After first unlock post-boot, including while locked; never leaves device | **Refresh token** and any key needed by background sync / silent push |
| `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` | Only if a passcode is set; item is deleted if passcode removed | Highest-sensitivity items where you want to *require* a passcode (optional, stricter) |

Avoid the non-`ThisDeviceOnly` variants and never use the deprecated `kSecAttrAccessibleAlways`. ([Curiosity](https://blogs.curiositytech.in/day-21-security-best-practices-for-ios-developers-keychain-encryption-secure-storage/), [Harkhani — Keychain, Biometrics, Secure Enclave](https://medium.com/@gauravharkhani01/app-security-in-swift-keychain-biometrics-secure-enclave-69359b4cffba))

**Background-sync gotcha:** if Yolkling syncs creatures while the app is suspended or on silent push, the items it needs must be `AfterFirstUnlock...`. A `WhenUnlocked...` item returns `errSecInteractionNotAllowed` / `-25308` when the device is locked. ([Apple Forums — SecItemCopyMatching -25308](https://developer.apple.com/forums/thread/748434))

**Biometric gating (optional, recommended for re-auth):** combine Keychain with `SecAccessControl` flags such as `.biometryCurrentSet` or `.userPresence` to require Face ID/Touch ID before a sensitive item (e.g., the wrapped E2EE master key) is released. `.biometryCurrentSet` invalidates the item if the enrolled biometrics change — good for high-trust items. ([Harkhani](https://medium.com/@gauravharkhani01/app-security-in-swift-keychain-biometrics-secure-enclave-69359b4cffba))

**Concrete recommendation for Yolkling:** Access token → `WhenUnlockedThisDeviceOnly`. Refresh token → `AfterFirstUnlockThisDeviceOnly`. A Secure-Enclave P-256 device key signs sync/identity requests and wraps the symmetric E2EE key; the wrapped key sits in the Keychain. Gate the unwrap of the E2EE master key behind biometrics if you add a "private journal/notes" surface.

---

## 2. Secrets management — what is safe in the binary vs what must NEVER ship

**Treat the app binary as fully public.** Anyone can unzip the IPA, dump strings, and proxy the traffic. The only question is whether a leaked value *grants privilege*.

### Safe to embed (these are public by design)

- **Supabase publishable key** — `sb_publishable_...` (new format, replacing the legacy `anon` key). It is explicitly **designed to ship in client apps**. It carries the same low privileges as the old anon key, so your **Row Level Security (RLS)** policies fully govern what it can touch. Embedding it is normal and expected. ([Supabase — Understanding API keys](https://supabase.com/docs/guides/getting-started/api-keys), [Supabase — Migrating to publishable and secret keys](https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys))
- **Supabase project URL** — public.
- Public config: feature flags, public CDN URLs, RevenueCat/StoreKit *public* keys.

> **The RLS caveat that makes this safe — and dangerous if ignored:** the publishable key is only "safe" *because RLS is enabled and correct on every table*. A publishable key against a table with RLS off (or a permissive `USING (true)` policy) means **anyone with your app can read/write everyone's data.** This exact misconfiguration is the #1 Supabase incident class (see CVE-2025-48757 write-ups). **Action: enable RLS on every table, write per-user policies (`auth.uid() = user_id`), and run `get_advisors` / the Supabase linter before launch.** ([VibeAppScanner — Is Supabase Safe for Production](https://vibeappscanner.com/is-supabase-safe), [StingrAI — Supabase security](https://www.stingrai.io/blog/supabase-powerful-but-one-misconfiguration-away-from-disaster))

### Must NEVER ship in the app (server-only secrets)

- **Supabase `service_role` key** / new **`sb_secret_...` keys** — they **bypass RLS entirely**. In a client they give any user full read/write to the whole database. Server-side only (Edge Functions, your backend). The new secret keys even reject browser/User-Agent use with HTTP 401 as a guardrail, but **do not rely on that — just never put them in the app.** ([Supabase — API keys](https://supabase.com/docs/guides/getting-started/api-keys), [ASA Standard — service_role exposure](https://asastandard.org/checks/service-role-key-exposure), [PTKD — Is the service role key public?](https://ptkd.com/journal/is-supabase-service-role-key-public))
- **Postgres DB password / connection string** — never.
- **JWT signing secret** — never; minting tokens client-side defeats auth.
- Third-party server secrets: Stripe secret key, push (APNs) auth key, OpenAI/LLM keys, webhook signing secrets. Anything that costs money or grants admin → server only.

**If you need privileged work from the app** (e.g., relate two accounts as friends, fan-out a "visit"), do it through a **Supabase Edge Function** that holds the secret server-side and authorizes the caller via their JWT. The app never holds the secret.

**Migration note:** Legacy `anon`/`service_role` keys still work but are being retired — new projects already default to the new keys, and legacy keys are slated for deprecation by end of 2026. Start Yolkling on `sb_publishable_` / `sb_secret_` from day one. ([Supabase changelog #29260](https://supabase.com/changelog/29260-upcoming-changes-to-supabase-api-keys))

---

## 3. App Transport Security defaults & certificate pinning

### Leave ATS on, change nothing

ATS is **on by default** and already enforces HTTPS (TLS 1.2+), strong ciphers, and valid certificate trust for all outbound connections. Supabase endpoints are modern TLS, so the defaults "just work." ([MoldStud — ATS importance](https://moldstud.com/articles/p-maintaining-user-trust-the-importance-of-app-transport-security-in-ios-development))

**Do:**
- Ship with **no `NSAppTransportSecurity` exceptions** in `Info.plist`. No `NSAllowsArbitraryLoads`, no per-domain downgrades. A clean ATS posture is itself a (quiet) security win and avoids App Review questions.
- If a third party ever forces an exception, scope it to that one domain and document why.

### Certificate pinning: skip it for v1

For a small app, the 2025/2026 consensus is that **pinning is usually not worth it** — the platform's ATS + CA trust already removes the trivial MITM cases, and pinning adds a real operational hazard: if a pinned cert/CA rotates and you haven't shipped an update with the new pin, **you brick every installed app until users update.** ([CaveraV — The obsolescence of SSL pinning](https://caverav.cl/posts/ssl-pinning/ssl-pinning/), [SecureVale — Deep dive into certificate pinning on iOS](https://securevale.blog/articles/deep-dive-into-certificate-pinning-on-ios/))

**If/when Yolkling grows and you want pinning** (e.g., you handle real health records and want defense-in-depth), use Apple's **declarative Identity Pinning** via the `NSPinnedDomains` key in `Info.plist` (iOS 14+) rather than hand-rolled `URLSession` delegate code. It is less error-prone, and you should **pin the CA/intermediate (and include a backup pin)** rather than a single leaf cert to survive rotation. ([SAP — Certificate pinning on iOS 14](https://community.sap.com/t5/technology-blog-posts-by-sap/certificate-pinning-on-ios-14/ba-p/13513651), [SecureVale](https://securevale.blog/articles/deep-dive-into-certificate-pinning-on-ios/))

**Recommendation:** No pinning for launch. Re-evaluate only if you take on regulated data or a concrete threat model demands it; if so, use `NSPinnedDomains` with backup pins and a rotation runbook.

---

## 4. Data-at-rest encryption + the honest E2EE story

### 4a. Data Protection / file protection classes

iOS encrypts the filesystem with a hardware-rooted key, and **Data Protection** layers per-file class keys tied to the passcode/lock state. Choose the class per file based on whether the app must read it while locked. ([Mukesh Yadav — Securing user data in iOS](https://mukeshydv.medium.com/securing-users-data-in-ios-with-swift-9e2be41c3b31), [DEV — OWASP iOS data protection](https://dev.to/felipefmmobile/security-ios-apps-with-owasp-best-practices-for-data-protection-2c5l))

| Class | Readable when | Use for in Yolkling |
|---|---|---|
| `NSFileProtectionComplete` | Only while **unlocked** | Wellness signals, private notes, anything not needed in background — **strongest, prefer this** |
| `NSFileProtectionCompleteUnlessOpen` | Can finish a write started before lock | Active uploads/downloads in progress |
| `NSFileProtectionCompleteUntilFirstUserAuthentication` | After first post-boot unlock (this is the **default**) | The SwiftData store **if** background sync must read it while the device is later locked |
| `NSFileProtectionNone` | Always | Avoid for any user data |

### 4b. SwiftData / Core Data encryption

Neither SwiftData nor Core Data ships a built-in cipher — **encryption at rest is delivered by the file-protection class on the store file.** ([HackingWithSwift — encrypt SwiftData](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-encrypt-swiftdata), [Developer Areeb — Securing SwiftData](https://blog.developerareeb.com/S271oTGiUys40UeycRtv))

- **SwiftData:** set the protection on the `ModelConfiguration`'s store. With `NSFileProtectionComplete` the DB is unreadable while the device is locked — so only use it for data you never need to touch in the background.
- **Core Data:** set `NSPersistentStoreFileProtectionKey` on the store options to the matching class.
- **Trade-off to design around:** `Complete` = best security but the store is inaccessible while locked (breaks background sync, widgets, locked-screen reads). For Yolkling, a sensible split is: **default app store → `CompleteUntilFirstUserAuthentication`** (works for background sync), and a **separate "sensitive" store (wellness readings, journal) → `Complete`**, only touched while the app is in the foreground.

If you ever need encryption *independent of the lock state* (e.g., a value readable in background but still ciphered), wrap those specific fields with a CryptoKit `AES.GCM` key that is itself stored in the Keychain — but keep this targeted; full custom DB crypto is rarely worth the complexity.

### 4c. The HONEST end-to-end encryption story for a social app

This is the part founders most often overclaim. Here is what is **actually true** for an app where the server must relate accounts (friends, creatures visiting, sync).

**What E2EE can genuinely do:** encrypt **content** on the device so the server stores only ciphertext and **cannot read it** — private journal entries, notes attached to a creature, direct messages, custom wellness annotations. The server is a "dumb pipe" that routes and stores blobs it can't open. ([Technology.org — what E2EE actually means and doesn't cover](https://www.technology.org/2026/06/05/what-end-to-end-encryption-actually-means-and-what-it-doesnt-cover/), [DEV — social platform with client-side E2EE](https://dev.to/webdevtodayjason/building-a-social-platform-with-client-side-end-to-end-encryption-36b2))

**What E2EE fundamentally CANNOT hide when a server relates accounts:**
- **The social graph** — who is friends with whom, who is in which group. The server must know this to route a "visit" or sync.
- **Activity/timing metadata** — who was active when, who visited whom and when, message counts/sizes.
- **Account-linking identifiers** — the stable IDs the server uses to connect accounts.
- **IP addresses** from server logs; push-notification payloads can also leak content to APNs if you put real data in them.

This is an *architectural* limit, not a coding gap: a centralized server that must connect accounts inherently sees relationship + timing metadata. Even Signal — the gold standard — protects message content end-to-end but cannot make all metadata disappear, which is why it invests heavily in *minimizing* it (sealed sender, tiny retention). ([arXiv — push-notification metadata leakage](https://arxiv.org/pdf/2407.10589), [Session whitepaper — minimal metadata leakage](https://arxiv.org/pdf/2002.04609))

**The marketing-honest framing (a realistic privacy posture the founder can state truthfully):**

> ✅ Safe to say: *"Your private content (journal entries, notes, messages) is end-to-end encrypted — we store it encrypted and we can't read it."*
> ✅ Safe to say: *"We collect as little as possible. Wellness signals are processed on your device. We never sell your data and we don't track you across apps."*
> ✅ Safe to say: *"To connect you with friends and let creatures visit, our server stores who you're connected to and basic activity timing — and nothing more than needed."* (Honest about the graph.)
> ❌ Do **not** say: *"Fully end-to-end encrypted — we see nothing"* or *"zero-knowledge"* if your server knows the friend graph and visit timing. That is an overclaim that a security researcher (or the press) will catch.

**Concrete posture for Yolkling:**
1. E2EE the *content* fields (notes/messages/private wellness annotations) with per-user keys (Keychain-stored, optionally Enclave-wrapped).
2. Store the relationship graph and routing metadata in plaintext server-side — but **minimize and short-retain** it (Section 7).
3. Keep raw wellness signals **on-device**; sync only derived, non-sensitive creature state (e.g., "creature is happy") rather than raw health readings, if you can.
4. Use **content-free push payloads** ("You have a visitor!") so APNs never sees sensitive content.
5. If you want the strongest provable claim, document the model publicly (a short "How Yolkling protects your data" page) — transparency *is* the marketing asset.

> Note for any iCloud-backed sync: Apple's *standard* iCloud is encrypted in transit and at rest but Apple holds keys; only **Advanced Data Protection** makes iCloud truly E2EE. Don't imply iCloud-synced data is E2EE unless ADP is in play. ([Apple — iCloud data security overview](https://support.apple.com/en-us/102651))

---

## 5. Apple Privacy Manifests, required-reason APIs & nutrition labels

### PrivacyInfo.xcprivacy is mandatory

Since **May 1, 2024**, App Store Connect rejects apps that don't declare their **required-reason API** usage in a `PrivacyInfo.xcprivacy` privacy manifest. The manifest also declares **data types collected** and **tracking domains**, and Apple now validates that **bundled third-party SDKs ship their own manifests + signatures.** ([Apple — privacy requirement starts May 1](https://developer.apple.com/news/?id=pvszzano), [Bugfender — complying with Apple's privacy requirements](https://bugfender.com/blog/apple-privacy-requirements/))

### Required-reason APIs Yolkling will likely touch

There are five categories; declare a reason code for each you use. ([Apple — Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), [Anand Sharma — Apple's Privacy Manifest](https://medium.com/@anand_sharma/apples-privacy-manifest-33bfde782764))

| Category (`NSPrivacyAccessedAPICategory…`) | Likely Yolkling reason code | Meaning |
|---|---|---|
| **UserDefaults** | `CA92.1` | Read/write info accessible only to the app itself (you almost certainly use `UserDefaults`/`@AppStorage`) |
| **File Timestamp** | `C617.1` | Access timestamps/size of files inside the app/group/CloudKit container |
| **Disk Space** | `E174.1` | Check free space before writing / clean up when low |
| **System Boot Time** | `35F9.1` | Measure elapsed time between in-app events |
| **Active Keyboard** | (usually N/A) | Only if you enumerate active keyboards |

([Apple Forums — UserDefaults CA92.1 clarification](https://developer.apple.com/forums/thread/735286), [Singular — Privacy manifest FAQ](https://support.singular.net/hc/en-us/articles/24045392537243-iOS-SDK-Privacy-manifest-FAQ))

A near-minimal Yolkling manifest will declare **`NSPrivacyTracking = false`**, an **empty `NSPrivacyTrackingDomains`**, the **`NSPrivacyAccessedAPITypes`** you actually use (UserDefaults at minimum), and a **`NSPrivacyCollectedDataTypes`** array reflecting Section 5's nutrition-label decisions.

### App Store privacy nutrition labels — what a minimal-data app declares

The label is a self-declaration across categories (Contact Info, Health & Fitness, Location, User Content, Identifiers, Usage Data, Diagnostics, etc.), and whether any data is used to **track**. The best-case badge is **"Data Not Collected."** ([Apple — App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/), [Jamf — Privacy nutrition labels](https://www.jamf.com/blog/privacy-nutrition-labels-in-the-app-store/))

**How to legitimately reach (or approach) "Data Not Collected":**
- "Collected" means data **leaves the device, linked to identity, in a way you control.** Data that stays **on-device** (your local wellness processing) is **not** "collected." Data that is **E2EE and unreadable by you** still typically counts as collected/stored even though you can't read it — so be precise.
- Collection that is **optional, infrequent, off the critical path, fully disclosed, and not used for tracking/ads** may be exempt from disclosure — but when unsure, **declare it.** ([Apple — App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/))

**Realistic Yolkling label (given friends + sync):** you will likely declare **Identifiers** (account/user ID) and possibly **User Content** (the synced creature/notes) and **Diagnostics** if you keep crash data — all marked **"Not Used to Track You"** and **"Not Linked"** where honest. If you keep wellness signals strictly on-device and only sync derived creature state, you can **avoid declaring Health & Fitness collection** entirely. That is a strong, truthful position — close to minimal, without claiming the perfect "Data Not Collected" badge you can't honestly earn once a server relates accounts.

### If you touch HealthKit

HealthKit data is **sensitive** and carries extra App Store rules: per-type, separate read/write consent; a **required privacy policy**; and a hard ban on **using health/fitness data for advertising or sharing it with third parties for ads.** Prefer reading the *minimum* health signal, processing on-device, and **not** persisting raw health data server-side. ([Apple — Protecting access to users' health data](https://support.apple.com/guide/security/protecting-access-to-users-health-data-sec88be9900f/web), [Apple — Health & fitness](https://developer.apple.com/health-fitness/))

---

## 6. App Tracking Transparency — and how to legitimately not need it

ATT requires a system prompt before an app may read the **IDFA** or otherwise **track** users across apps/websites owned by other companies. Opt-in rates sit around ~35% globally, so the prompt mostly costs you measurement and adds friction. ([Adapty — What is ATT](https://adapty.io/glossary/app-tracking-transparency/), [Twinr — IDFA in 2025](https://twinr.dev/blogs/app-tracking-transparency/))

**The clean path: never trigger ATT by collecting nothing trackable.**
- **No IDFA, no ad SDKs, no third-party analytics that build cross-app profiles.** If you never read the IDFA and never share data with data brokers/ad networks, you have nothing to prompt for.
- **First-party data is fine without ATT.** Account details, in-app activity, settings, and your own product analytics **kept in-house and not linked to third-party data** are *not* "tracking" under ATT. The `IDFV` (per-vendor identifier) is available without consent for first-party measurement. ([EasyInsights — what is ATT](https://easyinsights.ai/blog/what-is-app-tracking-transparency/), [Singular — ATT glossary](https://www.singular.net/glossary/app-tracking-transparency/))

**Concrete recommendation:** Yolkling ships **no ATT prompt**, declares **`NSPrivacyTracking = false`** with **no tracking domains**, and marks the nutrition label **"Not Used to Track You."** For product metrics, use a privacy-respecting, first-party/aggregate analytics approach (self-hosted or an analytics tool that does not build cross-app identity), and never join it to ad-network data. This is a genuine, marketable "we don't track you" position.

---

## 7. Privacy-by-design data-minimization patterns

Design so the *easiest* path collects the *least* data.

- **Minimize identity at sign-up.** Prefer **Sign in with Apple** with the **private-relay email** so you never hold a real email. Avoid phone numbers. Don't ask for real name, birthday, or location unless a feature truly needs it.
- **Opaque, random IDs everywhere.** Use random UUIDs as account/creature keys; never derive IDs from emails/phones. Don't expose enumerable sequential IDs.
- **Friend codes, not contact upload.** Connect friends via short shareable codes / QR / deep links instead of uploading the address book. If you ever must match contacts, do it with **hashed, salted, on-device** matching and never store the raw contact list.
- **Process wellness on-device; sync derived state.** Read the gentle wellness signal locally, compute the creature's mood locally, and sync only the *result* ("happy/sleepy"), not the raw reading. This keeps Health & Fitness off your servers and off your nutrition label.
- **Data-free notifications.** Push says "Your friend's creature came to visit!" — no health content, no names in the payload — so APNs and lock screens leak nothing. ([arXiv — push notifications leak data](https://arxiv.org/pdf/2407.10589))
- **Short metadata retention.** The relationship/visit/timing metadata your server *must* keep should have a **retention limit** (e.g., purge visit logs after N days). Less stored = less to breach, subpoena, or apologize for.
- **Real account deletion.** Provide in-app **account deletion** (also an App Store requirement) that actually erases server rows + storage objects, not just a soft flag. Document it.
- **Encrypt the content you do store** (Section 4c) and keep **server secrets server-side** (Section 2).
- **Default to private.** Visits/social features are opt-in; nothing about a user is discoverable by default.
- **Write the privacy story down.** A plain-language "what we collect, why, and what we can't see" page turns your minimalism into a credible marketing asset — and keeps you honest, because you have to match the nutrition label and the manifest to it.

**Net posture you can market truthfully:** *"Yolkling is built privacy-first. We sign you in without an email or phone number, your wellness signals stay on your device, your private content is end-to-end encrypted so we can't read it, we don't track you across apps, and the little we must store to connect you with friends is kept minimal and deletable."* Every clause in that sentence is backed by a concrete decision above.

---

## Pre-launch checklist

- [ ] RLS enabled + correct policies on **every** Supabase table; ran `get_advisors`/linter
- [ ] Only `sb_publishable_` key in the app; **no** `sb_secret_`/service_role/DB password/JWT secret anywhere in the binary or repo
- [ ] Privileged operations behind Edge Functions (authorized by user JWT)
- [ ] Keychain: tokens `…ThisDeviceOnly`; refresh token `AfterFirstUnlockThisDeviceOnly`; biometric gating on the E2EE master key
- [ ] Secure-Enclave device key for signing/wrapping (keys only, never data)
- [ ] ATS defaults, **no exceptions**; no certificate pinning for v1 (documented decision)
- [ ] Data Protection set: sensitive store `Complete`, sync store `CompleteUntilFirstUserAuthentication`
- [ ] E2EE on content fields; relationship metadata minimized + short retention
- [ ] `PrivacyInfo.xcprivacy` present: `NSPrivacyTracking=false`, required-reason APIs (UserDefaults `CA92.1` at least), collected data types
- [ ] Nutrition label matches reality; **"Not Used to Track You"**; Health & Fitness not declared if wellness stays on-device
- [ ] No ATT prompt; no IDFA/ad SDKs; no cross-app data joins
- [ ] In-app account deletion that truly erases data
- [ ] Public, plain-language privacy explainer that matches the manifest + label (no overclaim)

---

## Sources

**Keychain & Secure Enclave**
- [Apple — The Secure Enclave](https://support.apple.com/guide/security/the-secure-enclave-sec59b0b31ff/web)
- [Apple — CryptoKit SecureEnclave.P256](https://developer.apple.com/documentation/cryptokit/secureenclave/p256)
- [NowSecure — Use the Keychain carefully](https://github.com/nowsecure/secure-mobile-development/blob/master/en/ios/use-the-keychain-carefully.md)
- [Curiosity — iOS security best practices (Keychain, encryption, secure storage)](https://blogs.curiositytech.in/day-21-security-best-practices-for-ios-developers-keychain-encryption-secure-storage/)
- [Harkhani — App Security in Swift: Keychain, Biometrics, Secure Enclave](https://medium.com/@gauravharkhani01/app-security-in-swift-keychain-biometrics-secure-enclave-69359b4cffba)
- [Gridnev — iOS Keychain: using Secure Enclave-stored keys](https://medium.com/@alx.gridnev/ios-keychain-using-secure-enclave-stored-keys-8f7c81227f4)
- [Apple Forums — SecItemCopyMatching returns -25308 when locked](https://developer.apple.com/forums/thread/748434)

**Supabase secrets / RLS**
- [Supabase — Understanding API keys](https://supabase.com/docs/guides/getting-started/api-keys)
- [Supabase — Migrating to publishable and secret API keys](https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys)
- [Supabase — Upcoming changes to API keys (changelog #29260)](https://supabase.com/changelog/29260-upcoming-changes-to-supabase-api-keys)
- [ASA Standard — service_role key exposure](https://asastandard.org/checks/service-role-key-exposure)
- [PTKD — Is the Supabase service role key public?](https://ptkd.com/journal/is-supabase-service-role-key-public)
- [VibeAppScanner — Is Supabase Safe for Production (RLS, CVE-2025-48757)](https://vibeappscanner.com/is-supabase-safe)
- [StingrAI — Supabase: one misconfiguration away from disaster](https://www.stingrai.io/blog/supabase-powerful-but-one-misconfiguration-away-from-disaster)

**ATS & certificate pinning**
- [MoldStud — Importance of App Transport Security in iOS](https://moldstud.com/articles/p-maintaining-user-trust-the-importance-of-app-transport-security-in-ios-development)
- [CaveraV — The Obsolescence of SSL Pinning in Mobile App Security](https://caverav.cl/posts/ssl-pinning/ssl-pinning/)
- [SecureVale — Deep Dive into Certificate Pinning on iOS](https://securevale.blog/articles/deep-dive-into-certificate-pinning-on-ios/)
- [SAP — Certificate Pinning on iOS 14 (Identity Pinning / NSPinnedDomains)](https://community.sap.com/t5/technology-blog-posts-by-sap/certificate-pinning-on-ios-14/ba-p/13513651)

**Data at rest & E2EE**
- [HackingWithSwift — How to encrypt SwiftData](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-encrypt-swiftdata)
- [Developer Areeb — Securing SwiftData with Encryption](https://blog.developerareeb.com/S271oTGiUys40UeycRtv)
- [Mukesh Yadav — Securing user's data in iOS with Swift](https://mukeshydv.medium.com/securing-users-data-in-ios-with-swift-9e2be41c3b31)
- [DEV — Security iOS Apps with OWASP Best Practices for Data Protection](https://dev.to/felipefmmobile/security-ios-apps-with-owasp-best-practices-for-data-protection-2c5l)
- [Technology.org — What E2EE actually means and what it doesn't cover](https://www.technology.org/2026/06/05/what-end-to-end-encryption-actually-means-and-what-it-doesnt-cover/)
- [DEV — Building a social platform with client-side E2EE](https://dev.to/webdevtodayjason/building-a-social-platform-with-client-side-end-to-end-encryption-36b2)
- [arXiv — Secure messaging apps leak data to push notification services](https://arxiv.org/pdf/2407.10589)
- [arXiv — Session: E2EE with minimal metadata leakage](https://arxiv.org/pdf/2002.04609)
- [Apple — iCloud data security overview (standard vs Advanced Data Protection)](https://support.apple.com/en-us/102651)

**Privacy manifests, required-reason APIs, nutrition labels, HealthKit**
- [Apple — Privacy requirement for app submissions starts May 1](https://developer.apple.com/news/?id=pvszzano)
- [Apple — Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Apple — NSPrivacyAccessedAPIType](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- [Bugfender — Complying with Apple's New Privacy Requirements](https://bugfender.com/blog/apple-privacy-requirements/)
- [Anand Sharma — Apple's Privacy Manifest](https://medium.com/@anand_sharma/apples-privacy-manifest-33bfde782764)
- [Singular — iOS SDK Privacy Manifest FAQ](https://support.singular.net/hc/en-us/articles/24045392537243-iOS-SDK-Privacy-manifest-FAQ)
- [Apple Forums — UserDefaults CA92.1 clarification](https://developer.apple.com/forums/thread/735286)
- [Apple — App Privacy Details (nutrition labels)](https://developer.apple.com/app-store/app-privacy-details/)
- [Jamf — Privacy Nutrition Labels in the App Store](https://www.jamf.com/blog/privacy-nutrition-labels-in-the-app-store/)
- [Apple — Protecting access to users' health data](https://support.apple.com/guide/security/protecting-access-to-users-health-data-sec88be9900f/web)
- [Apple — Health & Fitness for developers](https://developer.apple.com/health-fitness/)

**App Tracking Transparency**
- [Adapty — What is App Tracking Transparency (ATT)](https://adapty.io/glossary/app-tracking-transparency/)
- [Twinr — Mobile App IDFA and how it's changing in 2025](https://twinr.dev/blogs/app-tracking-transparency/)
- [EasyInsights — What is App Tracking Transparency](https://easyinsights.ai/blog/what-is-app-tracking-transparency/)
- [Singular — App Tracking Transparency glossary](https://www.singular.net/glossary/app-tracking-transparency/)
