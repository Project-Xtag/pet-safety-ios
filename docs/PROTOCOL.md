# Senra — Two-Seat Protocol

**Home:** `pet-safety-ios/docs/PROTOCOL.md` — governs both repos. Tracked on the active redesign branch; merges to `main` with it.
**Both seats read this in full before doing anything.** It is short on purpose.

> This file is the **sole owner** of: how the seats work, the rules, and the known hazards.
> No other document restates them. If another document contradicts this one, this one wins,
> and the other document is the bug.

---

## 1. Where every fact lives (one owner each)

| Fact | Sole owner |
|---|---|
| The plan, the locked decisions, the gaps register, the CODEMAP | `docs/SENRA-MOBILE-REDESIGN.md` |
| The buildable chunk contract — files, edits, must-not-touch, named tests, done-when | `docs/phase-1-spec.md` (Phase 1) · `docs/phase-2-spec.md` (Phase 2 — created at scoping close, CC-authored; recorded 2026-07-21) |
| How the seats work; the rules; the hazards | **this file** |
| **The board** — what is done, what is red, what is owed | `scripts/senra-status.sh` — **derived, never written** |
| Which chunk is live right now | `docs/HANDOVER.md` — contains **no facts**, only pointers |

**The rule that makes this work:** if a fact appears in two places, one of them will be wrong within a week. It has been, every week. So each fact appears exactly once, and every other document *points* at it.

**If an item cannot be expressed as a check in `senra-status.sh`, it is either:**
- **a DECISION** → it belongs in the plan's Locked decisions or gaps register, or
- **NOT READY** → we do not yet know what would resolve it. Say so, in those words.

Nothing else goes on a board. There are no other boards.

---

## 2. The seats

- **Viktor** — owns the product, the decisions, and **all git**, exclusively.
- **CC (build seat)** — investigates, writes code, **surfaces the diff**, **stops**. Read-only git only: `status`, `log`, `show`, `diff`, `branch --list`, `reflog`, `merge-base`, `merge-tree`. **No commit, push, branch, merge, rebase, stash, reset.** Exceptions are per-command, explicit from Viktor, and recorded. **Credentials:** CC does not authenticate as Viktor by default; performing auth steps (entering an OTP, logging in on a device) requires the same per-command, explicit, recorded go as the git exceptions, and CC records that the session was cleared afterward. *(First exercised 2026-07-20, D.7a device run; codified after the fact.)*
- **Claude in chat (review seat)** — byte-reviews every diff before anything is committed. Drafts CC's instructions. Does not write production code. May draft documentation.

### The loop

1. CC builds **one chunk**.
2. CC surfaces the **exact diff** + its hash (Rule 7).
3. **Stop.**
4. Review seat hashes the artifact it received and **compares**. Mismatch → stop.
5. Review → Viktor commits → **Viktor logs the commit in the CODEMAP** → next chunk.

Step 5's logging is not optional. The board's §7 fails when the log is behind the code — §7 owns which commits it keys on; read the board, don't restate it here. *(This sentence used to say "the branch tip"; `16de442` changed the script to key on chunk commits and the restatement drifted — §1's prediction, inside the file that makes the rule.)*

---

## 3. The rules

Retractions in this project cluster in one place: **wiring claims** — what calls what, what fires when, what cannot coexist. Type-level claims, arithmetic, and single-file reads have been reliable. Wiring has not, because it is a *call graph*: it cannot be read off one file, so it gets reconstructed from **names** — and names lie.

Verified, in this codebase: `onBackToLogin` routes to *landing*. `drawsValidLocalizedLogo` never touched the view it named. `handleDeepLink` is **two different functions in two different types doing unrelated things**.

### Rule 1 — Two-ended citation for wiring claims

Any claim of the form *"X calls Y"*, *"Z fires when W"*, *"these can't both happen"*, *"this is unreachable"*, *"already handled"*, *"correct by construction"* **must cite both ends** — the call site **and** the definition — each as `file:line` plus the verbatim line.

No two-ended citation → it is a **HYPOTHESIS**, and you label it that way. A hypothesis is a fine thing to surface. **A hypothesis dressed as a finding is the failure.**

**Corollary — enumerate the callee, not the retired name.** *"Zero references to `screenKey`"* is a claim about a **name**. It says nothing about who else calls `AuthScreen(`. When the claim is *"this is the only thing that routes here,"* grep the **callee's call sites**.

### Rule 2 — Read plan before investigation

Before investigating anything, output the plan, then **stop**:

```
READ PLAN
  1. <file>:<range>  — <why this range decides the question>
  2. <file>:<range>  — <why>
  Anything I conclude outside these ranges is a guess, and I will say so.
```

The expense has never been reading — it has been reading the *wrong* thing, concluding, surfacing, and redoing.

**A read plan is a deliverable.** *"I have not read this yet; here is exactly what I need to read and why"* is a **complete, correct answer.** The premature finding is the failure. The pause is the work.

### Rule 3 — A comment is not evidence

A code comment is an unverified claim by a past author. A **hypothesis**, never a premise.

*Precedent:* `SplashScreenView` carried `// The storyboard launch screen already covered the ~5s init time`. An entire design argument rested on it. **Measured: ~1.2s.**

This applies to **this documentation** and to **build-seat reports**. A doc entry with no `file:line` is a comment. So is *"presenting the scanner fires a permission prompt"* until someone opens the file.

### Rule 4 — Never adjudicate a literal from rendered text

String literals get mangled in transit. A bare hostname in a Kotlin `setOf` rendered as a markdown link in chat, and a confident four-file bug report was written about corruption that did not exist.

Where exact bytes matter, use output that **cannot be rendered**: `grep -c`, `shasum`, `wc -l`, `xxd | head`. A count cannot be linkified.

*Broken by the **review** seat, not the build seat. It applies to everyone.*

**⚠️ `e3b0c44298fc` IS THE EMPTY FILE.** That is the sha256 of zero bytes. If a hash starts `e3b0c442…`, the artifact is **empty** — the command produced nothing and the shell wrote an empty file anyway. It never means "no change". *Precedent 2026-08-01: `git show a085bf5:…CountryRoutes.tsx > out.tsx` in a checkout that had never fetched that ref produced a 0-byte file; the hash was computed, reported, and only caught because `e3b0c442` was recognised. Learn the prefix.* Corollary: hash the artifact **and** print `wc -c` beside it — a byte count of 0 cannot be misread.

**⚠️ ENUMERATE THE CHUNKS — NEVER ASSUME WHICH ONE A SURFACE LIVES IN.** On a code-split build, greping the wrong artifact returns a confident zero. The rule is not "check the chunk instead of the index" — it is **list what was actually served, then pick by evidence.**

*Precedents, all 2026-07/08 on tagme-now:* routed pages are `lazy()`-imported, so `index-*.js` carries **none** of their component code — a sweep of it returned 0 for every key and read as "already fixed". Then, having learned that, the home page was assumed to be inline because it is the index **route** — it has its own `Redesign7-*.js` chunk, and an `index-*.js` grep would have been a second false pass for the same reason. **Route position tells you nothing about chunk position.**

Method: fetch the served HTML → read the real `index-*.js` name from it → grep *that* for `<Name>-[A-Za-z0-9_-]+\.js` → fetch each chunk → grep the chunk, **with a control that must hit**. And remember comments strip at build, so a key appearing only in a `/* … */` rationale greps 1 in source and 0 in the chunk.

**⚠️ ON A VERSIONED API, `null`/`None` ON A LEGACY FIELD IS NOT A VALUE — IT IS AN ABSENCE.** Same shape as the two rules above: a definitive-looking negative that is really "this field no longer exists". Before acting on a falsy field, establish that the field is still *populated* by the API version you are talking to, and find what replaced it.

*Precedent 2026-08-01, and it was one step from a wrong call on a live payment question:* a Stripe invoice returned **`paid: None`** while `status: "paid"`, `amount_paid: 59900`, `amount_remaining: 0`. The legacy `paid` boolean is gone from the current API version. Read alone and in a hurry, `paid: None` says "she never paid" — the opposite of the truth, and it would have justified closing a real dead letter as expected-behaviour. The same response had **`payment_intent: None`**, which had merely moved under the `payments` sub-object. The authoritative pair was `status` + `amount_remaining`, not the field with the obvious name.

The general rule: **the obviously-named field is the one most likely to have been superseded.** Prefer the field the API version actually documents, and cross-check any negative against a second field that must agree.

**⚠️ A NEGATIVE GREP NEEDS A POSITIVE CONTROL, IN THE SAME COMMAND.** A zero is a claim about the **pattern**, never about the tree. Run a second grep you *know* must hit; if the control also returns zero, the pattern is broken, not the code.

The failure mode is usually **case**, and it is invisible: `grep -l "rateLimiter" middleware/` returns **0** on a directory whose file defines `createRateLimiter` and `authRateLimiter` — capital `R`, so the lowercase substring never appears. Reported as "no rate limiters exist"; there are 21. *Same session, three more: `grep "web-handoff"` (real zero, proven only once `handoff` alone returned 2 files), a JSONB predicate using `line1`/`postal_code` against a column whose keys are `street1`/`postCode` (0 matches across 80 rows, including a user with 26 shipped orders), and `grep -c` counting **lines** rather than occurrences in a minified bundle.*

### Rule 5 — A build is not a run, and a run is not a look

`BUILD SUCCEEDED` proved nothing about the splash→content crossfade, which **a `Group` wrapper silently broke.** It compiled. It passed tests. Only a physical device caught it.

Anything **visual, animated, timing-dependent, or structural in a `WindowGroup`** needs a device. Say which of the three you did — built, ran, or looked — and never let one stand in for another.

### Rule 6 — Force the test run; read the report; grep for the criterion

`BUILD SUCCESSFUL` with `41 up-to-date, 1 executed` means Gradle **replayed a cache and ran nothing.** Always `--rerun-tasks`. Always read `app/build/reports/tests/.../index.html`, never the console.

**And grep the artifact for every named acceptance criterion, by name.** C2's first artifact was **795 green with `backFromAuthReturnsToLanding` absent**, while the report asserted every decision honored. `grep -c` found it in seconds. **A verbatim criterion is worth exactly one grep. Run it every chunk.**

**⚠️ THIS HALF IS THE REVIEW SEAT'S, NOT THE BOARD'S. RULED 2026-08-02 — see the plan's §2 Locked decisions.** Board §12 forces the re-run (`--rerun-tasks`) and nothing more: it keys on gradle's **exit code**, does not read the HTML report, and greps **no criterion and no test name** — including `backFromAuthReturnsToLanding`, the very miss this rule was written about. That is **correct** and §12 stays as-is: the criterion list lives in the chunk spec, which is prose, so the check is not derivable and is therefore a DECISION (§1), not a board row. **Consequence to hold: nothing mechanical will ever catch a named criterion going missing. Only the review seat running the grep will.**

### Rule 7 — The green light is a hash

CC surfaces the artifact **and its hash**. The review seat hashes what it received. **Match → the thing reviewed is the thing being committed.** Mismatch → stop.

```bash
git diff | shasum -a 256 | cut -c1-12
```

**⚠️ That command omits new files.** Untracked files are invisible to `git diff`, so any chunk that adds files — every chunk so far — is **under-hashed**.

**For a chunk that is only new files, hash the file. Plainly.**

```bash
shasum -a 256 <file> | cut -c1-12    # and print wc -c beside it
```

*Promoted from HANDOVER 2026-08-02, and it OVERRULES the `git diff` -against-`/dev/null` wrapper this rule used to prescribe: the wrapper adds nothing over hashing the bytes and is fragile to reproduce, so the two seats computed different values from the same file. PROTOCOL §1 makes HANDOVER the bug when they disagree — here HANDOVER was right, so the refinement is promoted rather than deleted. **The wrapper is retired; do not reintroduce it.** For a MIXED chunk (edits **and** new files) hash the `git diff` and each new file separately, and send every value.*

**⚠️ THE SHUTTLE IS RULE 7's LIVE FAILURE MODE, AND IT IS NEITHER SEAT'S CODE.** **The artifact and its hash must arrive in the SAME message, or the comparison never happens.** The review seat can only hash what actually reaches it; a hash quoted about bytes that stayed on CC's disk is not a verification, it is a claim. Four rounds once ran half-satisfied — hash without artifact, artifact without hash, a hash CC declined to compute, then bytes that never got attached.

*Fired twice more on 2026-08-02, after that was written down: PR #46 was surfaced as `6ed67ce0a2ea / ffdf96b55d60` with no diff attached — the reviewer's words were "I can't hash what didn't reach me" — and a manifest listed a hash that had already been superseded. **A tool-call transcript is not delivery either**: if the bytes did not travel in the message the reviewer reads, they did not travel.*

**Re-hash after any stash, pop, rebase, or checkout between review and commit.**

This exists because *"I reviewed X and Y got committed"* already happened: C0-iOS round 2 shipped four unreviewed changes, two of which broke contracts the spec named must-preserve. Social approval did not catch it. **A hash would have.** It has worked every round since.

### Rule 8 — Check whether the evidence is even in the blast radius

**Four times in one session, a frightening artifact pointed at code that was correct.** Every time the tell was identical: **the evidence named a subsystem nobody had touched.**

| Looked like | Was |
|---|---|
| A corrupted Kotlin literal | The **chat channel** linkifying a hostname |
| `Fatal signal 6 (SIGABRT)` | The **system Bluetooth process**. Not Senra. |
| `INSTALL_BASELINE_PROFILE_FAILED` | A **release-variant profile installer**. The APK had already built. |
| "The app shows the old login screen" | A **stale APK**. The seam was correct all along. |

**Before debugging a line, ask whether the error is inside the change.** An error naming an untouched subsystem is a claim about the **environment**, not the code.

**The counterweight, so this is not read as *distrust everything*:** the same discipline caught the one thing that *was* real — a missing acceptance test hiding behind 795 green. **Hash the artifact. Distrust the environment.**

---

## 4. The board is a script, not a document

`scripts/senra-status.sh` derives every ✅/❌ live from the repos, the server, and the code. **Nothing on it is a claim you have to trust — it is a claim you can re-derive in twenty seconds.**

Run it at the **start of every session** and **before every commit**.

---

## 5. Known hazards (each has already cost a re-do)

| Hazard | Mitigation |
|---|---|
| **The review channel rewrites source.** `"www.senra.pet"` in a Kotlin `setOf` rendered as a markdown link → a confident, wrong, four-file bug report. | Rule 4. Counts and hashes, never pasted literals. |
| **Gradle cache replay.** `BUILD SUCCESSFUL`, `41 up-to-date`, zero tests run. | Rule 6. `--rerun-tasks`, read the HTML. |
| **Commit IDs get misreported.** The docs tip was given as `5fc9a64`, `1eeb192`, and `7cc026a` in three consecutive messages. | Verify against `git log`. Never a summary — **including this document's**. |
| **A clean build hides a broken `WindowGroup`.** `Group` vs `ZStack` killed the crossfade and compiled fine. | Rule 5. Device look. |
| **`git diff` omits new files** → the hash under-covers the chunk. | Rule 7: for new files, plain `shasum -a 256 <file>` with `wc -c`. The old wrapper is retired. |
| **🔴 A stale APK survives a "fresh" install.** `lastUpdateTime` proves the *install* is fresh, **not that the APK is.** Debug and release share `applicationId` (only `staging` has a suffix) but are signed with **different keys** — a stale install can survive and relaunch, looking exactly like a code bug. | **When the device contradicts the source: `adb uninstall` + `./gradlew clean` BEFORE debugging a line.** |
| **Wrong variant.** The suite runs `testDebugUnitTest`; Studio may be installing **release**, whose baseline-profile step fails for unrelated reasons. | Match the variant to the tests. |
| **zsh is not bash.** `#` is **not a comment** interactively, and `$VAR:P` is a **parameter modifier** — `$T:PetSafety/...` silently rewrites a hash into a path. | **One command per line. No inline comments.** Inline the value, don't interpolate before a `:`. |
| **Xcode 16 `project.pbxproj` noise** — reorders, empty-`exceptions` removals. | **Benign.** Synchronized folders don't enumerate sources; a deletion there can't drop one. Discard freely. |
| **Untracked files in the repo root** — loose `.diff`s, extracted doc copies, `build-derived/`. One `git add -A` and they land on a code branch. | `.gitignore` + the `landmines` check in `senra-status.sh`. |
| **A hash of `e3b0c44298fc`** — the artifact is EMPTY (sha256 of zero bytes), usually an unfetched ref or a failed command whose `>` still created the file. | Rule 4. Print `wc -c` beside every hash; learn the prefix. |
| **Assuming which bundle a surface is in** — routed pages are `lazy()`-chunked; even the index ROUTE has its own chunk. A grep of `index-*.js` returns a false zero. | Rule 4. Enumerate served chunks from the HTML, grep the chunk, always with a control. |
| **PR numbers collide across repos** — `#113` is the backend postapoint backfill (HELD) *and* the tagme-now copy batch (MERGED). Same number, opposite status. | Always write `pet-safety-eu#113` / `tagme-now#113`. A bare `#113` is ambiguous. |
| **A falsy legacy field on a versioned API** — Stripe `paid: None` alongside `status: "paid"`. Absence, not a value. | Rule 4. Cross-check against a field that must agree (`amount_remaining`); find what replaced it. |
| **A grep returning 0 with no control** — case (`rateLimiter` vs `createRateLimiter`), wrong field names (`line1` vs `street1`), or `grep -c` counting lines not occurrences in minified output. | Rule 4. Run a control that must hit, in the same command. |
| **`gh run watch` exits 0 on an already-completed FAILED run.** Its exit code reflects the watch, not the outcome. | Read the `conclusion` field: `gh run view <id> --json status,conclusion`. |
| **A no-op cherry-pick ABORTS THE SEQUENCE** — every later commit then silently never applies, and nothing errors. | Check `git diff --name-only main..HEAD` **before** pushing. Empty is the tell. |
| **A `--stat` is not a diff.** An in-line amendment never moves the counts: `338a7d1`'s plan half read `3+/1−` both before and after an added line was rewritten in place. | Read the diff. A `--stat` clears nothing. |
| **A count only verifies if the counting method travels with it.** "73 executable lines unchanged" was unreproducible — two honest methods gave 56 and 73, because one counted blank lines and one did not. A bare number is not evidence; it is a number. | Send the command with the count. For a comments-only claim pin a fingerprint both seats can recompute: `grep -vE '^[[:space:]]*(--\|#\|$)' <file> \| shasum -a 256`. |

---

## 6. Hard boundaries

- **INVOICING IS OFF-LIMITS.** A separate workstream owns NAV / Számlázz.hu. **Do not "helpfully" fix its compile errors.** *Precedent:* C0 was blocked by a stale invoicing test; the proposed fix — defaulting `CreateReplacementOrderRequest.billingAddress` to `nil` — would have silently removed the compile-time forcing function the billing-primary design depends on. Viktor fixed the *test*. **A compile error in invoicing code is not yours to resolve.**
- **Do not touch the authenticated shell internals** — `MainTabView` (iOS) / `MainTabScaffold` (Android).
- **Do not touch the derivation of `isAuthenticated`.** *Boundary refinement (approved 2026-07-14):* its **computation** is untouchable; **supplying a dependency through a defaulted parameter is a seam, not a derivation change.** Seams are approvable; derivation changes are not.
- **The C2 routing seam — growth is additive; derivation is untouchable.** *(RULED 2026-07-26, mirroring the `isAuthenticated` entry; the chunk-scoping of §E walls is the plan's Locked decision of the same date.)* Adding an `AuthOverlay` member, its root `when` arm, and a call-site binding that **assigns** (`nav = nav.enterX()`) is the seam doing its job. Changing `resolveRootRoute`'s logic, the existing arms' behaviour, or the §5 invariants is a **derivation change and is not approvable**. Mechanised: the board's C2-seam derivation guard (single resolver definition + every pre-existing arm pinned) — a rewrite disguised as growth reads red there, not in review.
- **Do not wire the dormant screens** — iOS `ScannedPetView`; Android `AlertsScreens.kt`, `PricingScreen.kt`.
- **G-a:** no "coming soon" placeholders. **G-b:** compose from **existing named primitives**; if one doesn't fit → **surface a gap, don't invent a styled component.**
- **All new strings localized, HU canonical, 13 locales. Zero hardcoded English.**
- **⚠️ A scope guard that names a FILE does not guard a BEHAVIOR.** G12b forbade wiring `ScannedPetView`. Nobody wired it. **Logged-out delivery shipped on iOS anyway**, through a live component one branch over. Write guards against the **behavior**, and mechanise them in `senra-status.sh` where possible.
- **⚠️ Corollary — defaulted params + a device-only behaviour = an unwired call site nothing catches.** When a chunk's new parameters are **defaulted** (so prior tests' shorter call sites still compile) *and* the behaviour they drive is device-only (no unit test), a version that never passes them **compiles, runs, and passes the whole existing suite** — those tests lean on the defaults — while the feature ships inert. No test, and no file-named guard, catches it. **Mechanise the *wiring* as a `senra-status.sh` grep** — a count of the behaviour (e.g. the seeded argument present at *both* call sites), written on **one line** so the grep proves *what it guards*, not just that a string exists — **and land the check *before* the chunk** so the board reads red-until-wired. §1: an item expressible as a check is not optional.

---

## 7. Two platform laws, learned the hard way

- **iOS —** `Group` is a type-erasing `@ViewBuilder` helper; `ZStack` is a **real container with stable identity**. Transitions ride identity. Swapping one for the other **compiles, passes tests, and silently kills the animation.**
- **Android —** SwiftUI republishes on in-place mutation of a `struct` in `@State`. **Compose does not.** `mutableStateOf` recomposes only when `.value` is **reassigned** (structural equality). A nav state with mutating methods leaves `.value` untouched → **no recomposition → the button does nothing → and every pure value test still passes.** **Copy-on-write; every call site is an assignment.**

Both are invisible to a compiler. One was caught by a device, one by design review. **Neither by a test.**

---

**The spec is authoritative. "Surface it and stop" beats "guess and proceed." And if you have not opened the file, you do not know.**
