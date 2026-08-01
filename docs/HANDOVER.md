# Senra Mobile Redesign — Session Handover

**Current work: the Phase-2 destinations read. Read A is CLOSED** — executed 2026-07-26, 2,031 lines across seven files, findings appended to `docs/PHASE2-READ-PLAN.md` and byte-reviewed at `19328828a520`. Reads B/C/D are **re-scoped but not executed**. Three review findings are open; none blocks reading, all three block contract-writing.

> **NEXT: execute the re-scoped Reads B/C/D**, starting with iOS `RootRoute.swift` — it is small and it resolves the one HYPOTHESIS Read A carries, which decides the iOS shape. Chunk contracts land in `docs/phase-2-spec.md` (PROTOCOL §1) when the read closes; `PHASE2-READ-PLAN.md` deletes into it at that point. *(Set by the review seat 2026-07-26; Viktor ratifies by committing.)*

---

## This file points. It does not restate.

Every fact has exactly one owner. Restated facts drift and then contradict each other. **Where this file and an owner disagree, the owner wins and this file is the bug.**

| You need | Owner — read this |
|---|---|
| Roles, the rules, the hazards, the hard boundaries | `docs/PROTOCOL.md` — **read in full, first** |
| The plan, locked decisions, gaps register, CODEMAP | `docs/SENRA-MOBILE-REDESIGN.md` |
| What C5/C6 were contracted to do (and their gate) | `docs/phase-1-spec.md` **§E C5/C6** |
| The Phase-2 destination scopes | plan **§4 2.3 / 2.3b / 2.4** + §6 [[G-alert-detail-android]] |
| **Read A's findings, the read ranges, the B/C/D re-scope** | `docs/PHASE2-READ-PLAN.md` — **§READ-A FINDINGS** |
| **What is done, red, or owed right now** | `scripts/senra-status.sh` — **run it. Do not read a summary of it.** |

---

## If you are a fresh session with no memory, start here

You are **not** expected to remember anything — it is all in the repo.

1. Read `docs/PROTOCOL.md` in full.
2. Run `./scripts/senra-status.sh`. It supersedes anything this file claims.
3. Identify your seat and do that seat's first moves.

**CC (build seat):** PROTOCOL → board → plan §4 2.3/2.3b/2.4 + §6's rows → `PHASE2-READ-PLAN.md` **including §READ-A FINDINGS**. Read A does not need re-running; **re-ground every `file:line` by symbol (`grep -n`) before relying on it** — the findings say so themselves. First deliverable is the re-scoped B/C/D read, then **stop**. Git is read-only absent an explicit, recorded per-command go.

**Review seat (chat):** PROTOCOL → board → §E C5/C6 → `PHASE2-READ-PLAN.md` → this file's open findings. Hash every artifact before reading it (Rule 7). Grep for every named acceptance criterion by name (Rule 6). Demand two-ended cites for wiring claims (Rule 1). Ask whether the evidence is even inside the change (Rule 8).

**⚠️ Rule 7's live failure mode is the SHUTTLE, not either seat.** CC surfaces bytes to disk and quotes a hash; the review seat can only hash what actually reaches it. Four rounds ran half-satisfied — hash without artifact, artifact without hash, a hash CC declined to compute, then bytes that never got attached. **The artifact and its hash must arrive in the same message, or the comparison never happens.** For a chunk that is only new files, plain `shasum -a 256 <file>` is the artifact hash; the `git diff --no-index` wrapper adds nothing and is fragile to reproduce.

**⚠️ A `--stat` is not a diff.** `338a7d1`'s plan half read `3+/1−` both before and after an added line was rewritten in place. An in-line amendment never moves the count. Only the diff shows it.

---

## Verify before you trust this file

- **Expected reds — the six standing, every one explained:** the four product reds (AASA `/*/t/*`, the www 301, the 2 `.onOpenURL` handlers, G-owner) and the two Zone-3 ship-gates in board §5b (red **by design** until 2.3/2.4 wire the destinations). **§8 additionally reds whenever a shuttle artifact or an uncommitted governing doc sits untracked — expected while a shuttle is in flight, cleared by commit or post-review deletion; a §8 red with no shuttle in flight is a real landmine.** **The heuristic is "every red is explained," never a number to match.**
- **§7 is genuinely green on the committed tree** — all 9 iOS + 7 Android chunk commits logged. If it reddens, the log is behind the code.
- C5/C6's closure is logged: `grep -n '4c00cf2\|7851b2f' docs/SENRA-MOBILE-REDESIGN.md`
- Read A's findings survived: `grep -n 'READ-A FINDINGS' docs/PHASE2-READ-PLAN.md` — **if empty, Read A must be re-run; do not reconstruct it from this file or any summary.**
- **The §5b pinned-literal guards.** If one goes red, a device-bought behaviour has been dropped — that is the whole point of them.
- **Standing obligation:** the moment `phase-2-spec.md` names the two Zone-3 destination handlers, both ship-gates **RE-POINT** to positive assertions (grep the named handler, expect 1, red-until-wired), landed **before** the wiring chunk.

## Open review findings on the read plan — all three unresolved

- **The iOS `RootRoute` claim contradicts itself.** §READ-A FINDINGS asserts in its VERIFIED section that iOS `RootRoute` has no order state, cited to `RootRoute.kt` — a **Kotlin** file — while the same section says anything about what iOS `RootRoute`/`RootNavState` holds is a guess until read. `handleDeepLink` is the standing precedent for same-named types across the two codebases. **Label it HYPOTHESIS or drop it; iOS `RootRoute.swift` decides it.**
- **2.3b's navigation shape was never in Read A's frame.** Read A owns *landing → destination*; the alert detail is *board → detail*, one level deeper. Third root arm, or nested nav inside the board arm? Different blast radius, different re-point targets, different test strategy. `CommunityDestination` has two members; 2.3b is a third surface that is not one of them. **Settle it two-ended before contracts close.**
- **`F3` names two different things in one document** — the G6 behavioral-guard read, and the deferred landing-restyle chunk in the same file's OUT list. Rename the read item.

## Must not be lost (owners named; this file only points)

- **[[G-session-loggedout]]** — session-expiry dialog on the logged-out landing. **The remaining PHASE-1-SHIP-BLOCKER. Owner: auth workstream — nobody in this loop has worked it.**
- **[[G-owner]]** — device-confirmed 2026-07-20. Board §3 red.
- **The G6 behavioral guard** — recorded in the read plan's Reads F, unmechanised today. A guard naming a FILE does not guard a BEHAVIOR (PROTOCOL §6; the G12b precedent). 2.3b-Android **lifts** from `ReportSightingDialog`, one import away from **calling** it. The zero-external-callers check on `AlertsScreens.kt` lands **before** the 2.3b chunk, not before the read.
- **The iOS root switch rides a `Group`** (`ContentView.swift:16`) — any new route arm inherits PROTOCOL §7's `Group`/`ZStack` class, which compiles, passes tests, and silently kills the animation. Device look, not a test.
- **The error-genre chunk — RULED 2026-07-21, one chunk, owner unassigned:** [[G-scan-error-raw]] + [[G-foundform-error-raw]] + 2.4's ungated-submit 401. Should-fix-before-ship, not ship-blocking.
- **[[G-tab-scan-noparity]]** and **[[G-alert-detail-android]]** — §6 rows feeding the remaining reads.
- **[[G-deactivate-authz]]** — backend workstream. Do not fix from here.
- **F3 → C7/C8** — DEFERRED behind the Phase-2 destinations (plan §2; §E C7/C8 pasted-and-held).
- **§13's standing rows** — release under R8, the delivery cold-start, dark-mode strokes, Samsung/Xiaomi splash.
- **The deep-link merge hazard** (board §10) — merges cleanly, so nothing forces a look; never device-run merged.
- **The release-line merge notes** — the 2026-07-23 Fix 5 change-log entry owns them (the authed prepend removal meets C5/C6's untouched copy; the it/fr/cs/es synonym divergence on `found_pet_reported_success`). Read it the day the branches meet.
- **One surface per chunk in Phase 2** (locked §2, restated in the read plan's spec-time note). This read feeds 2.3, 2.3b on two platforms (one a BUILD), and 2.4 — **the spec must not collapse them because they shared a read.**

## Open rulings Viktor owes

- **§E C5/C6's must-not-touch wall** — Read A reads the enum/resolver/`when`-block ban as that chunk's boundary, not a standing one, and the Android shape depends on it. Probably right, but reclassifying a recorded must-not-touch is a **DECISION** (PROTOCOL §1) and belongs in Locked decisions **before** the spec relies on it.
- **HU register** — the census (te:ön = 157:5) is owned by the plan's 2026-07-26 C5/C6 entry. **A census is not a ruling.** Rule "informal is deliberate" (or overrule) so a native-speaker reflex cannot re-open it. Blocks nothing.
- **Chunk numbers for the destination chunks** — §A.1: numbers follow build order, named at spec time (C7/C8 held by deferred F3).
- **Q6** — root-vs-`docs/` doc home. §6's G-home row names the exact residual and the two ways to close it.
- **Q3** — HU canonical wording for the guest-order success surface. Blocks all of Phase 3.3; not this read.

---

## When the next chunk lands

Two commits, one pass: **chunk commit → §7 goes RED naming the SHA (transient, expected, documented) → doc-only CODEMAP commit citing it → §7 GREEN.**

Viktor owns all git; CC executes only under an explicit, recorded per-command go — **the record's home is the CODEMAP; the 2026-07-26 post-commit entry is the precedent.** **Re-hash immediately before the chunk commit** so the committed tree is the reviewed tree — and re-hash again after *any* edit made between review and commit, however small. **If bytes change after review, they go back to the review seat; a re-hash alone proves the tree matches itself, not that anyone read it.** Stage pathspec-limited; `git add -A` and `git commit -a` sweep tracked-modified files the landmines check does not catch.

Update this file's current-chunk line. Then the next chunk.
