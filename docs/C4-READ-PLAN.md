# C4-Android Read Plan (1.2b landing content — the Android mirror of C3)

**Provenance:** produced by CC 2026-07-17 (Rule 2), refined by the review seat the same day.
**Spec §E C4 already EXISTS (`phase-1-spec.md:232`)** and was amended 2026-07-17 with the device-findings-to-verify and the C4b split. This read plan is the **execution detail behind that amended §E** — the concrete reads that resolve its "verify in Kotlin" items. **§E is the owner; where they differ, §E wins.** Delete this file once its reads are folded back into §E.

**The incoming CC re-confirms this against the current spec and board before executing.** Cites drift — §9.4 caught C1's gate line-drifting 13 lines off its cite, and the iOS `PetsListView` lift cite `:436-465` was stale by the time C3 built. **Re-ground every `file:line` by symbol (`grep -n`), never by trusting the number written here.** Rule 2 governs: output the read plan, stop for review, do not conclude before it is reviewed. Anything concluded outside these ranges is a guess — say so.

---

## Read A — the read that decides C4's SHAPE (do this first, before the crash reads)

One fact determines whether C4 inherits 0, 1, or 2 of the iOS regressions:

**A1. How does Android present a full-screen surface from the landing?** — a Nav destination (route push), a `Dialog`, a `ModalBottomSheet`, or a full-screen Composable swap? Read `LandingScreen.kt` and the nav host (`PetSafetyApp.kt` / `RootRoute.kt`).
- **Nav destination (route push):** Compose scaffold/overlay semantics differ from a SwiftUI cover — the host's overlays may **not** be occluded, and G-scanfeedback's law may not transfer. C4 could be simpler than C3.
- **Dialog / full-screen overlay above the host:** C4 inherits both iOS regressions (occluded dismiss, occluded spinner) and must carry the close affordance **and** the lookup indicator into the presentation, exactly as iOS did.
- **Verify, do not assume the mirror.** This read reframes everything after it.

---

## Reads B — crash / blast-radius (a wrong wiring claim here is a runtime crash, not a lint nit)

**B1. `ui/screens/LandingScreen.kt` — whole file.** Does populating it change the composable's parameters? Spec §C4 says Zone 2 routes to the `showOrderTagsScreen` pre-auth branch. Decides whether `PetSafetyApp.kt`'s call site enters C4's blast radius (the Android analogue of iOS `ContentView:36-39`).

**B2. `ui/screens/QrScannerScreen.kt` — declaration + whole composition.** Spec §C1:65 / §C4:228 claim it "needs only the app-level `AppStateViewModel`." **That is a Rule 1 wiring claim in Kotlin nobody has checked** — the iOS equivalent (`OrderMoreTagsView`'s "no authed deps") was FALSE. Read what it actually hoists: `hiltViewModel()`, a passed `AppStateViewModel`, any `LocalContext`/session singleton, any VM whose `init` assumes a session. A logged-out landing presenting a scanner that assumes a session is C4's crash. Grep the whole composable body, not just the signature — a dependency on a nested child crashes as hard as one on the root (enumerate-the-callee corollary). This read also covers the deferred G11 camera-permission sub-decision (§6 says read `QrScannerScreen.kt:140-155` before ruling).

**B3. `ui/screens/FoundPetFormScreen.kt` — declaration + params.** Confirm auth-optional, the mirror of the iOS `FoundPetFormView` finding. Two-ended.

**B4. The order path — `showOrderTagsScreen` and what it presents (`OrderTagsScreen`?).** iOS's `OrderMoreTagsView` needed two env-objects re-injected at the presentation site. Compose has no `@EnvironmentObject`; the analogue is a Hilt scope or a passed VM. Read what the order surface requires and whether the landing can supply it logged-out. This is the Android mirror of the highest-value iOS finding — **expect the spec's "no authed deps" claim to be wrong until proven right.**

---

## Reads C — the G-scanfeedback verification (the inherited law, both ends in Kotlin)

**C1. Lookup-feedback + scan-result presentation.** The Compose analogue of iOS's `DeepLinkService.isLookingUpTag` + `ContentView`'s `.overlay`/`.sheet`. G11 (§6) traced part of this: `QrScannerViewModel.lookupAndRoute` is the writer, `scanResult` the state. Read: **where does the scan result present** (a host-level composable, a nav route, a dialog?), and **where does any loading indicator live** — at the host, or already inside the scan surface? If the host draws them and Read A says the presentation occludes the host, C4 inherits the occlusion. This is the read that tells C4 whether it inherits **one** regression or **two**.

---

## Reads D — primitives + parity

**D1. `ui/components/CommunityEntryCard.kt` (new, per §D.2) lift sources:** `ui/components/BrandCard.kt:30-56` and `PetFriendlyPlacesScreen.kt:404-422` (§B.2). Re-ground by symbol. Plus `BrandButton.kt:42-98` / `SecondaryButton.kt:105-134` (Zone 1/2 CTAs) and `DesignTokens.kt` (AppSpacing/AppRadius). Confirm each primitive exists and gets its true line, replacing the cites here.

**D2. `res/values*/strings.xml` — the 6 approved keys' Android parity.** HU is already written and shipped on iOS (`landing_scan_cta`, `landing_found_stray_cta`, `landing_order_subtitle`, `landing_order_cta`, `community_section_title`, `community_lost_found_subtitle`); C4 reuses the SAME HU strings. A `grep -c` per locale confirming Android's locale set matches, and that `landing_sign_in` / `community_*` title twins are **not** minted here either — the iOS §F key-reuse ruling applies: reuse `log_in`/`register` and the shipping community title/subtitle keys; mint `community_lost_found_subtitle` only, for the same logged-out-context reason (the existing lost-and-found description carries an owner-facing clause wrong for a finder). Rule 4: counts, never eyeballed literals.

**D3. `ui/screens/CommunityEntry.kt` (new, per §D.2) + `RootRoute.kt` (C2's committed seam).** The enum/descriptor shape, and the route the Zone-3 intent emits into.

---

## Reads E — test strategy (settle before code; Android differs from iOS here)

**E1. Android may be able to automate what iOS could not.** iOS could not automate the tap→present tests — no ViewInspector, and no launch-state hook to reach a logged-out landing. C2's `AuthBackAffordanceTest` pressed a **real** chevron on a **real** screen via a Compose UI test. Read whether `createComposeRule` / `createAndroidComposeRule` can drive the landing's Zone-1 tap and reach a logged-out state. If it can, the tap→present test iOS declared device-QA may be **automatable** on Android. **Do not assume the iOS device-QA verdict transfers** — this is a place the platforms genuinely diverge.

**E2. The Compose dead-button trap (PROTOCOL §7 Android law).** `mutableStateOf` recomposes only on `.value` reassignment. A nav-state mutation that leaves `.value` untouched does nothing — the button does nothing — and every pure-value test still passes. This is the Android analogue of the iOS `cardInvokesItsTapClosure` gap that only a device closed. The Zone-3 card tap → intent emission must be verified to actually **recompose / navigate**, not merely to store a closure. Name in the test strategy which assertion proves the *wiring* versus the *value*.

---

## Explicitly OUT (same walls as C3)

Zone 3 destinations (emit-only, resolved in Phase 2); `PetsListScreen` / `MainTabScaffold` edits (G10 dedup deferred); the dormant `AlertsScreens.kt` / `PricingScreen.kt`; `isAuthenticated`'s derivation (§2 — its computation is untouchable; supplying a dependency is a seam, a derivation change is not); invoicing (§6 hard boundary — a compile error there is not yours to fix).

---

## The one ruling owed before C4 is built

**G11 / C4 scope — RULED 2026-07-17: SEPARATE (C4b), with a documented trigger.** C4 is the **clean mirror**; G11's seeded-scan close is **chunk C4b** — its own §E amendment, its own cold-kill device-QA, its own unresolved camera-permission sub-decision (§6.11). **Trigger to reconsider:** *only if* Read A shows Android presents the scanner as a surface C4 builds anyway **and** B2 shows G11's close is a pure `LaunchedEffect(savedQrCode)` seeding with no new permission complication — then it may fold into C4. Absent both, it stays C4b. Mirrored in spec §E C4. **Not a mid-chunk discovery — decided.**
