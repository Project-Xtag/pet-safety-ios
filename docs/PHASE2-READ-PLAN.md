# Phase-2 Destinations Read Plan (2.3 board · 2.3b detail-BUILD · 2.4 pet-friendly)

**Provenance:** produced by CC 2026-07-26 (Rule 2), after the 338a7d1 doc pass set this as NEXT CHUNK.
**The owner-to-be is `docs/phase-2-spec.md`** (PROTOCOL §1) — the chunk contracts written when this read closes. This file is the execution detail that grounds them. **Delete this file once its reads are folded into the spec.**

**The executing CC re-grounds every `file:line` below by symbol (`grep -n`) before relying on it** — the line numbers here were grep-grounded 2026-07-26 and will drift. Rule 2 governs: this plan is surfaced for review, then the reads run; nothing is concluded outside these ranges without being labelled a guess. Line numbers marked ⊙ were re-verified exact on 2026-07-26; unmarked ranges are locating hints only.

**Doc reads that frame everything (read first, cheap):** plan §4 rows 2.3 / 2.3b / 2.4; §6 rows **G6** (quarantine/delete ruling, af238f9), **G7**, **[[G-alert-detail-android]]** (the 2.3b-Android BUILD ruling), **[[G-tab-scan-noparity]]** (adjacent to 2.3b's scan action), **[[G-pfp-cache-stale]]** (2.4 adjacency); §E C4b (the proven landing presentation idioms C5/C6's guards pin).

---

## Read A — the read that decides the SHAPE of every contract (do first)

**Execution order (review-ratified 2026-07-26): execute Read A, surface its answer, STOP. B/C/D's ranges are re-scoped against A's answer before they run** — if A returns landing-hosted overlay the root files shrink and the landing files grow, and vice versa; planning them in full before A returns is Rule 2's own failure mode.

**The one question: how does a Zone-3 destination PRESENT from the logged-out landing — a root-level route, or a landing-hosted overlay (the C4 `showScanner`/`showFoundStray` boolean pattern)?** Everything downstream — files touched, §5b re-point targets, blast radius — follows from this. **A per-platform split is a legitimate outcome, not an asymmetry defect** — §9.16 is the precedent (C4's Read A found Android presents via an `AnimatedContent` swap and iOS's G-scanfeedback carry was correctly NOT ported). The answer is recorded per platform, not forced into one shape.

- **A1. Android root:** `ui/PetSafetyApp.kt` whole file (420 lines), centered on the landing call site + `onNavigate = { }` ⊙`:361`; plus `RootRoute.kt` (C2's seam). What idiom exists at the root for a logged-out full surface, and can a destination screen present WITHOUT entering `MainTabScaffold` (hard boundary)?
- **A2. iOS root:** `App/ContentView.swift` (765 lines), the landing branch + log-only handler ⊙`:49`, and the deep-link-sheet pattern the locked decision names (doc cites `:53`/`:84` — re-ground). Same question: sheet/`fullScreenCover` from the landing branch vs a root-level swap.
- **A3. The landing's own idiom:** `ui/screens/LandingScreen.kt` presentation region (the C5/C6-guarded file — **every §5b pinned literal is must-not-touch**) + `Views/Landing/LandingView.swift` ⊙`:58` (`onNavigate: (CommunityDestination) -> Void`), ⊙`:239-240` (seed → card → `onNavigate(entry.destination)`); `ui/screens/CommunityEntry.kt` ⊙`:17` (`enum CommunityDestination { LOST_AND_FOUND, PET_FRIENDLY_PLACES }`) + `Views/Landing/CommunityEntry.swift` (iOS twin). The intent plumbing is built and tested — the read decides only where the handler lives.

---

## Reads B — 2.3 Lost & Found board

- **B1. iOS `Views/Alerts/AlertsTabView.swift` whole file (690).** Centered `:348-366` (the `currentUser` geocode fallback + `showAddressRequiredMessage`) and `:40-41` (`AddressRequiredView()` — no such file exists; locate its definition). Enumerate every auth dependency (VMs hoisted, `currentUser` reads) and what the AddressRequiredView CTA does today (the plan says rework it). Decides: what optionalizes vs what hides.
- **B2. Android `ui/screens/LostAndFoundScreen.kt` (658) — declaration + every VM/`hiltViewModel()` hoist + the location source; `ui/screens/AlertsTabScreen.kt` (180) whole.** The plan's "2 unused VMs" is a Rule-1 claim nobody has two-ended — verify or refute it. Decides: render `LostAndFoundScreen` directly with a device location, or optionalize `AlertsTabScreen`'s fallback. Also read its existing report-a-found-pet affordances — the 2.2 remnant ("wire entry from landing/board") folds in here or is declared already-satisfied.
- **B3. The G6 wall:** `ui/screens/AlertsScreens.kt` (2141, dormant) — census ONLY: what 2.3 must not resurrect, and where `ReportSightingDialog` lives for C-read's lift (grep matched it to this file and `QrScannerScreen.kt` — attribute it). **Dormant screens stay unwired (§6 hard boundary); this read takes inventory, nothing else.**

---

## Reads C — 2.3b missing-pet detail (iOS relocate · Android BUILD)

- **C1. iOS `Views/Alerts/AlertDetailView.swift` whole file (495).** Ownership check ⊙`:24-25` (`authViewModel.currentUser?.id`); the authed `ReportSightingView(alertId:)` presentation ⊙`:274`. Enumerate EVERY `currentUser`-gated affordance — Q1 (locked) says the public read exposes exactly Report-a-sighting + Scan-a-tag and nothing else. Also every `@EnvironmentObject` it hoists (the crash class: grep the whole body, not the signature).
- **C2. iOS `Views/Alerts/ReportSightingView.swift` whole file (359).** Deps + presentability from a public context — the C4-read B2 lesson: the "no authed deps" genre of claim is FALSE until proven.
- **C3. Android BUILD inputs:** `data/repository/AlertsRepository.kt` ⊙`:106-139` (`reportSighting` — two-ended against its ApiService route; §5.6 already proved the backend `optionalAuth`, no backend read needed); `ReportSightingDialog`'s body (in the file B3 attributes) — the form logic 2.3b lifts per G6; the Alert DTO the detail must render; and where a board item's tap currently dies ([[G-alert-detail-android]]: items navigate nowhere — find the dead end, two-ended).
- **C4. Scan-a-tag second action:** reuse the proven landing scanner seam (§E C4b) — read only the entry point a detail screen would call. No scanner internals (must-not-touch).
- **C5. The detail's navigation shape (review-added 2026-07-26 — never in Read A's frame).** Read A owns *landing → destination*; the alert detail is *board → detail*, **one level deeper**. Third root arm, or nested nav inside the board arm? The answer changes the blast radius, the §5b re-point targets, and the test strategy — and `CommunityDestination` has two members while the detail is a third surface that is not one of them. **Settle it two-ended before contracts close**, on both platforms (iOS: how `AlertsTabView` reaches `AlertDetailView` today; Android: there is no live detail — the BUILD chooses its container).

---

## Reads D — 2.4 pet-friendly places (a ROUTING BUILD, re-grounded 2026-07-21)

- **D1. iOS `Views/PetFriendlyPlaces/PetFriendlyPlacesView.swift` whole file (476).** Market derivation ⊙`:249` (`user?.country ?? Locale.current.region?.identifier ?? ""` — CAN yield empty); the `notInMarket` state (`:50` comment, `:231`); submit gating (`createPetFriendlyPlace` is `requiresAuth:true` — locate the submit entry to gate at action level); env deps.
- **D2. Android:** `ui/screens/PetsScreen.kt` ⊙`:68-69` (uppercased, never-blank market — the delta the contract converges) + ⊙`:412` (the SOLE live entry, inside the authed Pets tab) + `ui/screens/petfriendly/PetFriendlyPlacesScreen.kt` (443) declaration + deps. What does the screen need that the authed tab supplies today? The screen's drifted "pushed from the community area" doc comment is corrected in-chunk (Rule 3).
- **D3. The action-level login prompt (locked decision), both platforms.** iOS: the deep-link-sheet pattern (A2's re-grounded lines). Android: "the existing activation/login-prompt route" — a named-but-never-two-ended claim; locate it or surface that it doesn't exist.

---

## Reads E — remnant reconciliation (2.1 leftovers; keep it a census, not a chunk)

- **E1. Android `ui/screens/PublicPetProfileScreen.kt` (856)** — declaration + `currentUser`/`appStateViewModel` reads + **enumerate its call sites** (the callee, not the name). Plan 2.1 predates C4b's landing-seeded path; what of "nullable `currentUser` + drop unused param" remains true?
- **E2. iOS G7 `ScannedPetView`** — no such FILE exists today; a COMBINED grep for `ScannedPetView|AddressRequiredView|CommunityDestination` matched `ContentView.swift` / `PetPublicProfileView.swift` / `QRScannerView.swift`, unattributed. **Named hypothesis (Rule 8, before the read): the hits are probably stem-matches on OTHER symbols** — `PetPublicProfileView` is the public-profile twin, and the Android `ScannedPetSheet` shows the stem is shared across types; §6/G6 records `ScannedPetView` at zero callers + one stale test comment. Re-run per-symbol to confirm or refute; do not report drift before attribution. Status only; wire nothing.

---

## Reads F — mechanization + test strategy (settle before contracts close)

- **F1. `scripts/senra-status.sh:221-241`** (the two Zone-3 ship-gates) — the recorded obligation: the moment `phase-2-spec.md` names the destination handlers, both gates RE-POINT to positive assertions (named handler, expect 1, red-until-wired), landed BEFORE the wiring chunk (PROTOCOL §6 corollary — the d85e3d5 pattern).
- **F2. Test strategy:** Android — can `createComposeRule` drive a Zone-3 card tap to a presented destination (C4-read E1 said Android may automate what iOS could not)? Mind the Compose dead-button trap (PROTOCOL §7): assert the wiring recomposes/navigates, not that a closure stored a value. iOS — closure-proof + device gate; no test named `…Presents…`.
- **F-G6. The G6 behavioral guard (review-added 2026-07-26; renamed from "F3" — that name collides with the deferred landing-restyle chunk in this file's OUT list).** PROTOCOL §6: a scope guard that names a FILE does not guard a BEHAVIOR — G12b forbade wiring `ScannedPetView`, nobody wired it, and logged-out delivery shipped on iOS anyway through a live component one branch over. 2.3b-Android **lifts** form logic from `ReportSightingDialog`, which is one import away from **calling** it instead. **Land a zero-external-callers check on `AlertsScreens.kt` symbols in `senra-status.sh` BEFORE the 2.3b chunk** (the d85e3d5 pattern: the guard precedes the chunk it guards), so a resurrect-instead-of-lift reads red on the board, not in review.

---

## Explicitly OUT (walls, all previously ruled)

The error-genre chunk (G-scan-error-raw + G-foundform-error-raw + 2.4's ungated-submit 401 — RULED one separate chunk); [[G-session-loggedout]] (auth workstream); [[G-owner]]; invoicing (hard boundary); `MainTabView`/`MainTabScaffold` internals; `isAuthenticated`'s derivation; F3/C7/C8 restyle (deferred, held); wiring any dormant screen.

## Rulings owed (none block the READ itself)

Chunk numbers for the destination chunks — §A.1: numbers follow build order, Viktor names them at spec time (C7/C8 are held by deferred F3). Q3 blocks only Phase 3.3, not this. The HU register ruling stays owed in HANDOVER, non-blocking.

## For spec time, not read time (recorded here so the spec can't forget it)

Locked §2: **one surface per chunk in Phase 2.** This read feeds 2.3, 2.3b on two platforms (one a BUILD), and 2.4 — **the spec must not collapse them into fewer chunks because they shared a read.**

---

# READ-A FINDINGS (executed 2026-07-26 by CC; appended on Viktor's instruction — this file is the home until `phase-2-spec.md` exists)

Read A ran against this file at `e503aac0a7bf` and read **whole files, 2,031 lines**: `PetSafetyApp.kt` (420), `RootRoute.kt` (79), `LandingScreen.kt` (385), `ContentView.swift` (765), `LandingView.swift` (270), `CommunityEntry.swift` (59), `CommunityEntry.kt` (53). Labels per Rule 1: **VERIFIED** = both ends cited below; **HYPOTHESIS** = labelled, unread at one end.

## Android — VERIFIED (two-ended throughout)

- Root resolution: `resolveRootRoute(isAuthenticated, nav.overlay)` — call `PetSafetyApp.kt:305`; definition `RootRoute.kt:34-44`. Five-arm `when` inside `AnimatedContent`, `PetSafetyApp.kt:319-368`.
- Logged-out full surfaces are **first-class `AuthOverlay` states** (`RootRoute.kt:27` — `NONE, LOGIN, REGISTER, ORDER_TAGS`), each an arm of the root `when`.
- **Zone-2 precedent, the decisive one:** `onOrderTag = { nav = nav.enterOrderTags() }` (`PetSafetyApp.kt:358`) resolving to the `RootRoute.ORDER_TAGS` arm (`:326-335`), with the in-code rationale "C2's single routing authority... NOT a new local overlay" (`:355-357`; restated `LandingScreen.kt:63-65`).
- The landing-hosted `when`-swap (`LandingScreen.kt:99-150`, `showScanner`/`showFoundStray`) serves the Zone-1 acute surfaces only (chrome-less camera, form).
- The dead CTA: `onNavigate = { }` at `PetSafetyApp.kt:361` — inside the same arm where every other landing intent already resolves to `nav = nav.enterX()`.
- **Indicated shape (recommendation, not a ruling):** two new `AuthOverlay`/`RootRoute` states + two `when` arms + the `:361` binding — the exact Zone-2 pattern. Zone-3 destinations are full screens with own scaffolds (`LostAndFoundScreen` 658 lines; PFP screen 443) — they resemble `OrderMoreTagsScreen`, not the scanner. Spec-time note: §E C5/C6's must-not-touch on the enum/resolver/`when` was **that chunk's wall, not a standing boundary**; the standing walls (`MainTabScaffold` internals, `isAuthenticated` derivation) are untouched by this shape.

## iOS — VERIFIED two-ended, with one HYPOTHESIS named

- Root switch: `RootRoute.resolve` call `ContentView.swift:14`; `switch route` `:17-53` over `.main/.register/.login/.landing`, `.transition(.opacity)` per arm + `.animation` `:64`. The switch rides a `Group` (`:16`) — any new arm inherits PROTOCOL §7's `Group`/`ZStack` device-QA class.
- The landing hosts Zone 1 via `fullScreenCover` (`LandingView.swift:90-163`) **and — divergently from Android — Zone 2 via a landing `.sheet`** (`:175-183`, re-injecting two `@EnvironmentObject`s). **That iOS `RootRoute` has no order state is a HYPOTHESIS** — its only source is the Kotlin twin's comment (`RootRoute.kt:11-14`), a claim about a Swift type from a Kotlin file; `handleDeepLink` is the standing precedent for same-named types diverging across the codebases. iOS `RootRoute.swift` decides it.
- The root hosts three deep-link `.sheet`s (`ContentView.swift:76` / `:92` / `:107`); the modal-over-modal handshake is the §5b-pinned yield (`LandingView.swift:66-70`) + dismiss-on-flag (`:186-188`).
- The dead CTA: the log-only closure `ContentView.swift:48-50`, whose own comment names this site as where "Phase 2 ... adds the handler."
- **Viable shapes:** **(a) new route arms — carries a HYPOTHESIS: iOS `RootRoute.swift` was NOT in Read A's ranges, so anything about what iOS `RootRoute`/`RootNavState` can hold is a guess until it is read.** **(c) root-hosted presentation** — the `:48` closure sets `ContentView` state driving a sheet/cover; the idiom is VERIFIED to exist at this exact root (`:76-120`). **Shape (b), landing-hosted, is disfavored by the code:** it would loop the emitted intent back into its emitter, bypassing the tested §C.2 seam (`LandingView.swift:58` emits; `ContentView.swift:48` consumes).
- Per-platform divergence (root-arms Android / root-sheets iOS) is a **legitimate outcome** per this plan's Read A preamble.

## Yields for later reads (facts noted en route, not conclusions beyond them)

- **2.4-D3 iOS primitive located:** `DeepLinkLoginPromptView` (`ContentView.swift:143-211`), auth-branched inside the sheets at `:78-88` / `:109-118`. **The plan §2's `ContentView:53/:84` cites are STALE → actual `:76-120`.**
- **2.4-D3 Android weakened:** `LandingScreen.kt:111-116`'s comment claims a logged-out finder has "NO Android activation path (no DeepLinkLoginPrompt analogue)" — a comment, so Rule-3 HYPOTHESIS, but the D3 read should now expect to surface a **gap**, not find a primitive.
- **E2 hypothesis strengthened:** `ContentView.swift`'s stem-hit is `DeepLinkScannedPetView` (`:437`) — a live, different type. Attribution still owed per-symbol in Read E.
- Any iOS destination hosting the scanner (2.3b's scan action) **re-enters the modal-over-modal law** (dismiss-on-flag class).

## Proposed B/C/D re-scope (pending review — not executed)

- **ADD:** iOS `RootRoute.swift` (small) — resolves the HYPOTHESIS, decides (a) vs (c).
- **SHRINK:** `AlertsTabScreen.kt` to a params-only look — under the root-route shape the board arm can bypass it; the "2 unused VMs" claim still gets checked so `LostAndFoundScreen`'s standalone viability is known.
- **UNCHANGED:** B1 (`AlertsTabView` whole — it is the surface to relocate), all of C, D1/D2.
- **SHARPEN:** D3-Android reads for a gap, not a primitive; F1's re-point targets become the named `nav = nav.enter…` binding (Android) and the named handler at `ContentView:48` (iOS).
