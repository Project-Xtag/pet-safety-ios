# Senra — work plan, rewritten 2026-08-01

Replaces the pre-cutover plan. Every line below was re-checked against a pinned ref during the
2026-08-01 verification pass; claims that turned out to be branch reads rather than field facts have
been corrected and are marked **[was wrong]**.

**Reference state at time of writing**

| Repo | Ref | Note |
|---|---|---|
| pet-safety-eu | `main` = `33b59a0` | post-flip |
| pet-safety-eu | `docs/pricing-cutover-record` = `14a4b7a` | branch only, no PR |
| tagme-now | `main` = `cefb43b` | copy batch deployed |
| pet-safety-ios | `main` = `5e27855` | docs current |
| pet-safety-ios | `feat/mobile-redesign-phase1` = `1856938` | 9 code chunks unmerged |
| Android fielded | `8260097` | `release/2.2.1-vc22`, versionCode 22, 100% |
| iOS submitted | `4756295` | `release/2.2.1-build5`, 2.2.1 (5) |

---

## A. Price change — SHIPPED

Window executed 2026-07-31 22:0x–22:3x UTC. Every step closed on a direct observable, not an exit code.

| Step | Outcome |
|---|---|
| B1 | `SAFE FOR B2` — 24 keys, exactly one value changed. Secret VersionId `c1ff8a2a-fd2c-4fe7-9673-ffdf0968f725` (the 599 image is now `AWSPREVIOUS`, i.e. the fast rollback) |
| B2 | `completed / success`, sha `33b59a0`; migration `20260801_04` applied 22:25:06; catalog `standard \| HUF \| 2750.00`; restart proven pid 788208 → 794537; drift watchdog named `STRIPE_PRICE_STANDARD_MONTHLY_HUF` in `backend-error.log` |
| B3 | `completed / success`, sha `a085bf5`; tagme-now `main` `ed6aaee → a085bf5`; delta re-hashed `040f20e632ea` at merge time |
| C1 | PASS — `amount_total 275000 huf`, three-link chain (in-process id → live price object → session) |
| C3 | PASS — catalog + display agree at 2750, render-verified |
| C4 | PASS — interstitial fires for a new account, not for a pre-cutover one |
| C5b | PASS — `199000`, `metadata.delivery_method = postapoint`, driven through the app's own `create-checkout` |
| B4 | Clear — no session created pre-B1 and paid after |
| C0 | **RETRY** — `checked=0`, examined zero rows, proves nothing |

**INV-1 confirmed twice**, and the second is the strong form: a pre-flip invoice finalised 599 on
2026-07-06 collected on 2026-08-01 06:46 — 8¾ hours *after* the cutover — still at 599, through a
Secrets Manager swap and a backend restart.

### A remaining

- **C5** — nudge targeting, after the first 10:30 UTC run past Aug 2.
- **C6** — Sentry + Stripe dashboard, first 24h.
- **C0 re-run — a trigger, not a date.** Fires when Android orders flow. Acceptance is
  `checked > 0 AND paid_mismatch = 0`. With current volume it will sit at `checked=0` indefinitely.

---

## B. The subscribe flow — release 2.3

The flow: register → subscribe → already logged in on the subscription page. Client code, so a store cycle.

### B1 — Freeze the contract ✅ DONE

`WEB-HANDOFF-CONTRACT.md` — **FROZEN 2026-08-01**, `a6ce9dd2e930`, 293 lines. Six corrections were
made at freeze, each against running code:

- `manage_subscription` → **`/{cc}/manage-subscription`**, top-level and public — not nested under
  `account`. **[was wrong]**
- `orders` — **no route and no page exists.** Kept in the enum, always returns 400, which is what §2's
  own rule means by reserved. **[was wrong]**
- **Prod host is `senra.pet`.** `app.senra.pet` has no DNS record; U1 built to the draft would have
  returned a URL to a nonexistent host that the client could not recover from. Staging genuinely is
  `staging-app.senra.pet` — the asymmetry is deliberate and is noted in the doc so nobody "fixes" it.
  **[was wrong]**
- **Redeem shape** — the web user flow has no password login at all (OTP only). Cookies are primary,
  the body token is a documented cross-origin fallback. Redeem must store a refresh token in DB, set
  both cookies via `utils/cookies.ts`, and return `{success, user, token, refreshToken}`.
  `refresh_token` is `sameSite:'strict'`, `path:'/api/auth/refresh'`. **[was wrong]**
- **`locale_hint` is NOT dropped.** `/hu/` forces Hungarian (`countries.ts:18` +
  `CountryContext.tsx:33-37`), so an HU-market customer who reads English gets Hungarian copy at the
  moment they pay. v1 **sends** it — reserving it in the schema alone buys nothing, because §8 freezes
  request field names. It is a **language signal only and must never feed market resolution**; the
  market stays pinned to `hu`. **[was wrong]**
- **Self-guard enum rule** replaces the draft's auth-boundary handling: a destination may only enter
  the enum if its page self-guards. `choose-plan`, `manage-subscription` and `billing` are outside
  `RedesignProtectedRoute` deliberately (they survive the Stripe round-trip) and each self-guards —
  `ChoosePlan:88` navigates to `/login` with a `returnTo`. `OrderConfirmation` is the live
  counter-example that deliberately does not.

Also recorded: **`POST /auth/login` is the wrong precedent** — it exists at `auth.routes.ts:162` and
the name invites copying, but the web never calls it. `verify-otp` (`:539`) is the precedent. The
three `.login(` hits are admin/partner/coop portals, all token-only.

**Cross-origin is architectural but benign.** `senra.pet` and `api.senra.pet` are different origins
but the same *site*, so `sameSite:'strict'` cookies ride the handoff normally. This was flagged as a
possible blocker and is not one.

### B2 — Server side, ships independently and inert

Nothing exists (`web-handoff`/`webhandoff`/`web_handoff` = 0 matches at `33b59a0`, controls hit).
Every primitive does.

- **U1 — `POST /api/auth/web-handoff` + redeem.** Opaque single-use token, ≥128 bits, 90s TTL,
  Redis-backed at `webhandoff:{token}` → `user_id`, bound to `user_id` only, rate-limited both ends.
- **U2 — tagme-now accepts `?handoff=`**, redeems, `history.replaceState` to strip the param,
  `Referrer-Policy: no-referrer`.

**Build against these, they already exist:**

| Primitive | Location | Note |
|---|---|---|
| Redis client | `config/redis.ts:1,41` | **`ioredis`.** Test mock exists at `config/__mocks__/redis.ts` |
| Rate limiter factory | `middleware/rateLimiter.ts:49` | 21 exports |
| Issue endpoint limiter | `apiRateLimiter:226` or `paymentRateLimiter:395` | latter is the tighter money-adjacent precedent |
| Redeem limiter (per IP) | `publicWriteRateLimiter:251` | redeem is unauthenticated by design |
| Sub-router precedent | `routes/auth/twoFactor.routes.ts` | |
| Cookie call site | `utils/cookies.ts` | |

⚠ **`adminRateLimiter:437` is a no-op passthrough.** Do not compose it by name expecting limiting.
⚠ `package.json` carries both `ioredis` and `redis`; only `ioredis` is imported. Drop the other.

Both endpoints can be live long before any client calls them. Until then every call 404s and users get
today's flow.

### B3 — Client side, one cycle

**The env-aware-host prerequisite is BOTH platforms, not just iOS. [was wrong]**

- **iOS** — `WebURLHelper.swift` @ `4756295`, `9d1479e38813`: prod host hardcoded at `:28`, market from
  device region at `:19-24` with `?? "uk"`. Nine call sites: 1 money path
  (`SubscribeInterstitialView:43`), 7 legal links, 2 read-only `validCountryCodes` checks. **Fix the
  helper, not the call site** — scoping to the call site leaves seven armed.
- **Android** — `WEB_BASE_URL` is genuinely absent from the fielded vc22 (`8260097`); it exists **only**
  in `2635a62` (vc23), which was never built. The fielded CTA at `PetSetupWizardScreen.kt:147` is
  `Uri.parse("https://senra.pet/${WebUrlHelper.countryCode}/choose-plan")` — hardcoded prod host **and**
  device-region market. **Do not plan U3 as "Android already has the host."**

Production users are unaffected by the host half (a release build resolves to `senra.pet` either way).
The cost is that staging QA on either fielded build cross-wires to prod, so the handoff cannot be
exercised safely anywhere until this lands.

**U3 (Android) / U4 (iOS)** — call the endpoint, open the returned URL, fall back to
`{env-host}/hu/choose-plan` on any failure. Timeout budget 3s. **No device region anywhere in either
client's fallback** — miss this and the `/uk/` bug survives in exactly the path that fires between
submission and U1 reaching prod.

**Pre-redirect notice** — key `subscribe_interstitial_redirect_notice`, **HU only** (not "HU canonical";
the apps are HU-market and the 13-locale parity gate does not apply). Copy:
"Most átirányítunk a SENRA weboldalára, ahol elő tudsz fizetni a Kedvenc csomagra." SENRA caps, te-form.

**Fix the flash** — interstitial dismisses and the underlying screen paints before the browser covers
it. Device look, not a test.

**Fold-ins — same cycle, not several:**

- `G-session-loggedout` — gate `/api/pets` + FCM registration on `isAuthenticated`. Phase-1 ship
  blocker. On iOS registration is driven by a notification hop (`AppDelegate:232` posts,
  `PetSafetyApp:172` is the only subscriber) — that subscriber is where the login-only behaviour lives.
- `G-owner` — **`lookup.isOwner` has no branch today.** Its only use on the scan path is a debug
  `print` at `DeepLinkService.swift:154`; `AlertDetailView`'s `isOwner` at `:23` is a separate locally
  computed property with the same name. The DTO exists and decodes (`QRTag.swift:71,80`), so the field
  is plumbed end to end and only the branch is missing. **[was wrong — the plan assumed a branch existed]**
- **Error-genre chunk — pin it.** `error.localizedDescription` appears at **106 sites** on iOS. Keep the
  chunk to `G-scan-error-raw` + `G-foundform-error-raw` + 2.4's raw 401; open the remaining ~103 as a
  separate inventory item. Do not let "fix raw errors" become release-blocking. **[was wrong — scoped as three]**
- **NEW: interstitial copy + spacing.** Shipped on web 2026-08-01 (`cefb43b`): title →
  "Fizess elő a teljes körű védelemért", spacing between `Előfizetek` and `Most inkább nem`. iOS and
  Android carry the same interstitial and **will diverge until this cycle**. Accepted, not a defect.

### B4 — Ship

Device pass, both platforms. **Tag before submitting** — now the established practice; the tags exist
(`release/2.2.1-vc22` → `8260097`, `release/2.2.1-build5` → `4756295`, and `release/2.2.1-vc23` deleted
because that build was never made).

---

## C. The redesign — resume

Phase 1 is complete; its last ship-blocker (`G-session-loggedout`) rides 2.3.

### C1 — Close the scoping (first, and cheap)

- **Ratify the B/C/D re-scope** — `PHASE2-READ-PLAN.md` (`32b9a8be00f0`, 113 lines), line 108,
  `## Proposed B/C/D re-scope (pending review — not executed)`. Still unratified. Blocks the reads.
- Read A is executed and its findings are recorded in the same file — it does not need re-running.
- Execute Reads B (board), C (detail), D (pet-friendly), E (remnants).
- Write `docs/phase-2-spec.md` — CC-authored chunk contracts. Then delete `PHASE2-READ-PLAN.md`.
- **Guard at spec time: one surface per chunk.** They shared a read; they must not collapse.

### C2 — Build, one surface per chunk

- **2.1 Scan → public profile.** ~~delete `ScannedPetView`~~ — **the file does not exist.** Four files
  still reference the name and the dormant-screen guard therefore can never fire. Rewrite the chunk as
  *remove the surviving references and retire the guard*. **[was wrong]**
- **2.2 Found-stray report.**
- **2.3 Lost & Found board.** `AlertsScreens.kt` exists and has **1 external caller**, so the
  zero-callers quarantine guard reads RED today. Either remove the caller first or drop the guard's
  premise. **[was wrong]**
- **2.3b Missing-pet detail** — iOS relocates; Android has `FoundPetDetailScreen.kt` and
  `PetDetailScreen.kt` but no single missing-pet detail screen, so Android BUILD stands.
- **2.4 Pet-friendly places** — routing build, action-level login gate.

### C3 — Phase 3

- **3.1 / 3.2 Guest-order wiring** — thread `user_id`/`email` on the guest path. Exact edits known.
- **3.3 Copy fix** — blocked on **Q3**, HU wording for the guest-order success surface.

### C4 — The branch merge

`feat/mobile-redesign-phase1` and the release line must eventually meet. Three known conflicts:

1. **`shippingCost = 0.0` hardcode — UNVERIFIED on the redesign branch.** The grep that reported "not
   hardcoded in production code" ran without a stated ref and the production sites it found are
   serialized model fields; the fix (`00ec476`) landed on v2.2. Re-run pinned explicitly to
   `feat/mobile-redesign-phase1` before treating this as resolved. **[status downgraded]**
2. **`found_pet_reported_success`** — the it/fr/cs/es divergence is real but **synonym-level**, and no
   locale is missing the key. Under the HU-only ruling this is inventory, not a gate. Still: pick one
   side wholesale, never hand-merge per locale.
3. **NEW — `case pending`.** `origin/main` (iOS) has `case pending = 0`; control `case active = 1`
   proves the zero. The fix exists as twins `ddfadf4` (redesign) and `bf16239` (release line) —
   identical hunks `5056ddacd879`, identical resulting files. **Do not re-fix** (it would make a third
   copy of a one-line enum case) and **do not assume `main` is clean**: anything cut from `main` before
   the redesign branch merges carries a live decode defect where a found-pet report is created
   server-side but the finder sees a decode error and each retry duplicates it.

---

## D. Account invoices — NEW workstream

**The problem.** `redesign7/Billing.tsx:55` → `/billing/invoices` → `billing.routes.ts:57` →
`billingService.getInvoices()` → Stripe. Users are shown Stripe's PDF. **The Számlázz.hu számla — the
legally meaningful Hungarian document — is not reachable from the account UI at all.**

**Legal frame (settled).** No invoicing for past transactions. The accountant owns everything pre-flip.
This is forward-only and it is a read-path job, not an issuance one.

**Decided:**

- Show **only számlák**. No Stripe receipts in the list.
- UI, wording and the `Megtekint` button are unchanged — document name + button.
- **Számlaszám** fills the document-name slot.
- **Sztornó: both documents listed, adjacent.** This is free — `storno_invoice_number` / `storno_pdf` /
  `storno_issued_at` are nullable columns **on the original row**, not a separate row. One row renders
  as one or two entries, inherently adjacent.
- **Add `user_id` + index to `szamla_invoices` and backfill.** The table currently has no `user_id`,
  no `order_id`, no `subscription_id` — the only linkage is `business_key` holding the Stripe object id,
  with no index for the reverse lookup. Seven rows to backfill; cheap now, expensive later. Migration
  numbers above `20260801_04`.

**Implementation notes:**

- `pdf` is a `bytea` column at **382–390 KB per row**. The list endpoint must select metadata only;
  fetch the PDF on the `Megtekint` click. `SELECT *` there would pull megabytes to render a list of names.
- Watch for the paid-but-uninvoiced case: under számlák-only, a post-flip payment whose invoice failed
  would silently vanish from the customer's list rather than showing a receipt. Correct legally, poor
  for support.

**Standing risk:** `szamla_invoices.pdf` is an unbounded BLOB in the primary transactional database with
no archival path. ~2.7 MB at seven rows.

---

## Standing hazards — carried, not fixed

| Item | Detail |
|---|---|
| `LOOKBACK_DAYS = 30` | A paid order uninvoiced past 30 days stops being re-enqueued. `AGED_TAIL_SQL` still counts it, so the escape hatch is a gauge, not a fix |
| Sub reconciliation page cap | Stripe listing capped at 20×100; beyond that the oldest gated-window invoices are unreachable and the run is not resumable. Self-declared, logs `invoice_reconciliation_sub_page_cap` |
| Dead-letter alerting | `dead_letter` is terminal and the job re-alerts **daily**, so Sentry counts grow indefinitely and do not indicate scale. A manually-issued számla is invisible to the job, so its op must be marked resolved or it alerts forever |
| Stripe address snapshot | `customer_address` is snapshotted at **finalization** and never revisited. A later backfill cannot repair an already-finalised invoice |
| Storno op naming | May fall outside the `%invoice%` op_type cut. Untested — nothing has been storned yet |
| Migration ordering | `run-migrations.sh` checks an applied-version *set*, not a high-water mark. Five historical inversions exist. `#66` carries `20260607_01` and must be renumbered above `20260801_04` |
| `redesign7.menu.*` | Menu labels are hardcoded literals with no locale entries — HU-only by construction, not by translation |

---

## Verification rules earned this session

These are in PROTOCOL; repeated here because every drift corrected today came from skipping one.

1. **A hash of `e3b0c442…` means an empty file**, never "no change". Print `wc -c` beside every hash.
2. **A zero from a negative grep is a claim about the pattern.** Always run a control that hits.
   (`grep -l "rateLimiter" middleware/` returned 0 against a file defining `createRateLimiter` — there
   are 21.)
3. **`gh run watch --exit-status` returns 0 for an already-completed FAILED run.** Read the
   `conclusion` field. `gh pr view` reporting `UNKNOWN` is not `CLEAN`.
4. **Enumerate the chunks; route position tells you nothing about chunk position.** Routed pages are
   `lazy()`-chunked so `index-*.js` carries none of their code — *and* the home page has its own
   `Redesign7-*.js` despite being the index route. Serve the HTML, read the real chunk names, grep each
   with a control.
5. **Comments strip at build.** A key named inside a `/* … */` rationale reads 1 in source and 0 in the
   bundle — neither is the answer. Read the call sites. (`choose_plan.activating`: live at `:308`,
   comment-only at `:282`.)
6. **A no-op cherry-pick aborts the sequence** and later commits silently never apply. Check
   `git diff --name-only main..HEAD` **before** pushing; empty is the tell.
7. **On a versioned API, `None` on a legacy field is absence, not a value.** Stripe's `paid: None` does
   not mean unpaid; `status: paid` + `amount_remaining: 0` is the authoritative pair.
8. **PR numbers collide across repos.** Always qualify: pet-safety-eu`#113` (postapoint backfill, HELD)
   vs tagme-now`#113` (copy batch, deployed). Same for `#111` and `#112`.
9. **A report about a diff is not a diff.** `MERGEABLE/CLEAN` is a mergeability fact, not a clearance.
10. **A claim written from a branch read is not a fact about the field.** Four separate errors this
    session traced to this root.

---

## Open decisions

- Error-genre chunk: confirm pin-to-three + inventory the rest.
- 2.1 rewrite (reference removal + guard retirement) and 2.3 (`AlertsScreens.kt` caller vs guard premise).
- Drop the unused `redis` dependency.
- Delete `flip/sub-billing-prereq` (local-only, 0 ahead of main, zero overlap with U1's surface).
- Ratify the B/C/D re-scope; ratify the 2.3 fold-in list.
- pet-safety-eu`#113` — merge as defence-in-depth or close. Evidence favours closing: zero paid
  mismatches ever, the one pending row was never charged, `#117` is deployed and verified, and the
  fielded Android carries Fix 9. If it merges it needs a rebase, a fresh byte review, and a check that
  its test file at `src/tests/` is inside the jest `roots` — otherwise it never executes.
- `#66` renumber · `#103` rebase · `G-scanback-ios` · what's-next card · **Q3** · whether `/plans`
  should state a subscription is required · chunk numbering and `G-home`'s doc home · owners for
  unassigned gaps.

## Cleanup — one deliberate pass, never piecemeal

17 stale `STRIPE_PRICE_*` lines in prod `.env` (inert, SM wins; the watchdog asks for exactly this) ·
`.env.pre-a3-7-revert` on the staging box · the 80 untracked backend files (hidden by
`.git/info/exclude`, not gone) · confirm `PRICING_CUTOVER_OVERRIDE` was reverted on staging after A3 ·
implement `legacyPageTestImports` in `senra-status.sh` (declared in CODEMAP §10, never written) ·
fix `pricingCutover.ts:6-7`, which names a C7 registration-reminder job that was never built ·
orphaned keys: `most_popular` ×3, `tag_card_footnote`, `plans.get_started` (orphaned on `/choose-plan`,
live on `/plans`), `choose_plan.activating`, `redesign7.menu.*`.
