# Senra — work plan, rewritten 2026-08-01

Replaces the pre-cutover plan. Every line below was re-checked against a pinned ref during the
2026-08-01 verification pass; claims that turned out to be branch reads rather than field facts have
been corrected and are marked **[was wrong]**.

**Reference state at time of writing**

| Repo | Ref | Note |
|---|---|---|
| pet-safety-eu | `main` = `218a2d2` — as of 2026-08-04; **re-derive, do not trust:** `git -C <eu> rev-parse origin/main` | post-flip |
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
| C0 | **RETRY** — `checked=0`, examined zero rows, proves nothing. **The durable fix is pet-safety-eu#130** — `checked=0` must warn, not pass silently. Acceptance below is unchanged and still owns the criterion |

**INV-1 confirmed twice**, and the second is the strong form: a pre-flip invoice finalised 599 on
2026-07-06 collected on 2026-08-01 06:46 — 8¾ hours *after* the cutover — still at 599, through a
Secrets Manager swap and a backend restart.

### A remaining

- **C5** — nudge targeting, after the first 10:30 UTC run past Aug 2.
- **C6** — Sentry + Stripe dashboard, first 24h.
- **C0 re-run — a trigger, not a date.** Fires when Android orders flow. Acceptance is
  `checked > 0 AND paid_mismatch = 0`. With current volume it will sit at `checked=0` indefinitely.
  **Two known-positive rows now exist as its test** — `ORD-20260605-3C2C93A5` and
  `ORD-20260723-23FDA613`, both session-`postapoint` against a `home_delivery` row, both outside the
  detector's window. A run scoped to cover them satisfies the acceptance without waiting on Android
  volume. → pet-safety-eu**#130** carries the fix; C0 keeps the criterion. *(These are one finding
  recorded twice, six days apart. §E6 then cited the detector as proof of "zero paid mismatches"
  while this row said it proves nothing — the same document disagreeing with itself, inside the
  closeout that exists to stop that.)*

---

## B. The subscribe flow — release 2.3

The flow: register → subscribe → already logged in on the subscription page. Client code, so a store cycle.

### B1 — Freeze the contract ✅ DONE

`WEB-HANDOFF-CONTRACT.md` — **FROZEN 2026-08-01**, `fdf0d570c218`, 323 lines (re-pinned 2026-08-02 for the §9.4 `locale_hint` reversal; freeze intact — §8's binding surface unchanged, was `a6ce9dd2e930`/293). Six corrections were
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
- **`locale_hint` is NOT dropped — v1 sends it.** **The contract owns this; do not restate it here
  (PROTOCOL §1).** Ruling, evidence, freeze impact and the permitted language API are all in
  `WEB-HANDOFF-CONTRACT.md` **§9.4** (the answer, reversed and re-evidenced 2026-08-02) and **§5**
  (`Locale.current.language` / `Locale.getDefault().language` permitted; `.region` / `.country`
  banned). One line only, because U1 depends on it: it is a **language signal and must never feed
  market resolution** — the market stays the literal `hu`. **[was wrong]**
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

#### B2 read plan — the three things that were NOT already written down

*Surfaced under PROTOCOL Rule 2 in the 2026-08-02 review session, carried here 2026-08-04 so it stops
living in a chat transcript. Items 2–5's conclusions were already in §B1 and the primitives table
above and are deliberately not repeated (PROTOCOL §1). Item 1 — "does the strict-path cookie survive
the `senra.pet` → `api.senra.pet` hop" — is **removed, not carried**: §B1 already rules it, and
`HANDOVER.md`'s settled list now protects it.*

**a. The read's provenance, re-grounded by symbol.** Ranges drift; symbols do not. All six re-ground
against `origin/main` as of 2026-08-04:

| File | Symbols that anchor it |
|---|---|
| `src/utils/cookies.ts` | `:27` `getCookieOptions`, `:44` `setAuthCookie`, `:68` `setRefreshCookie` |
| `src/routes/auth.routes.ts` | `:539` `verify-otp`; `:162` `/login`; `:694` `refresh` |
| `src/middleware/rateLimiter.ts` | `:49` factory, `:226` `apiRateLimiter`, `:251` `publicWriteRateLimiter`, `:395` `paymentRateLimiter`, `:437` `adminRateLimiter` |
| `src/config/redis.ts` | `:1` `import Redis from 'ioredis'`, `:41` `export const redis` |
| `src/routes/auth/twoFactor.routes.ts` + `src/app.ts` | `:54` import, `:239` mount |

⚠ **The original read plan pinned five range hashes** — `7eab63b653d0`, `12b5a59951ac`,
`048ac3d1c34a`, `6eb8074c090f`, `be2ee175f42b`. Only the first is reproducible: it is
`cookies.ts` whole-file. **The other four are hashes of line ranges whose extraction method was never
recorded**, so neither seat can recompute them — the ledger's own *"a count only verifies if the
counting method travels with it"* row, applied to a hash. They are listed as provenance and **must
not be used as a gate**. The symbol groundings above are the reproducible form.

**b. OPEN QUESTION — does `appCheckIfEnforced` apply to a route the web calls?**
`app.ts` mounts `authRoutes` behind it — ground by expression, not line:
`app.use('/api/auth', appCheckIfEnforced, authRoutes)` — so `POST /api/auth/web-handoff` inherits App
Check by construction, and `app.use('/api/auth/2fa', appCheckIfEnforced, twoFactorRoutes)` shows the
sub-router precedent doing the same. Both verified present at pet-safety-eu `218a2d2`; note
`const appCheckIfEnforced = appCheckMiddleware` is a direct alias, so whether it enforces is a
config question, not a code one. **Redeem is called by a
browser, which has no App Check token.** If enforcement is ever switched on, redeem 4xxs for every
web client and the handoff dies silently — falling back to today's flow, which is safe but makes the
feature permanently inert. Settle before U1: either mount redeem outside the enforced group, or
confirm enforcement is off and record what turning it on would break.

**c. U2's tagme-now entry — path corrected.** The read plan said `src/routes/CountryRoutes.tsx`;
it is **`src/components/CountryRoutes.tsx`** (`3ca143f5e2f1`, 290 L — byte-identical from the frozen
ref `a085bf5` to `main` `cefb43b`, so the contract's §2/§11 citations still hold). Route lines: 193
`order-confirmation`, 194 `choose-plan`, 195 `manage-subscription`, 196 `billing`, 204
`RedesignProtectedRoute` opens, 205 `account`. Language forcing: `src/config/countries.ts:18` gives
`hu` `language: 'hu'`; `src/contexts/CountryContext.tsx:35` calls `changeLanguage`.

**Still true at pet-safety-eu `ca877a0`, and re-verified at `218a2d2`:** `web.?handoff` = **0**
across the backend `src` tree, controls `verify-otp` 7 files and `setAuthCookie` 2 files. Nothing to
build against has moved. *(Derive, do not trust the count:
`git grep -lE 'web.?handoff' <ref> -- ':(top)pet-safety-eu/backend/src' | wc -l` — the `:(top)` is
load-bearing, the repo root is `Project-Xtag` and a bare pathspec silently returns 0, which reads
identically to the claim being true.)*

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
- ~~**Add `user_id` + index to `szamla_invoices` and backfill.**~~ **DONE 2026-08-02** as
  `20260802_01_szamla_invoices_user_id.sql` — applied to prod 16:04:09Z, `user_id` (UUID, nullable,
  `REFERENCES users(id) ON DELETE SET NULL`) plus `idx_szamla_invoices_user_id_issued_at`, all seven
  rows attributed and verified programmatically (`declared_pairs 7, exact_match 7, mismatch 0`). The
  CODEMAP entry in `SENRA-MOBILE-REDESIGN.md` is the record. *(This item read as pending, and asserted
  "the table currently has no `user_id`", for three days after it shipped — corrected 2026-08-05.)*

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
| Migration ordering | `run-migrations.sh` checks an applied-version *set*, not a high-water mark. Five historical inversions exist. The mark is now **`20260802_01`**, not `20260801_04`. `#66` carries `20260607_01` — but **#66 was closed 2026-08-04, unmerged**, so the renumber only matters if `feat/onboarding-email-rework` is revived (pet-safety-eu**#129**). Re-derive the mark rather than trusting this row; and note the deploy does not prune, so a *rename* under the current deploy makes a migration run twice (pet-safety-eu**#126**) |
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

- **Post-shipping registration reminder — a surviving idea, not a branch.** `orders` has no
  `registration_reminder_sent_at` on `main` (`grep -c` → 0) and no job sends one;
  `recoveryEmails.routes.ts` is abandoned-cart at 3h on `shipping_payment_status='pending'`, which is
  a different thing. The idea arrived inside pet-safety-eu`#66`, **closed 2026-08-04 as superseded** —
  its activation half already ships as `activation_reminder_7day_sent_at` /
  `activation_reminder_21day_sent_at` — so this half would otherwise have existed only in a closed PR.
  Recorded here to decide on its own merits: one column, one query, one email.

- Error-genre chunk: confirm pin-to-three + inventory the rest.
- 2.1 rewrite (reference removal + guard retirement) and 2.3 (`AlertsScreens.kt` caller vs guard premise).
- Drop the unused `redis` dependency.
- Delete `flip/sub-billing-prereq` (local-only, 0 ahead of main, zero overlap with U1's surface).
- Ratify the B/C/D re-scope; ratify the 2.3 fold-in list.
- ~~pet-safety-eu`#113` — merge as defence-in-depth or close.~~ **RULED 2026-08-06: MERGED** as
  `a2a92b8`, deployed and verified in `dist/` the same minute. The ruling and its reasoning are
  recorded in `SENRA-MOBILE-REDESIGN.md` §2 Locked decisions, which is where E-items close.

  **The evidence that decided it, kept because the first version of it was wrong.** Stripe read across
  all 11 candidates: **zero paid mismatches, all time** — 3/3 completed are genuine home orders, so no
  billing correction was ever owed. **But the defect fired twice** on unpaid orders
  (`ORD-20260605-3C2C93A5`, `ORD-20260723-23FDA613`), which moved it from theoretical to demonstrated
  and is what tipped the ruling to merge rather than close.

  **The hold was the cutover window, not the merits.** #113 was converted to draft 2026-07-31 22:13:17
  UTC — 13 minutes after the price flip instant (22:00) and 10 minutes before #116 deployed (22:23) —
  to keep the deck clear while the 599 → 2 750 cutover was in flight. That window closed the same
  night. It is the only draft the repo has ever carried, which is why PROTOCOL §5 records this PR as
  HELD.


- `#103` rebase · `G-scanback-ios` · what's-next card · **Q3** · whether `/plans`
  should state a subscription is required · chunk numbering and `G-home`'s doc home · owners for
  unassigned gaps.

### Carried from the closeout ledger's §E — decisions no grep can close

Absorbed here because the ledger is deleted. **They close by being recorded in
`SENRA-MOBILE-REDESIGN.md` §2 Locked decisions** — that sentence came from the ledger's §E and was
dropped when this table absorbed it; without it a reader knows a decision is owed but not what
discharging one looks like. **This table is the only home for E1–E7** — `HANDOVER.md`
used to carry a second copy of four of them and now points here instead. E3 and E7 also have tracked
issues; the ledger was never the place for work GitHub can hold.

E6 and E7 keep their detail in **Open decisions** above rather than in this table, but they are listed
here so that searching for the label finds them — an entry nobody can grep for is the same as no entry.

| # | The decision owed | Why it does not close itself |
|---|---|---|
| **E1** | **§E C5/C6's must-not-touch wall — chunk boundary, or standing rule?** | Shapes Android Phase 2. **Deadline is C1, not B2** — must land before `phase-2-spec.md` relies on it. Does not have to ride any closeout. |
| **E2** | **HU register — "informal is deliberate", or overrule it.** | Blocks nothing. But without a ruling on record, a native-speaker reflex reopens it forever. |
| **E3** | **Migration `002` — was it ever real?** Absent from the applied set *and* from `main`. | On a set-membership runner a `002` file appearing later **will run**, against a schema ~164 migrations downstream. → pet-safety-eu**#128** |
| **E4** | **Does a rolled-back transaction against prod count as a production action needing a recorded go?** `ROLLBACK` bounds persistence, not lock acquisition; `ALTER TABLE` takes ACCESS EXCLUSIVE either way. The 2026-08-02 dry run had no go; the v4 apply and the Stripe reads did. | It will recur. No longer blocking anything — `317cc10` rewrote E5's entry to carry an interim rule that holds if E4 is never written. |
| **E5** | **CODEMAP entry for `20260802_01`** — the migration, the manual apply, the hand-written version row. | Record it before it is forgotten. This is the case that produced the "applied ≠ done" rule now in PROTOCOL §5. |
| **E6** | ~~pet-safety-eu#113 — merge as defence-in-depth, or close.~~ **RULED 2026-08-06: MERGE.** Merged `a2a92b8`, deployed and verified on the box the same minute. Recorded in `SENRA-MOBILE-REDESIGN.md` §2. | **CLOSED.** |
| **E7** | **Renumber `20260607_01` above the current mark.** Detail in the migration-ordering row of **Standing hazards** above. | **#66 was closed 2026-08-04, unmerged** — so this only matters if `feat/onboarding-email-rework` is revived. Blocked on the prune fix either way. → pet-safety-eu**#129**, **#126** |

⚠ **E7 changed under us and the entry above is the corrected one.** The ledger, `migrations/README.md:23`
and the first draft of #129 all describe **#66 as open**; it was **closed 2026-08-04 12:19 as
superseded**, unmerged. Its migration `20260607_01_onboarding_email_schedule.sql` still sits on
`feat/onboarding-email-rework`, so the real question is whether that branch is dead — if it is, delete
it and the renumber evaporates. A textbook correct-when-written claim, inherited by three documents on
the same day it expired.

### `web.legacyPageTestImports.allowedTwins` — move it or delete it. Do not grow the board.

**The board's C6 check reds on this today, and the red is correct.** The key is declared in plan §10
and consumed by nothing. It was already on the cleanup list as *"implement `legacyPageTestImports` in
`senra-status.sh` — declared, never written"*; that line is now removed, because implementing it
there is the wrong fix.

`senra-status.sh` reads iOS, Android and the deep-link repo **by design**. Growing it a `TAGME` root
to satisfy one orphaned web key is building infrastructure to answer a check. Two options only:

- **Move it** to `tagme-now`'s own test suite, where a consumer can exist. The rule is real and
  already written out at plan `:490` — *no test may import `@/pages/X` when `X` has a routed
  `redesign7/X` twin*, with `PublicPetProfile` / `PrivacyPolicy` / `TermsConditions` the only
  legitimate cases, and the check must **name** the offending import rather than count.
- **Delete it** from plan §10 if nobody can say what it protects.

PROTOCOL §1 routes an item that cannot be expressed as a check to *DECISION* or *NOT READY* — but a
`CONTRACT` declaration exists only to be consumed, so for this construct the two options above are the
whole set. A contract with no consumer and no board is a sentence.

⚠ Worth noting what this is: **C6's first finding is this session's own defect**, surfaced by a check
rather than by a person — a rule that lived in prose and never ran. Which is the thing the whole
closeout has been deleting.

### §D cleanup — checklist, not prose

The ledger's §D, reduced to what is actually actionable. Ticked items are done.

- [x] **Track `pricing-C9-cutover-runbook.md`** — was untracked *and* `.git/info/exclude`'d, so
      invisible to `git status`, to `git add -A`, and to the landmines check. `git add -f`'d onto
      pet-safety-eu `main` at `896318e`.
- [x] **branch `docs/pricing-cutover-record` @ `14a4b7a`** — verified already pushed; it is a
      decision (keep or fold), not a rescue.
- [ ] **Delete `SESSION-HANDOVER-2026-08-01.md`** — **delete, do not merge into `HANDOVER.md`.** It
      still lists `CODEMAP` as a peer file and still carries the superseded `20260801_04` high-water
      mark; a merge drags both into the survivor. Diff first to confirm nothing unique is lost; if
      something is, copy that one thing by hand.
- [ ] **Delete `SESSION-HANDOVER-2026-07-31.md`** — superseded.
- [ ] **Delete `SESSION-START.md`** — carries its own deletion instruction, and its §5 predicted
      step 5's failure branch, which then happened and was fixed. Merged to `main` to preserve the
      history; delete because it is finished. **Do not fold its §5–§7 into `HANDOVER.md`** — that is
      the merge-vs-delete trap again.
- [ ] **Cut `HANDOVER.md`'s PR-status paragraph and its board counts.** Both are transient state in a
      governing document — the same drift engine as a dated filename. GitHub owns PR status; the board
      owns counts. Keep the sentence that the board is branch-scoped and that counts differ by branch;
      delete every specific number. *(Both were already wrong: the PR paragraph calls #45/#47 unmerged
      when they merged 2026-08-02, and the counts say RED 10 / RED 7 when `main` now reads 12.)*
- [x] **Renamed `SENRA-WORKPLAN-2026-08-01.md` → `WORKPLAN.md`** 2026-08-05, and added it to
      `senra-status.sh` §9.
- [x] **Deleted `DOCS-CLOSEOUT.md`** 2026-08-05. ⚠ It has **no §9 entry** — the manifest names seven files and the
      ledger is not among them, so there is nothing to remove alongside it. §D's conditional clause
      anticipated exactly this; the unconditional reading sends someone hunting an entry that never
      existed.
- [ ] **monorepo `docs/` (74 files)** — one pass: delete, or one README saying "archive, nothing here
      is current".
- **`senra-status.md` — nothing to do.** §D lists it for deletion; it does not exist on `main`, on
  disk, or in the deletion history. Recorded so the next reader does not go looking.

## Cleanup — one deliberate pass, never piecemeal

17 stale `STRIPE_PRICE_*` lines in prod `.env` (inert, SM wins; the watchdog asks for exactly this) ·
`.env.pre-a3-7-revert` on the staging box · the 80 untracked backend files (hidden by
`.git/info/exclude`, not gone) · confirm `PRICING_CUTOVER_OVERRIDE` was reverted on staging after A3 ·
fix `pricingCutover.ts:6-7`, which names a C7 registration-reminder job that was never built ·
orphaned keys: `most_popular` ×3, `tag_card_footnote`, `plans.get_started` (orphaned on `/choose-plan`,
live on `/plans`), `choose_plan.activating`, `redesign7.menu.*`.
