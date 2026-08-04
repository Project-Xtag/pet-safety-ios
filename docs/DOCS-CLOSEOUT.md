# Docs closeout — the ledger

**Purpose.** Every documentation change owed from the 2026-08-02 review session, each with the
command that proves it landed. **A row is done when its check returns the expected value, not when
someone says it is done.**

**Provenance.** Review seat, 2026-08-02. Recut after the B2 sequencing decision; contract pin
updated after PR #47 was reported. **YOU ARE READING THE CANONICAL COPY** — `pet-safety-ios/docs/DOCS-CLOSEOUT.md`,
tracked. It is where the checks below run, which is why it is the one that governs. *(Moved from the
untracked repo root and committed 2026-08-03; `docs/` rather than root under the Q6 ruling of the
same date. It enters `senra-status.sh` §9's manifest at the seam, not before — a §9 edit changes
`main`'s board and would void §M's resolution.)*

**Phase 1 status:** `df266fb` **CLEARED** 2026-08-02 — diff `a5a73d34ddb1` applied to independently
held pre-images, seven post-images reproduced, contract byte-identical to the separately sent
artifact, §8 verified, every check below green. All four commits (`df266fb`, `317cc10`, `628b25e`, `c0c47dd`) **cleared and MERGED to `main`**, followed by `#48` (`35d6afa`, board branch-scope + E5 retroactive note). pet-safety-eu `#119` merged: `20260802_01`'s source is in `main`, checksum verified from a fresh clone.

**Single copy — collapse COMPLETE 2026-08-02.** *(Self-pin removed 2026-08-03 under the pin rule
below — this file is neither frozen nor deleted, so it carried a hash with a one-session shelf life.
Three values were in circulation before it came out. Re-hash at read time.)* This file
previously had two homes and they diverged inside one exchange: the root copy was described as
gaining the freeze-gate command while quoting the review copy's hash, which did not contain it. The
review-seat copy is now read-only reference; this one governs. **Do not re-create a second home** —
two homes for the document that exists to stop drift is not a defensible arrangement, and it took
under an hour to prove that the first time.

**The review seat cannot verify any row** — it sees only what is uploaded. Verification is
mechanical, or it is Viktor's eyes. It is never the review seat's word and never CC's.

**Rule 4 applies to this file.** Every expected-zero check carries a control that must hit.

## ⚠ THE PIN RULE — write a hash only for a file that is FROZEN or DELETED

**A hash pin is written only for a file that is FROZEN or DELETED. Every other file carries the
derivation instead**, re-derived at read time and never re-typed:

```bash
git show "origin/main:${f}" | shasum -a 256 | cut -c1-12
```

*Ruled 2026-08-03, after the same defect surfaced four times in three review rounds: this file's own
`:15` self-pin, `HANDOVER.md`'s `DOCS-CLOSEOUT` and `SENRA-MOBILE-REDESIGN` rows, and §M's four-file
table below — each a hash written for a file that was still moving, and each read later as a value
someone forgot to update rather than as a value that could not have stayed true.* A pin on a moving
file is not a weaker assertion than a derivation; it is a **false** one with a shelf life measured in
commits. **The exception is real and narrow:** `WEB-HANDOFF-CONTRACT.md` is FROZEN, so its pin *is*
the assertion — P1-1's freeze gate has nothing to check without it. Deleted files are pinned for the
same reason: their bytes cannot move again.

**Applies twice in the closeout sequence** — §M's table (below, done 2026-08-03) and `HANDOVER.md`'s
"Cleared and final — pinned" table, which rides #49's folds. Two of that table's rows are scheduled
to rot inside this very sequence: `SESSION-HANDOVER-2026-08-01.md` is deleted by §D and
`SENRA-WORKPLAN-2026-08-01.md` is renamed by it.

**Run from** `pet-safety-ios/` unless a row says otherwise.

⚠ **A DIRECTORY IS NOT A REF.** **PHASE 1 MERGED TO `main` 2026-08-02** (`#45` then `#47`; pet-safety-ios `main` is now past `2103878`), so `main` is the correct ref and a plain working-tree check is right **only if you are on `main`**. The working tree usually sits on `feat/mobile-redesign-phase1`, which carries **none** of Phase 1. Run these against the working tree and
they read the pre-Phase-1 values and look like failures. Two live examples: `HANDOVER.md`'s CODEMAP
count is **3** on the redesign line and **1** on the docs line; `WEB-HANDOFF-CONTRACT.md` is
`a6ce9dd2e930` on `main` and `fdf0d570c218` on the docs line. **Until Phase 1 merges, name the ref:**

```bash
H=origin/docs/phase1-closeout-2026-08-02
git show "${H}:<path>" | <check>
```

**The six-command acceptance check RAN and PASSED from `main` 2026-08-02** — contract `fdf0d570c218`, §8 pin `86a1c13aaad5`, old §9.4 answer 0 with control 12, `senra-status.sh` present, both 08-01 docs readable. That is what converts "Phase 1 is written" into "Phase 1 is what a fresh session reads."

---

## §0 — How this closes

Two phases, deliberately split. **Phase 1 is in B2's blast radius and goes before CC starts.**
Phase 2 is the disruptive half — renames and deletions — and lands at the U1/U2 → U3/U4 seam,
when nothing is mid-review.

1. Phase 1, in the order given. §B before anything that trims a document.
2. B2 U1/U2.
3. Phase 2 at the seam.
4. Re-upload changed files to the review seat: it re-hashes and re-runs this session's checks.
   **That is the acceptance gate** — the ledger proves the edits landed; only a re-read proves
   they say the right thing.
5. Delete this file **and remove its `senra-status.sh` §9 entry in the same edit** — a manifest
   pointing at an absent file reads as a governing doc gone missing, which is the exact red §9 exists
   to raise. A closeout ledger that outlives its closeout is another stale doc.

---

# PHASE 1 — before B2. One commit, ~1 hour.

Six items. Everything here is something a fresh CC would read, or misread, while building U1/U2.

## P1-1 · CONTRACT §9.4 — the `locale_hint` reversal ⚠ load-bearing

**RULED 2026-08-02: v1 sends `locale_hint`; market stays pinned `hu`.**

**REPORTED DONE in PR #47 (`df266fb`) — NOT BYTE-REVIEWED.** The contract moved
`a6ce9dd2e930` (293 lines) → **`fdf0d570c218`** (323 lines), re-pinned at all three sites with the
old value retained as "was". Thirty lines added to a FROZEN document: before this closes, confirm
against bytes that §8's left column is untouched — endpoint path and method, request field names,
`destination` values, that the response carries `url`, fallback-on-any-failure.

```bash
shasum -a 256 docs/WEB-HANDOFF-CONTRACT.md | cut -c1-12    # expect fdf0d570c218
grep -c 'Does v1 send `locale_hint`? — NO' docs/WEB-HANDOFF-CONTRACT.md   # expect 0
grep -c 'locale_hint' docs/WEB-HANDOFF-CONTRACT.md                        # CONTROL: expect >0
```

**The freeze gate, as a command rather than an instruction:**

```bash
awk '/^## 8\. Frozen/{o=1} /^## 9\./{o=0} o' docs/WEB-HANDOFF-CONTRACT.md > /tmp/s8.txt
shasum -a 256 /tmp/s8.txt | cut -c1-12    # expect 86a1c13aaad5
wc -c /tmp/s8.txt                          # expect 383  — CONTROL: a silent-empty extractor reads 0
head -1 /tmp/s8.txt                        # CONTROL: '## 8. Frozen once a client ships'
```

`86a1c13aaad5` / 383 B / 11 L is identical across `a6ce9dd2e930` and `fdf0d570c218`, verified from
both. **The hash is the assertion.** "§8 sits outside the conflict regions" is a tip-scoped
explanation that must be re-derived whenever either tip moves — it is not a substitute.

⚠ **`fdf0d570c218` is the pin from here.** Any document still citing `a6ce9dd2e930` as current is
stale; the old value survives only as a "was".

## P1-2 · CONTRACT §5 — name the permitted language API

§5 bans `Locale.current.region`, `Locale.getDefault().country`, and the two `countryCode` helpers.
Now that U3/U4 must read a *language*, the permitted call has to be named explicitly —
`Locale.current.language` is one word from the banned call on iOS.

```bash
grep -c 'Locale.current.language\|Locale.getDefault().language' docs/WEB-HANDOFF-CONTRACT.md  # >0
```

## P1-3 · WORKPLAN §B1 + HANDOVER — `locale_hint` restatements

Both said "v1 sends it" while the frozen contract said the opposite. The ruling now agrees with
them, but they should **point at the contract** rather than restate a ruling (PROTOCOL §1).
Same pass as P1-1, since the hash re-pin lands here anyway.

## P1-4 · HANDOVER — the frozen contract is not in the pointer table

A fresh session onboarding through HANDOVER never learns `WEB-HANDOFF-CONTRACT.md` exists — and it
is what B2 is built against. B2 spans sessions; this one cannot wait.

```bash
grep -c 'WEB-HANDOFF-CONTRACT' docs/HANDOVER.md                 # expect >0
```

## P1-5 · Board §9 becomes the manifest

**If a file is not in §9, it is not governing.** Add `WEB-HANDOFF-CONTRACT.md`,
`PHASE2-READ-PLAN.md`. (`WORKPLAN.md` and the merged `HANDOVER.md` get added in Phase 2 with the
rename. `phase-2-spec.md` cannot be tracked before it exists — its `:223` obligation should add it
to §9 in the same edit that re-points the Zone-3 gates.)

Cheap, permanent, and the thing that stops docs drifting *during* a multi-session workstream
rather than after it.

```bash
for f in WEB-HANDOFF-CONTRACT PHASE2-READ-PLAN; do
  printf '%-22s %s\n' "$f" "$(grep -c "docs/$f.md" scripts/senra-status.sh)"   # each expect >0
done
```

## P1-6 · Hazard promotions into PROTOCOL

**Before any document is trimmed.** Five hazards live only in files scheduled for deletion or
cutting. Cutting first loses them.

| | Hazard | Lives only in |
|---|---|---|
| a | **No-op cherry-pick aborts the sequence.** Later commits silently never apply; `git diff --name-only main..HEAD` empty is the tell | WORKPLAN + 08-01 handover |
| b | **The SHUTTLE.** *"The artifact and its hash must arrive in the same message."* Fired twice more on 2026-08-02: PR #46 arrived as hashes without bytes, and a manifest listed a superseded hash. This is Rule 7's live failure mode and belongs inside Rule 7 | HANDOVER |
| c | **`--stat` is not a diff.** `338a7d1` read `3+/1−` both before and after an in-line rewrite | HANDOVER |
| d | **Rule 7's new-file recipe.** PROTOCOL `:138` prescribes the `git diff --no-index` wrapper; HANDOVER `:36` says it *"adds nothing and is fragile"* and prescribes plain `shasum`. PROTOCOL §1 makes HANDOVER the bug by declaration — but the refinement is right. **Promote it, don't delete it** | contradiction |
| e | **A count only verifies if the counting method travels with it.** "73 executable lines unchanged" was unreproducible; two honest methods gave 56 and 73. For a comments-only claim, pin a fingerprint: `grep -vE '^[[:space:]]*(--\|#\|$)' <file> \| shasum -a 256` | **new, 2026-08-02** |

**Also record the Rule 6 ruling.** *Criterion-grepping is a review-seat obligation, not a board
check* — not expressible as a check, therefore a DECISION, therefore
`SENRA-MOBILE-REDESIGN.md` §2 Locked decisions, with PROTOCOL Rule 6 pointing at it. Board §12
stays as-is and is correct to.

```bash
for p in 'cherry-pick' 'same message' 'stat.* is not a diff' 'counting method'; do
  printf '%-24s %s\n' "$p" "$(grep -Eic -- "$p" docs/PROTOCOL.md)"    # each expect >0
done
grep -c 'Rule 7' docs/PROTOCOL.md            # CONTROL: expect >0
grep -c 'no-index' docs/PROTOCOL.md          # expect 0 after (d)
grep -ic 'criterion' docs/SENRA-MOBILE-REDESIGN.md    # expect >0
```

---

# PHASE 2 — at the U1/U2 → U3/U4 seam

The disruptive half. Renames make every stale pointer bite at once, so it wants a moment with
nothing in flight.

## §A — content corrections

### A1 · WORKPLAN §C2 2.3 — the guard now exists **and is green**

Today: *"the zero-callers quarantine guard reads RED today."* Wrong twice over as of `6632108`:
the guard did not exist when that was written, and now that it does, it reads **GREEN** — the
symbols measure 0 external callers. Replace the sentence; do not merely delete it.

```bash
grep -c 'quarantine guard reads RED' docs/WORKPLAN.md          # expect 0
grep -c 'AlertsScreens' docs/WORKPLAN.md                        # CONTROL: expect >0
```

### A2 · WORKPLAN §C2 2.3 — the caller count is stale

*"`AlertsScreens.kt` … has 1 external caller"* — measured 0/0/private at android `931b51b`,
control `MainTabScaffold` → 4 files.

```bash
grep -c '1 external caller' docs/WORKPLAN.md                    # expect 0
```

### A3 · WORKPLAN §D — the index claim reads as false

*"no index for the reverse lookup"* — `business_key` **is** unique-btree'd. What is missing is an
index supporting **user → invoices**.

```bash
grep -c 'no index for the reverse lookup' docs/WORKPLAN.md      # expect 0
grep -c 'user → invoices' docs/WORKPLAN.md                      # expect >0
```

### A4 · WORKPLAN §D — record the backfill key, and that §D's migration is APPLIED

`business_key` resolves to nothing (0/68 on both payment-intent columns; `cs_…` vs `pi_…`;
subscriptions carry no invoice id). Attribution came from the Stripe chain. Write it down or a
future reader reaches for `business_key` again and gets a backfill matching zero rows that looks
like it worked.

**Status update in the same edit:** `20260802_01` applied to prod 2026-08-02 16:04:09Z, 7/7
attributed, 164 applied, new high-water mark. §D's remaining work is the **forward path** — the
assembler must write `user_id` at issue time (`session.metadata.user_id` already exists there) —
and the read-path swap from Stripe receipts to számlák.

```bash
grep -c '20260802_01' docs/WORKPLAN.md                          # expect >0
```

### A5 · WORKPLAN §D — the seven rows are six customers plus one test artifact

`hello_fr@senra.pet` / E-SENRA-2026-7 is a test customer on the live prod app. Any later census
or support-facing figure reading 7 as the customer-invoice population is off by one. It also
intersects the pre-HU-flip test-row cleanup: `ON DELETE SET NULL` fires on a real `DELETE` and not
on a soft delete, so a soft delete leaves the invoice listed under the test account while a hard
delete orphans a számla with no other linkage. Cross-reference both ways.

*(Separately, and yours: it is a real Hungarian számla issued on prod, so NAV has it. Whether a
test-purchase számla wants a sztornó is a könyvelő question — and the sztornó rule is full
cancellation only, keyed on the original számlaszám.)*

### A6 · WORKPLAN Standing hazards — four new rows

| | Hazard |
|---|---|
| a | **`add_subscriptions.sql` is unnumbered, on `main`, and `run-migrations.sh` skips it forever.** Reads as applied, never was, never will be |
| b | **`run-migrations.sh` has no `ON_ERROR_STOP`.** Verified on prod: an aborted transaction exits 0; the same file with the flag exits 3. So a `RAISE EXCEPTION` rolls back the schema change **and the runner records the version as applied** — a permanent silent hole, and the migration never re-runs. Code fix deliberately deferred; **the hazard is not** |
| c | **65 of 152 migrations carry no `BEGIN` of their own** (87 do). Those run in autocommit, so a mid-file error leaves them *partially* applied and recorded as applied. Historically the dangerous flavour. A bounded audit — does the object each one creates actually exist? — wants scoping |
| d | **"164 applied" means `psql` was invoked, not that the effects are present.** Set membership is not schema truth. This weakens the earlier "every file on `origin/main` is applied, 0 pending" reading |

### A7 · WORKPLAN Standing hazards — enumerate the inversions

Replace *"five historical inversions exist"* with the list: `017`→`001` ·
`20260122_01`→`00000000` · `20260526_03`→`20260522_01` · `20260530_01`→`20260528_01` ·
`20260608_01`→`20260605_01`.

```bash
grep -c '20260526_03' docs/WORKPLAN.md                          # expect >0
```

### A8 · WORKPLAN cleanup + PROTOCOL §5 — the sandbox key

**Prod `.env` `STRIPE_SECRET_KEY` is a sandbox key** — `acct_1SxS0jR2nJiUv7I5` against live
`acct_1SxS0ZJh5q1ETi1p`. They differ by `Jh5q1ETi1p` vs `R2nJiUv7I5` and one lowercase character,
and the failure mode is *"No such payment_intent"*, which reads as missing objects rather than
wrong account. The cleanup line says the 17 stale `STRIPE_PRICE_*` entries are inert because
Secrets Manager wins — **confirm that for this key specifically**, don't inherit it from a claim
about siblings. `GET /v1/account` names the account in one call; that discriminator belongs in
PROTOCOL §5.

### A9 · CODEMAP is not a separate document — ⚠ PARTIALLY CLOSED, do not mark done

The doc map lists `CODEMAP` as its own file. PROTOCOL §1 is right: it is
`SENRA-MOBILE-REDESIGN.md` §10 plus the change log.

**A9 has TWO homes. One is closed, one is not.**

- ✅ **`HANDOVER.md` — CLOSED** by `c0c47dd`'s rewrite. One `CODEMAP` hit, at `:21`, inside the
  pointer row that resolves to `docs/SENRA-MOBILE-REDESIGN.md`. Correct by construction.
- ❌ **`SESSION-HANDOVER-2026-08-01.md` — STILL OPEN.** Its §6 document map lists
  `` | `PROTOCOL.md`, `CODEMAP`, `SENRA-MOBILE-REDESIGN.md`, `HANDOVER.md` | `` — naming CODEMAP as a
  peer of the very plan that contains it. **Re-ground the line by `grep -n 'CODEMAP'` at edit time
  and cite what it returns.** *(This row said `:136`; `grep -n` against `origin/main` returns `:137`,
  control `grep -c 'SENRA-MOBILE-REDESIGN'` = 1 on the same line. The number is not written back here
  on purpose — four count errors across three rounds all came from carrying a number instead of
  re-deriving it, and this row would be the fifth.)*
- ❌ **Same file, second defect — trap 13 carries a superseded high-water mark.** It reads
  *"anything carrying a migration below `20260801_04` must be renumbered"*; the mark is
  `20260802_01`. **Control: `grep -c '20260802_01'` in that file = 0** — it does not hold both marks
  with one stale, it knows only the superseded one, so no reading of that line is currently true.
  `migrations/README.md` predicts this file by name (*"an earlier note may still say
  `20260801_04`"*). Its owner is now that README; it must not survive the dissolution.

**Why the distinction is load-bearing and not pedantry:** §D dissolves
`SESSION-HANDOVER-2026-08-01.md` **into** `HANDOVER.md`. If A9 reads as closed, the merge carries that
wrong line into the surviving document — and it lands in the file that was just cleaned of it, at the
seam, when nobody is looking for it. **The row survives into Phase 2 for that file.**

⚠ **This check is REF-SENSITIVE and reads the wrong answer from the wrong branch.** The working tree
usually sits on `feat/mobile-redesign-phase1`, where `HANDOVER.md` is still the pre-rewrite
`1beb74e70647` and `grep -c CODEMAP` returns **3**, not 1. That is not a failure — it is the check
being run against a tree the work never landed on. Name the ref:

```bash
H=origin/docs/phase1-closeout-2026-08-02          # or main, once #47 → #45 → main has merged
git show "${H}:docs/HANDOVER.md" | grep -c CODEMAP     # expect 1 — and it must resolve to the plan
git show "${H}:docs/HANDOVER.md" | grep -n CODEMAP     # CONTROL: read the hit, never trust the count
git show "${H}:docs/SESSION-HANDOVER-2026-08-01.md" | grep -c CODEMAP   # 1 today, 0 after Phase 2
```

**Dissolution check, broadened 2026-08-03 — both terms must read 0 on the output:**

```bash
grep -c 'CODEMAP' docs/HANDOVER.md      # expect 1 — the Owners pointer row, correct by construction
grep -n 'CODEMAP' docs/HANDOVER.md      # read the hit: must RESOLVE TO the plan, never list it as a peer
grep -c '20260801_04' docs/HANDOVER.md  # expect 0 — trap 13's mark must not survive
grep -c '20260802_01' docs/HANDOVER.md  # CONTROL: >0, the mark that IS current
```

⚠ **The two terms are DIFFERENT KINDS OF CHECK and must not be folded into one `grep`.**
`20260801_04` is a zero-check. `CODEMAP` is a **read-the-hit** check that legitimately expects **1** —
`HANDOVER.md:21`'s Owners row *resolves to* `docs/SENRA-MOBILE-REDESIGN.md`, which is A9's own ✅
condition. *(Recorded because it was briefly written as `grep -n 'CODEMAP\|20260801_04' … # both 0`:
that reads FAIL on correct output, and the repair a session would reach for is deleting a correct
pointer row. A combined grep inherits the strictest expectation of its terms — which is why terms
with different expected values do not share one.)*

### ~~A10 · HANDOVER — two closed findings still listed as open~~ — **CLOSED 2026-08-03**

`grep -c 'all three unresolved' docs/HANDOVER.md` returns **0** on `main` and on #49. Cited targets
re-ground: `PHASE2-READ-PLAN.md:95` carries the iOS `RootRoute` HYPOTHESIS label, `:61` carries the
F-G6 rename. *(Control note: `grep -c 'unresolved'` is also 0 — two zeros, but not a broken pattern.
`c0c47dd` rewrote the file and the word is gone; `grep -c 'three'` = 1 is the control that
discriminates.)* By this ledger's own rule — a row is done when its check returns the expected
value — the row was already closed and was still reading as owed.

### A11 · PLAN §10 — stale self-pointer

*"read by `scripts/senra-status.sh` §5"* — the reader is **§6**; §5 is Android seam invariants.

```bash
grep -c 'senra-status.sh` §5' docs/SENRA-MOBILE-REDESIGN.md     # expect 0
```

### A12 · PHASE2-READ-PLAN — record the ratification

**RULED 2026-08-02: the B/C/D re-scope at `:108` is ratified.** The heading still says
*"pending review — not executed."*

```bash
grep -c 'pending review — not executed' docs/PHASE2-READ-PLAN.md  # expect 0
```

## §C — board

C1–C4 (§6 `else fail`, §6 one-match pin, §7 comment, F-G6 incl. the `app/src` widening) landed in
PR #46 at `6632108`, post-image `7dd21f156710`, cleared. C5 moved to Phase 1.

### C6 · New check — every declared contract has a consumer

`check_contract` fails on an *undeclared key*. There is no inverse — so
`web.legacyPageTestImports.allowedTwins` is declared in plan §10 with **zero** consumers and §6
reads all-green while doing it. The board cannot report this gap about itself.

```bash
grep -c 'legacyPageTestImports' scripts/senra-status.sh         # expect >0
```

### C7 · New check — §8 is blind to MODIFIED tracked files

§8's landmine scan filters `git status --porcelain` on `^??`. A **modified tracked file** (` M`) is
therefore invisible to the board entirely — and it is the more dangerous state of the two, because
`git commit -a` sweeps it without any `git add` at all.

This is not hypothetical. On 2026-08-02 the rewritten `HANDOVER.md` sat as ` M` in the
`feat/mobile-redesign-phase1` working tree. §8 read its usual 3 untracked files and said nothing. A
`git commit -a` there would have put `a8e82562b99a` on the redesign line — converting §M's
"HANDOVER.md IDENTICAL → docs version resolves it" into a genuine three-way and silently invalidating
the four-file table. It was caught by reading, not by the board.

**The mitigation already exists as discipline** — the handover's *"stage pathspec-limited; `git add -A`
and `git commit -a` sweep tracked-modified files the landmines check does not catch"*. That sentence
names the gap and then asks a human to cover it. **Close it in the check instead**, at **warn** level
rather than fail: a dirty tracked file is normal mid-chunk, so a red would cry wolf and train people
to skim §8 — the failure mode §6's v1 drift detector already demonstrated.

```bash
# in §8, alongside the existing '^??' count
MOD=$(git -C "$repo" status --porcelain | grep -c '^ M')
[ "$MOD" -gt 0 ] && warn "$name: $MOD modified tracked file(s) — 'git commit -a' would sweep these; stage pathspec-limited"
```

```bash
grep -cF '^ M' scripts/senra-status.sh     # expect >0 once landed
grep -cF '^??' scripts/senra-status.sh     # CONTROL: the existing §8 filter, expect >0 (it is at :364)
```

⚠ **Use `-F`.** Written first as `grep -c '\^??'`, which is a *regex*: `?` is a quantifier, so the
pattern means something other than the literal `^??` and the count is not the one you think you asked
for. Fixed-string is the only form that reliably counts a literal containing regex metacharacters —
and `^??`, `^ M`, `$VAR` and `*.js` all qualify.

This is the same direction as every other change this session: a rule that lived in prose becomes a
line that runs at session start.

## §D — renames and deletions

| Action | File | Why |
|---|---|---|
| **Merge → delete** | `SESSION-HANDOVER-2026-08-01.md` → `HANDOVER.md` | Two handovers is one too many; the day-stamped name is the drift engine |
| **Merge → delete** | `SESSION-START.md` → `HANDOVER.md` (its §5–§7) | The file carries its own deletion instruction; this row is what makes that a **scheduled action rather than a hope**. **Remove its `senra-status.sh` §9 entry in the same edit** — same reasoning as §0 step 5, and it applies only if the file survived to the seam and reached the manifest at all |
| **Rename** | `SENRA-WORKPLAN-2026-08-01.md` → `WORKPLAN.md` | Same |
| **Add to §9** | `WORKPLAN.md`, `HANDOVER.md` | Completes P1-5's manifest |
| **Delete** | `senra-status.md` | Stale at `203748cf8b57`; the board is now `7dd21f156710`. A rendering of a moving file is a second copy |
| **Delete** | `SESSION-HANDOVER-2026-07-31.md` | Superseded |
| **Merge or delete** | branch `docs/pricing-cutover-record` @ `14a4b7a` | A branch with no PR and no owner is a doc that exists nowhere |
| **Track now, delete later** | `pricing-C9-cutover-runbook.md` | Untracked **and** `.git/info/exclude`'d is worse than deleted — the landmine check can't see it either. Delete after C5/C6/C0 |
| **One pass** | monorepo `docs/` (74 files) | Delete, or one README saying "archive, nothing here is current" |

**Keep** `PHASE2-READ-PLAN.md` — it deletes into `phase-2-spec.md` when the read closes.

⚠ **`SESSION-START.md` is undated on purpose, and that is precisely why it needs a row rather than a
check.** The dated-filename check below is what catches a handover outliving its session; an undated
name walks straight past it, so the only thing that will ever catch this file is the `test !` line.
It is **rewritten in place and never forked per session** — a `SESSION-START-2026-08-11.md` is the
drift engine returning under a name the check cannot see. It is tracked but **not governing** until
the seam, the same window this ledger sits in: `git commit`-ing it did not add it to §9, because a
§9 edit moves `senra-status.sh` on `main` and voids `9e9c2fbf2b4c` (see §M's shelf life). Both
entries land in **one** board edit at the seam, alongside C6/C7 — and this row takes them both back
out again.

```bash
ls docs/ | grep -c '2026-0[78]-'                                # expect 0 — no dated filenames
test -f docs/WORKPLAN.md && test -f docs/HANDOVER.md && echo OK
test ! -f docs/senra-status.md && echo "senra-status.md gone"
test ! -f docs/SESSION-START.md && echo "SESSION-START.md folded and gone"
grep -c 'SESSION-START' scripts/senra-status.sh                 # expect 0 — no manifest entry outliving the file
grep -c 'docs/HANDOVER.md' scripts/senra-status.sh              # CONTROL: expect >0 — §9 is still a manifest
```

## §M — the cross-branch merge. Five files, and the resolver picks bytes no review covered.

`senra-status.sh` and four docs conflict between `fix/board-guards-2026-08-02` (#46) and
`docs/phase1-closeout-2026-08-02` (#47). **They do not auto-merge** — an earlier "the hunks are far
apart" reading compared the two tips to each other rather than to the merge base `b0b076b`, where
the file is 267 lines. Both lines independently advanced it to `203748cf8b57` before their own
edits, so git sees a change on both sides. Test merge: `rc=1`, 5 conflicted files.

This is the C4 branch-merge hazard family on a fifth file.

**Four of the five have exactly one correct resolution.**

⚠ **The empty-diff test does NOT work here.** *Written by the review seat; corrected 2026-08-02 by
CC's replacement below, on measurement.* Attribution recorded because a correction with the wrong
author reads as a build-seat error being fixed by review, which inverts what happened.
`git diff b0b076b..<redesign> -- <file>` is **non-empty for all four**
(13 009 / 12 996 / 110 021 / 21 524 B), because `b0b076b` predates the point where *both* lines
independently advanced these files to identical content. Measured from that base everything reads as
changed on both sides — which is the same reason the merge conflicts at all. A test that returns
"genuine resolution needed" for every file cannot tell you which need one.

**Use this instead: does the redesign tip's copy equal what the docs line STARTED from?** If yes, the
redesign line never edited that file and the docs-line version is the whole answer.

```bash
RED=origin/fix/board-guards-2026-08-02; START=2bcc2ac   # the docs line's base
for f in docs/HANDOVER.md docs/PROTOCOL.md docs/SENRA-MOBILE-REDESIGN.md \
         docs/WEB-HANDOFF-CONTRACT.md scripts/senra-status.sh; do
  a=$(git show "${RED}:${f}"   | shasum -a 256 | cut -c1-12)
  b=$(git show "${START}:${f}" | shasum -a 256 | cut -c1-12)
  [ "$a" = "$b" ] && echo "$f IDENTICAL -> docs version resolves it" || echo "$f DIFFERS -> genuine merge"
done
# CONTROL: 2bcc2ac must be an ancestor of the docs line
git merge-base --is-ancestor 2bcc2ac origin/docs/phase1-closeout-2026-08-02 && echo "base ok"
# CONTROL: a file neither side touched must read IDENTICAL — docs/phase-1-spec.md (6b4ac3f6c239)
```

Result 2026-08-02, tips frozen at `6632108` / `317cc10`: **all four IDENTICAL**
(`1beb74e70647` · `71e8d3ebc4e8` · `0f1213ae58e1` · `a6ce9dd2e930`), `senra-status.sh` **DIFFERS**
(`7dd21f156710` vs `203748cf8b57`). Both controls hit. So the table below is the complete answer for
the four, and `senra-status.sh` is the only genuine judgement call. Note the contract line: the
redesign tip holds the **pre-P1-1** `a6ce9dd2e930`, so resolving to `fdf0d570c218` is the only change.

The resolution must equal the value already cleared:

| File | Resolution must hash to |
|---|---|
| `WEB-HANDOFF-CONTRACT.md` | **`fdf0d570c218`** (323 L) — pinned, and the pin is the point: FROZEN |
| `HANDOVER.md` | `main`'s value at merge time — **re-derive, do not re-type** |
| `PROTOCOL.md` | `main`'s value at merge time — **re-derive, do not re-type** |
| `SENRA-MOBILE-REDESIGN.md` | `main`'s value at merge time — **re-derive, do not re-type** |

```bash
for f in docs/HANDOVER.md docs/PROTOCOL.md docs/SENRA-MOBILE-REDESIGN.md; do
  printf '%-34s %s\n' "$f" "$(git show "origin/main:${f}" | shasum -a 256 | cut -c1-12)"
done
```

⚠ **Three hashes came out of this table 2026-08-03 under the pin rule, and the reason is not
tidiness — it is that no value written here could still be true when step 7 reads it.** All three
were already stale (`a8e82562b99a` → `cc5e0da1f3dd`; `4379eb3afdbc` → `63603befd524`, corrected only
in a footnote below; `79402e281962` → `a44a3c4675b2`), and two move **again** inside the agreed
sequence: `HANDOVER.md` when #49 merges, `SENRA-MOBILE-REDESIGN.md` when §7-Q6 is amended. The
IDENTICAL test above already establishes *which side wins*; after that the expected value is
whatever `main` holds, which is one command. The contract keeps its pin because it is FROZEN and
P1-1's freeze gate has nothing to check without it.

Any other value means the resolution invented something. A `DIFFERS` result means a genuine
three-way, and that file becomes a real artifact needing real review.

⚠ **`PROTOCOL.md` moved twice while this table stood still** — `628b25e` took it `4379eb3afdbc` →
`63603befd524`, and the row above was patched by this footnote rather than by the table. **That is
the whole case for the pin rule**, and the row is now a derivation, so this note is kept as evidence
rather than as a correction: a hash in a table plus a footnote saying the hash is wrong is strictly
worse than no hash, because the footnote is what a hurried reader skips.

⚠ **`WEB-HANDOFF-CONTRACT.md` is a bright line.** No legitimate resolution produces anything other
than `fdf0d570c218`. Run P1-1's freeze gate on the resolved file too — a merge resolution is exactly
where a frozen document silently acquires an unreviewed §8.

**`senra-status.sh` is the only genuine judgement call.** The two edits are disjoint in intent —
§5b/§6/§7 from the redesign line, §9's manifest from the docs line — and it resolves to a **fourth**
value, neither `7dd21f156710` (531 L, #46) nor `e451a2820970` (445 L, #47).

⚠ **DO NOT "TAKE BOTH SIDES" LITERALLY — that is the wrong instrument here, and it silently
duplicates content.** This conflict comes from a *stale base*: `b0b076b` predates the point where
both lines independently advanced the file to `203748cf8b57`, so each conflict block contains the
whole shared region, not just that side's edit. Concatenating `<<<` and `>>>` blocks therefore emits
the shared region **twice** — and the result is a plausible-looking script that runs, which is the
worst kind of wrong.

**Use a three-way against the real common content:**

```bash
git show "2bcc2ac:scripts/senra-status.sh"                                > base.sh    # 203748cf8b57
git show "origin/fix/board-guards-2026-08-02:scripts/senra-status.sh"     > ours.sh    # 7dd21f156710
git show "origin/main:scripts/senra-status.sh"                            > theirs.sh  # a1aeca162505
git merge-file -p ours.sh base.sh theirs.sh > resolved.sh                 # rc 0 = clean
shasum -a 256 resolved.sh | cut -c1-12                                    # 9e9c2fbf2b4c
```

**Resolved: `9e9c2fbf2b4c` / 32 196 B / 546 L**, rebuilt 2026-08-02 against merged `main`, `git merge-file` rc **0**.
**`fd70647aeb4a` (31 639 B / 540 L) is VOID** — it was the union with `e451a2820970`, which PR #48 superseded on `main`. Do not re-type it; it is listed only so a stale citation is recognisable.
Arithmetic that must hold: 531 + (451 − 436) = 546.

Acceptance, and the bidirectional diff is the check that catches a marker left behind or a line
dropped between hunks:

- vs `7dd21f156710` → **only** the docs line's additions (2 hunks, +17 / −2)
- vs `a1aeca162505` → **only** §5b/§6/§7's F-G6, one-match pin and allowlist comment (3 hunks, +102 / −8)
- `grep -c '^<<<<<<<\|^=======\|^>>>>>>>'` = **0**, control: the same grep on the raw conflicted file = 6
- `bash -n` clean · runs **RED 7** (same seven) · §9 renders **7/7** · F-G6 fixture: `readSource` test
  GREEN, Compose-render test RED · header sequence `1,2,3,4,5,5b,6,7,8,9,10,11,12,13`

⚠ **SHELF LIFE — if `scripts/senra-status.sh` changes at EITHER end, `9e9c2fbf2b4c` is VOID and gets
REBUILT, not carried.** *(Corrected 2026-08-03: this rule still named `fd70647aeb4a`, which was
already void, so the sentence protected a dead value and left the live one unguarded — the exact
misreading the paragraph goes on to warn about.)* This is the single most losable fact in this section. A voided hash does not
look voided six weeks out; it looks like a stale hash someone forgot to update, and the temptation is
to "fix" the number rather than re-run the merge. **Re-derive; never re-type.**

⚠ **§M's OPERANDS ARE EXEMPT FROM THE PIN RULE, and §M owns the exemption because §M is what
breaks without it.** The resolution's inputs — `7dd21f156710` (#46, unmerged and still able to move)
and `a1aeca162505` (`main`) — and its output `9e9c2fbf2b4c` are **operands of a comparison, not
descriptions of state**. The shelf-life rule above works by checking them *against* current reality;
converted to derivations they would compare `main` to `main` and could never fire. **A tripwire pin
is supposed to go stale — going stale is the signal.** So: do not convert them to derivations, and
do not "refresh" them to match current state either. Refreshing one is the same act as deleting the
check, and it looks like tidying.

*(`e451a2820970` is NOT among them. #47 is merged, so those bytes cannot move — it is SUPERSEDED,
and it is an input to the **void** `fd70647aeb4a`, not a live end of anything.)*

**The unit is FILE CONTENT, not tip SHAs** — corrected 2026-08-02 after an earlier draft of this rule
said "if either tip moves". That was too strict and would force pointless rebuilds: the resolution is
the union of `7dd21f156710` (PR #46) and **`a1aeca162505` — `main`'s copy, and `main` is the end that
can still move**, so a commit touching the workplan, this ledger,
`HANDOVER.md`, or anything else leaves it **valid**. *(Corrected 2026-08-03: this sentence still
named `e451a2820970`, the merged docs line. Read literally it pointed both ends at branches that can
no longer move — #47 is merged — so a reader would conclude the resolution is permanently valid.
**Any edit to `senra-status.sh` on `main` voids it**, which is why §9 gains this file at the seam and
not in step 1, and why ruling Q6 toward `root` would void it too.)* Two commits have already proved it in both
directions — `628b25e` (PROTOCOL §5) and `c0c47dd` (HANDOVER rewrite) each moved a tip and left
`senra-status.sh` unchanged, so the resolution survived both. **`e451a2820970` itself was then superseded by PR #48 on `main` (`a1aeca162505`), which is what voided `fd70647aeb4a` and forced the rebuild to `9e9c2fbf2b4c`.** This matters right now: writing
the B2 read plan into `WORKPLAN.md` is another such commit, and under the stricter rule it would have
read as a void.

**Not conflicted but it does move:** `SESSION-HANDOVER-2026-08-01.md` (`7b7bb5538501`, 243 L) exists
only on the docs line, so it merges as an add. "Four hashes" is not "all that moved."

⚠ **ORDER §D's RENAME BEFORE THE MERGE, and this file is why.** §D dissolves
`SESSION-HANDOVER-2026-08-01.md` into `HANDOVER.md`. Merge first and it is carried through a
resolution only to be deleted minutes later — a throwaway resolution, and worse, a *sixth* set of
bytes someone has to review to reach a file that will not exist. **Rename first and it is not
present to merge at all.** Both land at the same seam, so the ordering is free; it is only free if
someone decides it in advance. Same argument applies to `senra-status.md`, which §D deletes — do not
resolve anything into a file scheduled for deletion in the same pass.

**Sequence, and step 4 is what makes this a review rather than a rehearsal:**

1. Freeze both PR tips. A new commit on either voids the resolutions.
2. CC prepares all five, bytes and hashes in one message.
3. Review seat clears them.
4. Merge, resolve, then verify the **actual merge output equals the reviewed resolution byte for
   byte**. Otherwise the resolved file is a nice artifact and the merge still invents its own.
5. Run the board. Expect RED, same 7, §9 rendering 7/7 tracked.

## §F — one command

Fold Phase 2's checks into `scripts/docs-closeout.sh`, run it, require all-green, then **delete the
script with this ledger**. The permanent half — P1-5's manifest and C6's contract-consumer check —
lives in `senra-status.sh` and stays. That is the part that means this audit never repeats: a
governing doc going missing, untracked, or off-branch becomes a red on a script already run at
session start, not a discovery on turn four of a chat.

---

## §E — decisions. No grep can close these.

They close by being recorded in `SENRA-MOBILE-REDESIGN.md` §2 Locked decisions.

| # | Owed | Blocks |
|---|---|---|
| E1 | **§E C5/C6's must-not-touch wall** — chunk boundary or standing? | The Android Phase-2 shape. **Deadline is C1, not B2** — must land before `phase-2-spec.md` relies on it. Does not have to ride this closeout |
| E2 | **HU register** — "informal is deliberate," or overrule | Nothing. But a native-speaker reflex reopens it forever otherwise |
| E3 | **Migration `002`** — ever real? Absent from the applied set *and* from `main` | On a set-membership runner, a file numbered `002` appearing later **will run** against a schema 164 migrations downstream |
| E4 | **CC and production actions** — §9 ruling: does a rolled-back transaction against prod count as a production action needing a recorded go? `ROLLBACK` bounds persistence, not lock acquisition; `ALTER TABLE` takes ACCESS EXCLUSIVE either way. The 2026-08-02 dry run had no go; the v4 apply and the Stripe reads did | It will recur. **No longer blocking a dangling pointer** — `317cc10` rewrote E5's entry to state the question and carry an interim rule that holds if E4 is never written |
| E5 | **CODEMAP entry for `20260802_01`** — the migration, the manual apply, the hand-written version row | Record before it is forgotten |
| E6 | **pet-safety-eu#113** — merge as defence-in-depth, or close | Evidence favours closing |
| E7 | **#66** — renumber `20260607_01` above `20260802_01` | Note the mark moved: it is now `20260802_01`, not `20260801_04` |

---

## §G — WITHDRAWN. Do not "fix" these back.

Two of these are corrections the review seat asked for and then had to retract. Without this
section someone re-derives them.

- **AASA `components` vs `paths`** — hypothesis **refuted**. Served file: `details|length=1`, keys
  `["appID","paths"]`, `has_components=false`. The board's three greens are on entries iOS reads.
  `/*/t/*` is genuinely missing; that red is real.
- **`szamla_invoices` per-row PDF size** — WORKPLAN's **382–390 KB is correct** (decimal KB; raw
  382,307–390,530 B). The "373–381" correction was `pg_size_pretty` KiB. **No edit.**
- **`~2.7 MB at seven rows`** — **correct** (2,707,749 B). "2.58 MB" was the same unit error.
  **No edit.** On-disk 1,376 kB stands separately: TOAST compresses ~2:1, control
  8,192 + 1,368,064 + 32,768 = 1,409,024 exactly.
- **`phase-2-spec.md` in §9's manifest** — review-seat error. Cannot be tracked before it exists.
- **F-G6 keeping `app/src/main` scope** — CC's justification generalised one symbol's test
  exposure across two that did not share it. Widened at `6632108`; the dialog correctly stays out
  of the zero-callers check and on the `private` pin. Do not narrow it back.

---

## §L — Lessons that are checks, not memories

Four things this session produced that outlive it. Each is here because the discipline version already
existed and did not hold.

### L1 · A migration is not done when it is APPLIED. It is done when the SOURCE IS IN THE REPO.

`20260802_01` was applied to prod, recorded in `schema_migrations`, byte-reviewed, behaviour-reviewed,
written into a CODEMAP entry **and** a handover — and existed on one laptop for six hours, in no
repository. Every one of those gates passed while the file was untracked, because **not one of them
asked.** Clearance covers what it covers.

Committed retroactively as `7f11d5a` (PR pet-safety-eu#119), bytes verbatim, checksum intact and
verified from a fresh clone. **The definition of done for a migration is: applied ∧ version row ∧
source committed.** Anything less is a schema change with no source.

### L2 · The board is BRANCH-SCOPED. Expected reds differ by branch. — **owed action CLOSED 2026-08-03**

From `main` the board reads **RED 10**, not 7: the six standing reds plus **four `SUBJECT FILE
MISSING` on iOS §5b**, because `LandingView.swift` and the rest of the Phase-1 chunks live on
`feat/mobile-redesign-phase1` and are unmerged. **Not a regression, and not a check to fix.** §5b
failing on an absent subject is `lguard` working exactly as designed — making it pass on `main`
would reintroduce the silent evaporation the `else fail` was added to prevent. *(This said
`lguard :192`; on the board `main` serves the definition is `:187` and the missing-subject `fail` is
`:198`. Re-ground by symbol — `grep -n 'lguard'` — rather than carrying either number.)*

✅ **The owed action — "fix the message, not the check" — LANDED IN #48.** `main`'s board now emits:

> `SUBJECT FILE MISSING ($1); EXPECTED on main and the docs line (Phase-1 chunks unmerged); a REAL`
> `failure on feat/mobile-redesign-phase1. Absence is a defect in §5b, never a skip`

The lesson stays recorded — a fresh session landing on `main` still needs to know why it sees 10 —
but **nothing is owed here.** It was reading as a live trap after the trap had been closed.

### L3 · §8 misses MODIFIED tracked files — it counts only `??`

Covered as a check in **C7**. Recorded here too because the mitigation currently lives as a discipline
(*stage pathspec-limited*), and a discipline is what failed.

### L4 · A9 is PARTIALLY closed — see the A9 row

`HANDOVER.md` clean; `SESSION-HANDOVER-2026-08-01.md` still lists `CODEMAP` as a peer file, and
**separately** still carries the superseded `20260801_04` high-water mark. §D dissolves that file
**into** `HANDOVER.md`, so a closed-looking A9 carries both wrong lines into the surviving document.
Line numbers deliberately not carried here — see the A9 row.

---

## §Deferred — real, and not owed by this closeout

Findings that are correct and that nothing in the current sequence depends on. **This section exists
because "deferred" with no written location is how owed work ends up living in a chat transcript** —
the `Items 5, 7, 9, 12` failure, where four numbered items survived only in a conversation and could
not be resolved from any governing file. Each entry says what it is, why it is not urgent, and what
would make it urgent.

### D1 · §M's byte-for-byte comparison is sound; verifying a REVISION by hunk count is not

§M step 4 — diff the actual merge output against the reviewed resolution, byte for byte — is right
and unchanged. The gap is elsewhere: when a reviewer verifies a **revision** of an artifact by
diffing both versions against a shared pre-image, hunk structure is not a stable instrument.
`diff` realigns interchangeable blank lines when total file length changes, so ranges shift and
blocks split or merge with no content change at all.

Measured on this file 2026-08-03. Two post-images differing **only** inside one code block gave 20
vs 21 change blocks against the shared pre-image, with ranges moving throughout; a direct
post-to-post diff showed exactly two blocks, 2 lines out and 12 in, and nothing else moved.

**The two instruments that hold are the hash and the post-to-post diff.** A hunk count against a
common ancestor is not one — and it is a harder case than the existing *"a count only verifies if
the counting method travels with it"* row, because here the **same** method on the **same**
pre-image yields different structure depending on unrelated text elsewhere in the file. Sending the
method with the count would not have saved it.

**Not urgent:** §M already prescribes the correct comparison. **Urgent if** anyone writes a review
step that verifies a revised artifact by comparing two diffs against a common ancestor.

### D2 · The build tree serves STALE copies of three governing docs

`feat/mobile-redesign-phase1`'s working tree carries these untracked, and they are **not** copies of
what `main` serves:

| File | Working tree | `origin/main` |
|---|---|---|
| `docs/SENRA-WORKPLAN-2026-08-01.md` | `9463140e6be9` · 20,359 B | `21162d0195e3` · 20,627 B |
| `docs/SESSION-HANDOVER-2026-08-01.md` | `89170a0b8c8b` · 12,615 B | `7b7bb5538501` · 13,374 B |
| `docs/DOCS-CLOSEOUT.md` — **this file** | `2651ceb0b814` · 44,239 B | `4a6daa85e99b` · 48,963 B |

⚠ **The third row is this ledger, and it was found the only way it could be — by running D2's own
check before an edit, 2026-08-04.** The build tree is 72 lines behind `main`: it has the pre-P1-5 §9
(five entries, no manifest comment), so a §D edit made there would have been written against a
version of the board that no longer exists, and a reader checking §9's contents from the build tree
gets the wrong answer with no signal that anything is wrong. **The file that prescribes this check
was itself failing it.** That is not irony, it is the expected case: nothing exempts a doc from
staleness because the doc is about staleness.

All three are pre-merge drafts, all three smaller than the tracked versions. **§8 sees them as untracked and
says nothing about them being *older than* what `main` holds** — which is the more dangerous half.
The landmine row warns that `git add -A` sweeps stray files; here it would commit **older content
over newer**.

**Not urgent in general:** §D renames one and dissolves the other at the seam, and `main` supersedes
both. **Urgent for two specific steps**, and known in advance: the sequence's **step 5** writes into
the workplan and **step 7's §D** dissolves the session handover. *(An earlier draft of this line said
"step 3". Step 3 is the runner PR, which is in `pet-safety-eu` and which D2 does not gate at all;
the dissolution is Phase 2 and lands at the seam, per §0. Recorded rather than silently fixed because
the wrong number was acted on before it was caught.)* Run from the build tree, each would edit a base
no review ever covered — and A9 and trap 13 are line-specific findings against `7b7bb5538501`, not
against `89170a0b8c8b`.

⚠ **So every remaining docs step verifies its pre-image against `origin/main` before editing** —
`21162d0195e3` for the workplan, `7b7bb5538501` for the session handover, `4a6daa85e99b` for this
ledger — and edits from a worktree cut from `main`, not from the build tree. *(This is the blockage that stopped the Q6 edit on
2026-08-03; it is now a known property of two more steps rather than a discovery.)*

---

## §H — CLOSED this session

Kept as the audit trail; delete with the rest.

- **Migration `20260802_01`** — v1 `f73fa84a7341` (email join, rejected) → v2 `a914a91dbf87` →
  v3 `b7c8a436ed15` (Stripe chain) → **v4 `87e88be96acb`**, executable fingerprint `7a50f3f135bc`
  (56 lines). Bytes cleared, then **behaviour** cleared: executed against PostgreSQL 16.2 on a
  reconstructed schema — vacuous pass on an empty DB, 7/7 on the full set, tripwire aborts on a
  mutated `buyer_email`, re-run guard fires on a tampered UUID, clean re-run is a no-op, FK
  violation rolls the whole thing back. Applied to prod 2026-08-02 16:04:09Z.
- **Docs PR #47 / `df266fb`** — diff `a5a73d34ddb1`, seven post-images reproduced from independently
  held pre-images. Contract `a6ce9dd2e930` → `fdf0d570c218`, +33/−3 in two places only; §8, §1, §2,
  §4, §6, §10 and all section headings byte-identical. `HANDOVER.md` correctly gained the contract
  as a pointer **without** its hash — PROTOCOL §1, pointers not facts. Second commit `317cc10`
  outstanding.
- **`gshow`** — landed in `~/.zshrc`, mitigation column on PROTOCOL §5's two existing rows rather
  than a fourth row. Its bad-ref control is the point: the failure was never "wrong hash", it was
  "empty file, plausible hash, no error". Three instances this session, the third written into the
  commit that promotes the rule — knowledge was not the gap.
- **Board PR #46** — `1856938` → `6632108`, post-image `7dd21f156710`, reproduced from the
  verified pre-image `203748cf8b57`. F-G6 widening re-tested on the fixture that exposed the gap.
