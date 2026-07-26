# Senra Mobile Redesign — Session Handover

**Current work: the 2026-07-26 doc pass (this commit) logs C5/C6 + the two `pending` decode fixes in the CODEMAP, closing the four §7 reds.** C5 (iOS `4c00cf2`) and C6 (Android `7851b2f`) are **DONE** — committed, byte-reviewed, and the §E done-when-4 device gate **ATTESTED PASSED on both platforms** (attestation granularity; the 2026-07-26 change-log entry owns the record *and its caveats* — read it, not this line). **[[G-landing-submit]] is CLOSED.** The decode fixes (`ddfadf4` / `931b51b`) are non-redesign prod fixes riding the branch — **a Phase-1 revert must not revert them.**

> **NEXT CHUNK: the Phase-2 destinations read — 2.3 (Lost & Found board) / 2.3b (alert detail; Android is a BUILD, RULED 2026-07-21) / 2.4 (pet-friendly places, a ROUTING BUILD).** First deliverable is a **Rule-2 READ PLAN, then stop**; chunk contracts land in `docs/phase-2-spec.md` (PROTOCOL §1) when the read closes. These are the Zone-3 destinations — the two §5b ship-gates stay red until they wire (plan §2, Zone-3-ships-in-v1 ruling). *(Set by the 2026-07-26 doc pass; Viktor ratifies by committing it. The plan leaves no other front: F3/C7/C8 is deferred behind these; Phase 3.3 is Q3-blocked.)*

---

## This file points. It does not restate.

Every fact has exactly one owner. Restated facts drift and then contradict each other. **Where this file and an owner disagree, the owner wins and this file is the bug.**

| You need | Owner — read this |
|---|---|
| Roles, the rules, the hazards, the hard boundaries | `docs/PROTOCOL.md` — **read in full, first** |
| The plan, locked decisions, gaps register, CODEMAP | `docs/SENRA-MOBILE-REDESIGN.md` |
| What C5/C6 were contracted to do (and their gate) | `docs/phase-1-spec.md` **§E C5/C6** |
| The Phase-2 destination scopes the next read grounds | plan **§4 2.3 / 2.3b / 2.4** + §6 [[G-alert-detail-android]] |
| **What is done, red, or owed right now** | `scripts/senra-status.sh` — **run it. Do not read a summary of it.** |

---

## If you are a fresh session with no memory, start here

You are **not** expected to remember anything — it is all in the repo.

1. Read `docs/PROTOCOL.md` in full.
2. Run `./scripts/senra-status.sh`. It supersedes anything this file claims.
3. Identify your seat and do that seat's first moves.

**CC (build seat):** read PROTOCOL → board → plan §4 2.3/2.3b/2.4 + §6's rows for them. First deliverable is a **READ PLAN** (Rule 2), then **stop**. Re-ground every `file:line` by symbol (`grep -n`) — never trust a number written in a doc, including this one. Git is read-only absent an explicit, recorded per-command go.

**Review seat (chat):** read PROTOCOL → board → §E C5/C6 → the 2026-07-26 change-log entries. Hash every artifact before reading it (Rule 7) — **a hash quoted in prose is not a hash; require the artifact itself.** Grep for every named acceptance criterion by name (Rule 6). Demand two-ended cites for wiring claims (Rule 1). Ask whether the evidence is even inside the change (Rule 8).

---

## Verify before you trust this file

- **Expected reds after this doc pass: the four product reds** (AASA `/*/t/*`, the www 301, the 2 `.onOpenURL` handlers, G-owner) **plus the two Zone-3 ship-gates in board §5b** (Android `onNavigate` empty-lambda; iOS log-only inert handler — red **by design** until 2.3/2.4 wire the destinations). **The heuristic is "every red is explained," never a number to match. Any unexplained red is new and must be explained before the next chunk.**
- C5/C6's closure is logged — if this grep comes back empty, reconstruct before building and say so loudly: `grep -n '4c00cf2\|7851b2f' docs/SENRA-MOBILE-REDESIGN.md`
- **The §5b pinned-literal guards are green through C5/C6's edits of the guarded files.** If one goes red, a device-bought behaviour has been dropped — that is the whole point of them.
- **Standing obligation (recorded in §E C5/C6's board-guards block): the moment `phase-2-spec.md` names the two Zone-3 destination handlers, both ship-gates are RE-POINTED to positive assertions** (grep the named handler, expect 1, red-until-wired).

## Must not be lost (owners named; this file only points)

- **[[G-session-loggedout]]** — session-expiry dialog on the logged-out landing. **The remaining PHASE-1-SHIP-BLOCKER. Owner: auth workstream — nobody in this loop has worked it.**
- **[[G-owner]]** — device-confirmed 2026-07-20. Board §3 red.
- **The error-genre chunk — RULED 2026-07-21, one chunk, owner unassigned:** [[G-scan-error-raw]] + [[G-foundform-error-raw]] + 2.4's ungated-submit 401. Should-fix-before-ship, not ship-blocking.
- **[[G-tab-scan-noparity]]** and **[[G-alert-detail-android]]** — §6 rows feeding the Phase-2 read.
- **[[G-deactivate-authz]]** — backend workstream. Do not fix from here.
- **F3 → C7/C8** — DEFERRED behind the Phase-2 destinations (plan §2; §E C7/C8 pasted-and-held).
- **§13's standing rows** — release under R8, the delivery cold-start, dark-mode strokes, Samsung/Xiaomi splash.
- **The deep-link merge hazard** (board §10) — merges cleanly, so nothing forces a look; never device-run merged.
- **The release-line merge notes** — the 2026-07-23 Fix 5 change-log entry owns them (the authed prepend removal meets C5/C6's untouched copy; the it/fr/cs/es synonym divergence on `found_pet_reported_success`). Read it the day the branches meet.

## Open rulings Viktor owes

- **Q6** — root-vs-`docs/` doc home. The branch half of G-home is closed; this is the remainder.
- **Q3** — HU canonical wording for the guest-order success surface. §8 calls it the only open decision on the critical path, and it blocks all of Phase 3.3.
- **HU register** — §E C5/C6 routed it to Viktor: the census says te-form dominates (157:5) and the shipped confirmation string is te-form. Rule "informal is deliberate" (or overrule) so a native-speaker reflex can't re-open it. Does not block anything.

---

## When the next chunk lands

Two commits, one pass: **chunk commit → §7 goes RED naming the SHA (transient, expected, documented) → doc-only CODEMAP commit citing it → §7 GREEN.**

Viktor owns all git; CC executes only under an explicit, recorded per-command go. **Re-hash immediately before the chunk commit** so the committed tree is the reviewed tree — and re-hash again after *any* edit made between review and commit, however small. Use Rule 7's multi-file recipe if the chunk adds files; `git diff` alone omits them.

Update this file's current-chunk line. Then the next chunk.
