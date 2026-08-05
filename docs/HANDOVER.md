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
absent subject *by design* (`lguard`'s missing-subject `fail`): a guard that skips when its subject vanishes is a guard
that evaporates during exactly the work it exists for.

**So: do not "fix" those four, and do not raise them as a regression.** If you are on `main` and see
10, that is the expected number. If you are on the build branch and see anything other than 7, that
is real. The six standing reds are the same on both — AASA `/*/t/*`, the www 301, the two
`.onOpenURL` handlers, G-owner, and the two Zone-3 ship-gates.

**The heuristic is unchanged: every red is explained, never a number to match.**
| The documentation closeout, phased | `docs/DOCS-CLOSEOUT.md` — tracked, transitional; deleted at close |

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
| `PROTOCOL.md` | **derive** — `gshow origin/main docs/PROTOCOL.md` | |
| `SENRA-MOBILE-REDESIGN.md` | **derive** | |
| `SENRA-WORKPLAN-2026-08-01.md` | **derive** | |
| `SESSION-HANDOVER-2026-08-01.md` | **derive** — see the note below | |
| `HANDOVER.md` (the version this replaces) | `b8d204cd1042` | 89 L |
| Migration `20260802_01` v4 | `87e88be96acb` | 12,130 B / 202 L |
| └ executable-only fingerprint | `7a50f3f135bc` | 56 L |

**This table follows the pin rule** (`docs/DOCS-CLOSEOUT.md`): **a hash is written only for bytes that
cannot move.** Everything else says **derive** and is re-derived at read time. Use `gshow`, which
returns hash, bytes and lines together so a byte count cannot drift away from its hash:

```bash
gshow origin/main docs/PROTOCOL.md        # or: git show "origin/main:<path>" | shasum -a 256
```

**Three classes keep a hash, and they are not the same thing:**

- **FROZEN** — `WEB-HANDOFF-CONTRACT.md` and its §8 surface. The pin *is* the assertion; P1-1's
  freeze gate has nothing to check without it.
- **SUPERSEDED or APPLIED** — the 89-line `HANDOVER.md` this replaces, the merged docs line's
  `e451a2820970`, migration `20260802_01` and its fingerprint, and the Historical block below. Those
  bytes were fixed by an event.
- **§M's OPERANDS** — `7dd21f156710`, `a1aeca162505` and `9e9c2fbf2b4c`. **Exempt under §M — do not
  convert them.** See `docs/DOCS-CLOSEOUT.md` §M, which owns the exemption and the reason.

`SESSION-HANDOVER-2026-08-01.md` is DELETED-class **by intent and not yet by fact** — §D dissolves it
into this file at the seam. Until that happens its bytes can still move, so it derives; it earns a
pin only once someone needs to cite the exact bytes that were dissolved.

`DOCS-CLOSEOUT.md`'s row is **gone**, not converted: it is now tracked at `docs/DOCS-CLOSEOUT.md`,
so it is one `gshow` away and needed no row. Three different values for it were in circulation
before it came out.

**Historical, for merge work only:** `senra-status.sh` pre-image `203748cf8b57` (436 L); merge base
`b0b076b` where it is 267 L (`6fa4ad359d8b`); contract pre-P1-1 `a6ce9dd2e930` (293 L); docs-line
base `2bcc2ac` (PR #45).

### Branches

Three PRs stacked and unmerged: **#45** (08-01 docs) → **#47** (Phase 1 closeout, `df266fb` +
`317cc10`), and **#46** (board guards) on the redesign line separately. pet-safety-eu migration
high-water mark is `20260802_01` (verified at `218a2d2`). **The eu `main` sha is not restated here** —
the workplan's reference-state table owns it. Two documents carrying that sha is what produced the
F2 drift; do not re-add it.

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
build not started at time of writing. Build to `fdf0d570c218` and **do not amend it**. Four things
are settled and must not be re-derived:

- Prod host `senra.pet` is a literal. `app.senra.pet` has no DNS record; staging genuinely is
  `staging-app.senra.pet` and the asymmetry is deliberate.
- Market is pinned `hu`. **`locale_hint` is sent by v1 and is a language signal only** — accepted,
  validated, never fed into market resolution. Ruled 2026-08-02; §9.4 carries the reasoning and the
  retired evidence.
- `orders` stays in the destination enum and always returns 400. "Reserved" means exactly that.
- **Redeem shape: cookies are primary, the body token is a documented cross-origin fallback.**
  `refresh_token` is `sameSite:'strict'`, `path:'/api/auth/refresh'`; `senra.pet` and `api.senra.pet`
  are different origins but the same *site*, so it rides the handoff normally — flagged once as a
  possible blocker and it is not one. Contract §10 owns the detail. *(Added 2026-08-04. This was
  ruled at freeze and marked `[was wrong]` in the workplan's §B1, but was the one previously-wrong
  ruling this list did not protect — so the B2 read plan re-opened it as an open question. A ruling
  that has already been got wrong once is exactly the kind that needs to be on this list.)*

U1/U2 ship independently and inert: until a client calls the endpoint every request 404s and users
get today's flow.

**Migration `20260802_01` is applied to prod** (2026-08-02 16:04:09Z, 7/7 attributed, 164 applied,
new high-water mark) **and its source is committed — that hole is CLOSED.** It was applied manually,
outside the runner, and for ~6 hours the schema change existed in prod with its source in no
repository. It is now on pet-safety-eu `main` at `ca877a0` (PR #119), and the chain is verified end
to end at one value:

| Link | sha256 |
|---|---|
| Reviewed artifact (v4) | `87e88be96acb…587ed` |
| Committed on `main`, from a fresh clone | `87e88be96acb…587ed` |
| `schema_migrations.checksum` in prod | `87e88be96acb…587ed` |

⚠ **Nothing validates that chain automatically** — the runner writes a checksum and never reads one
back. If you need to know a migration's source still matches what was applied, verify it by hand:
`gshow <ref> <path>` against `SELECT checksum FROM schema_migrations WHERE version=…`.

§D's column and index are live. **The forward path is open** — nothing writes
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
  applied — the schema change rolls back, the version row lands, and it never re-runs.
  **⚠ AND THE RUNNER IS INVOKED BY CI, UNATTENDED — "apply migrations by hand" is NOT a gate that
  exists.** Verified on `origin/main` 2026-08-03: `.github/workflows/deploy-backend.yml:219` and
  `deploy-backend-staging.yml:125` both run `bash scripts/run-migrations.sh` as SSM Phase 2, and the
  prod workflow triggers on **push to `main` touching `pet-safety-eu/backend/**`** — which every
  migration does. So a migration merged to `main` is applied automatically, and if it aborts it is
  recorded as applied with no human in the loop. Applying by hand protects only the migrations you
  personally apply; it does not protect the pipeline, and a session inheriting that advice will
  believe it is covered when it is not. **Fix owed** — `-v ON_ERROR_STOP=1` in the runner, its own PR
  and its own session. Until it lands, treat every merge of a migration to `main` as an unattended
  apply.
  *(A checksum read-back is deliberately NOT bundled with that fix: 164 recorded checksums have never
  been audited, so a mismatch cannot be distinguished from ordinary drift. Measure first, warn, then
  enforce.)*
- **Three copies of the deploy workflow exist and all three differ.** Only the repo-root
  `.github/workflows/` is live. `pet-safety-eu/.github/workflows/deploy-backend.yml` and
  `pet-safety-eu/backend/.github/workflows/deploy-backend.yml` are inert **and already drifted** —
  the three hash `30247a49afd3` / `d1714894bd66` / `d96f47052942`. Read the wrong one and you are
  describing a file nothing executes. **Always confirm you are in repo-root `.github/workflows/`.**
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

⚠ **PROPORTIONALITY — block only on what would ship wrong, corrupt data, or mislead a fresh
session.** Everything else is noted **once, in one line**, and does not generate a round.

**There is always another finding in any artifact.** The question is never whether one exists — one
always does — but whether it justifies another exchange. A correct observation that changes no
decision still costs a full round trip, and rounds are the scarce resource, not findings.

*Recorded because this is the failure the rest of the protocol has no defence against.* Every other
rule here makes review **stricter**; none of them says when to stop. On 2026-08-02 this loop found
four things genuinely worth blocking on — the `locale_hint` reversal, the email-join backfill, the
board's evaporating guards, and a migration applied with no source — and then ran several more
rounds past them on wording, hash re-pins and counts that changed nothing. The work was correct; the
rounds were not free.

**Test before raising it: if this is wrong, does something ship broken, does data corrupt, or does
the next session believe something false?** If none of the three, write the line and move on.

**Both:** if a document and running code disagree, **the code wins and the document gets corrected
in the same pass.**

---

## Append here as B2 proceeds

*(Chunk, artifact hash, review status. Replace this section rather than adding a dated file.)*
