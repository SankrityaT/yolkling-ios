# Apple Search Ads: brand defense campaign

~$30 total. The one paid channel worth running at this budget, because bidding on your own
name is the cheapest keyword you will ever buy and it stops competitors intercepting the
traffic your own posts create.

## Prerequisites, in order

1. **The app must be LIVE on the App Store.** Not approved, live. Campaigns cannot run
   against an unreleased app, so this is a day-after-release task.
2. **Havi signs in** at `searchads.apple.com` with the Apple ID on the developer account,
   and completes 2FA. Only he can.
3. **A payment card goes on the account.** This is a real financial commitment by the
   account holder, not a form field. He should enter it himself rather than hand the
   details to anyone, agent or otherwise.

Once the account exists and has a card, the campaign build itself can be delegated.

## The one setting that decides whether this works

**Search Match must be OFF.**

It is ON by default. It lets Apple serve your ad against any query it thinks is relevant,
which for a $30 budget means the entire budget disappears into generic terms like "virtual
pet" at roughly $2 a tap, against apps with real budgets. Brand defense is exact match on
your own name and nothing else.

If only one instruction survives from this page, it is that one.

## The campaign

| setting | value |
|---|---|
| Campaign name | `Yolkling Brand Defense` |
| Countries | United States only |
| Total budget | $30 |
| Daily cap | $3 |
| Ad group name | `Brand Exact` |
| **Search Match** | **OFF** |
| Keywords | `yolkling`, `yolkling app`, `yolkling pet` — all **exact match** |
| Default bid | $0.50 cost-per-tap to start |
| Audience | leave everything default; do not narrow by age, gender or device |

Nothing else. No discovery ad group, no broad match, no second campaign. Those are for
budgets with a zero on the end.

## What to expect

Brand traffic is cheap because nobody else wants it, so $30 lasts a while and the tap
volume will be low until your organic posts start driving searches. That is the point:
this campaign exists to catch demand you create elsewhere, not to create demand.

Check after a week. If it has barely spent, that is fine and means nobody is competing for
your name. If it spent fast, look immediately at whether Search Match got left on.

## Prompt for the browser agent

> Set up an Apple Search Ads campaign for Yolkling at searchads.apple.com. The account
> holder has already signed in and added a payment method. Create ONE campaign with these
> exact settings, change nothing else, and report back what you created before it starts
> spending.
>
> - Campaign name: `Yolkling Brand Defense`
> - Countries or regions: **United States only**
> - Total budget: **$30**. Daily cap: **$3**
> - One ad group named `Brand Exact`
> - **Search Match: OFF.** This is the most important setting on the page. It is on by
>   default and will spend the entire budget on generic keywords if left on.
> - Keywords, all **exact match**: `yolkling`, `yolkling app`, `yolkling pet`
> - Default bid: **$0.50** cost-per-tap
> - Leave audience, demographics and device targeting at their defaults
>
> Do NOT create a discovery campaign, do not enable broad match, and do not add any
> keyword that is not our own app name. Report the campaign status, the confirmed Search
> Match setting, and the budget caps.
