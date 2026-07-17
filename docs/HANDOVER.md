# Senra Mobile Redesign — Session Handover

**Current chunk: C4-Android — iOS C3 is DONE (built, committed, DEVICE-VERIFIED).** iOS landing content: `bc8ccd7`, + scan-dismiss fix `1e70664`, + lookup-spinner fix `72d5a06`.

**C3 device-QA gate — passed on hardware (Viktor, iPhone iOS 26.5, 2026-07-17).** Of the four outcomes in §E C3's gate, **three are reachable from a scan and all three passed** — active-tag (`:170`), inactive-tag (`:179`), and the **forced network-error `:187`** path (airplane mode); the chevron draws over the camera preview and sits in the safe area; the lookup spinner now shows (it was occluded by the cover — `72d5a06`). **The fourth outcome, promo (`:165`), is NOT reachable from a scan** — shelter promos are checkout/registration codes, not scannable tags; the branch is latent, backend-gated on `can_claim_promo`, not dead (Finding B / [[G-scanfeedback]], §9.15).

**Next: C4-Android**, the mirror of C3. It inherits **two** iOS truths the gate bought (§9.15): the overlay chevron works over the preview layer, **and** a `fullScreenCover` occludes the host's overlays — so Android's equivalent presentation must carry **both** the close affordance **and** the lookup indicator into the cover, or it ships the same two regressions iOS just paid to find.

*(C0-iOS, C0-Android, C1-iOS, C2-Android: built, reviewed, committed, device-verified.)*

---

## This file contains no facts. That is deliberate.

Every previous handover restated the plan, the protocol, the findings, and the board. Every restatement went stale, and the stale copies then contradicted each other — three different values for the docs tip, two different meanings for "Rule 5," a CODEMAP that did not know C1 existed.

**So this file states nothing. It points.** It cannot go stale, because there is nothing in it to be wrong about.

| You want to know | Read |
|---|---|
| How the seats work, the rules, the hazards, the hard boundaries | `docs/PROTOCOL.md` — **read this first, in full** |
| What we're building, what's locked, what's known about the codebase | `docs/SENRA-MOBILE-REDESIGN.md` — §2 decisions, §5 findings, §6 gaps, §9 CODEMAP, §10 contracts |
| Exactly what to build in this chunk | `docs/phase-1-spec.md` §E — files, edits, must-not-touch, named tests, done-when |
| **What is actually done, red, or owed right now** | `./scripts/senra-status.sh` — **run it. Do not read a table about it.** |

**Where this file and the spec differ, the spec wins.** Where any document states a commit ID or a line number, **verify it against the repo.** They have been wrong before, in every document, including this one.

---

## First moves

**CC (build seat):**
1. Read `docs/PROTOCOL.md` in full. It is not boilerplate — it is the distilled cause of every re-do this project has paid for.
2. Run `./scripts/senra-status.sh`. That is the board.
3. Read `docs/phase-1-spec.md` §E for this chunk, end to end, at its current tip. Skim the plan's §5 / §6 / §9.
4. **Output a READ PLAN and stop** (Rule 2). Do not conclude anything before it is reviewed.
5. Build one chunk. Surface the diff **and its hash — including new files** (Rule 7). **Stop.**

**Review seat:**
1. Read `docs/PROTOCOL.md` in full.
2. **Hash every artifact before reading a line of it** (Rule 7).
3. **Grep the artifact for every named acceptance criterion, by name** (Rule 6). C2's first artifact was 795 green with one of them missing, while the report said all were honored.
4. Demand two-ended citations for wiring claims (Rule 1). A hypothesis is welcome; a hypothesis dressed as a finding is not.
5. Rule 5: a build is not a run, and a run is not a look.
6. Rule 8: when something scary appears, check first whether it is even inside the change.

---

## When this chunk lands

Viktor commits → **logs the commit in the CODEMAP (§9 + the change log)** → updates the single line at the top of this file → next chunk.

If the CODEMAP entry is skipped, `senra-status.sh` goes red on `log-behind-code` the next time anyone runs it. That is intentional.
