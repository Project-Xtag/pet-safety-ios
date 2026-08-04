# Senra — session start, closeout run

**Transitional. This file points; it does not restate.** Where this file and an owner disagree, the
owner wins and this file is the bug.

**It carries its own deletion.** Fold §5–§7 into `docs/HANDOVER.md` and delete this file at the first
convenient commit. A dated session handover that outlives its session is exactly what `§D` of the
closeout ledger is deleting; this one is a fork that terminates itself.

Written 2026-08-04, at the end of a review run that landed closeout steps 1–3.

---

## 1. The seats

**Viktor** runs **all** git operations, exclusively. Neither seat commits, merges, pushes, tags or
deletes. Exceptions are per-command, explicit, and recorded — and they do **not** carry across steps.
A forwarded message is transmission, not authorisation.

**CC — build seat.** Proposes and executes code, gathers evidence, produces diffs and artifacts.
Never merges. Never treats its own report as a review.

**Review seat (chat).** Byte-reviews every artifact before anything commits. Rules on gates. Does not
write production code. Its job is to say *"that's a claim, not a fact — show me the bytes."*

**Rule 7 — the shuttle.** Every artifact travels with `shasum -a 256 <file> | cut -c1-12`, plus
`wc -c` and `wc -l`, **in the same message as the artifact**. A hash in a later message is not a
verification. The review seat re-computes before reading.

**Clearance attaches to bytes.** A branch gaining a commit voids its review. Re-hash, re-clear.

**Reproduce, don't trust.** Where the review seat holds the pre-image, it applies the diff and
compares to the post-image rather than accepting the post-image. Retain reproductions — they become
the base for the next round's post-to-post diff.

---

## 2. ⚠ THE READ RULE — new, and it exists because of this run

Six of this run's defects came from the same root: **grep used as a substitute for reading.** Not one
of them looked wrong at the time.

> **Any file whose content enters a claim is read in full before the claim is made, and the whole-file
> identity travels with the claim.**

**The declaration.** Before citing any file, CC states one line:

```
READ <path> @<ref> — <hash12> · <bytes> B · <lines> L · read 1–<lines>, no gaps
```

If the read was ranged, the ranges must cover `1..N` with no gaps and be listed. `wc -l` is the
check: you cannot claim a complete read without stating the line count you completed.

**grep locates; it never concludes.**

- Any count feeding a decision is paired with the enumeration — `grep -n` or `grep -o`, not `-c`
  alone. `grep -c` counts **lines containing**, not occurrences. This produced "three `CREATE INDEX`"
  (there were two, line three was a comment) and "three semicolons" (there was one statement).
- Every reported **zero** carries a control that hits **and shares the suspected defect** — same
  case-sensitivity, same file, same pattern class. `grep -c 'the'` proves the file is readable; it
  does not test the pattern.
- Beware substring and case: `grep -ic 'CI'` matched `specific`. Use `\b` anchors.
- Beware markdown in diffs: `grep -c '^-[^-]'` cannot match a removed line that itself begins `- `.
  Use `diff`'s own `NcN` ranges.

**Comments are content.** `20260801_04` was read as its one `UPDATE` statement and passed review; the
full read found a header carrying a deployment coupling (Secrets Manager swap must travel with the
migration) that changed the operational picture. **Migrations, workflows and scripts are read
including their headers**, always.

**Line citations are forbidden as carried facts.** Cite by symbol and let the reader `grep -n`. This
run produced five stale line numbers in one README because the file it documented grew fifteen lines
in the same commit. Numbers in prose are fine as *evidence of a read*; they are not fine as
*instructions to a future reader*.

**A hash over a line range is not a gate unless its extraction command travels with it.** Four of the
five B2 range hashes cannot be reproduced — only `7eab63b653d0` (a whole file) can — because the
extraction method was never recorded. That is the *"a count only verifies if the counting method
travels with it"* row applied to a hash. Whole-file hashes are gates; range hashes are provenance.
**Symbol groundings are the usable form.**

**Hunk counts are not an instrument.** `diff` implementations break ties differently, so a hunk count
is not portable between seats. Verify a revision **post-to-post**, never by comparing two diffs
against a shared ancestor. See `§Deferred` D1 in the ledger.

**`e3b0c442…` is the sha256 of an empty file.** It means "I read nothing", never "no change". Print
`wc -c` beside every hash. Use `gshow` (in `~/.zshrc`), which returns hash, bytes and lines together.

---

## 3. Owners — read these, don't read summaries of them

| You need | Owner |
|---|---|
| Roles, rules, hazards, hard boundaries | `docs/PROTOCOL.md` — **read in full, first** |
| The closeout sequence, `§M`, `§D`, `§Deferred`, the pin rule | `docs/DOCS-CLOSEOUT.md` — tracked, transitional |
| Redesign plan, locked decisions, gaps register, CODEMAP | `docs/SENRA-MOBILE-REDESIGN.md` |
| Priority stack and open decisions | `docs/SENRA-WORKPLAN-2026-08-01.md` (→ `WORKPLAN.md` at Phase 2) |
| The web-handoff contract — **FROZEN** | `docs/WEB-HANDOFF-CONTRACT.md` |
| Phase-2 read scopes | `docs/PHASE2-READ-PLAN.md` |
| Migration hazards, runner behaviour | `pet-safety-eu/backend/migrations/README.md` |
| What is done, red, or owed | `scripts/senra-status.sh` — **run it**, do not read a summary. Branch-scoped. |

All four repos, not a monorepo. The monorepo's `docs/` is a stale archive.

---

## 4. Reference state

**The pin rule governs** (`docs/DOCS-CLOSEOUT.md`): **a hash is written only for bytes that cannot
move** — FROZEN, DELETED, superseded, or applied. Everything else is re-derived at read time:

```bash
gshow origin/main <path>        # or: git show "origin/main:<path>" | shasum -a 256 | cut -c1-12
```

**Pinned, and must not be converted or "refreshed":**

| | |
|---|---|
| `WEB-HANDOFF-CONTRACT.md` — FROZEN | `fdf0d570c218` · 22,854 B · 323 L |
| └ §8, the frozen surface | `86a1c13aaad5` |
| §M operand — `senra-status.sh` #46 tip | `7dd21f156710` · 531 L |
| §M operand — `senra-status.sh` on `main` | `a1aeca162505` · 451 L |
| §M output — the cleared resolution | `9e9c2fbf2b4c` · 32,196 B · 546 L |

⚠ **§M's operands are exempt from the pin rule and going stale is their signal.** Do not convert them
to derivations and do not refresh them to match current state — refreshing one deletes the check.
`9e9c2fbf2b4c` is void **only if `scripts/senra-status.sh` changes at either end**, and `main` is the
end that can still move. **No board edit before the seam.** It survived four merges this run.

**Derive, do not trust these numbers** — recorded only as "was, at 2026-08-04":

| Path | Was |
|---|---|
| `ios docs/HANDOVER.md` | `358112d8c74b` · 282 L |
| `ios docs/DOCS-CLOSEOUT.md` | `4a6daa85e99b` |
| `ios docs/SENRA-MOBILE-REDESIGN.md` | `1e4d38a56b7d` · 536 L |
| `ios docs/PROTOCOL.md` | `63603befd524` · 246 L |
| `ios docs/SENRA-WORKPLAN-2026-08-01.md` | `21162d0195e3` · 323 L |
| `ios docs/SESSION-HANDOVER-2026-08-01.md` | `7b7bb5538501` · 243 L |
| `eu backend/scripts/run-migrations.sh` | `ab9db2e22dce` · 197 L |
| `eu backend/migrations/README.md` | `285543261f02` · 159 L |

**Merged this run** (immutable, safe to cite): eu `#121` → `218a2d2`, eu `#122` → `aae0c09`,
ios `#51` → `4dfb559`, ios `#49` → `947a49f`. ios `#66` and `#40` **closed**. eu `#120` **parked**.

---

## 5. Where the run stands

| Step | State |
|---|---|
| 1 · ledger corrections + Q6 ruled `docs/` | **MERGED** |
| 2 · `#49` folds + pin rule applied to `HANDOVER.md` | **MERGED** |
| 3 · runner `ON_ERROR_STOP=1` + README | **MERGED**, prod deploy green |
| 4 · `#66` | **CLOSED, not done** — superseded; E7 closes with it |
| 5 · B2 read plan into the workplan | **NEXT** — D2-gated |
| 6 · U1, then U2 | the next substantive build — ⚠ **gated, see below** |
| 7 · closeout Phase 2, at the seam | waits for U1/U2 per `§0`; §D renames → §9 → §M merge |

### ⚠ U1 is gated on `appCheckIfEnforced` — settle before building

`app.ts:236` mounts `authRoutes` behind `appCheckIfEnforced`, so the web-handoff endpoint **inherits
App Check** — and `redeem` is called by a browser, which has no App Check token. If enforcement is
ever switched on, `redeem` 4xxs for every web client, the flow falls back to today's, and the feature
is **safe but permanently inert**.

That is the worst available failure shape, and the frozen contract guarantees its silence:
**fallback-on-any-failure is part of `§8`'s frozen surface**, so the contract's own safety property is
what hides the breakage. Nothing 500s. Nothing alerts. Users simply never get the new flow.

Two consequences for U1's design:

- **Decide the mount before building.** The sub-router precedent (`twoFactor.routes.ts` + `app.ts:54`)
  is read-plan item 5's other half and exists for exactly this — mount `redeem` outside the enforced
  router, or rule explicitly that enforcement will never be switched on and record why.
- **U1 needs a positive signal, not just fallback.** With fallback-on-any-failure frozen into the
  contract, there is no way to distinguish *working* from *inert* in production without something that
  reports `redeem` **succeeded**. Build that in, or the feature can be dead for months and look fine.

Re-ground `app.ts:236` by symbol before relying on it — the line number is from a report, not a read.

**Step 5 carries three things, not one:**

1. The B2 read plan's **genuine additions only** — the five range hashes, the `app.ts:54,239` mount
   question and whether `appCheckIfEnforced` applies, and item 6 (tagme-now `CountryContext` /
   `countries.ts` / the redesign7 route entry). Items 2, 3, 4 and 5a are **already committed** in the
   workplan; re-adding them mints a second copy.
2. **"Redeem shape / cross-origin" onto the settled-do-not-re-derive list.** It is ruled at workplan
   `§B1` (cookies primary, body token is the documented fallback; same-site so `sameSite:'strict'`
   rides the handoff) and tagged `[was wrong]` — got wrong once already, and nothing currently
   protects it.
3. `registration_reminder_sent_at` as a surviving idea from closed `#66`.

### ⚠ Step 5 is BUILT, UNREVIEWED, UNCOMMITTED — and its provenance is unstated

CC produced these at the close of the previous session. **No byte of them has been through the review
seat.** Do not commit them; re-clear from scratch.

| File | sha256 | Bytes | Lines |
|---|---|---|---|
| `WORKPLAN.post-step5.md` | `9116f3725bba` | 24,538 | 375 |
| `HANDOVER.post-step5.md` | `80fc086565b2` | 17,877 | 289 |
| `step5.diff` | `65a2e9f2073f` | 6,527 | 97 |
| `CC-ROUND22.md` | `90283911876a` | 5,116 | 98 |

**Three things the fresh review seat must establish before reading a line of it:**

1. **D2 gate — CC reports it was honoured**: built against the D2-gated pre-images, worktree cut from
   `main`, `+60 / −1`. Reported, not verified. Re-derive the workplan pre-image before clearing.
2. ⚠ **Step 5 is a two-file edit and `HANDOVER.md`'s half has a placement defect.** `HANDOVER.md`
   carries **two** settled lists — `:131` (*"are settled and must not be re-derived"*, in *What is
   live right now*) and `:276` (*"Settled and not to be re-derived: prod host… market… `locale_hint`…
   `orders`"*). **`:276` sits inside the `B2 read plan` section at `:251`–`:279`, which that section's
   own text says to delete**: *"Write it into `WORKPLAN.md` §B2, or have the fresh session produce its
   own under Rule 2 and discard this."*
   - If step 5 extended `:276` to four, **redeem-shape's protection dies the moment the section is
     discarded**, which is the next scheduled action on it.
   - If it extended `:131`, the two lists now disagree — three items against four.
   - Either way, `−1` line means the `B2 read plan` section was **not** removed, so `HANDOVER.md` and
     the workplan now both carry it. That is a second home for a moving fact.
   - **Completion, not a new round:** one settled list, outside the read-plan section; then delete
     `:251`–`:279` per its own instruction. Step 5 is not done until this is closed.
3. **Confirm items 2, 3, 4 and 5a were not re-added.** CC reports §B2 gains exactly three things and
   items 2–5's conclusions are not repeated because §B1 and the primitives table own them. Verify.

**Read-plan item 1 was dropped, not carried — accepted.** Recording an open question one section below
`§B1`'s answer, and below a settled list that now protects it, would be three statements of one ruling,
one of them interrogative. It is not lost: `§B1` owns the answer and carries the `[was wrong]` tag.

⚠ **D2 gates step 5.** The build tree's untracked copies are **stale drafts**, not copies of `main`:
workplan `9463140e6be9` vs `main`'s value, session-handover `89170a0b8c8b` vs `main`'s. Verify the
pre-image against `origin/main` before editing, and edit **from a worktree cut from `main`**, never
the build tree. `git add -A` there would commit older content over newer.

---

## 6. The queue — six items, none urgent, all real

| | Item | Home |
|---|---|---|
| 1 | **D3** — staging was recorded 57/48, was 2/12, now current. Write the derivation, not the number | ledger `§Deferred` |
| 2 | `:51` tense — the pin rule's `HANDOVER.md` application has landed; it reads as outstanding | ledger |
| 3 | **§M gains a step before its byte diff** — *read the merged result for facts that contradict each other, not just for conflicts*. `git merge-tree` says CLEAN when the contradiction lives in different files on each side | ledger `§M` |
| 4 | `README:26-28` and `HANDOVER:174`'s E7 row — both name `#66`, now closed | eu README + ios HANDOVER |
| 5 | `registration_reminder_sent_at` | workplan, rides step 5 |
| 6 | **The deploy does not prune** — see below | SSM + eu README |

**Item 6 in full, because it is the largest and is not a stale-file problem.** The runner enumerates
`$SCRIPT_DIR/../migrations` — the **deployed** directory, `:116` — and the deploy extracts without
pruning. So the deployed tree is a permanent superset of the repo, and the repo is not a statement
about what will run.

- **6a.** `add_subscriptions.sql` is still physically on prod and staging, logged as skipped on every
  run, two days after `#119` deleted it from the repo. Needs an SSM `rm` on both boxes; the README's
  *"deleted 2026-08-02"* is repo-true and server-false until then.
- **6b.** ⚠ **A renumber is a rename in the repo and an ADD on the servers.** The old-numbered file
  persists, is not in `schema_migrations`, and under set-membership **it runs**. The README currently
  prescribes renumbering with no mention of this. The instruction is incomplete as written.
- **6c.** Fix the prune, or document it as a property. This is the real remedy.

---

## 7. Owed by Viktor — neither seat can close these

- **Staging's `STRIPE_PRICE_STANDARD_MONTHLY_HUF`.** `20260801_04` applied to staging without its
  paired Secrets Manager swap, so **staging displays 2750 and may still charge 599** — the exact split
  the migration's own header warns about. Price-adjacent QA on staging is untrustworthy until closed.
- **SSM `rm` of `add_subscriptions.sql`** on prod and staging (item 6a).
- **`#120`** — a translation-workstream decision, not a sequencing one. Its own gate reports 62
  Critical of 6,482 findings. Mechanically safe to merge (computed: resolves to the current README,
  deletion preserved) and blocking nothing.
- **A PR sweep** — seventeen open across eu and ios, several auto-generated i18n sweeps old enough
  that the `#40`/`#50` supersede logic likely applies. Hygiene, not a gate.
- All git operations; store console state; anything needing a device or browser; prod Stripe and
  Secrets Manager; könyvelő questions.
- **`A6c`** — the bounded "does each object actually exist" audit over the 65 no-`BEGIN` migrations.
  Still unscoped, and now the load-bearing item: `164 applied` means `psql` was invoked, not that the
  effects are present, and a green staging run proves the runner works rather than that the flag
  catches anything.

---

## 8. Hazards that actually fired during this run

Pointers, not copies. `PROTOCOL.md §5` and `SESSION-HANDOVER-2026-08-01.md §7` are the owners.

- **A pin on a moving file is a false assertion with a shelf life measured in commits.** Six
  instances. The pin rule exists because fixing instances never ended; deleting the generator did.
- **Clearance is per-branch; consistency is not.** Two independently cleared branches, each
  internally consistent, merged CLEAN into a file that contradicted itself in four places. Pre-flight
  the merged *result*.
- **`gh pr view` reporting `UNKNOWN` is not `CLEAN`.** Poll until it resolves. Confirm `state=MERGED`
  after, never trust the pre-merge read. Capture the run id **before** merging.
- **Read `conclusion`, never `gh run watch`'s exit code.**
- **The SHUTTLE fired three times** — a report truncated and duplicated, a file that arrived as text
  only, and four of five artifacts missing while the prose describing them arrived intact. **The
  prose always makes it; the artifacts sometimes don't.** Count attachments against the table before
  sending.
- **A stale instruction propagates silently.** Two incompatible step-numberings coexisted for eight
  rounds and got acted on. When a sequence is renumbered, say the old one is superseded.
- **PROPORTIONALITY.** Block only on what ships wrong, corrupts data, or misleads a fresh session.
  Everything else is recorded, not fixed. Four rounds of this run were spent on line numbers.

---

## 9. First moves

**CC:** `PROTOCOL.md` in full → `§2`'s read rule → run the board → `docs/DOCS-CLOSEOUT.md` `§0`
and `§Deferred` → the workplan's priority stack. Re-ground every `file:line` by symbol before relying
on it. Git is read-only absent an explicit, recorded, per-command go.

**Review seat:** `PROTOCOL.md` → the board → `§M` if merges are in play. Hash every artifact before
reading it. Reproduce post-images from pre-images you hold. Demand the control on every reported
negative, and ask whether the control shares the suspected defect. Nothing clears on a summary.

**Both:** if a document and running code disagree, **the code wins and the document gets corrected in
the same pass.**

**The immediate task is step 5**, D2-gated, carrying the three items in §5.
