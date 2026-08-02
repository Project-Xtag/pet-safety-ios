# Senra — Session Handover

**This file points. It does not restate.** Every fact has exactly one owner; a restated fact drifts
and then contradicts. **Where this file and an owner disagree, the owner wins and this file is the
bug.**

Program-scoped: all four repos, not just the mobile redesign. Undated by design — this file is
rewritten in place, never dated and never forked. Supersedes `SESSION-HANDOVER-2026-08-01.md` and
`SESSION-HANDOVER-2026-07-31.md`, both of which are deleted by the closeout ledger's §D.

Current as of **2026-08-02**, end of the review session that cleared PR #46, PR #47, and migration
`20260802_01`.

---

## Owners — read these, don't read summaries of them

| You need | Owner |
|---|---|
| Roles, the rules, the hazards, the hard boundaries | `docs/PROTOCOL.md` — **read in full, first** |
| The redesign plan, locked decisions, gaps register, CODEMAP | `docs/SENRA-MOBILE-REDESIGN.md` |
| The priority stack and open decisions | `docs/SENRA-WORKPLAN-2026-08-01.md` (→ `WORKPLAN.md` at Phase 2) |
| The web-handoff contract — **FROZEN** | `docs/WEB-HANDOFF-CONTRACT.md` |
| Phase-2 read scopes, Read A findings | `docs/PHASE2-READ-PLAN.md` — **§READ-A FINDINGS** |
| C5/C6's contract and gate | `docs/phase-1-spec.md` **§E C5/C6** |
| What is done, red, or owed right now | `scripts/senra-status.sh` — **run it. Do not read a summary of it.** ⚠ **branch-scoped — see below** |

⚠ **THE BOARD IS BRANCH-SCOPED, AND YOU ARE PROBABLY ON `main`.**
From **`main`** it reads **RED 10**. From **`feat/mobile-redesign-phase1`** it reads **RED 7**.
Both are correct; neither is a regression.

The extra four are `SUBJECT FILE MISSING` on iOS §5b — `LandingView.swift` and its siblings are
Phase-1 chunk files that live on the redesign branch and are **unmerged**. §5b fails loudly on an
absent subject *by design* (`lguard:192`): a guard that skips when its subject vanishes is a guard
that evaporates during exactly the work it exists for.

**So: do not "fix" those four, and do not raise them as a regression.** If you are on `main` and see
10, that is the expected number. If you are on the build branch and see anything other than 7, that
is real. The six standing reds are the same on both — AASA `/*/t/*`, the www 301, the two
`.onOpenURL` handlers, G-owner, and the two Zone-3 ship-gates.

**The heuristic is unchanged: every red is explained, never a number to match.**
| The documentation closeout, phased | `DOCS-CLOSEOUT.md` (repo root, untracked, transitional) |

There is **no monorepo for docs** — four repos only, and the monorepo's `docs/` is a stale archive.

---

## Reference state — pinned. Do not infer state from a branch name.

### Cleared and final

| Artifact | Hash | Size |
|---|---|---|
| `senra-status.sh` — **redesign line**, PR #46 @ `6632108` | `7dd21f156710` | 30,895 B / 531 L |
| `senra-status.sh` — docs line @ `628b25e` (now merged) | `e451a2820970` | 25,740 B / 445 L |
| `senra-status.sh` — **`main`**, after #47 + #48 | `a1aeca162505` | 26,297 B / 451 L |
| `senra-status.sh` — **#46 ⊕ `main` RESOLVED**, unmerged | `9e9c2fbf2b4c` | 32,196 B / 546 L |
| ~~`senra-status.sh` — #46 ⊕ #47~~ | ~~`fd70647aeb4a`~~ | **VOID** — superseded when #48 changed `main` |
| `WEB-HANDOFF-CONTRACT.md` — **FROZEN** | `fdf0d570c218` | 22,854 B / 323 L |
| └ §8, the frozen surface | `86a1c13aaad5` | 383 B / 11 L |
| `PROTOCOL.md` | `63603befd524` | 246 L |
| `SENRA-MOBILE-REDESIGN.md` | `79402e281962` | 535 L |
| `SENRA-WORKPLAN-2026-08-01.md` | `21162d0195e3` | 323 L |
| `SESSION-HANDOVER-2026-08-01.md` | `7b7bb5538501` | 243 L |
| `HANDOVER.md` (the version this replaces) | `b8d204cd1042` | 89 L |
| Migration `20260802_01` v4 | `87e88be96acb` | 12,130 B / 202 L |
| └ executable-only fingerprint | `7a50f3f135bc` | 56 L |
| `DOCS-CLOSEOUT.md` | `8ccdf9f9ba91` | 24,670 B / 440 L |

**Historical, for merge work only:** `senra-status.sh` pre-image `203748cf8b57` (436 L); merge base
`b0b076b` where it is 267 L (`6fa4ad359d8b`); contract pre-P1-1 `a6ce9dd2e930` (293 L); docs-line
base `2bcc2ac` (PR #45).

### Branches

Three PRs stacked and unmerged: **#45** (08-01 docs) → **#47** (Phase 1 closeout, `df266fb` +
`317cc10`), and **#46** (board guards) on the redesign line separately. pet-safety-eu `main` =
`33b59a0` plus migration `20260802_01`.

⚠ **#46 and #47 do not auto-merge.** Five files conflict. Four resolve to values already cleared
(the redesign line never edited them — its copies are content-identical to the docs line's starting
point). `senra-status.sh` was the only genuine one and **is already resolved and cleared at
`9e9c2fbf2b4c`**, reconstructed independently from both sides.

**Build it with `git merge-file -p <ours> <base @2bcc2ac> <theirs>`, not by taking both conflict
sides.** Concatenating sides duplicates the shared region: the conflict exists *because* both lines
advanced the same content from an old base, so each side's block already contains that content.
`rc=0` — there was never a semantic collision, only a textual one.

⚠ **`9e9c2fbf2b4c` is pinned to FILE CONTENT, not tip SHAs.** It is the union of `7dd21f156710`
and `a1aeca162505`. It is **void only if `senra-status.sh` changes at either end** — a commit
touching the workplan, the ledger or any other file leaves it valid. Check the two hashes, not the
branch names. A voided resolution reads exactly like a stale one; this is what distinguishes them.

At merge time: §D's renames go **first** (do not resolve into a file scheduled for deletion), then
diff the real merge output against `9e9c2fbf2b4c` byte for byte. A cleared resolution nobody checks
against the actual merge is a rehearsal.

---

## What is live right now

**B2 — the web-handoff subscribe flow, `pet-safety-eu`.** Read plan approved across six ranges;
build not started at time of writing. Build to `fdf0d570c218` and **do not amend it**. Three things
are settled and must not be re-derived:

- Prod host `senra.pet` is a literal. `app.senra.pet` has no DNS record; staging genuinely is
  `staging-app.senra.pet` and the asymmetry is deliberate.
- Market is pinned `hu`. **`locale_hint` is sent by v1 and is a language signal only** — accepted,
  validated, never fed into market resolution. Ruled 2026-08-02; §9.4 carries the reasoning and the
  retired evidence.
- `orders` stays in the destination enum and always returns 400. "Reserved" means exactly that.

U1/U2 ship independently and inert: until a client calls the endpoint every request 404s and users
get today's flow.

**Migration `20260802_01` is applied to prod** (2026-08-02 16:04:09Z, 7/7 attributed, 164 applied,
new high-water mark). §D's column and index are live. **The forward path is open** — nothing writes
`user_id` at issue time yet, so new invoices land NULL. `session.metadata.user_id` already exists at
checkout; the assembler change is the fix and it is not written.

---

## Owed by Viktor. Neither seat can close these.

| | |
|---|---|
| **E1** | §E C5/C6's must-not-touch wall — chunk boundary or standing? **Gates the Android Phase-2 shape; deadline is C1, before `phase-2-spec.md`.** Send `phase-1-spec.md` §E C5/C6 to the review seat as C1's first artifact |
| **E2** | HU register — rule "informal is deliberate" or overrule |
| **E3** | Migration `002` — ever real? Absent from the applied set *and* from `main` |
| **E4** | Does a rolled-back transaction against prod count as a production action needing a recorded go? |
| **E6** | pet-safety-eu#113 — merge or close |
| **E7** | #66 — renumber `20260607_01` above **`20260802_01`** (the mark moved) |
| | The §M merge resolutions, then Phase 2 of the closeout |
| | All git operations; store console state; anything needing a device or browser; prod Stripe and Secrets Manager; könyvelő questions |

---

## Standing hazards that bit during this session

Every one is in `PROTOCOL.md` §5 — this list is a pointer, not a copy. Read the owner.

- **`e3b0c442…` fired three times in one day**, twice from `$VAR:path` parsing as a zsh parameter
  modifier. Knowledge was not the gap; `gshow` is the mitigation, in `~/.zshrc`, and it returns
  non-zero and prints nothing on a bad ref rather than a plausible hash for an empty file.
- **A control must share the suspected defect.** A case-mismatched grep read 0 and so did a control
  known to be present — *two zeros where one was impossible* is what localised the fault to the
  pattern. `grep -c 'the'` proves the file is readable; it does not test the pattern.
- **The SHUTTLE.** The artifact and its hash must arrive in the *same message*. Fired repeatedly,
  including on the commit that promoted it.
- **A count only verifies if the counting method travels with it.** Pin a fingerprint instead:
  `grep -vE '^[[:space:]]*(--|#|$)' <file> | shasum -a 256`.
- **`run-migrations.sh` has no `ON_ERROR_STOP`.** An aborted migration exits 0 and is recorded as
  applied — the schema change rolls back, the version row lands, and it never re-runs. Apply
  migrations manually with `-v ON_ERROR_STOP=1` and write the version row by hand until fixed.
- **Mergeability is not clearance,** and clearance attaches to bytes. A branch gaining a commit
  voids its review.

---

## First moves

**CC (build seat):** `PROTOCOL.md` in full → run the board → the workplan's priority stack → this
file's reference state. Re-ground every `file:line` by symbol (`grep -n`) before relying on it.
Git is read-only absent an explicit, recorded per-command go; prod is Viktor's, rolled back or not.

**Review seat (chat):** `PROTOCOL.md` → board → the ledger's §M if merges are in play. Hash every
artifact before reading it. Demand the control on every reported negative, and ask whether the
control shares the suspected defect. Nothing clears on a summary.

**Both:** if a document and running code disagree, **the code wins and the document gets corrected
in the same pass.**

---

## B2 read plan — surfaced under Rule 2, NEVER RATIFIED

**This exists in no committed file.** It was produced in the 2026-08-02 review session and is
reproduced here so it is not lost. **Write it into `WORKPLAN.md` §B2, or have the fresh session
produce its own under Rule 2 and discard this.** Do not treat it as approved.

Ref: pet-safety-eu `origin/main` `33b59a0`. Build to `fdf0d570c218`, do not amend it.

1. `src/utils/cookies.ts:1-98` (`7eab63b653d0`) — **whole file.** Decides redeem's response shape.
   `:68-79` `setRefreshCookie` is `sameSite:'strict'`, `path:'/api/auth/refresh'`; `:44`
   `setAuthCookie` uses `getCookieOptions` (`:27`, none/lax, path `/`). Whether the strict path
   survives the `senra.pet` → `api.senra.pet` hop decides if the body token is fallback or primary.
2. `src/routes/auth.routes.ts:539-694` (`12b5a59951ac`) — verify-otp through refresh. **`:539` is
   the precedent redeem must copy, NOT `:162` `/login`, which the web never calls.**
3. `src/middleware/rateLimiter.ts:49-70, 226-260, 395-405, 437` (`048ac3d1c34a`). `:226`
   `apiRateLimiter` and `:395` `paymentRateLimiter` are the ISSUE candidates; `:251`
   `publicWriteRateLimiter` for REDEEM. **`:437` `adminRateLimiter` is a `next()` no-op — confirmed,
   must not be composed by name.**
4. `src/config/redis.ts:1-56` (`6eb8074c090f`). `:1` imports **ioredis**, `:41` exports the client —
   so `set(k,v,'EX',90)`, not node-redis's options object.
5. `src/routes/auth/twoFactor.routes.ts:1-20` + `src/app.ts:54,239` (`be2ee175f42b`). The sub-router
   mount precedent, and whether `appCheckIfEnforced` applies to a route the web calls.
6. tagme-now: the redesign7 route entry + `CountryContext:33-37`, `countries.ts:18`. U2 only.
   **Unpinned — a locating hint, not a citation.** Range to be fixed by `grep -n` at read time.

Settled and not to be re-derived: prod host `senra.pet` is a literal; market pinned `hu`;
`locale_hint` accepted, validated, never fed into market resolution; `orders` stays in the enum and
always 400s.

## Append here as B2 proceeds

*(Chunk, artifact hash, review status. Replace this section rather than adding a dated file.)*
