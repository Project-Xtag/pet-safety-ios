# Senra — Pricing Cutover & Mobile Release: Session Handover

**Written 2026-07-30 by the review seat. The flip is 2026-07-31 22:00 UTC (= 2026-08-01 00:00 Europe/Budapest). One working day out.**

This file covers the **pricing/orders/mobile-release** workstream. It is **not** the redesign's handover — that is `pet-safety-ios/docs/HANDOVER.md`, which is committed, current, and owns its own state. The two do not overlap and neither blocks the other.

---

## Owners — read these, do not trust this file over them

| Fact | Owner |
|---|---|
| The cutover procedure, step by step | `pricing-C9-cutover-runbook.md` — **the operational document for Friday night** |
| The pickup-type defect, #117's design, its sequencing | `orders-mpl-pickup-type-2026-07.md` |
| The web-handoff API contract (U1–U4 build against it) | `WEB-HANDOFF-CONTRACT.md` — **DRAFT; §9 must close before it freezes** |
| Roles, the rules, the hazards (governs both workstreams) | `pet-safety-ios/docs/PROTOCOL.md` |
| The redesign's state | `pet-safety-ios/docs/HANDOVER.md` + `docs/SENRA-MOBILE-REDESIGN.md` |
| The cutover instant | `pet-safety-eu/backend/src/config/pricingCutover.ts` — `2026-07-31T22:00:00Z`, verified |

**Both seats read PROTOCOL in full first.** Rule 7 (artifact + hash in the *same* message), Rule 1 (two-ended cites for wiring claims), Rule 8 (is the evidence even inside the change) all applied repeatedly in this workstream and all earned their keep.

---

## THE ONE THING: the flip needs nothing new

The price change ships from **backend `#116` + tagme-now B3**. No mobile work is required and none can arrive in time.

The subscribe interstitial exists **only in `integration/v2.2`, which is not submitted and not rolled out.** No fielded Android app has it. On Aug 1, users subscribe from the web, where there is no mobile→web handoff and no double login.

**Do not let mobile UX work pull scope into the window.**

---

## State — verified, not assumed

**Prod backend `7e523e9`** — pre-cutover deployed and verified 2026-07-27: `_02` (subscription_nudges) and `_03` (notification_logs `subscribe_nudge` CHECK) applied; catalog still 599; `post_cutover_account` present and false.

**Boundary gate CLOSED.** `pricingCutover.ts` reads the correct instant (inclusive `>=`, fail-safe false, lazy read). `SELECT COUNT(*) FROM users WHERE created_at >= '2026-07-31 22:00:00+00'` → **0**.

**A3 rehearsal RAN.** Staging Secrets Manager holds the 2750 price (`price_1TwewUR2nJiUv7I5LqE6Pcbl`); B1's read-back gate exercised successfully (24 keys, one value changed); restarts proven by PID/uptime, not exit status; nudge fired `candidates: 1, sent: 1` with zero constraint violations — `_03`'s reason for existing, proven; an authed staging session created at **`price_…Pcbl` / amount_total 275000**, which is C1's exact smoke shape.

**Precedence PROVEN, not inferred.** Secrets Manager overrides `.env` for price keys: loader does an unconditional `process.env[key] = secrets[key]` (`secrets.ts:360`, stripe group at `:220`), prod's drift watchdog names `STRIPE_PRICE_STANDARD_MONTHLY_HUF … (SM won)`, and the effective session price confirms it end to end. Prod `.env` carries **17 stale `STRIPE_PRICE_*` lines** from the old Stripe account — inert, but a debugging landmine. **Strip them after Phase C, never in the window.**

**`#116` MERGED 2026-07-31 as `33b59a0` (B2).** Carried exactly one file: `20260801_04_standard_huf_2750.sql`, `+27/-0`. **Hashes: `45afc43a4070` (executable SQL, comments stripped and whitespace-normalised) / `6b86b938675a` (whole file) / `cfad1d9657b7` (the PR diff).** ~~`53f116b1e03e`~~ was recorded here and **cannot be re-derived** under any of those spans — treat it as misreported, not as a different span. The substantive claim it supported holds and was re-verified directly: `diff -u` against `5c997cc:…20260801_01…` shows **only the three-line renumber note added**, nothing else. Applied to prod 22:25:06Z, above the `20260801_03` high-water mark, no ordering inversion.

**Android `integration/v2.2`** — device pass complete on a fresh debug install (stale-APK excluded by construction). Proven: PostaPont Stripe session at 1990; order row `delivery_method=postapoint` + details; **`shipping_cost = 1990.00` at creation and after the payment webhook** (the `00ec476` addendum); tokenless guest purchase working end to end (`c8f7762`, the path with no server-side rescue); interstitial fires for a post-cutover account and choose-plan shows 2750.

**iOS integration merge is DONE** — tip `4756295`, local = remote-tracking = origin. `fa4d86a` merges `fix/guest-checkout-user-id`; `372c2b1` merges `feat/pricing-2026-08` (C4); both onto release line `bf6c1bb`, all three constituents verified as ancestors. Union regions were **read**, not trusted to the clean auto-merge, and the dry run caught two real breaks: the release line's memberwise test constructions (fixed in `de1475d` via the Fix-9 `var … = nil` precedent) and the encode-contract test carry (`fd4658f`, pinning the `user_id`/`email` wire behaviour). Counting discipline applied: 364 (release line) + 9 (C4 decision tests) + 1 (new pin) = 374, then **375/46 green** after `0ea8844` (prefill guard, HU-only parity allowlist). Device-passed on iPhone — tokenless guest purchase, PostaPont legs, interstitial dormancy. IPA **2.2.1 (5)** exported from `4756295`.

*(An earlier version of this file stated iOS had no integration merge. That was false — it originated in a build-seat report of absence that the review seat propagated without verification. Corrected 2026-07-30.)*

---

## Friday night — the window

Follow the runbook. It has been amended three times today and those amendments matter:

1. **B1** — read-modify-write the prod stripe secret, then the **read-back gate** (assert key set identical, exactly one value changed, new id correct). `SAFE FOR B2` is the gate. Prod Zod rejects unknown keys, so a typo is a **failed boot**, not a degradation. The gate has now been exercised on staging.
2. **B2** — merge `#116`, **watch the deploy live** (`gh run watch --exit-status`). There is **no automatic recovery**: on 2026-07-27 two concurrent deploys corrupted each other's extract and prod was down ~4 minutes until a human reran it. `#112`'s concurrency guard now queues rather than cancels, but it is **unproven under collision** — the real protection is the procedural freeze. If it fails: rerun first to restore service, diagnose after.
   - **B2's provenance check was rewritten today.** The boot audit prints a curated subset per group and **never prints price ids**. Verify the group-loaded line and the drift watchdog's `(SM won)` line — which lives in **`backend-error.log`, not `backend-out`** — and lean on B1's gate for the stored value.
3. **B3** — merge tagme-now `feat/pricing-2026-08` to tagme-now `main`. **The artifact is `0d44816`, NOT `2d79311`** — the latter still carried the Free plan card and is superseded. Verified 2026-07-30 against staging's **served bundle bytes** (staging web runs merge `f4170c5` = pricing tip `0d44816`): single Kedvenc csomag card, no Free card, new what's-next copy, subscribe CTA. Confirm the merge lands `0d44816` and that nothing further accumulated on the branch. Web deploys from **tagme-now's own workflow**, not the monorepo gitlink.
4. **B4** — watch Stripe the first hour for sessions created before B1 and paid after: **cancel and let the user retry.** No reconciliation logic exists.

**Phase C:** C0 dispatch the mismatch detector immediately (its schedule is 06:00 UTC, eight hours after the flip, across peak traffic) → C1–C5 smoke + **C5b** (PostaPont tag checkout at 1990) → then `#113`, then `#117`, **one at a time with a verify between.**

**Smoke tests must send a browser User-Agent.** `curl` matches the bot regex and gets "Access denied" — that is what produced a phantom 403 in an earlier smoke run.

**Rollback:** re-run B1 with the ids swapped; catalog reverts by manual SQL (in the runbook); web reverts by reverting the tagme-now merge; apps need nothing. Grandfathered 599 subscribers are unaffected throughout (INV-1) — the old price id is **never archived, never modified.**

---

## Owed before Friday — short

- **⚠ CHECK THE APP STORE CONNECT RELEASE SETTING ON iOS 2.2.1 (5).** It is **submitted**. If it is set to release automatically on approval, switch it to **manual**. This is a toggle, not a deploy, and it is the only thing that can put a broken conversion path in front of real customers this weekend — see the market bug below.

- ~~Is staging web serving the pricing branch?~~ **CLOSED 2026-07-30.** It serves `f4170c5` (= pricing tip `0d44816`), verified in the served bundle bytes: no Free card, new copy. **This corrected B3's artifact from `2d79311` to `0d44816`** — see the window steps above. The Free card was real on `2d79311`; merging it would have shipped the defect.
- ~~Confirm A3.7 ran~~ **CLOSED 2026-07-30.** Override deleted (backup `.env.pre-a3-7-revert` on the staging box), restart verified by PID/uptime, boot healthy. Staging's cutover instant is back to the real Jul 31 22:00 UTC, so every existing staging account is now pre-cutover: **the interstitial is dormant and nudges are stopped until the real instant.** Correct prod-parity — but it means **any interstitial-dependent test before Friday needs the override put back**, one command. This includes testing U5, whose entire job is darkening an interstitial that only fires post-cutover.
- **Review `0d44816`'s what's-next copy before Friday.** It arrived in B3's artifact rather than as the separate U0 deploy that was planned, so the window now carries copy that has not been through a review pass. The standing flag: *"services are only available with an active subscription"* is **inaccurate for existing free users (feature set frozen) and grandfathered 599 subscribers**, both of whom can reach `/choose-plan`. Qualify the wording or gate the card.
- **`.env.pre-a3-7-revert`** is now an untracked artifact on the staging box — same family as the 79 files in the backend tree. Name it in the post-Phase-C cleanup or delete it once the window closes.
- **Draft `#113` and `#117`** (`gh pr ready --undo`). Draft PRs cannot be merged, which makes the freeze mechanical instead of remembered. Undo after Phase C.
- **Optional, valuable:** apply `_04`'s content to staging's catalog and deploy the pricing branch to staging web — the only way to rehearse the display half.

---

## After the window — the mobile UX chunk (U-series)

The three items Viktor wants: a pre-redirect notice, no flashed privacy screen, and no second login. All mobile client work; none can ship before Aug 1; none needs to.

- **U1 — backend.** `POST /api/auth/web-handoff` (authed) issues a single-use, ~90s, Redis-backed token bound to `user_id`; a redeem endpoint validates, consumes, returns a normal session. Rate-limited. Token-in-URL leaks via history/referrer/sharing — short TTL and single-use are the defence. Precedent: the HMAC-signed opt-out links.
- **U2 — tagme-now.** Accept `?handoff=`, redeem, establish session, `history.replaceState` to strip the param, land on `/choose-plan`. Referrer-Policy on that route.
- **U3 — Android.** Request the token, build the URL, **fall back to the plain URL on any failure** (never worse than today). Pre-redirect notice, localized, HU canonical, 13 locales. Fix the flash — the interstitial dismisses and the underlying screen paints before the browser covers it, so it is **device-only: a look, not a test** (PROTOCOL §5).
- **U4 — iOS.** Same as U3, plus the **env-aware web host** (`WebURLHelper` builds on `https://senra.pet` unconditionally, so every staging QA session cross-wires to prod — Android's equivalent is already fixed). Lands on the merged branch at `4756295`; not blocked. **Note:** the iOS device pass proved interstitial *dormancy* (the negative case). The positive case — interstitial fires, handoff, choose-plan at 2750 — cannot be exercised on staging until the web host is environment-aware, because the CTA cross-wires to prod. **The env fix is therefore a prerequisite for testing U4, not just a cleanup.**
- **U5 — the decoupling lever, do this first, and note it is RETROACTIVE.** Add a `feature_flags` check consulted by `isPostCutoverAccount()`'s **presentation path only**. The nudge job compares `created_at` in SQL directly, so nudges keep running. Because the gate is **server-side**, it darkens the interstitial on binaries already built and submitted — including iOS 2.2.1 (5), which can no longer be modified. That is what makes it the highest-leverage chunk: it should land **before either platform releases**. **Do not use `PRICING_CUTOVER_OVERRIDE` instead** — it kills nudges too, and its own doc comment says never-in-prod; setting it without amending that comment plants a stale-comment trap (PROTOCOL §3).

### ⚠ The `/uk/` market bug — live on submitted builds

The interstitial's Subscribe CTA builds its URL **client-side**, and derives the country segment from **device region** (`Locale.getDefault().country` / `Locale.current.region`, via `regionToCountry`, defaulting to **`uk`**). The user record is never consulted.

**Consequence:** a Hungarian customer whose phone region is English/US taps Subscribe and lands on `/uk/choose-plan` — UK site, EUR pricing, no Kedvenc csomag at 2750, none of the approved copy. A dead conversion path.

**The mobile apps are distributed in the Hungarian store only, and will stay that way.** Every mobile user is an HU-market customer by construction. But store availability does **not** constrain device region — an HU Apple ID and an English-region device coexist normally — so the bug is live regardless of distribution.

**The governing distinction: market is fixed, language is not.** Store availability fixes the market (`hu`, always). Device language still varies, so in-app strings keep their 13 locales and HU-canonical convention. Using a region signal to pick a *market* is the defect.

**This is fixed by the handoff contract, not by a client patch** — once the server returns the whole URL, the client cannot get the market wrong. Until then, U5 plus the manual-release toggle is the containment.

- **U0 — the copy card.** **Already in `0d44816`**, so it ships with B3 rather than as the separate post-Phase-C deploy originally planned. Canonical HU is in the chat record. **Still owed: a review pass, and a decision on the "services only available with an active subscription" line**, which is inaccurate for existing free users and grandfathered 599 subscribers who can also reach that page. Qualify it or gate the card.

---

## Android submission

**Blocked on nothing functional.** Before uploading:

- ~~Check `versionCode`~~ **CLOSED 2026-08-01. The fielded build is `8260097` — versionCode 22, versionName 2.2.1 — tagged `release/2.2.1-vc22` on origin.**
  - **`2635a62` (vc23) was built but NEVER fielded.** It is the tip of `integration/v2.2`, which is why it was mistaken for the store build; an earlier version of this file said so and was wrong. A tag `release/2.2.1-vc23` was created on it and has been **deleted locally and on origin**.
  - **Consequence, and it matters for the contract: the env-aware web host is NOT in the field.** `WEB_BASE_URL` does not exist at `8260097` (0 files; control: `API_BASE_URL` matches 1 file, so the zero is real). The fielded CTA at `ui/screens/PetSetupWizardScreen.kt:147` is `Uri.parse("https://senra.pet/${WebUrlHelper.countryCode}/choose-plan")` — hardcoded prod host **and** device-region market. Production users are unaffected by the host half (a release build resolves to `senra.pet` either way); the cost is that **staging QA on the fielded build cross-wires to prod**.
  - Attestation record: **passed on `c8055f3` (vc21), fielded as `8260097` (vc22)**; delta between them is the versionCode 21→22 bump and the versionName 2.2→2.2.1 bump, 2 commits, no behavioural change.
- **Tag the submitted commit.** `integration/v2.2` is a movable branch tip; the store binary needs an immutable ref.
- **Submit early, gate the rollout.** C4/C5 self-gate, so early approval is safe. **Start the phased release only after `#117` is deployed and verified** — v2.2 is what makes the pickup-type defect reachable (MPL error 60 blocks fulfilment). With U5 in place, the rollout also does not have to wait for the handoff.
- **iOS 2.2.1 (5) is already submitted** from `4756295`. It carries the `/uk/` market bug and cannot be patched without another cycle. **Do not release it until U5 is deployed** and the interstitial is confirmed dark. Set the release to manual now.
- **Write the pass record** in this workstream's files, not the redesign CODEMAP. Include the negative results: recovery-email check **void** (amount-free by construction — no observable); the **`.staging` variant is unbuildable** (`google-services.json` has no `.staging` client); staging is **structurally excluded** from both recovery-email sends (`cs_live_%` filter) and shipping-line invoicing (`HU_SZAMLA_LINE_NAMES` is prod-keyed only).

---

## Hazards specific to this workstream

- **79 untracked files** sit in the backend working tree (currently on `flip/sub-billing-prereq`), including the runbook, the pricing spec, and the szamla records. One `git add -A` sweeps the whole record set onto a code branch. **Stage explicit paths, never `-A`.** `.git/info/exclude` is the freeze-safe mitigation (local, uncommitted, no deploy). Relocating or tracking them is **one deliberate pass after the window**, never piecemeal — and note the sibling project tracks its docs deliberately (board §9), so tracking is a live option if a `docs/` path is deploy-filtered.
- **Two Stripe accounts.** Prod ids carry `Jh5q1ETi1p`, staging carries `R2nJiUv7I5`. That fragment is the fastest way to tell which environment an object belongs to — it identified a "prod invoicing failure" as staging-only in under a minute.
- **INVOICING IS OFF-LIMITS** (PROTOCOL §6). A dead-lettered invoice is the boundary working. Never add a `HU_SZAMLA_LINE_NAMES` entry to silence an error — the HU line name is a könyvelő decision. And **no invoicing for past transactions**.
- **`sudo -u ubuntu pm2 restart backend`.** SSM runs as root; plain root pm2 **silently no-ops**. Prove restarts by PID and uptime, not exit status.
- **zsh is not bash.** `#` is not a comment interactively. One command per line, no inline comments.
- **A `--stat` is not a diff** — an in-line amendment never moves the count.
- **Paged output lies.** A trailing `:` from `less` means the result was truncated. A near-missed constraint migration hid behind exactly that. Use `--no-pager` and counts.
- **A negative grep is a claim about the pattern, not the file.** Three false zeroes today (`shuttled` vs `shuttle`, `zero-external-callers` vs `external caller`, a package name guess). Prove the pattern matches something known-present before drawing an inference from absence.

---

## Seat first moves

**CC (build seat):** read PROTOCOL in full → read the runbook → confirm prod tip and `#116`'s state against git → then the "owed before Friday" list. Surface artifact **and** hash in the same message. Git is read-only absent an explicit, recorded per-command go; the record's home is the workstream files.

**Review seat (chat):** read PROTOCOL → the runbook → this file → `orders-mpl-pickup-type-2026-07.md`. Hash every artifact you receive and compare. Demand two-ended cites. Ask whether the evidence is inside the change. When a verdict arrives without an observable attached — "all green" — ask what was actually read.

**Both:** the flip is the only fixed date. Everything else moves.
