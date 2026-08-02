# Session handover — 2026-08-01

**For:** a fresh CC (build seat) and a fresh Claude chat (review seat).
**Companion document:** `SENRA-WORKPLAN-2026-08-01.md` — that is the plan. This is the operating
context you need before you touch it.

Read §1 and §2 before doing anything. §7 is the list of ways this workstream has actually gone wrong;
every entry there cost real time on 2026-07-31/08-01.

---

## §1 — The seats

**Viktor** runs **all** git operations. Neither seat commits, merges, pushes, tags, or deletes
branches. Both seats produce artifacts; Viktor moves them.

**CC — the build seat.** Proposes and executes code. Gathers evidence from the repos. Produces diffs,
greps, query output. Never merges. Never treats its own report as a review.

**Claude chat — the review seat.** Byte-reviews every diff before anything commits. Rules on
acceptance gates. Does not write production code. Its job is to be the thing that says *"that's a
claim, not a fact — show me the bytes."*

**Rule 7 — hash verification.** Every artifact travels with its hash, **in the same message** as the
artifact.

```
shasum -a 256 <file> | cut -c1-12
```

Print `wc -c` and `wc -l` beside every hash. A hash arriving in a later message than its artifact is
not a verification. The review seat re-computes and compares before reading.

**A report about a diff is not a diff.** `MERGEABLE / CLEAN` is a statement about mergeability, not a
clearance. Nothing is cleared until the review seat has seen the bytes.

**Clearance attaches to bytes.** If a branch gains a commit after review, the clearance is void —
re-hash and re-review. This happened correctly on PR #42 (`1379c4c31f75` → `7f76846da91b`).

---

## §2 — Reference state

Everything below is pinned. Do not infer state from a branch name.

| Repo | Ref | Meaning |
|---|---|---|
| pet-safety-eu | `main` = `33b59a0` | post-flip, running in prod |
| pet-safety-eu | `docs/pricing-cutover-record` = `14a4b7a` | branch only, **no PR** |
| tagme-now | `main` = `cefb43b` | copy batch deployed 2026-08-01 |
| pet-safety-ios | `main` = `5e27855` | docs current as of today |
| pet-safety-ios | `feat/mobile-redesign-phase1` = `1856938` | 9 code chunks, unmerged |

### What is actually in the field — read this twice

Four separate errors on 2026-08-01 traced to one root: **a claim written from a branch read, stated as
a fact about the field.** Do not repeat it.

| Platform | Fielded / submitted | Tag | Note |
|---|---|---|---|
| Android | `8260097` — versionCode **22**, versionName 2.2.1, 100% rollout | `release/2.2.1-vc22` | |
| iOS | `4756295` — 2.2.1 (5), submitted | `release/2.2.1-build5` | |

⚠ **`2635a62` (versionCode 23) was never built and never shipped.** It exists only as a commit. It
carries the Android `WEB_BASE_URL` build field, which is therefore **absent from everything in the
field**. Any document claiming "Android's env-aware host is done" is describing a branch.

⚠ `release/2.2.1-vc23` was deleted (local and origin) because it tagged a build that does not exist.

**The fielded CTA on both platforms hardcodes the prod host and derives market from device region:**

- Android `PetSetupWizardScreen.kt:147` — `Uri.parse("https://senra.pet/${WebUrlHelper.countryCode}/choose-plan")`
- iOS `WebURLHelper.swift` — prod host at `:28`, device region at `:19-24` with `?? "uk"`

---

## §3 — What shipped, and what it means for you

The August 1 pricing cutover executed on 2026-07-31 between ~22:07 and ~22:35 UTC. **It is done.**
Backend, catalog and web all read 2 750 HUF. Grandfathered subscribers remain at 599 on
`price_1TY98HJh5q1ETi1pwgkltMzm` (INV-1), confirmed both by census and by a real dunning collection
that settled at 599 nearly nine hours *after* the flip.

The web copy batch shipped 2026-08-01 as `cefb43b` — seven HU string and layout changes.

**Three things from that window are still open and are in the workplan, not here:** C5 (nudge
targeting, Aug 2+), C6 (24h watch), and C0 (needs `checked > 0`; it is a **trigger on Android orders
flowing**, not a date).

---

## §4 — Immediate next work

The workplan is authoritative. In priority order:

1. **B2 of the subscribe flow** — U1 (`POST /api/auth/web-handoff` + redeem) and U2. Ships
   independently and inert; until a client calls it, every request 404s and users get today's flow.
   The contract is **FROZEN** (`a6ce9dd2e930`) — build to it, do not amend it.
2. **The invoices workstream (§D of the workplan)** — `user_id` + index + backfill on
   `szamla_invoices`, then swap the account list from Stripe receipts to számlák.
3. **C1 of the redesign** — ratify the B/C/D re-scope (`PHASE2-READ-PLAN.md` line 108, still
   unexecuted), then the reads, then `docs/phase-2-spec.md`.

**Blocked on a device or browser, and only Viktor can supply it:** the interstitial spacing and the
`/choose-plan` tag-card shape after the CTA removal. The interstitial requires a fresh post-cutover
registration to reach.

---

## §5 — The frozen contract

`WEB-HANDOFF-CONTRACT.md`, **FROZEN 2026-08-01**, `a6ce9dd2e930`, 293 lines.

Freezing binds §8's left column: endpoint path and method, request field names, `destination` values,
that the response carries `url`, and fallback-on-any-failure. Host, country-segment resolution,
path-per-destination, token format, TTL and param name remain free to change.

**Six corrections were made at freeze, each against running code. If you are working from any earlier
copy, you have the wrong document.** They are enumerated in the workplan §B1; the two most dangerous:

- **Prod host is `senra.pet`.** `app.senra.pet` has no DNS record. Staging genuinely is
  `staging-app.senra.pet` — the asymmetry is deliberate, do not "fix" it.
- **`locale_hint` is sent by v1** and is a **language signal only**. It must never feed market
  resolution; the market stays pinned to `hu`. Putting it in a market-resolution chain rebuilds the
  `/uk/` bug server-side where it is harder to see.

---

## §6 — Document map

| Document | Where | Committed? |
|---|---|---|
| `SENRA-WORKPLAN-2026-08-01.md` | local | **NO** |
| `SESSION-HANDOVER-2026-08-01.md` (this) | local | **NO** |
| `WEB-HANDOFF-CONTRACT.md` | pet-safety-ios `docs/` | yes, on `main` |
| `PROTOCOL.md`, `CODEMAP`, `SENRA-MOBILE-REDESIGN.md`, `HANDOVER.md` | pet-safety-ios `docs/` | yes, current on `main` as of `5e27855` |
| `SESSION-HANDOVER-2026-07-31.md` | pet-safety-ios `docs/` | yes |
| `pricing-C9-cutover-runbook.md` | monorepo, untracked + hidden by `.git/info/exclude` | **NO** |
| `PHASE2-READ-PLAN.md` | pet-safety-ios `docs/` | yes |

**Standing risk:** the two documents at the top of this table are local-only. Until 2026-08-01 the
governing docs on `main` were the 2026-07-17 versions — two weeks stale for the entire duration of the
flip, with `senra-status.sh` on `main` missing every guard added since. PR #42/#44 fixed that. Do not
let it recur.

There is **no monorepo for docs** — four repos only, and the monorepo's `docs/` is an archive of 74
stale files.

---

## §7 — Traps. Every one of these has fired.

1. **`e3b0c442…` is the sha256 of an empty file.** It means "I read nothing", never "no change". It
   fired when `git show <ref>:<path> > out` ran in a checkout that had not fetched the ref. Print
   `wc -c` beside every hash.
2. **A zero from a negative grep is a claim about your pattern.** Always run a control that hits.
   `grep -l "rateLimiter" middleware/` returned 0 against a file defining `createRateLimiter` — there
   are 21.
3. **`gh run watch --exit-status` exits 0 on an already-completed FAILED run.** Read the `conclusion`
   field: `gh run view <id> --json status,conclusion`. Require `completed / success`.
   Also: `gh run list --limit 1` right after a merge can return the *previous* run. Capture the run id
   before merging and poll until it changes.
4. **`gh pr view` reporting `UNKNOWN` is not `CLEAN`** — GitHub has not computed mergeability yet.
   Confirm `state=MERGED` after, never trust the pre-merge read.
5. **Route position tells you nothing about chunk position.** Routed pages are `lazy()`-chunked, so
   `index-*.js` carries none of their code — *and* the home page has its own `Redesign7-*.js` despite
   being the index route. Serve the HTML, read the real chunk names, fetch each, grep with a control.
6. **Comments strip at build.** A key named inside a `/* … */` rationale reads 1 in source and 0 in the
   bundle. Neither is the answer — read the call sites. Live example: `choose_plan.activating` is live
   at `ChoosePlan.tsx:308` and comment-only at `:282`.
7. **A no-op cherry-pick aborts the sequence** and every later commit silently never applies. Check
   `git diff --name-only main..HEAD` **before** pushing; empty is the tell.
8. **On a versioned API, `None` on a legacy field is absence, not a value.** Stripe's `paid: None` does
   not mean unpaid — `status: paid` + `amount_remaining: 0` is the authoritative pair. Same for
   `payment_intent: None`.
9. **PR numbers collide across repos.** pet-safety-eu`#113` (postapoint backfill, **HELD**, drafted)
   vs tagme-now`#113` (copy batch, merged and deployed). Same for `#111` and `#112`. Always qualify.
10. **A bundle grep is not a render proof.** A card once rendered a literal `choose_plan.info_4` bullet
    while the bundle agreed it was gone. Open the page.
11. **`tsc --noEmit` will not catch the class of error that broke the staging deploy twice.** Run
    `npx vite build` before pushing anything to tagme-now.
12. **Smoke tests need a browser User-Agent** — `curl` hits the bot regex.
13. **Migration ordering is set-membership, not high-water-mark.** Five historical inversions exist in
    prod. Anything carrying a migration below `20260801_04` must be renumbered.
14. **`adminRateLimiter:437` is a no-op passthrough.** Do not compose it by name expecting limiting.
15. **`dead_letter` is terminal.** No retry re-surfaces it, and the reconciliation job re-alerts
    **daily**, so Sentry counts grow indefinitely and do not indicate scale. Nine alert events once
    read as nine dead letters; there was one.

---

## §8 — Rulings that look like bugs

Record these before someone "fixes" them back.

- **`/choose-plan`'s tag card has no CTA; `/plans` keeps one.** The tag column ends on `Features`'
  `flex-1` whitespace against a filled Standard button. This asymmetry is **intended** as of
  2026-08-01. The CTA was added 2026-07-31 for parity and removed because this page is the subscribe
  flow and a second exit competes with it. C3's *"`/plans` is the visual reference"* ruling is
  **superseded**. Do not restore parity on sight.
- **`orders` stays in the destination enum and always returns 400.** No route and no page exists. That
  is what "reserved" means in contract §2 — a client landing somewhere it did not ask for is worse
  than a client falling back.
- **`featured` is kept on the home-page plan card** even though the `Legnépszerűbb` badge was removed.
  It drives the card's background, ring and shadow, not just the badge.
- **The `/uk/` market bug is expected on both platforms** on a non-HU-region device. Never fixed in the
  field. It is not a regression.
- **`origin/main` (iOS) has `case pending = 0`.** The fix exists as twins `ddfadf4` (redesign) and
  `bf16239` (release line) — identical hunks `5056ddacd879`. **Do not re-fix**, and do not assume `main`
  is clean: anything cut from `main` before the redesign branch merges carries a live decode defect.

---

## §9 — Viktor only

Neither seat can close these.

- All git operations: commit, merge, push, tag, delete.
- Store console state — Play Console and App Store Connect. A branch read is **not** a statement about
  what shipped.
- Anything requiring a device or a browser: render proofs, layout looks, the interstitial (needs a
  fresh post-cutover registration).
- Production Stripe and Secrets Manager actions.
- Könyvelő questions.

---

## §10 — Start here

**CC:** read `SENRA-WORKPLAN-2026-08-01.md`, then §7 of this document. Pick up B2 (U1/U2) unless
Viktor directs otherwise. Gather evidence pinned to explicit SHAs; state the ref in every output.

**Review seat:** ask for the artifact and the hash together. Do not clear anything on a summary.
When a negative is reported, ask what the control was.

**Both:** if a document and running code disagree, the code wins and the document gets corrected in
the same pass. Four errors on 2026-08-01 survived because a stale claim was quoted forward instead of
re-checked.
