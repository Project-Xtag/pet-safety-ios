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
| The buildable chunk contract — files, edits, must-not-touch, named tests, done-when | `docs/phase-1-spec.md` |
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

Step 5's logging is not optional. `senra-status.sh` fails the board if the branch tip has no CODEMAP entry.

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

### Rule 5 — A build is not a run, and a run is not a look

`BUILD SUCCEEDED` proved nothing about the splash→content crossfade, which **a `Group` wrapper silently broke.** It compiled. It passed tests. Only a physical device caught it.

Anything **visual, animated, timing-dependent, or structural in a `WindowGroup`** needs a device. Say which of the three you did — built, ran, or looked — and never let one stand in for another.

### Rule 6 — Force the test run; read the report; grep for the criterion

`BUILD SUCCESSFUL` with `41 up-to-date, 1 executed` means Gradle **replayed a cache and ran nothing.** Always `--rerun-tasks`. Always read `app/build/reports/tests/.../index.html`, never the console.

**And grep the artifact for every named acceptance criterion, by name.** C2's first artifact was **795 green with `backFromAuthReturnsToLanding` absent**, while the report asserted every decision honored. `grep -c` found it in seconds. **A verbatim criterion is worth exactly one grep. Run it every chunk.**

### Rule 7 — The green light is a hash

CC surfaces the artifact **and its hash**. The review seat hashes what it received. **Match → the thing reviewed is the thing being committed.** Mismatch → stop.

```bash
git diff | shasum -a 256 | cut -c1-12
```

**⚠️ That command omits new files.** Untracked files are invisible to `git diff`, so any chunk that adds files — every chunk so far — is **under-hashed**. Include them:

```bash
NEW="path/to/NewFileA.kt
path/to/NewFileB.kt"
( git diff; while read -r f; do git diff --no-index -- /dev/null "$f"; done <<< "$NEW" ) 2>/dev/null \
  | shasum -a 256 | cut -c1-12
```

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
| **`git diff` omits new files** → the hash under-covers the chunk. | Rule 7's multi-file recipe. |
| **🔴 A stale APK survives a "fresh" install.** `lastUpdateTime` proves the *install* is fresh, **not that the APK is.** Debug and release share `applicationId` (only `staging` has a suffix) but are signed with **different keys** — a stale install can survive and relaunch, looking exactly like a code bug. | **When the device contradicts the source: `adb uninstall` + `./gradlew clean` BEFORE debugging a line.** |
| **Wrong variant.** The suite runs `testDebugUnitTest`; Studio may be installing **release**, whose baseline-profile step fails for unrelated reasons. | Match the variant to the tests. |
| **zsh is not bash.** `#` is **not a comment** interactively, and `$VAR:P` is a **parameter modifier** — `$T:PetSafety/...` silently rewrites a hash into a path. | **One command per line. No inline comments.** Inline the value, don't interpolate before a `:`. |
| **Xcode 16 `project.pbxproj` noise** — reorders, empty-`exceptions` removals. | **Benign.** Synchronized folders don't enumerate sources; a deletion there can't drop one. Discard freely. |
| **Untracked files in the repo root** — loose `.diff`s, extracted doc copies, `build-derived/`. One `git add -A` and they land on a code branch. | `.gitignore` + the `landmines` check in `senra-status.sh`. |

---

## 6. Hard boundaries

- **INVOICING IS OFF-LIMITS.** A separate workstream owns NAV / Számlázz.hu. **Do not "helpfully" fix its compile errors.** *Precedent:* C0 was blocked by a stale invoicing test; the proposed fix — defaulting `CreateReplacementOrderRequest.billingAddress` to `nil` — would have silently removed the compile-time forcing function the billing-primary design depends on. Viktor fixed the *test*. **A compile error in invoicing code is not yours to resolve.**
- **Do not touch the authenticated shell internals** — `MainTabView` (iOS) / `MainTabScaffold` (Android).
- **Do not touch the derivation of `isAuthenticated`.** *Boundary refinement (approved 2026-07-14):* its **computation** is untouchable; **supplying a dependency through a defaulted parameter is a seam, not a derivation change.** Seams are approvable; derivation changes are not.
- **Do not wire the dormant screens** — iOS `ScannedPetView`; Android `AlertsScreens.kt`, `PricingScreen.kt`.
- **G-a:** no "coming soon" placeholders. **G-b:** compose from **existing named primitives**; if one doesn't fit → **surface a gap, don't invent a styled component.**
- **All new strings localized, HU canonical, 13 locales. Zero hardcoded English.**
- **⚠️ A scope guard that names a FILE does not guard a BEHAVIOR.** G12b forbade wiring `ScannedPetView`. Nobody wired it. **Logged-out delivery shipped on iOS anyway**, through a live component one branch over. Write guards against the **behavior**, and mechanise them in `senra-status.sh` where possible.

---

## 7. Two platform laws, learned the hard way

- **iOS —** `Group` is a type-erasing `@ViewBuilder` helper; `ZStack` is a **real container with stable identity**. Transitions ride identity. Swapping one for the other **compiles, passes tests, and silently kills the animation.**
- **Android —** SwiftUI republishes on in-place mutation of a `struct` in `@State`. **Compose does not.** `mutableStateOf` recomposes only when `.value` is **reassigned** (structural equality). A nav state with mutating methods leaves `.value` untouched → **no recomposition → the button does nothing → and every pure value test still passes.** **Copy-on-write; every call site is an assignment.**

Both are invisible to a compiler. One was caught by a device, one by design review. **Neither by a test.**

---

**The spec is authoritative. "Surface it and stop" beats "guess and proceed." And if you have not opened the file, you do not know.**
