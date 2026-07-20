# Senra Mobile Redesign — Session Handover

**Current chunk: C4b is CODE-COMPLETE and COMMITTED. It is NOT done.**
The `D.1–D.7b` device gate in `phase-1-spec.md` §E C4b has **never run**. Board-green proves the wiring *exists*; it does not prove a logged-out finder sees a pet. C4 sat in exactly this state for two days — do not let "green" read as "done."

**The next chunk has not been chosen.** Viktor sets the line below before anyone builds.

> **NEXT CHUNK: ______** *(candidates: the C4b device gate first; then F3 landing design / Phase 2.1+2.2 / G-landing-submit)*

---

## This file points. It does not restate.

Every fact has exactly one owner. Restated facts drift and then contradict each other. **Where this file and an owner disagree, the owner wins and this file is the bug.**

| You need | Owner — read this |
|---|---|
| Roles, the rules, the hazards, the hard boundaries | `docs/PROTOCOL.md` — **read in full, first** |
| The plan, locked decisions, gaps register, CODEMAP | `docs/SENRA-MOBILE-REDESIGN.md` |
| What C4b was contracted to do, and its device gate | `docs/phase-1-spec.md` **§E C4b** |
| What C4 and the 2026-07-20 gate session established | `docs/SENRA-MOBILE-REDESIGN.md` **§9.16 / §9.17** |
| **What is done, red, or owed right now** | `scripts/senra-status.sh` — **run it. Do not read a summary of it.** |

---

## If you are a fresh session with no memory, start here

You are **not** expected to remember anything — it is all in the repo.

1. Read `docs/PROTOCOL.md` in full.
2. Run `./scripts/senra-status.sh`. It supersedes anything this file claims.
3. Identify your seat and do that seat's first moves.

**CC (build seat):** read PROTOCOL → board → §E C4b → §9.17. First deliverable is a **READ PLAN** (Rule 2), then **stop**. Re-ground every `file:line` by symbol (`grep -n`) — never trust a number written in a doc, including this one. Git is read-only absent an explicit, recorded per-command go.

**Review seat (chat):** read PROTOCOL → board → §E C4b → §9.17 → the C4b CODEMAP entry. Hash every artifact before reading it (Rule 7) — **a hash quoted in prose is not a hash; require the artifact itself.** Grep for every named acceptance criterion by name (Rule 6). Demand two-ended cites for wiring claims (Rule 1). Ask whether the evidence is even inside the change (Rule 8).

---

## Verify before you trust this file

- **Four product reds are expected and are not yours:** AASA `/*/t/*`, the www 301, the 2 `.onOpenURL` handlers, G-owner. **Any fifth red is new and must be explained before the next chunk.**
- C4b's closure is logged — if either grep comes back empty, reconstruct before building and say so loudly:
  - `grep -n 'C4b' docs/SENRA-MOBILE-REDESIGN.md`
  - the Android chunk SHA and its CODEMAP entry, against `git log`
- **The two C4b board guards exist and are green.** They are the deliberate substitute for a unit test that cannot be written (PROTOCOL §6 corollary). If either goes red, C4b's wiring has been dropped — that is the whole point of them.

---

## What C4b left owed

- **`D.1–D.7b` — the entire device gate.** Real device, cold-killed, logged out, real tag. D.7a's baseline already PASSED (2026-07-20, `am start`-fired, in-app chain only). **D.7b includes the self-heal round-trip look.**
- **The `isNullOrBlank` / `== null` predicate split** between `LandingScreen`'s auto-present and `QrScannerScreen`'s guard — resolved in-chunk or logged as a gap. Check which; §E C4b's text says `!= null`.
- **`d85e3d5`** (the board checks) — confirm it was byte-reviewed, not just approved in prose.

## Not C4b's, but must not be lost

- **G-landing-submit** — a finder submits a found-pet report and gets no confirmation. Both platforms. **PHASE-1-SHIP-BLOCKING, and it is our surface, not another workstream's.**
- **G-session-loggedout** — session-expiry dialog on the logged-out landing. **PHASE-1-SHIP-BLOCKING. Owner: auth workstream — nobody in this loop has worked it.**
- **G-owner** — device-confirmed 2026-07-20. Board §3 red.
- **G-scan-error-raw** — the scan Error path ships raw English exception text to every locale; breaks §6's zero-hardcoded-English boundary.
- **G-deactivate-authz** — backend workstream. Do not fix from here.
- **F3** — landing design (logo + vertical spacing), cross-platform, its own chunk.
- **§13's standing rows** — release under R8 (C1/C2 have never run under it; release is what ships), the delivery cold-start, dark-mode strokes, Samsung/Xiaomi splash.
- **The deep-link merge hazard** — the fix merges *cleanly*, so nothing forces anyone to look. The merged pairing has never run on a device.

## Open rulings Viktor owes

- **Q6** — root-vs-`docs/` doc home. The branch half of G-home is closed; this is the remainder.
- **Q3** — HU canonical wording for the guest-order success surface. §8 calls it the only open decision on the critical path, and it blocks all of Phase 3.3.
- **Scope for v1** — whether Zone 3's community cards ship, or are hidden until Phase 2 completes. This decision moves roughly six chunk-equivalents on or off the critical path.

---

## When the next chunk lands

Two commits, one pass: **chunk commit → §7 goes RED naming the SHA (transient, expected, documented) → doc-only CODEMAP commit citing it → §7 GREEN.**

Viktor owns all git; CC executes only under an explicit, recorded per-command go. **Re-hash immediately before the chunk commit** so the committed tree is the reviewed tree — and re-hash again after *any* edit made between review and commit, however small. Use Rule 7's multi-file recipe if the chunk adds files; `git diff` alone omits them.

Update this file's current-chunk line. Then the next chunk.
