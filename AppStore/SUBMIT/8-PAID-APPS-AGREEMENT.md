# Paid Applications Agreement: step by step (account holder only)

Status right now is **Pending User Info**, which means the agreement is signed but the
banking and tax details behind it are missing, so it is not in effect.

This is the ONLY remaining task with an external clock. Apple verifies bank details and
activation takes roughly 24 hours after everything is submitted, so this is the one to
start first. Nothing paid can be submitted until it reads Active: not the subscriptions,
and the paywall shows "unavailable" to everyone including the App Review team.

Only the Account Holder can do this. It cannot be delegated to a team member.

---

## Gather these first (5 minutes, saves restarting the form)

**Identity / tax**
- Legal name, spelled exactly as it appears on your tax return
- Social Security Number (for an individual enrolment; an EIN only if you have a
  registered business and are filing as that business)
- Home address as it appears on your tax records

**Banking**
- Bank routing number (9 digits)
- Bank account number
- Account type (checking or savings)
- The account holder name on that bank account

**The single most common cause of rejection is a name mismatch.** The name on the bank
account, the name on the tax form, and the name on the Apple Developer account must all
be the same legal person. An account in a parent's name, a joint account with a different
primary holder, or a nickname instead of a legal name will bounce and cost days.

---

## The steps

1. Sign in to **App Store Connect** as the Account Holder.
2. Go to **Business** (older UI calls this **Agreements, Tax, and Banking**).
3. Find **Paid Applications**. It will read *Pending User Info*.
4. Click **Set Up Tax and Banking** (blue link on that row).

### Banking

5. Under **Bank Account**, click **Add Bank Account**.
6. Choose **United States** and enter the routing number, account number and account type.
7. Confirm the account holder name matches your legal name.
8. Tick the confirmation box and **Save**.

### Tax

9. Under **Tax Forms**, complete the **U.S. Tax Form (W-9)**. Every developer completes a
   US form regardless of country; as a US person this is the W-9.
10. Select **Individual / sole proprietor** unless you have a registered business.
11. Enter your legal name, address and SSN.
12. Sign electronically and **Submit**.

### Contact info

13. If it asks for a **Financial Contact**, **Senior Management Contact** or **Technical
    Contact**, you can be all three. It just needs a name, email and phone on file.

---

## After submitting

- The row moves from *Pending User Info* to **Active**, usually within about 24 hours.
- Check back the next day. If it still says Pending, open the row and look for a field
  flagged incomplete rather than assuming it is still processing.
- You do NOT need to wait for Active to upload a build. Do that in parallel: see
  `3-UPLOAD-A-BUILD.md`. Active is only required to SUBMIT the subscriptions.

## What this unblocks

Once Active:
- both subscription products can be submitted
- the paywall loads real prices instead of "the supporter tier isn't available right now"
- the subscription review screenshots become possible, since there is finally something
  real to photograph
