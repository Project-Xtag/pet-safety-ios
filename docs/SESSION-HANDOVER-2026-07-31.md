# Session Handover — Pricing Cutover Window & Onward

**Written 2026-07-30 by the review seat, at the end of a session that ran from `#117` review
through the tagme-now copy/layout repairs.**

Audience: a fresh CC (build) session, and a fresh chat (review) session. Read the whole thing
once before touching anything.

This document is a **sequence and a state snapshot**. It does not own facts that live
elsewhere. Where another document owns something, this one points rather than restates —
otherwise it becomes a fifth board and drifts within a week (PROTOCOL §1).

| Fact | Owner |
|---|---|
| The flip's operational steps | `pricing-C9-cutover-runbook.md` |
| Redesign gaps, rulings, chunk log | `docs/SENRA-MOBILE-REDESIGN.md` |
| Web handoff API contract | `WEB-HANDOFF-CONTRACT.md` (still DRAFT) |
| Two-seat rules, Rules 1–8 | `PROTOCOL.md` |

---

## 0. Seat protocol — unchanged

CC proposes and executes; the review seat byte-reviews every diff before anything commits;
**Viktor runs all git operations.** Rule 7 applies to every artifact: `shasum -a 256 | cut -c1-12`,
artifact and hash in the **same** message. The review seat hashes what it receives and compares.
Mismatch → stop.

A report *about* a diff is not a diff. Clearance attaches to bytes actually received.

---

## 1. State as of end of session

### Backend (`pet-safety-eu`)

| Item | Value |
|---|---|
| `origin/main` | `950a03a` — `#117` merged and deployed 2026-07-30 16:24Z |
| `#116` (cutover) | head `48a3d57`, MERGEABLE/CLEAN, one file: `20260801_04_standard_huf_2750.sql` |
| `#113` (postapoint backfill) | **HELD** — no live population. See §6 |
| Deploy run for `#117` | `30561289408`, exit 0, 2m6s |

`#117` is **verified** in the strong sense: `resolvePickupPointType('118530')` returned `CS` on
the prod box, the map parsed 811 entries (643 CS / 168 PP), and `589837 → PP` is the control
that rules out a blanket-CS parse.

### Web (`tagme-now`)

| Ref | SHA | Notes |
|---|---|---|
| `origin/main` | `ed6aaee` | untouched — **prod** |
| `origin/staging` | `a281f24` | deployed, run `30639043553`, conclusion `success` |
| `feat/pricing-2026-08` | `b74bcd2` | **B3's artifact** — see §2 |

`origin/staging..origin/main` = 0 commits. Prod has no code the rehearsal never exercised.
The main-vs-staging differing file set and the pricing branch's touched file set are **exactly
equal** (29 files, both directions empty) — there is no third source of drift.

### Mobile

| Platform | SHA | Version | Status |
|---|---|---|---|
| iOS | `4756295` | 2.2.1 (5) | **Released** |
| Android | **UNKNOWN** | versionCode **22**, versionName 2.2.1 | **Released** |
| Android | `2635a62` | versionCode 23 | **Never built, never submitted** |

### ⚠ Android: what is in the field has not been established

This was corrected late in the session and it invalidates work that preceded it. CC reported
`integration/v2.2 @ 2635a62` as *"what's actually submitted"* and verified the Android
interstitial, the `regionToCountry` map and the `PostaPointDetails` DTO against it. **vc23 was
never built.** Every Android client-side verification in this session was therefore made against
a ref that is not in the field. The iOS checks are unaffected.

The tag `release/2.2.1-vc23` points at `2635a62` and names a release that does not exist.
**Delete or rename it** — it currently reads as "this is what shipped." The actually-released
build has no tag.

**Confirmed 2026-07-30 by `git show --stat 2635a62`.** That commit is two files
(`app/build.gradle.kts`, `PetSetupWizardScreen.kt`, +14/−2): versionCode 22 → 23 plus a
`WEB_BASE_URL` per-build-type config field and the CTA rewire. Its message states outright:

> *"debug/staging → staging-app.senra.pet, release → senra.pet. **Release behaviour is
> byte-identical in effect.**"*

and its `ATTESTATION DELTA` block records that the delta since the device-pass SHA `c8055f3` is
only the versionName bump, the debug/staging host field, and the versionCode bump — *"none can
affect release behaviour beyond the version identifiers."*

**So the fielded vc22 carries everything substantive:**

- **Fix 6** → tag ordering works on Android in the field.
- **Fix 9** → delivery fields serialize. **`#113`'s hold is correct** (see §6).
- **The interstitial** → Android arms at the flip, same as iOS. C4 should expect identical
  behaviour on both platforms, **including the `/uk/` market bug** — the region-derived market
  segment was never fixed on either.
- **Typeless postapoint rows** — the client-side `type` plumbing was deliberately excluded from
  v2.2 on both platforms, so `#117` is load-bearing for **both**, not just iOS. Deployed and
  verified, so this is covered.
  *Near-miss worth recording:* vc22 was in the field before `#117` deployed at 16:24Z on
  2026-07-30. A typeless locker order in that window would have hit MPL error 60. The prod audit
  found seven typeless rows, all cancelled and unpaid — luck, not design.

**vc23 has zero user-facing value.** Its only content is version identifiers and a staging-only
host field. **Do not ship it standalone.** The `WEB_BASE_URL` field is a testability prerequisite
for U3 and belongs in 2.3 (see §5).

**Tag cleanup, thirty seconds:** run `git log --oneline c8055f3..2635a62`. The attestation delta
says the versionName bump is a separate commit in that range, so vc22 was built from either
`c8055f3` or that bump commit — release behaviour is identical across them, so this only decides
**which SHA to tag**. Then delete `release/2.2.1-vc23` (and `git push --delete origin
release/2.2.1-vc23` if it was pushed) and tag the actual vc22 build point, which currently has no
tag at all.

### Runbook

`Project-Xtag/pricing-C9-cutover-runbook.md` — hash `6cef6c1e9e16`, 367 lines, **untracked**.
Stays untracked through the window; folded into the deliberate post-window pass with the other
78 files. Never `git add -A` in that tree.

---

## 2. C3 — done, deployed to staging

**Complete 2026-07-30. Two commits, not one — the first did not build.**

| SHA | What |
|---|---|
| `b74bcd2` | repairs the JSX comment that broke the build — **B3's artifact** |
| `e8178f7` | the three edits — **does not build on its own** |
| `ff7e4fc` | previous tip, now superseded |

### What shipped

1. **`redesign7.plans_page.subtitle`** → `Fizess elő a Kedvenc csomagra, és tartsd biztonságban a
   kedvenced.` Now identical to `choose_plan.description`. Deployed bundle: 2 occurrences; the old
   *"Kezdj ingyen, válts magasabbra…"* at 0. That string was false on both halves — no free tier is
   presented, and there is nothing higher to switch to.
2. **Grid** → `max-w-4xl mx-auto`. The class strings at `ChoosePlan.tsx:261` and
   `PricingCards.tsx:96` are now byte-identical.
3. **Tag-card CTA** → `plans.get_started` (**renders "Kezdjük"**) → `/get-your-tag`, same key and
   destination as `/plans`, using the page's own `PlanButton`. No new strings.

### The deliberate deviation — endorsed, do not revisit

CC did **not** change the Standard card's button to match `/plans`. On `/plans` that button is
marketing (`PlanCta` → `/get-your-tag`). On `/choose-plan` it is the actual purchase:
`handleSubscribe`, `disabled` on `!eligibleForPaidPlans`, a loading state, and a label carrying the
price.

Making them "the same" would have stripped the price from the money CTA and removed the ability to
subscribe. **Layout and the tag card match; the subscribe button keeps its function.** That is the
correct reading of "make the cards the same."

### Verified on the deployed artifact

`main` untouched at `ed6aaee` throughout, checked after every push. Chunk-level, every negative
backed by a passing control:

- `ChoosePlan-DroWL9Cq.js` — controls `info_3` / `description` / `tag_card_title` = 1;
  `info_4` = 0, `most_popular` = 0; new `plans.get_started` = 1, `max-w-4xl mx-auto` = 1
- `Plans-BjSLHifv.js` — controls `price_subtitle` / `standard_name` = 1;
  `tag_card_footnote` = 0, `most_popular` = 0

### Two things still open on this

- **`navigate("/get-your-tag")` may not be country-aware.** The tag CTA uses `onClick={() =>
  navigate("/get-your-tag")}`. On `/plans` the equivalent is `PlanCta to="/get-your-tag"`, and
  `PricingCards.tsx` imports `CountryLink`. If `navigate` is a plain `useNavigate()`, this lands on
  a bare `/get-your-tag` rather than `/hu/get-your-tag`. The chunk grep proves the *label* renders,
  not the destination. **One click on staging settles it.** If it drops the segment, the fix is one
  line using whatever `/plans` uses.
- **`loadingLabel={t("choose_plan.activating")}`** on that same button — it has no `loading` prop
  and never enters that state, so it is inert, but an "activating" string is wired to a tag-order
  button. Tidy whenever that file is next open.

### Reviewed

`ff7e4fc..b74bcd2` = `05f721730243`, 2 files (`hu.json`, `redesign7/ChoosePlan.tsx`), no riders.
Full delta vs `main` = `040f20e632ea`, 29 files, 4 new, **nothing outside `src/`** — consistent
with the pricing epic throughout.

---

## 3. The window — 2026-07-31 22:00 UTC

= 2026-08-01 00:00 Europe/Budapest (CEST, +02:00).

**The runbook owns the steps.** What follows is the shape, not a substitute.

### What is automatic

Only the **arming**. `isPostCutoverAccount()` compares `created_at` against a hardcoded instant,
so new accounts start returning `post_cutover_account: true` with no enable step. The nudge job
self-activates on the same constant.

### What is manual — B1, B2, B3

Nothing schedules these. **Someone must be at a terminal.**

- **B1** — `aws secretsmanager put-secret-value` on the prod stripe blob, plus the read-back gate.
  `SAFE FOR B2` is the gate.
- **B2** — merge `#116`, then watch the deploy live. Failure → rerun first, diagnose after.
  There is no automatic recovery; prod stayed down four minutes on 2026-07-27 while a human read logs.
  **Read the run's `conclusion` field — do not trust `gh run watch`'s exit code** (see §7).
- **B3** — merge tagme-now's pricing branch to `main`. Separate workflow.
- **B4** — watch Stripe the first hour for sessions created before B1 and paid after → cancel,
  let the user retry.

If nobody runs B1–B3: at 22:01 Stripe still charges 599, the catalog still reads 599, **but the
iOS interstitial arms anyway** for new registrants and sends them to a page selling the old plan.
Incoherent, recoverable, but the flip will not have happened.

### Hazard specific to the window

`deploy.yml` has `workflow_dispatch` as well as `push: branches: [main]`. **A manual dispatch
deploys whatever `main` points at** — which between B2 and B3 is a partially-flipped state.
Don't dispatch. Only merge.

### Phase C — immediately after B3

- **C0** — dispatch `detect-postapoint-mismatch.yml`.
  **Acceptance is `checked>0 AND paid_mismatch=0`, not exit status.** Expect `checked=0` (3-day
  window, nothing in it) — that is RETRY, not PASS. See §7.
- **C1** — fresh checkout session → `amount_total: 275000`. The definitive proof B1 took.
- **C2** — grandfathered subscribers still on the old price id.
- **C3** — catalog and display both read 2750; no Free card anywhere.
- **C4** — brand-new account → interstitial fires; pre-cutover account → does not.
- **C5b** — PostaPont tag checkout at 1990. Proves B1's blob rewrite didn't mangle an adjacent key.
- **C5** — nudge targeting, **Aug 2+** after the first 10:30 UTC run. Cannot run in the window.
- **C6** — Sentry + Stripe dashboard, first 24h.

Smoke tests need a **browser User-Agent** — plain `curl` hits a bot regex and returns 403.

---

## 4. After the window — cleanup

No rush; do as one deliberate pass.

- **The what's-next card copy.** `choose_plan.info_3` reads *"Fontos! A bilétákhoz kapcsolódó
  szolgáltatások csak aktív előfizetéssel érhetőek el."* It is scoped to **the tags**, not
  "services" generally — narrower than the English gloss in the old handover suggested. Still
  arguably wrong for grandfathered 599 subscribers who read it. Qualify or gate; own web deploy.
- **Orphaned keys sweep** — `choose_plan.most_popular`, `plans.most_popular`, `plans.tag_card_footnote`,
  and `redesign7.plans_page.subtitle` if the `Plans.tsx:9/:10` fallbacks are replaced with literals.
- **`/plans` marketing claim** — whether the page should state that a subscription is required is a
  product decision, deferred deliberately. Not a defect fix.
- Strip the 17 stale `STRIPE_PRICE_*` lines from prod `.env`.
- Delete `.env.pre-a3-7-revert` on the staging box.
- The 79 untracked backend files — one deliberate pass, never piecemeal. Confirm `.git/info/exclude`
  is in place first (named as the mitigation, never confirmed done).
- Re-run the detector once Android orders flow — first meaningful green it will ever produce.
- **Doc pass.** See §8.

---

## 5. Release 2.3 — the subscribe flow

**The flow Viktor wants:** register → subscribe → already logged in on the subscription page,
no second OTP round. This needs client code, so it needs a store cycle. Nothing shipped so far
delivers it.

### B1 — Freeze the contract

`WEB-HANDOFF-CONTRACT.md` is still DRAFT. Two items remain:
- Confirm the four destination paths against tagme-now's router.
- Confirm the redeem response shape matches what tagme-now's session layer already consumes.

`locale_hint` is **dropped** — HU-only market and language. Freeze before any client builds
against it.

### B2 — Server side, ships independently and inert

- **U1** — `POST /api/auth/web-handoff` + `/redeem`. Opaque single-use token, ≥128 bits, 90s TTL,
  Redis-backed (`webhandoff:{token}` → `user_id`), bound to `user_id` only, rate-limited both ends.
- **U2** — tagme-now reads `?handoff=`, redeems, `history.replaceState` to strip the param
  immediately, `Referrer-Policy: no-referrer`.

Both can be live long before any client calls them. Until then every call 404s and users get
today's flow.

### B3 — Client side, one cycle

- **U4 prerequisite first** — iOS `WebURLHelper` env-aware host. Without it a staging build's CTA
  points at prod and the handoff cannot be exercised in any safe environment. **Fix the helper, not
  the call site** — it also backs `termsURL`/`privacyURL`.
- **U3 prerequisite** — Android's `WEB_BASE_URL` build field, i.e. the content of the unshipped
  `2635a62`. Same reason: without it a staging build cross-wires to prod. Fold it in here rather
  than releasing vc23 standalone (see §1).
- **U3 (Android) / U4 (iOS)** — call the endpoint, open the returned URL, fall back to
  `{env-host}/hu/choose-plan` on any failure. Timeout budget 3s. No device region anywhere.
- **Pre-redirect notice** — fully specified, mint at build time:
  - key `subscribe_interstitial_redirect_notice`
  - HU: `Most átirányítunk a SENRA weboldalára, ahol elő tudsz fizetni a Kedvenc csomagra.`
  - SENRA in caps (census: 164:11 across the four shipped catalogs; Android has zero title-case)
  - te-form
  - **HU only** — see the ruling in §9
- **Fix the flash** — interstitial dismisses and the underlying screen paints before the browser
  covers it. Device look, not a test.
- **Fold in the client bugs, same cycle:**
  - `G-session-loggedout` — gate `GET /api/pets` and FCM registration on `isAuthenticated`.
    **Phase-1 ship blocker.** Diagnosis complete and two-ended from logcat.
  - `G-owner` — branch on `lookup.isOwner`; owner scanning own tag lands on the finder page with
    their own contact shown, and self-notifies. Device-confirmed. Every new customer testing their
    tag on arrival hits this.
  - Error-genre chunk — `G-scan-error-raw` + `G-foundform-error-raw` + 2.4's raw 401. Already ruled
    one chunk 2026-07-21; owner still unassigned.

### B4 — Ship

Device pass both platforms → **tag before submitting** → submit → release.

---

## 6. `#113` — held, with the reason

Zero paid mismatches in the entire order history. The single pending mismatch
(`ORD-20260723-23FDA613`) has `shipping_payment_status = failed` — nothing was charged, nothing
awaits fulfilment.

**The "no source of new ones" argument holds, on confirmed grounds.** It originally assumed the
fielded Android build was `integration/v2.2 @ 2635a62`, which was wrong — it is vc22. But per §1,
`2635a62`'s diff is two files and version identifiers, so vc22 carries Fix 9. Android in the field
serializes delivery fields correctly and there is no ongoing population.

The detector's all-time zero is consistent with the hold either way, so it was never the
discriminator — `2635a62`'s diff was.

**Do:** `gh pr ready --undo` on `#113` so it can't be merged by reflex during the window.
**Decide after Phase C:** merge as defence-in-depth, or close.

**If it is ever reviewed:** its test sits at `src/tests/webhookPostapointBackfill.test.ts`, while
`#117`'s sat at `tests/unit/`. Grep the jest config's `roots` and confirm the file appears in the
report **by name**. A test outside the configured roots never runs and the suite goes green
without it.

---

## 7. Standing facts and traps — read this section twice

These are the things that cost this session the most time. All were discovered the hard way.

### tagme-now: `src/pages/X.tsx` is dead code for 42 of 45 pages

Exceptions: `PublicPetProfile` routes legacy; `PrivacyPolicy` and `TermsConditions` route both.
Everything else routes `redesign7/`.

Four commits on the pricing branch edited the dead twin and shipped nothing. One of them
(`34e9506`) removed a badge, added two tests, went green, and left the badge live on the money
page. Another (`0d44816` — the *B3 artifact*) added a trial-warning CTA to a page nobody reaches;
its 13 locale additions landed, its component change is inert.

Recorded at `docs/SENRA-MOBILE-REDESIGN.md` §9.20 and §10
(`web.legacyPageTestImports.allowedTwins`). **The board check is declared but not implemented** —
the grep in `senra-status.sh` is a small separate chunk, still owed.

### A bundle grep is not a render proof

Locale JSON ships whether or not any component references the key. Three new strings were verified
present ×1 in the served bundle while the card rendering them showed a **literal
`choose_plan.info_4` bullet** — a retired key that i18next echoed back, with `fallbackLng: 'en'`
unable to help because `en.json` lacked it too.

**Measure the render** — through the project's own i18n instance, or by eye on the deployed page.

### Routed pages are `lazy()`-imported — grep the right chunk, and run controls first

A scan of `index-*.js` returned 0 for every negative **and every control**. The component key
references live in per-page chunks (`ChoosePlan-*.js`, `Plans-*.js`), not the main bundle.

**A control that fails alongside your negatives is the only thing standing between a false zero
and a confident wrong answer.** Always run controls.

### Never assert rendered text from a key or a `defaultValue`

The review seat did this three times in one session — claimed the activation badge reads
*"Biléta aktiválva!"* (read from a `hu.json` key three lines from the diff hunk) and the tag CTA
reads *"Megrendelem"* (read from a `defaultValue` in component source). The page shows
**"Kezdjük"**, and the badge text was wrong too.

A key in a locale file may not render. A `defaultValue` in code is overridden whenever the key
exists. **Open the page.**

### Verifying against a branch is not verifying against what shipped

CC verified the Android interstitial, region map and DTOs against `integration/v2.2 @ 2635a62`,
described as *"what's actually submitted."* It was never built. A branch tip, a submitted build
and a **released** build are three different things, and only the store console distinguishes
them.

Store state needs console credentials, which are Viktor's (PROTOCOL §2). So the build seat
**cannot** close this question and must not phrase a branch read as a statement about the field.
Ask, or say "unestablished."

### Run `npx vite build` before any push touching a routed redesign7 page

`e8178f7` placed a `{/* … */}` comment between `) : (` and its element. A parenthesised ternary
branch must hold exactly one expression, so esbuild rejected it and the staging deploy died at
Install & Build. It was reported that `tsc --noEmit` exited 0 and the suite was 748 green on the
broken file.

**The recorded explanation for that is suspect and should be established rather than trusted.**
CC attributed the green `tsc` to nothing importing `redesign7/ChoosePlan.tsx`. But `tsc --noEmit`
type-checks every file in the tsconfig include set regardless of what imports it — test coverage
has no bearing on it — and a JSX expression container at that position should be a parse error TS
catches too. The likelier explanation is that **`tsc` was not re-run after that edit**, which is a
skipped step rather than a structural blind spot.

Either way the mitigation stands: **`npx vite build` before any push touching a routed redesign7
page.** But do not rely on the "tsc can't see it" story until someone reproduces it — if the real
cause is a skipped step, the lesson is different.

Staging was never damaged: the build fails before the S3 upload, so it kept serving the prior
bundle throughout. Verified during the failure, not assumed.


### `gh run watch` exit 0 does not mean the run succeeded

It returned exit 0 on a **failed** run, because the run had already completed — the exit code
reflects the watch, not the outcome. **Read the `conclusion` field explicitly.** This applies
directly to B2 and B3 in the window.

### `checked=0` is not a pass

`detect-postapoint-mismatch.yml` exits SUCCESS having examined zero rows when its 3-day window is
empty (proven: run `30563594471`). Four outcomes: **PASS** (`checked>0 AND paid_mismatch=0`),
**RETRY** (`checked=0` — told you nothing), **FAIL** (any `PAID_MISMATCH`), **WARN**
(`PENDING_MISMATCH`, still exits 0). Read the summary, not the checkmark.

Unwindowed baseline measured 2026-07-30: `checked=11, paid=0, pending=1`.

### Translation-QA is red on every PR event and green on every push

Systematic and pre-existing, with a merged precedent (`feat/pricing-2026-08-precutover`). It means
a genuine locale regression is **invisible at PR time** — the gate that exists to catch the
13-locale law cannot. Its own row, post-window.

### The tagme-now workflows are branch-pinned

`deploy.yml` → `main`; `deploy-staging.yml` → `staging`. Both also have `workflow_dispatch`.
Pushing a feature branch fires nothing. The web deploys from tagme-now's own workflow on its `main`
merge, **not** from the monorepo gitlink — the gitlink showing as modified in the monorepo working
tree is cosmetic.

### The health endpoint 403s a plain `curl`

301 to https, then a bot regex rejects it. Use a browser User-Agent.

---

## 8. Doc pass owed — after Phase C, one go

**`docs/SENRA-MOBILE-REDESIGN.md`** (tracked — real commits):
- §1's status line still says "nothing is built."
- `G-android-shipping-cost-zero` reads "documented, NOT actioned" directly below its own ✅ FIXED
  entry. Both true of different branches; a reader scanning §6 gets the wrong answer.
- Record the te-form ruling; **remove it from HANDOVER's open-rulings list** so it stops resurfacing.
- Implement the §10 `legacyPageTestImports` check in `senra-status.sh`.

**Pricing workstream files** (untracked — fold into the same pass):
- `#117` verified, with the observable and the `getDeliveryPoints` parity cite.
- `#113` held, with the reason.
- U5 shelved / `/uk/` redirect dropped / `locale_hint` dropped — each with its reason, or they
  resurface.
- `HU → hu` verified byte-exact on both platforms (`0x48 0x55`).
- The notice string spec.
- **Correction:** the old handover records *"the Free card was real on `2d79311`"* as verified
  fact. It was an observation against the **dead legacy page**. `0625d53` created
  `redesign7/ChoosePlan.tsx` already Free-card-free, so the routed page never had a Free card.
  The conclusion (merge the tip) was right; the reason was wrong.

**Backend:**
- `pricingCutover.ts:6-7` names a "C7 registration-reminder" job that was never built. All 14 files
  in `src/jobs/` were enumerated; none is one.

**Other:**
- `#66` carries a `20260607_01` migration that would apply after `_02`/`_03` are already applied.
  `run-migrations.sh` accepts it (applied-version-set check, not a high-water mark), but it breaks
  applied-order-matches-numeric-order. **Needs a renumber before it ever merges.** Not in the window.
- `#103`'s 14 migrations are a stale-branch artifact — those files are already on `main`, surfacing
  through an old merge base. Needs a rebase, not a migration fix.

---

## 9. Rulings closed this session

- **Informal te-form is deliberate and standard across all platforms.** Closes an item open since
  2026-07-26. *Residual:* the C5/C6 census put te:ön at 157:5 — five shipping strings diverge.
  Look before converting; some may be legal copy where `ön` is correct.
- **HU only, everywhere.** All apps are Hungary-only; proper localisation is a separate future
  project. 13-locale parity is **not a gate** on this work. Leave the other twelve locale files
  as inventory. Consequence: the 2.3 notice string is minted in HU alone.
- **In-person tag collection no longer exists.** The footnote claiming it was false and live in
  prod; the render block was deleted (all languages at once) rather than the HU string reworded.
- **`/plans` is the visual reference.** `/choose-plan`'s cards match it, not the other way round.

---

## 10. Decisions owed

| When | What |
|---|---|
| Before the window | Who is at the terminal for B1–B3 |
| ASAP (not window-blocking) | `git log --oneline c8055f3..2635a62` → tag the real vc22 build point; delete `release/2.2.1-vc23` locally and on origin |
| Post-Phase C | What's-next card: qualify or gate |
| Post-Phase C | `#113`: merge as defence-in-depth, or close |
| Post-Phase C | Should `/plans` state a subscription is required (product, not defect) |
| Before 2.3 ships | `G-scanback-ios` — iOS gesture-exit parity: accept or fix |
| Before Phase 2 spec | Ratify the B/C/D re-scope (proposed 2026-07-26, never reviewed) |
| Before Phase 2 spec | Chunk numbering; `G-home`/Q6 doc home |
| Before Phase 3.3 | **Q3** — HU copy for the guest-order success surface |
| Whenever | Owners for the unassigned gaps |

---

## 11. Shelved, with reasons — so they don't resurface

- **U5** (feature-flag the interstitial) — blunt across all three clients *including web*, and the
  backend cannot split them: zero client-identifying headers anywhere in `src/` (control grep
  confirms the pattern finds `req.headers` in five middleware files, so the negative is real).
  Web is the platform that carries the whole subscription path. The mainline HU user is unaffected.
- **`/uk/` → `/hu/` redirect** — 404 on unconfigured segments is accepted; `HU → hu` verified
  byte-exact on both platforms. Only non-HU-region devices are exposed, and that is out of scope.
- **`locale_hint`** — no job in an HU-only product.
- **`G-tab-scan-noparity`** — needs a `MainTabScaffold` carve-out (a §6 hard boundary); polish.
- **A tag CTA as a product objection** — the review seat argued against it on the basis that
  `/choose-plan` is only reached post-activation. That was wrong: the page is also reached from the
  interstitial by users with no tag. Viktor's call to add it stands.

---

## 12. Redesign Phase 2 — resume after 2.3

Phase 1 is complete; its last ship-blocker (`G-session-loggedout`) rides 2.3.
`PHASE2-READ-PLAN.md` owns the read plan. Read A is executed.

1. **Ratify the B/C/D re-scope** — blocks the reads.
2. Execute Reads B (board), C (detail), D (pet-friendly), E (remnants).
3. **Write `docs/phase-2-spec.md`** — CC-authored chunk contracts. Then delete
   `PHASE2-READ-PLAN.md`; its job ends there.
4. **Guard at spec time: one surface per chunk.** They shared a read; they must not collapse into
   fewer chunks.

Then build: **2.1** scan → public profile (+ delete `ScannedPetView`) · **2.2** found-stray report ·
**2.3** Lost & Found board (+ `AlertsScreens.kt` quarantine) · **2.3b** missing-pet detail (iOS
relocates, **Android BUILD**) · **2.4** pet-friendly places (routing build, action-level login gate).

Then Phase 3: **3.1/3.2** guest-order wiring (thread `user_id`/`email` on the guest path; exact
edits already known) · **3.3** copy fix, **blocked on Q3**.

### The branch merge — known conflicts

`feat/mobile-redesign-phase1` and the release line must eventually meet:
- The redesign line still carries the `shippingCost = 0.0` hardcode, fixed on v2.2 by `00ec476`.
  **Do not re-fix; it collides.**
- `found_pet_reported_success` — it/fr/cs/es diverge synonymously between the two lines.
  **Pick one side wholesale, never hand-merge per locale.**
