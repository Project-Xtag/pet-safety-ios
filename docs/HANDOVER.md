# Senra Mobile Redesign — Session Handover

**Current chunk: C4b-Android** — G11's seeded-scan close on the landing (§6-G11 / spec §E C4b).
**Status: C4-Android is COMMITTED (`dfc8acc`, §9.16) — code-complete, NOT device-verified.** Its §E C4 device-QA gate (Part A/B/C) is owed on hardware, and the build surfaced a two-platform ship-blocker, [[G-landing-submit]]. Do not take this line's word for any of it — run the board.

*(C0–C3 iOS and C0/C2/C4 Android: built, reviewed, committed, logged. Device-QA: C3-iOS verified; C4-Android owed. The board derives all of this — run it.)*

---

## This file points. It does not restate.

Every fact in this project has exactly one owner. Restated facts drift and then contradict each other — that has cost a re-do nearly every week. So this file names owners and routes you to them. **Where this file and an owner disagree, the owner wins and this file is the bug.**

The single exception is the C4 read plan, which has no owner yet (it is destined for spec §E). It is carried in its own file and marked provisional.

| You need | Owner — read this |
|---|---|
| Roles, the rules, the hazards, the hard boundaries | `docs/PROTOCOL.md` — **read in full, first** |
| The plan, locked decisions, gaps register, CODEMAP, contracts | `docs/SENRA-MOBILE-REDESIGN.md` — §2 / §5 / §6 / §9 / §10 |
| What to build in this chunk | `docs/phase-1-spec.md` §E — the **C4 section exists** (amended 2026-07-17 with the device-findings-to-verify + the C4b split) |
| **What is done, red, or owed right now** | `scripts/senra-status.sh` — **run it. Do not read a summary of it.** |
| The reviewed C4 read plan (provisional → spec §E) | `docs/C4-READ-PLAN.md` |

---

## If you are a fresh session with no memory, start here

You have been handed this because a prior session was about to run out of context. You are **not** expected to remember anything — everything you need is in the repo. Bootstrap:

**Both seats, in order:**
1. Read `docs/PROTOCOL.md` in full. It is the distilled cause of every re-do this project has paid for. It is not boilerplate.
2. Run `./scripts/senra-status.sh` (it reads both repos via its `IOS`/`AND` variables). That is the board — the live truth. It supersedes anything this file claims.
3. Identify your seat (below) and do that seat's first moves.

**You are CC (build seat)** if you have the repo in front of you and are asked to investigate and write code.
- Read: PROTOCOL → board → `phase-1-spec.md` §E for C4 → `docs/C4-READ-PLAN.md`.
- Your first deliverable is a **READ PLAN** (Rule 2). Re-confirm the C4 read plan against the *current* spec and board — cites drift (§9.4 caught C1's gate line-drifting 13 lines off its cite; the iOS `PetsListView` lift cite was stale). Re-ground every `file:line` by symbol, not by trusting the number.
- Then **stop.** Do not write code before the read plan is reviewed. A read plan is a complete, correct answer on its own.
- Git: read-only only. No commit/push/branch/merge without an explicit, recorded per-command go from Viktor.

**You are the review seat (chat)** if you byte-review diffs and draft CC's instructions.
- Read: PROTOCOL → board → spec §E for C4 → the C4 read plan → the C3 CODEMAP entries (`grep -n 'C3\|1e70664\|72d5a06' docs/SENRA-MOBILE-REDESIGN.md`).
- You do not write production code. You may draft documentation.
- Every artifact: hash it before reading it (Rule 7). Grep it for every named acceptance criterion, by name (Rule 6). Demand two-ended cites for wiring claims (Rule 1). Check whether the evidence is even inside the change before debugging it (Rule 8). A build is not a run and a run is not a look (Rule 5).

---

## Verify before you trust this file

This file can be stale. The board and the plan cannot (derived / single-owner). Before acting on anything below, confirm it — and if a check fails, believe the check, not this file:

- `./scripts/senra-status.sh` is **green at rest** on both phase1 trees. §7 (chunk-logging), §8 (landmines), §9 (doc-home) must be green.
- **Four pre-existing product reds are expected and are not yours:** AASA `/*/t/*`, the www 301, the 2 `.onOpenURL` handlers (the check itself says expected until `fix/deeplink-root-handler` merges), and G-owner. A **fifth** red is new and must be explained before the next chunk.
- The C3 inheritance is actually logged. Grep the plan:
  - `grep -n 'scanfeedback\|scanexit' docs/SENRA-MOBILE-REDESIGN.md`
  - `grep -n '1e70664\|72d5a06\|bc8ccd7' docs/SENRA-MOBILE-REDESIGN.md`
  - `grep -n 'G-c3' docs/SENRA-MOBILE-REDESIGN.md`
- If any of those come back **empty**, the inheritance was not committed to its owner and this session must reconstruct it from `docs/C4-READ-PLAN.md` before building — say so loudly. A missing pointer is a lost lesson.

---

## What C4 inherits from C3 (pointers — read them in the plan, do not trust this list)

C4 is the Android mirror of C3, but the device-QA gate made C3 bleed for things the spec did not say. Each is logged; read it at its owner, verify by grep:

- **G-scanfeedback** — a full-screen presentation does **not** inherit its host's ancestor overlays. On iOS, `fullScreenCover` occluded both the dismiss affordance and the lookup spinner that lived on `ContentView`. C4's scan surface must carry both into its own presentation — *if* Android's presentation model has the same property. **It may not.** Verify in Kotlin (read plan Reads A / C).
- **G-scanexit** (§6) — a pre-existing missing back button on the Android push path may exist too; logged, not necessarily in C4's scope.
- **The C3 device findings** (§9, verify section numbers by grep, not by memory): the chevron composites over the camera preview layer; the cover occluded host overlays; the lookup Task is not cancellable, so the loading overlay dims the dismiss control **by design**.

**The rule this buys C4:** *do not assume the mirror holds.* Every iOS wiring claim the spec made was checked against the code and several were false (`OrderMoreTagsView` was not dependency-free). The Android equivalents are unchecked Kotlin claims. Read them two-ended before building.

---

## Open rulings Viktor owes (flagged, not decided)

- **G11 / C4 scope.** §6.11 says C4 is where G11 (the seeded-scan surface on the landing) closes, and that it *"requires an approved amendment to spec §E C4 before it is built."* So C4 may be a **bigger** surface than a clean C3 mirror. Decide before build whether G11's close is in this chunk or a separate one. Read plan Reads A / B2 inform it.
- **The §9.15 device-verified caveat.** C3-iOS was flipped to device-verified on a "working as it should" signal, not a blow-by-blow of three-assertions-per-outcome with `:187` re-forced. If that signal meant something narrower than a full re-run, §9.15 wants tightening before C3 is leaned on as a fully-verified baseline for C4.

---

## When this chunk lands

Two commits, one pass (the model §7 enforces): **chunk commit → §7 goes RED naming the SHA (transient, expected, documented) → doc-only CODEMAP commit citing it → §7 GREEN.** Viktor owns all git; CC executes only under an explicit, recorded per-command go. Re-hash immediately before the chunk commit so the committed tree is the reviewed tree. Update this file's current-chunk line. Then the next chunk.

If the CODEMAP entry is skipped, §7 goes red the next time anyone runs the board. That is intentional.
