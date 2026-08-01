# Senra Mobile Redesign — Phase-1 Chunk Spec

> **Companion to** [`../SENRA-MOBILE-REDESIGN.md`](../SENRA-MOBILE-REDESIGN.md) (the tracked plan). Written against **rev-4**: Q5 = **Shape A** three-zone landing is locked (§2); this spec honors guardrails **G-a** (no "coming soon" placeholders) and **G-b** (reuse existing components / surface a gap — resolved below, no gap).
> **Status:** SPEC ONLY — no feature code, no branch, no build. The build loop starts after chat review + Viktor approval.
> **Scope guard:** never touches `MainTabView`/`MainTabScaffold` internals, the authed order path, or anything invoicing.
> **Revisions:** 2026-07-10 (spec-tightening) — §C.0 recast as a release-coherence **dependency** (revisit-if-phased clause); §E C1/C2 add `backFromAuthReturnsToLanding` + an auth/register flag-interaction verify note. · 2026-07-10 (§G cleanup) — §G's three confirmations all resolved (release-coherence→§C.0; subtitle→build `CommunityEntryCard`; splash→**split per platform**) and §G retitled "all resolved." · 2026-07-10 (§A.1 hedge removed) — firmed the C0-granularity sentence to match locked §G #3 (split per platform).

---

## A. Sub-chunk breakdown, splash granularity, and build order

### A.1 Finalized chunks (refines the doc's a/b steer)
The rev-4 steer (1.1a/1.1b iOS, 1.2a/1.2b Android) is confirmed, with **one change: splash is pulled out as its own tiny leading chunk (C0).**

| Chunk | Platform | What | Risk |
|---|---|---|---|
| **C0 — Splash** | both | Pure-visual splash refresh (iOS `SplashScreenView`; Android `Theme.PetSafety.Splash`) | Lowest — no routing/auth |
| **C1 — 1.1a** | iOS | Shell/routing: Option-A gate branch → minimal `LandingView` scaffold; **carries the logout/session-expiry acceptance checks** | Structural (behavior-changing) |
| **C2 — 1.2a** | Android | Shell/routing: `screenKey` `"landing"` branch → minimal `LandingScreen` scaffold; **carries the acceptance checks** | Structural |
| **C3 — 1.1b** | iOS | Landing content: three zones + `CommunityEntryCard` + data-driven Community list | Iterative visual |
| **C4 — 1.2b** | Android | Landing content: three zones + `CommunityEntryCard` + data-driven Community list | Iterative visual |

**Splash decision — its own leading chunk (not folded into "a").** Rationale: splash is pure-visual, isolated, zero routing/auth surface, and the two platforms diverge (iOS refreshes `SplashScreenView` in place; Android has only the system SplashScreen theme). Making it the first chunk gives the safest possible warm-up, keeps the visual splash diff off the structural routing diff, and yields an easy first reviewed/committed unit. C0 is split per platform (decided — see §G #3): C0-iOS then C0-Android, committed as two separate units.

**Chunk numbering after C4b (RULED 2026-07-21, Viktor): numbers follow build order.** **C5 (iOS) / C6 (Android) = G-landing-submit** — the found-pet submit confirmation at the landing's presentation sites (§6's gap row + the 2026-07-21 three-reads findings are the contract seed; the §E C5/C6 contract landed the same pass). **F3 (landing restyle) renumbers to C7/C8 when specced** — DEFERRED behind the Phase-2 destinations (plan §2). F3 had no parked §E entry at ruling time (verified: zero `C5`/`C6`/`F3` matches in this file).

### A.2 Recommended build order — **layer-complete, iOS-leads-each-layer**
`C0 → C1 (1.1a) → C2 (1.2a) → C3 (1.1b) → C4 (1.2b)`

**Rationale (recommended over iOS-complete-first `1.1a→1.1b→1.2a→1.2b`):**
- The **structural "a" layer is where all the cross-platform risk lives** (the auth gate + the logout/expiry behavior change). Doing both a-chunks back-to-back surfaces any structural asymmetry — e.g. the Android `TokenAuthenticator` expiry path vs the iOS optimistic mid-session bounce — *before* either platform's visual content is built on top. iOS-complete-first would only reveal an "a"-layer problem after iOS is fully done.
- **iOS leads each layer** because it is the reference platform, lower-risk, and refreshes in place (existing `SplashScreenView` + `WelcomeView` to lift from). It proves each layer's approach; Android (build-new) then mirrors a proven pattern, reducing rework.
- The **"b" layer has no cross-platform coupling** (independent visual work + the shared `CommunityEntryCard` pattern, proven on iOS in C3 then mirrored in C4), so it is safe to do after both shells are solid and tested.

---

## B. G-b resolution — component reuse (the hard gate, RESOLVED: no gap)

Both platforms resolve to **path (ii)**: no pre-extracted reusable entry-card exists, so build a **thin `CommunityEntryCard`** composed from existing, named design-system primitives. This is reuse-compliant (a composition over shipping primitives), **not** a net-new styled component (iii).

### B.1 iOS — `CommunityEntryCard` (icon + title + subtitle + chevron, tap)
- **Card surface:** `.elevatedCard()` / `ElevatedCardModifier` — `Utilities/AppColors.swift:247-261` & `:273-275` (the sanctioned equivalent of the hand-rolled `systemBackground + cornerRadius 16 + soft shadow` at `PetsListView.swift:466-469`). (`.softCard()` `:227-241`/`:267-269` if the cream variant is chosen.)
- **Row layout (lift, don't reinvent):** the inline Success-Stories card body — `Views/Pets/PetsListView.swift:436-465` (HStack: 60pt tinted `Circle` icon disc + `VStack{ title .appFont(17,.semibold), subtitle .appFont(14) .mutedText }` + `Spacer` + `chevron.right`), wrapped in `Button`/`NavigationLink`.
- **Tokens:** `Color.cream`/`.softBorder`/`.mutedText`/`.ink`/`.brandOrange` + `.appFont(size:weight:)` (all `AppColors.swift`); `AppSpacing`/`AppRadius`.
- **Zone 1/2 CTAs (direct reuse):** `PrimaryPillButtonStyle` `AppColors.swift:169-199`, `SecondaryPillButtonStyle` `:203-222`.

### B.2 Android — `CommunityEntryCard(icon, title, subtitle, onClick)`
- **Clickable container:** `BrandCard(onClick = …)` — `ui/components/BrandCard.kt:30-56` (already a clickable cream surface: border + shadow + `AppRadius.lg`; nest a `Row` in its `ColumnScope`). Equivalent: `Modifier.softCard()` `DesignTokens.kt:76` + `.clickable{}`.
- **Row layout (lift):** the proven `PetFriendlyEntryCard` template — `ui/screens/petfriendly/PetFriendlyPlacesScreen.kt:404-422` (leading `Icon` tinted `BrandOrange` + `Column{ title SemiBold, 12sp subtitle onSurfaceVariant }.weight(1f)` + trailing `Icons.Filled.ChevronRight`).
- **Tokens:** `AppSpacing`/`AppRadius` `DesignTokens.kt:21`/`:31`.
- **Zone 1/2 CTAs (direct reuse):** `BrandButton` `ui/components/BrandButton.kt:42-98`, `SecondaryButton` `:105-134`.

### B.3 Scope boundary (minimal blast radius)
`CommunityEntryCard` is built **standalone for the landing only.** Phase 1 does **NOT** refactor `PetsListView`/`PetsListScreen` to consume it — that would touch authed-home internals (inside `MainTabView`/`MainTabScaffold`) and widen the blast radius. The pre-existing inline duplication (Success-Stories + Pet-Friendly cards on both platforms) is recorded as a **deferred dedup opportunity in the tracked doc §6 (G10)** — documented, not actioned here.

### B.4 One confirmation for chat (iOS only)
`ProfileMenuRow` (`Views/Profile/ProfileView.swift:235-268`) is the only pre-extracted struct that is close (icon + title + chevron + tap) but has **no subtitle**. Shape A (§2) requires a subtitle, so (ii) stands and we build `CommunityEntryCard`. *If* chat decided the Community entries should be subtitle-less menu rows, the verdict would flip to (i) direct `ProfileMenuRow` reuse. **Default: keep the subtitle, build the card** (per §2). Flagging only because it is the single thing that would change the approach.

---

## C. The cross-phase seam — every Phase-1 tap has a defined, tested behavior

**DEPENDENCY (confirmed 2026-07-10):** the redesign ships as a **single coherent release** — Zone-3 destinations are live (via Phase-2 read-decoupling) **before any user sees the landing**; the landing is **not** shipped to users chunk-by-chunk. Chunks are still committed + tested individually, but no dead CTA ever reaches a user. **If the release model ever changes to a phased user rollout, the Zone-3 seam design (built-but-intent-only cards) MUST be revisited.** The seam rests on this dependency, so a change to the release model should trip a review rather than silently break it.

### C.1 Zone 1 + Zone 2 — wire LIVE in Phase 1 (both platforms)
These destinations are already anonymous-reachable and their views carry **no authed dependencies** (per §5.2), so the landing presents them directly — no Phase-2 work required:
- **Scan a tag** → present the scanner (`QRScannerView` / `QrScannerScreen`) from the landing. Both scanner VMs have zero authed deps (§5.2); iOS `QRScannerView` has no `@EnvironmentObject`, Android `QrScannerScreen` needs only the app-level `AppStateViewModel` (available outside the shell). Present modally/full-screen from the landing — **not** placed in the tab scaffold.
- **I found a stray** → present `FoundPetFormView` / `FoundPetFormScreen` (auth-optional by design, anonymous manage-token) from the landing.
- **Order a tag** (Zone 2) → route to the existing pre-auth order flow (`OrderMoreTagsView` / the `showOrderTagsScreen` branch), which is already reachable logged-out. *(The guest-checkout dead-end is Phase-3 / G5 — the flow is reachable; do not fix it here.)*

### C.2 Zone 3 — Community cards: built + tested intent, destination wired in Phase 2
Board (2.3) and Pet-friendly (2.4) are **not decoupled until Phase 2**, and they are **public-by-intent** — so a login prompt on them (option a) would contradict the locked "reads are anonymous" decision, and an inert card (option b) is a dead CTA. **Chosen: a bounded form of (c).**

**Decision:** In Phase 1, each `CommunityEntryCard` is fully built (G-a: the section renders complete, two entries) and its tap **emits its descriptor's navigation intent** (`onNavigate(entry.destination)`). The **destination resolution** — rendering the board/places screens for logged-out users — is delivered by **Phase-2 read-decoupling of 2.3 (board list) and 2.4 (places)**, which is the single explicit **Phase-1 → Phase-2 dependency edge**. The read-decoupling itself stays in Phase 2 (it is *not* pulled into 1.1b/1.2b); only the intent-emitting card is Phase 1.

**Why this is not a dead CTA:** the card's behavior *is* defined and unit-tested — "tap card *i* → `onNavigate(destination_i)`." What Phase 2 adds is the router handler for those intents. The landing is not released to users until those handlers are live (C.0 assumption). This honors: no login-wall on public reads, no untested/ambiguous tap, and clean phase separation (the read-decoupling stays in 2.3/2.4).

### C.3 Testability of the seam
- Phase 1 (C3/C4): assert `onNavigate` fires with the correct `destination` per card (unit test), and that Zone-1/Zone-2 taps present their live destinations.
- Phase 2 (2.3/2.4): assert the router resolves each `CommunityDestination` to the now-anonymous screen.

---

## D. Community-list data shape (Zone 3 is data-driven, per §2)

A descriptor array → cards. Adding a future community feature = append one descriptor + add its destination case + its route handler. **No landing-layout change.** Seed with exactly the two current entries.

### D.1 iOS
```swift
enum CommunityDestination { case lostAndFound, petFriendlyPlaces }

struct CommunityEntry: Identifiable {
    let id: String            // stable key: "lost_and_found" | "pet_friendly"
    let systemImage: String   // SF Symbol
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey
    let destination: CommunityDestination
}

// Seed (the only two today):
static let seed: [CommunityEntry] = [
    .init(id: "lost_and_found", systemImage: "exclamationmark.triangle.fill",
          titleKey: "community_lost_found_title", subtitleKey: "community_lost_found_subtitle",
          destination: .lostAndFound),
    .init(id: "pet_friendly", systemImage: "mappin.and.ellipse",
          titleKey: "community_pet_friendly_title", subtitleKey: "community_pet_friendly_subtitle",
          destination: .petFriendlyPlaces),
]
```
Render: `ForEach(CommunityEntry.seed) { entry in CommunityEntryCard(entry: entry) { onNavigate(entry.destination) } }`.

### D.2 Android
```kotlin
enum class CommunityDestination { LOST_AND_FOUND, PET_FRIENDLY_PLACES }

data class CommunityEntry(
    val id: String,
    val icon: ImageVector,
    @StringRes val titleRes: Int,
    @StringRes val subtitleRes: Int,
    val destination: CommunityDestination,
)

// Seed (titles/subtitles REUSE existing Android keys; only community_lost_found_subtitle is minted — see §E C4):
val communitySeed = listOf(
    CommunityEntry("lost_and_found", Icons.Filled.Warning, R.string.lost_and_found_title,
                   R.string.community_lost_found_subtitle, CommunityDestination.LOST_AND_FOUND),
    CommunityEntry("pet_friendly", Icons.Filled.Place, R.string.pet_friendly_title,
                   R.string.pet_friendly_entry_subtitle, CommunityDestination.PET_FRIENDLY_PLACES),
)
```
Render: `communitySeed.forEach { CommunityEntryCard(it.icon, stringResource(it.titleRes), stringResource(it.subtitleRes)) { onNavigate(it.destination) } }`.

*(Icon type differs by platform — SF Symbol `String` vs `ImageVector` — intentionally platform-native.)*

---

## E. Per-sub-chunk specs

### C0 — Splash refresh (both platforms, pure-visual)
> **⚠️ Superseded during build (2026-07-12) — see master §9.5/§9.6.** C0 shipped as a **launch-screen + splash redesign**, not a pure-visual refresh: the launch screen / system splash is now **bare** (logo removed), and the splash is the **plain "X" mark** (`LaunchLogo` iOS / `splash_mark` Android) holding **2.0s** (not 0.8s). The "~0.8s handoff" and "localized-logo" contracts below were **deliberately superseded** (bare launch → the splash is the single branded moment; the mark is language-neutral and crisper). File sets grew accordingly (iOS `LaunchScreen.storyboard` + tests; Android `themes.xml`×2 + `SplashScreen.kt` + the `PetSafetyApp.kt` gate + `splash_mark` + tests).
- **Files:** iOS `Views/SplashScreenView.swift`. Android `res/values/themes.xml` + `res/values-night/themes.xml` (`Theme.PetSafety.Splash`); optional new post-splash composable.
- **Precise edit:** refresh the splash visual (gradient/animation/refined logo lockup) while **preserving the contracts**: iOS keeps the `~0.8s → onFinished()` handoff and `PetSafetyApp.showSplash` gate untouched; Android keeps `installSplashScreen()` in `MainActivity` and the `postSplashScreenTheme` handoff.
- **Must NOT touch:** any routing/auth; `ContentView`/`PetSafetyApp` gate; `MainActivity` routing logic.
- **Tests:** primarily **visual review** (splash is timing/visual). Smoke: iOS — `SplashScreenView` renders `LocalizedLogo.imageName` and invokes `onFinished` (existing testable closure); Android — `Theme.PetSafety.Splash` resource resolves and `MainActivity` still installs the splash. *(Inconclusive to unit-test the animation itself — resolved by visual QA sign-off.)*
- **Done-when:** refreshed branded splash; existing splash→content handoff still fires; no routing/auth change; visual review approved.

### C1 — 1.1a iOS shell/routing (+ acceptance)
- **Files:** `App/ContentView.swift` (gate — **re-confirmed `:16-33`**; `@State showRegistration` `:11`; `.animation(value: isAuthenticated)` `:38` + `value: showRegistration` `:39`; the spec's old `:15-33` was stale); **new `App/RootRoute.swift`** (the routing seam — below); new `Views/Landing/LandingView.swift` (minimal scaffold: persistent Sign-in / Register CTAs + empty zone containers; **no "coming soon"**, G-a). **⚠️ Spec amendment (2026-07-12, approved):** C1 adds `RootRoute.swift` because §9.1 (no ViewInspector) makes an inline `else if` chain over `@State` **not introspectable** — all four verbatim tests would be impossible. The seam extracts **branch selection only**; auth/session derivation is untouched. **⚠️ Amendment (2026-07-14, approved):** the C1 build + review also added `Views/Auth/AuthenticationView.swift` and `Views/Auth/RegistrationView.swift` (each gains an `onBack` back-to-landing affordance — login/register became overlays above the landing default, so each needs its own exit, not just a lateral switch) and `ViewModels/AuthViewModel.swift` (four defaulted test seams — see the boundary refinement in **Must NOT touch** below).
- **The seam (`App/RootRoute.swift`) — pure router + an unrepresentable-illegal-state overlay:**
  ```swift
  enum RootRoute: Equatable { case main, register, login, landing }
  enum AuthOverlay: Equatable { case none, login, register }   // both-true is UNREPRESENTABLE

  static func resolve(isAuthenticated: Bool, overlay: AuthOverlay) -> RootRoute {
      if isAuthenticated { return .main }
      switch overlay { case .login: return .login; case .register: return .register; case .none: return .landing }
  }

  struct RootNavState: Equatable {                 // value type in @State — no ObservableObject/Combine
      private(set) var overlay: AuthOverlay = .none
      mutating func enterLogin()    { overlay = .login }
      mutating func enterRegister() { overlay = .register }
      mutating func dismissAuth()   { overlay = .none }
  }
  ```
  `ContentView` computes `let route = RootRoute.resolve(isAuthenticated: authViewModel.isAuthenticated, overlay: nav.overlay)` and **`switch`es on `route`** (no inline `else if`). **`overlay` must reset to `.none` when `isAuthenticated` flips true** (see the stale-overlay test). **Collapse the animations:** replace the two `.animation(value:)` at `:38/:39` with a **single** `.animation(.easeInOut(duration: 0.3), value: route)` (one `Equatable` route → one transition).
- **Must NOT touch:** `MainTabView` internals; the **computation of `isAuthenticated`** in `AuthViewModel`/`KeychainService` (its gate logic + the `logout()`-on-fetch-failure) — that stays exactly as-is. **Boundary refinement (2026-07-14, approved — applies to C2 too):** *`isAuthenticated`'s computation is untouchable; supplying a dependency through a defaulted parameter is a seam, not a derivation change.* Under this rule C1's four defaulted seams on `AuthViewModel` (`hasStoredToken` / `fetchCurrentUser` / `connectSSE` + the `authCheckTask` handle) are in-bounds — zero production call-site changes, production byte-identical. Also off-limits: the authed order path; invoicing.
- **Tests (Swift Testing; ViewInspector-free — assert on `resolve` + `RootNavState` + the existing `AuthViewModelTests` harness):**
  - `landingIsDefaultWhenLoggedOut` — `resolve(isAuthenticated: false, overlay: .none) == .landing`.
  - **[VERBATIM — §4 1.1a]** `logoutRoutesToLanding` — `logout()` → `isAuthenticated=false` (existing `AuthViewModelTests`), then `resolve(false, .none) == .landing`.
  - **[VERBATIM — §4 1.1a]** `sessionExpiryRoutesToLanding` — drive the **mid-session bounce** in `AuthViewModelTests` (`checkAuthStatus` sets authed on token presence → throwing `getCurrentUser()` → `logout()`) → assert `isAuthenticated == false`, then `resolve(false, .none) == .landing`.
  - `landingSignInCTAOpensAuth` (`enterLogin()` → `resolve(false, .login) == .login`); `landingRegisterCTAOpensRegistration` (`enterRegister()` → `.register`).
  - **[VERBATIM — §4 1.1a]** `backFromAuthReturnsToLanding` — `dismissAuth()` → `resolve(false, .none) == .landing`.
  - **Mutual exclusion (semantics guard):** `enterRegister()` then `enterLogin()` → `overlay == .login` (both-true is already unrepresentable by the type).
  - **NEW — `staleOverlayDoesNotSurviveLogout`:** `enterRegister()` → authenticate (`isAuthenticated=true` ⇒ overlay resets `.none`) → `logout()` → `resolve == .landing`. *(The bug the inline chain hid: register→authed leaves the overlay set, so a later logout would route to `.register`, not `.landing`.)*
- **Done-when:** default logged-out state is `LandingView`; both acceptance checks pass (logout + mid-session expiry → `LandingView`); Sign-in/Register CTAs route correctly; **back-from-auth returns to `LandingView`**; `MainTabView` untouched.

### C2 — 1.2a Android shell/routing (+ acceptance)
- **Files:** `ui/PetSafetyApp.kt` — the `screenKey` `when`-block, **re-based post-C0 to `:294-299`** (⚠️ 2026-07-12: C0-Android wrapped the app in a splash gate `Crossfade (:283) → Box (:287) → Scaffold (:288)`, so the block moved down ~19 lines and is indented **two levels deeper** than the snippet below; the inner `AnimatedContent` `when (target)` that routes screens is at ~`:301-325`). **Treat the snippet as the _logical_ change, not a top-level paste.** Plus new `ui/screens/LandingScreen.kt` (scaffold, same minimal contents; no "coming soon") and **new `ui/RootRoute.kt`** (routing seam — mirror of iOS `RootRoute.swift`, §E C1; **spec amendment 2026-07-12, approved**).
- **The seam (`ui/RootRoute.kt`) — pure router + a FOUR-state overlay (Android has an extra branch iOS lacks: the order path):**
  ```kotlin
  enum class RootRoute { MAIN, ORDER_TAGS, REGISTER, LOGIN, LANDING }
  enum class AuthOverlay { NONE, LOGIN, REGISTER, ORDER_TAGS }   // both-true UNREPRESENTABLE

  fun resolveRootRoute(isAuthenticated: Boolean, overlay: AuthOverlay): RootRoute =
      if (isAuthenticated) RootRoute.MAIN
      else when (overlay) {
          AuthOverlay.LOGIN      -> RootRoute.LOGIN
          AuthOverlay.REGISTER   -> RootRoute.REGISTER
          AuthOverlay.ORDER_TAGS -> RootRoute.ORDER_TAGS
          AuthOverlay.NONE       -> RootRoute.LANDING
      }
  // nav-state holds a single `overlay` (enterLogin/enterRegister/enterOrderTags/dismiss);
  // reset to NONE when isAuthenticated flips true (stale-overlay test).
  ```
  **⚠️ Android is NOT a 3-Bool mirror of iOS.** Today's `screenKey` is four branches / three flags (`showOrderTagsScreen`, `showRegisterScreen`, + the new `showAuthScreen`). The **order path becomes a first-class overlay state (`ORDER_TAGS`)** — NOT dropped, NOT a loose Bool bolted back on (which would reintroduce precedence in the chunk told "do not touch the order path"). `PetSafetyApp` computes `resolveRootRoute(...)` and drives the `AnimatedContent` on it. The order **flow** (OrderMoreTagsScreen, checkout) is untouched — only its branch *selection* moves into the enum.
- **⚠️ C0 interaction (2026-07-12):** the session-expiry dialog now lives **inside** the C0 gate (it surfaces after the splash drops), and the deep-link capture (`pendingQrCode → savedQrCode`) sits **above** the gate. `sessionExpiryRoutesToLanding` here leans on the dialog surfacing post-gate; keep it inside the gated content when adding the `LANDING` branch.
- **Must NOT touch:** `MainTabScaffold` internals; `AuthViewModel`/`AuthTokenStore`/`AuthRepository.isAuthenticated` **derivation**; the order **flow** (its selection moves into `AuthOverlay.ORDER_TAGS`, behavior unchanged); invoicing.
- **Tests (JUnit + Robolectric; assert on `resolveRootRoute` + the nav-state — mirror of C1's five):**
  - `landingIsDefaultWhenLoggedOut` — `resolveRootRoute(false, NONE) == LANDING`.
  - **[VERBATIM — §4 1.2a]** `logoutRoutesToLanding` — post-`logout()` `isAuthenticated=false` → `resolveRootRoute(false, NONE) == LANDING`, not `LOGIN`.
  - **[VERBATIM — §4 1.2a]** `sessionExpiryRoutesToLanding` — the `TokenAuthenticator` one-shot expiry → "Session Expired" dialog + logout → `isAuthenticated=false` → `resolveRootRoute(false, NONE) == LANDING`, **not** `LOGIN`.
  - `landingSignInOpensAuth` (`enterLogin()` → `LOGIN`); `landingRegisterOpensRegister` (`enterRegister()` → `REGISTER`).
  - **[VERBATIM — §4 1.2a]** `backFromAuthReturnsToLanding` — `dismiss()` → `resolveRootRoute(false, NONE) == LANDING`.
  - **Mutual exclusion (semantics guard):** `enterRegister()` then `enterLogin()` → `overlay == LOGIN` (both-true unrepresentable by the type).
  - **NEW — `staleOverlayDoesNotSurviveLogout`:** `enterRegister()` → authenticate (overlay resets `NONE`) → `logout()` → `resolveRootRoute == LANDING`.
- **Must-verify:** `AuthOverlay.ORDER_TAGS` preserves the existing pre-auth order entry (from `AuthScreen`); `resolveRootRoute` + the nav-state are the sole routing authority (no leftover inline `when` over loose flags).
- **Done-when:** default logged-out = `LandingScreen`; both acceptance checks pass; **back-from-auth returns to `"landing"`**; `MainTabScaffold` untouched.

### C3 — 1.1b iOS landing content (+ `CommunityEntryCard`)
- **Files:** `Views/Landing/LandingView.swift` (populate three zones); new `Views/Landing/CommunityEntryCard.swift`; new `Views/Landing/CommunityEntry.swift` (descriptor + `CommunityDestination` + seed); `Resources/*.lproj/Localizable.strings` (all 13 locales, HU canonical) for the new keys (§F).
- **Precise edit:**
  - `CommunityEntryCard` per B.1 (`.elevatedCard()` + the `PetsListView.swift:436-465` row composition + pill/token primitives).
  - **Zone 1:** `PrimaryPillButtonStyle` "Scan a tag" (presents `QRScannerView`) + `SecondaryPillButtonStyle` "I found a stray" (presents `FoundPetFormView`), in a tight top row.
  - **Zone 2:** distinct Order-a-tag CTA (styled distinctly from Zone 1 — e.g. `.elevatedCard()` product block with its own glyph + a `PrimaryPillButtonStyle`), routes to `OrderMoreTagsView`.
  - **Zone 3:** titled "Community" section + `ForEach(CommunityEntry.seed) { CommunityEntryCard(entry:) { onNavigate($0) } }`.
- **Must NOT touch:** `PetsListView` (no dedup refactor — G10 deferred); `MainTabView`; no new styled component beyond the thin `CommunityEntryCard`.
- **Tests (XCTest / UI):**
  - `communityListRendersSeededEntries` — exactly 2 cards, correct titles/subtitles.
  - `communityCardTapEmitsDestination` — tapping card *i* invokes `onNavigate(destination_i)`.
  - `addingDescriptorRendersCardNoLayoutChange` — appending a 3rd descriptor renders a 3rd card (proves data-driven).
  - `zoneOneScanPresentsScanner`; `zoneOneFoundStrayPresentsForm`; `zoneTwoOrderPresentsOrder`.
- **⚠️ Done-when ALSO requires a DEVICE-QA GATE (amended 2026-07-17, C3 build). The 381-green suite is NOT proof of this.** The scan handoff is a **presentation-timing** question — the `Group`/`ZStack` class (§9.8): it compiles, every test passes, and only hardware shows it. C3 presents the scanner as a modal from the landing, so a scan fires one of `ContentView`'s three container-level sheets (`:64`/`:80`/`:95`) **while that modal is up** — a conflict that does not exist today, because the scanner is a tab. `LandingView` dismisses on flag; whether the dismiss→present handshake is clean is unverifiable from source.
  **Four outcomes × three assertions each. Real device, logged-out, cold-opened to the landing — the finder's actual context.**
  Each outcome asserts, by eye: **(1) the scanner is fully GONE** *(a half-dismissed scanner peeking behind a sheet and a sheet-behind-scanner are distinct failure renders — only a look separates them)*; **(2) the CORRECT destination is up**; **(3) it is DISMISSIBLE**.
  - **Active tag + pet** → `showScannedPetProfile` (`DeepLinkService.swift:170`) → public profile.
  - **Tag exists, inactive / no pet** → `showTagActivation` (`:179`) → `DeepLinkLoginPromptView` when logged out (`ContentView.swift:73`).
  - **🔴 Network error / failed lookup** → `showTagActivation` via the `:187` fallback. **FORCE IT** — airplane mode mid-scan, or a bad tag. Do **not** assume it behaves like the success path. It is the outcome nobody thinks to test **and it coincides with the real-world found-stray condition** (bad signal, outdoors). §10's *"merges cleanly so no one is forced to look"* hazard, aimed at the one flow the product exists for.
  - **Promo-batch tag** → `showPromoClaimFlow` (`:165`).
  A QA note saying *"scan works"* does not discharge this gate. It must say **which of the three assertions failed, per outcome, if any did**.
- **Done-when:** three zones render per Shape A; `CommunityEntryCard` built from the B.1 primitives (G-b); Zone 1 + Zone 2 present live destinations; Zone-3 cards emit tested nav intents; **no "coming soon" (G-a)**; new strings localized (HU canonical).

### C4 — 1.2b Android landing content (+ `CommunityEntryCard`)
> **✅ RESOLVED 2026-07-17 by the C4 read (Read A + B2/B3/B4), all two-ended against the Android tree (tip: android `3445784`).** The three "verify in Kotlin" items are now settled Android facts:
> - **G-scanfeedback does NOT transfer.** Android's top-level presentation is an `AnimatedContent` composable-swap (`PetSafetyApp.kt:305-352`), not a cover, and the scanner owns its own feedback (`QrScannerViewModel:41`/`:35` → `QrScannerScreen:121`/`:337`/`:502`); the host `LoadingOverlay` is a **different** source (`appStateViewModel.isLoading`, `:62`), not tag lookup. **No host spinner to hide → the iOS carry-the-spinner fix must NOT be ported.**
> - **The real inherited hazard is the C3 §9.14 dismiss-mirror** — *not* G-scanfeedback and *not* G-scanexit (`PendingRegistrationsView:192`, a separate pre-existing defect). `QrScannerScreen` has no logged-out exit (its only exit is the tab bar; params `:109-116` carry no `onClose`). C4 adds a close affordance **at the presentation site** — an overlay sibling, scanner internals byte-untouched — exactly as iOS `1e70664` did (`QRScannerView` untouched).
> - **Zone-2 order-analogue does NOT transfer.** `OrderMoreTagsScreen(authViewModel: AuthViewModel? = null)` (`:96`) is built auth-optional (`authViewModel?.let` `:189`; `if (currentUser == null)` `:208`) and is already a live logged-out route (`RootRoute.ORDER_TAGS`, `PetSafetyApp:321-330`). Zone 2 is the simplest zone.
> - **G11's seeded-scan close stays chunk C4b (confirmed):** trigger-half (a) met (C4 presents the scanner), (b) not met (the camera-permission prompt `QrScannerScreen:140-145` is §6.11's unresolved sub-decision).

- **Files:** `ui/screens/LandingScreen.kt` (populate); new `ui/components/CommunityEntryCard.kt`; new `ui/screens/CommunityEntry.kt` (descriptor + enum + seed); `res/values*/strings.xml` (all locales, HU canonical); **`ui/PetSafetyApp.kt` — the `RootRoute.LANDING -> LandingScreen(…)` call site only (`:347-350`), additive: hoisted `onOrderTag`/`onNavigate` closures + the app-level `appStateViewModel` param the scanner needs. A seam per the 2026-07-14 refinement — touches nothing in `resolveRootRoute`, the `RootRoute` enum, or the `when`-block (review-seat grep-verifies this boundary on the diff). Pin-3 approved 2026-07-17.**
- **Precise edit:**
  - `CommunityEntryCard(icon, title, subtitle, onClick)` per B.2 (`BrandCard(onClick)` + the `PetFriendlyEntryCard` row template — `PetFriendlyPlacesScreen.kt:403`, leading `Place` icon `:416` / trailing `ChevronRight` `:421`; re-grounded by symbol from the stale `:404-422`).
  - **Zone 1 scan:** local `showScanner` state → in-composition full-screen surface presenting `QrScannerScreen` (passing the app-level `AppStateViewModel`), with a **close overlay at the site** (§9.14 mirror) **and system/edge-swipe back → landing via a `BackHandler`** (device-QA fix `c2bdb45`, §9.17). **⚠️ AMENDED by Viktor's device-QA ruling 2026-07-18/19 (`c2bdb45`):** a scan with no active pet — **NotFound / NotActivated / `NeedsActivation`** — now shows a **centered finder report card** (the outcome message + "I found a pet" → the found-stray form + "Try Again" → resume the live scan); network `Error` keeps its retry snackbar. **`NeedsActivation` no longer auto-jumps to the form** (was `showScanner = false; showFoundStray = true`) — it shows the card, and the finder chooses. NotFound/NotActivated reach the card via the `onTagNotUsable` seam (see Must-NOT-touch); `NeedsActivation` via `onNavigateToActivation`. Still a **context-dependent binding** of the tab's real-activation callback (§3 `handleDeepLink`-is-two-functions hazard), documented at the site + CODEMAP.
  - **Zone 1 found-stray:** local `showFoundStray` state → `FoundPetFormScreen(onDismiss = { showFoundStray = false })` (auth-optional — two-arg ctor `:487`; its own dismiss `:142`). *Base fix presents the form as-is; threading the scanned code into the form is a deferred enhancement — it touches the form signature + VM, out of this ruling's scope.*
  - **Zone 2 order:** reuse `RootRoute.ORDER_TAGS` via a hoisted `onOrderTag → nav.enterOrderTags()`; the route's existing `onBack`/`onDone` return to the landing. **No new local order overlay** (keeps C2's single routing authority).
  - **Zone 3 community:** hoisted `onNavigate(destination)`, emit-only; Phase-2 resolves the destinations.
  - **Localization keys (grounded — supersedes the D.2 Android snippet + §F for C4):** mint **6** keys × 13 locales, HU canonical from the iOS source — `landing_scan_cta`, `landing_found_stray_cta`, `landing_order_cta`, `landing_order_subtitle`, `community_section_title`, `community_lost_found_subtitle`. **Reuse** existing Android keys — `lost_and_found_title` (`:363`), `pet_friendly_title` (`:1660`, the Android name; iOS's is `pet_friendly_entry_title`), `pet_friendly_entry_subtitle` (`:1661`), `log_in`/`register`. **Do NOT mint** the stale D.2 twins (`community_lost_found_title`, `community_pet_friendly_title`, `community_pet_friendly_subtitle`) — reconciles with §9.13's "6 new keys ×13, not 10." C4's Kotlin references the **Android** key names.
- **Must NOT touch:** `QrScannerScreen` internals — untouched **EXCEPT one approved seam** (⚠️ amended 2026-07-19): `onTagNotUsable: ((String) -> Unit)? = null` (device-QA `c2bdb45`, §9.17, **approved by Viktor**). It is necessary because the NotFound/NotActivated outcome is consumed inside the scanner's own `LaunchedEffect`, so **no call-site binding can intercept it** (unlike the close affordance — an overlay needing no param); the tab passes nothing → behaviour unchanged. This is the **Pin-2 pre-blessed conditional** ("if a param proves necessary it must be `defaulted-nullable`"), now triggered. The close affordance and the outcome routing remain **call-site bindings** (the tab uses the same callbacks for its real behaviour). Plus the existing walls: `PetsListScreen` (no dedup refactor — G10), `MainTabScaffold`, the dormant `AlertsScreens.kt`/`PricingScreen.kt` (do not wire), and `resolveRootRoute`/the `RootRoute` enum/the `when`-block (the C2 routing authority — Pin-3's `PetSafetyApp` edit is a call-site seam only).
- **Tests (`compose.ui.test` + JUnit):**
  - `communityListRendersSeededEntries`; `communityCardTapEmitsDestination`; `addingDescriptorRendersCard`.
  - `zoneOneScanPresentsScanner`; `zoneOneFoundStrayPresentsForm`; `zoneTwoOrderOpensOrder`.
- **Done-when:** three zones render per Shape A; `CommunityEntryCard` from the B.2 primitives (G-b); Zone 1/2 live; Zone-3 cards emit tested nav intents; no "coming soon" (G-a); localized per the grounded key map above. **PLUS a DEVICE-QA GATE — logged-out, cold-opened to the landing (source and the suite cannot answer these, per Read A):**
  - **Part A — compositing / feedback-visibility over the CameraX preview:** the close control (visible + tappable), the `ActiveWithPet` in-surface panel, the host `showError` snackbar (covering `NotFound`/`NotActivated`/`Error` — include **one forced failed-lookup**), and the camera-permission UI each **render visibly over the preview**. *(The snackbar is a host-level surface over a local scanner — Read A's flagged z-order, now live; grep `PreviewView.implementationMode` before QA to know whether it is a real hazard — PERFORMANCE/SurfaceView — or a formality — COMPATIBLE/TextureView.)*
  - **Part B — `NeedsActivation` logged-out routing (G-landing-activation):** scan of a `NeedsActivation` tag → **the finder report card** (per the amended Zone-1 scan — NeedsActivation **no longer auto-jumps** to the form), then "I found a pet" → form / "Try Again" → live scan. **⏳ NOT YET EXERCISED** — needs a NeedsActivation fixture (an **ordered, petless, non-inventory** tag: shipped/inactive/lost). **Fixtures (A.2 active tag + B): see [[§9.17]] (F2 resolution — reachable, not latent; recipe + the copy-decision + why B does NOT inherit A.3/A.5's card-rendering pass).**
  - **Part C — direct Zone-1 found-stray present + submit feedback.** Tapping "I found a stray" → the form **presents and is dismissible** logged-out. The unit test `zoneOneFoundStrayPresentsForm` asserts only that the CTA *closure fires* — **the present/dismiss is device-QA**, same class as scan (`zoneOneScanPresentsScanner`/`zoneTwoOrderOpensOrder` likewise assert the closure, NOT the surface swap; the `when`-swap, the `appStateViewModel != null` guard and the G-landing-activation binding are exercised by no test — JVM binds neither CameraX nor `hiltViewModel()` — and are correct-by-construction via `by remember` reassignment). And on submit, the finder **must receive a visible confirmation** — **currently SILENT (see [[G-landing-submit]]): the form dismisses straight to the landing with no feedback, on BOTH platforms.**
  - **`PromoClaimAvailable` is latent** (backend-gated, `QrTag.kt:35`, §9.15 Finding B) — **logged, not tested**; reopens only if promo tags ship.

---

### C4b — 1.2c Android seeded-scan close (G11)

> **APPROVED 2026-07-20 — folded verbatim from the C4b amendment draft (`216b313bd80a`).** Rulings carried: **§6.11 — guard `:149` on `pendingQrCode == null`** (Viktor, 2026-07-19); **clear-site threading — option (a)** (share the single closure); **backdrop — option (i)** (prompt-only guard; the (ii) reasoning is below). **v1's five holes and v2's lifecycle hole were CLOSED by CC's executed read plan (2026-07-20), two-ended, re-grounded at Android tip `c2bdb45`.**

**Trigger satisfied.** §E C4 `:237` recorded the split with two halves: (a) C4 presents the scanner — **met**; (b) the camera-permission prompt is a clean no-op — **not met**, now read and ruled. G11's close is its own chunk, with this amendment and its own device gate.

---

- **Files:**
  - `ui/PetSafetyApp.kt` — hoist `val onQrCodeHandled = { savedQrCode = null }` above the `when`; pass `savedQrCode` + that reference into the `RootRoute.LANDING -> LandingScreen(…)` call site (`:347`); the `RootRoute.MAIN` arm's `:319` inline lambda becomes the hoisted reference. **Argument expressions at call sites only.**
  - `ui/screens/LandingScreen.kt` — `ScannerSurface` (call `:90`, def `:272`) threads real `pendingQrCode` / `onQrCodeHandled` into its `QrScannerScreen(` call (`:296`), replacing C4's hardcoded `null` (`:298`) and `{}` (`:299`); auto-present the Zone-1 scan surface when `savedQrCode != null` at composition. **Plus:** remove or update the now-discharged F2 to-do comment (`:286-292`) — Viktor's 2026-07-19 staging look is the eyeball it asked for, and a satisfied to-do left in place is how the next session re-opens a closed question (Rule 3, inverted).
  - `ui/screens/QrScannerScreen.kt` — **second approved carve-out** (below): guard the `:149-150` permission launch on `pendingQrCode == null`, **written on one line** — `if (pendingQrCode == null) permissionLauncher.launch(Manifest.permission.CAMERA)` — so board §5's guard check greps the whole guarded expression (guard + what it guards), not merely the literal.
  - **`scripts/senra-status.sh` (iOS repo — added by this Files amendment, 2026-07-20):** §5 gains two C4b wiring guards — the mechanised behaviour guard standing in for the un-writable unit test (device-only behaviour + defaulted params; PROTOCOL §6 / the G12b corollary): `grep -c 'pendingQrCode = savedQrCode' PetSafetyApp.kt == 2` (MAIN + LANDING both seeded — the one assertion that C4b is *wired*, not merely present) and the one-line guard grep above `== 1`. **`LandingScreen`'s seeding parameter is named `pendingQrCode`** — the SEED check greps that literal, so a rename would false-red as "INERT"; the name is pinned here so check and contract cannot disagree. **Landed *before* the chunk** (red-until-wired), so no committed chunk is ever missing its guard.
  - **No new strings, no new components, no new route.** G-a and G-b satisfied trivially; if either becomes untrue, surface and stop.

- **Precise edit:**
  - **Seeding.** On the landing, `savedQrCode != null` at appearance auto-presents the Zone-1 scan surface seeded with `pendingQrCode = savedQrCode` — auto-present, **not tap-only** (G11's wording). The hook exists: `QrScannerScreen:153-155` calls `extractTagCode(pendingQrCode)` into `QrScannerViewModel.lookupAndRoute(code: String)` (`:49`) — a raw `String`, never a camera frame. **C4b mints no lookup path and no format contract; both are inherited from the MAIN arm, which already passes `savedQrCode` through the same argument.**
  - **Clearing — timing, not just site.** `onQrCodeHandled()` fires at `QrScannerScreen:156`, **synchronously after** `lookupAndRoute` at `:155` — i.e. *during* the lookup, before the result. LANDING inherits that moment by receiving the same closure. **Do not re-invent the trigger.** The chunk changes *who receives* the closure, never *when it fires*.
  - **Permission guard.** `:149-150`'s `LaunchedEffect(Unit) { permissionLauncher.launch(CAMERA) }` becomes conditional on `pendingQrCode == null`, using the parameter already in the signature. Tab scan passes `null` → guard true → prompt fires as today. Seeded path passes non-null → no prompt.
  - **⚠️ The guard is SHARED, and that is a deliberate, named consequence — not an oversight.** `MainTabScaffold.kt:306-309` presents the *same* `QrScannerScreen` for `TabItem.Scan`, fed from the MAIN arm (`:70-71` → `:196-197`). So an **authed** cold-launch deep-link user also gets no launch on the seeded visit; `hasPermission` stays `false` (`:131`) and their pet sheet composites over the `enable_camera` wall inside the Scan tab, even if camera was granted long ago. **Accepted, not refined** — the wall is the recovery affordance (below), refining costs a new predicate, and the lifecycle read (below) confirms the wall **self-heals on the first tab round-trip**. The "granted months ago" case cannot materialise: nothing retains `hasPermission` across the dispose.

- **Why (i) — prompt-only — and not (ii), suppress-the-wall:**
  - **"Try Again" needs the wall.** It is the report `AlertDialog`'s `dismissButton` (`LandingScreen.kt:337-339`), `onClick = { reportPrompt = null }` — a pure dismiss that reveals the `QrScannerScreen` surface underneath. Under (i) that surface carries the `enable_camera` CTA (`:317-335`) and the finder recovers. Under (ii) it is a neutral backdrop and **"Try Again" is a dead end.**
  - **(ii) is also more edit than it looks.** Because `onQrCodeHandled` fires mid-lookup (`:156`), a bare `pendingQrCode != null` conditional on the render path would flip the wall back in *during* the lookup; stabilising it needs `remember { … }`. (ii) is more code and worse behaviour.
  - **So the backdrop is not a wart to apologise for — it is the intended path back.** This reframes the device gate: D.3 stops asking "does this read as broken" and asks the same legibility question A.1/A.3/A.5 already answered, against a new source.

- **Must NOT touch:**
  - `resolveRootRoute`, the `RootRoute` enum, the `when (target)` block — C2's single routing authority. The MAIN-arm edit is an **argument expression**, not a branch change; the review seat greps this boundary on the diff exactly as C4's was grepped.
  - `MainTabScaffold` internals (PROTOCOL §6). `:306-309` is **read to establish the shared-guard consequence, not edited.**
  - `savedQrCode`'s declaration and `rememberSaveable` hold (`:74`).
  - `isAuthenticated`'s derivation.
  - `PetsListScreen` (G10 deferred), the dormant `AlertsScreens.kt` / `PricingScreen.kt`, invoicing (§6 hard boundary — a compile error there is not this chunk's to resolve).
  - **`QrScannerScreen` internals — byte-untouched except TWO named carve-outs:**
    1. `onTagNotUsable: ((String) -> Unit)? = null` — C4, approved 2026-07-19 (§9.17 FIX 3).
    2. **The `:149` permission guard — C4b, approved 2026-07-19 (this amendment).** Structurally the same case as (1): the effect fires inside the scanner's own composition, so **no call-site binding can intercept it.** That is the Pin-2 condition, triggered a second time. Recorded as an explicit exception rather than absorbed, because a carve-out that is not named becomes a precedent nobody voted for.

- **Board consequence — stated up front, not discovered mid-chunk:**
  - `senra-status.sh` §5 pins `grep -c 'savedQrCode = null' PetSafetyApp.kt` at **1**; a second clear site turns the board red (G11's C2 obligation).
  - Under option **(a)** the literal stays in that file exactly once → **§5 stays green by construction**, contract unchanged.
  - **Done-when includes: board §5 still reports exactly 1 after the chunk.**

- **Tests (`compose.ui.test` + JUnit) — name what each assertion proves:**
  - `RootRoutingComposeTest` (`createComposeRule`, `src/test/`) drives the **real** `LandingScreen`, taps CTAs (`:96`) and asserts surface swaps (`:98`) — so the landing's own state is reachable in JVM. **But the seeded surface is `QrScannerScreen`, which binds CameraX and `hiltViewModel()` and will not compose under JVM/Robolectric.**
  - **Testable — the value:** with `savedQrCode` set, the landing passes a non-null `pendingQrCode` into `ScannerSurface`, and flips its own show-scanner state. *Residual (code-time, not a blocker): confirm that state flip is assertable without composing `QrScannerScreen`. If there is no seam, even this is device-only — that shrinks the testable set, it does not dent the gate.*
  - **NOT testable — the wiring:** auto-present on appearance, the seeded lookup firing, the absence of the permission dialog, the clear, and every composite below. All device.
  - No test may be named `…PresentsScanner`. C4's zone tests assert a **closure fired**, not that a surface **presented**; this project has shipped that overclaim twice. State per test which assertion proves the **wiring** and which proves the **value**.

- **Done-when — DEVICE-QA GATE. Real device, cold-killed, real tag. The simulator cannot do this (Rule 5).**
  - **D.1 — the close itself.** Cold-launch from a real tag URL **while logged out** → landing → scan surface auto-presents seeded → **the public pet profile renders.** This is G11. Nothing else substitutes.
  - **D.2 — no gratuitous prompt.** The seeded path shows **no camera-permission dialog**. This is the ruling, observed.
  - **D.3 — the pet sheet over the wall (the one genuinely new composite).** With permission never granted, the `:190` false branch (`:273 } else {`) renders an **opaque full-screen** surface: `camera_access_required` heading, `camera_access_message`, `enable_camera` CTA (`:275-278`, `:317-335`). `ScannedPetSheet` (`:342`) is a **bottom sheet** compositing over it. **Assert by eye: the pet sheet is legible, complete and dismissible over the `enable_camera` wall.** Same assertion class as A.1/A.3/A.5, genuinely new backdrop — §9.17 is explicit that a pass over a live SurfaceView preview does **not** transfer to a different source. The wall is also what is visible during the lookup window (`else -> {}` is a no-op on `Loading`), so it is one eyeball, not two.
    - *Not in scope for D.3:* the NotFound / NeedsActivation **report card is an `AlertDialog`** (`:322`) with its own platform scrim, so dialog-over-wall is trivially benign and inherits nothing.
  - **D.4 — the second scan, and the wall as the path back.** Dismiss the card ("Try Again", `:337-339`) → the finder lands on the `enable_camera` wall → tapping the CTA (`:317`) prompts → a subsequent live scan works. **This is the intended recovery path, not a failure state.** Verify it completes.
  - **D.5 — the negative case.** Tab scan (`pendingQrCode == null`) still prompts exactly as today. The guard must not silently disable the real scanner.
  - **D.6 — back parity, on a new entry path.** System/gesture back from the seeded surface returns to the landing and **does not exit the app.** C4's FIX 2 added `BackHandler` to both `when`-branches; a new auto-presented entry must not regress it. *(Nothing in the suite catches this — it is why FIX 2 existed.)*
  - **D.7a — authed seeded BASELINE. ✅ PASS, 2026-07-20 (run before any code, as intended).** Cold-kill + intent fired at `MainActivity` while logged in → `savedQrCode` → MAIN → Scan tab → seeded `QrScannerScreen` → `lookupAndRoute` → `ScannedPetSheet` resolves to the pet profile. **The Rule-8 baseline is established: a post-C4b D.1 failure is C4b's own wiring, not a pre-existing defect.**
    - **Scope — read this before citing it.** `am start`-fired, so it exercises the **in-app chain only**. It does **not** cover delivery — App Links verification, the OS handoff, the browser path — which remains §13's standing "real device, real tag, cold-kill" row and is where AASA `/*/t/*`, the www 301 and the Play Console SHA-256 live. Do not let this PASS retire that row.
    - **Provenance:** CC, adb + screenshots. Per §9.17's own precedent, that is a pre-check rather than gate proof; it is recorded here as a baseline, not as a gate row.
    - **Baseline composite observed:** pet sheet over a **live camera preview** (torch control visible). This is the "before" half of the D.7b comparison below.
  - **D.7b — authed seeded POST-code, in the Scan tab.** Same action after the guard lands. Expect the **wall behind the pet sheet** instead of the live preview — that is the accepted shared-guard consequence, **not a regression against D.7a.** D.7a and D.7b are deliberately different composites; record both so the delta is read as designed. **Then the self-heal look:** switch away from the Scan tab and back → the wall is gone and the live preview is restored. This confirms the `Crossfade` dispose/re-enter reasoning **on a device rather than by inference** (Rule 5), and it is one extra tap in a session already running.
  - **Each row states which of the three assertions failed, if any — the surface is GONE / the CORRECT destination is up / it is DISMISSIBLE.** "Seeded scan works" does not discharge this gate.

- **Dependency — satisfied 2026-07-19/20.** C4's **B** (NeedsActivation card via `onNavigateToActivation`, the client `stringResource` that did not inherit A.3/A.5's pass) and **A.2** (`ActiveWithPet`) were exercised on staging: shipped + `pet_id` NULL → the activation card and its links; activated + pet attached → the public profile. B's untested delta is closed. **F2 closed 2026-07-20** by the prod query (3264 tags; zero `inactive`/`lost` + `pet_id NULL`; reachable = `shipped`) — the copy is correct for the reachable state, with [[G-deactivate-authz]]'s snapshot caveat recorded in §9.17. *(Still outstanding from that session: the finder card's "I found a pet" → form tap. "Try Again" is settled by code — a pure `AlertDialog` dismiss, `LandingScreen.kt:337-339`.)*

- **Explicitly OUT:** Zone-3 destinations (Phase 2); threading the scanned code into the found-stray form (deferred — touches the form signature + VM); G-landing-submit and G-session-loggedout (ship-blockers, other owners); G-scanback-ios; iOS parity (iOS never had this bug — G11 is an Android-only parity close); a `checkSelfPermission` pre-check — **ruled out 2026-07-20**, the lifecycle read removed its justification.

---

#### The lifecycle question — RESOLVED 2026-07-20 (self-heal)

**Does `QrScannerScreen` leave composition when the Scan tab is switched away from? — YES.**

`MainTabScaffold.kt:303` wraps the tab `when` in `Crossfade(targetState = selectedTab, animationSpec = tween(200))`. `Crossfade` composes only the current target and disposes the rest once the transition completes; **no `SaveableStateHolder` wraps the `when`** (the only `rememberSaveable` in the file is `showPushPrompt` at `:81`, scaffold-level). This is the same non-retention that makes `Crossfade` drop scroll state on tab switch.

Therefore, on switching back to Scan: fresh composition → `hasPermission` is a fresh `remember { false }` (`:131` — plain `remember`, disposed either way) → `LaunchedEffect(Unit)` fires again → `pendingQrCode` is now `null` (cleared during the seeded visit) → the guard passes → an already-granted user gets the silent callback and their live preview back.

**Consequence:** the authed wall is scoped to the single seeded visit and heals on the first tab round-trip or relaunch. **Ruling: accept and name it. No `checkSelfPermission` refine.** Confirmed on a device by **D.7b**'s self-heal look rather than left as inference.

---

### C5 / C6 — G-landing-submit: found-pet report confirmation (iOS then Android)

> **PHASE-1-SHIP-BLOCKING, both platforms.** Surfaced 2026-07-18 by the C4-Android build (§9.16), confirmed identical on iOS (§9.13's `FoundPetFormView` presented bare from `LandingView`). **A logged-out finder submits a found-pet report and receives nothing** — the form dismisses to the landing with no feedback. The confirmation on the *existing* entry point was the **list-prepend**; the landing has no list, so the confirmation that exists everywhere else is simply absent — on the exact persona the logged-out landing exists for.
>
> **Three reads executed 2026-07-21 (CC), all clean.** They are what makes this specifiable as copy rather than as a behaviour change:
> - **`onSubmitted` fires on SUCCESS ONLY, both platforms.** Android: `LaunchedEffect(state.submittedReport)` at `FoundPetFormScreen.kt:120-122`, and `submittedReport` is written at exactly one site (`:598-605`) inside `submit()`'s coroutine, only when `repository.create(...)` (`:583`) returns non-null; the failure path (`:607-608`) sets `_networkError` and never touches it. iOS: `FoundPetFormView.swift:328-331` — the `await createFoundPet(payload)` precedes `onSubmitted?(report)` (`:330`); a throw jumps to `catch` (`:332-334`), which sets `errorMessage` and neither fires the callback nor dismisses. **A failed submit cannot produce a success message.** This was the risk that would have made the fix bigger than copy.
> - **iOS's delivery mechanism already exists** and is root-level (below).
> - **The confirmation belongs at the two landing call sites, not in the form** (below).

**Ruling — Viktor, 2026-07-21.**

- **HU canonical string, verbatim:**

```
Köszönjük a segítséged! A bejelentést rögzítettük.
```

- **Acknowledge-required on BOTH platforms.** Not transient. **Rationale, on precedent:** C4 FIX 3 replaced *"a bare snackbar on a frozen camera"* with a card the finder must dismiss — same persona, same "did anything happen?" moment, and a submit is the higher-stakes of the two. A finder who submits and pockets the phone never sees a transient.

**Files — iOS (C5):** `Views/Landing/LandingView.swift`; `Resources/*.lproj/Localizable.strings` ×13.
**Files — Android (C6):** `ui/screens/LandingScreen.kt`; `res/values*/strings.xml` — **base + `values-en` + 13** (§9.16 caught this exact chunk a file short once).

---

#### Precise edit — iOS (C5)

- **`LandingView.swift:167`** presents `FoundPetFormView()` **bare** inside `.sheet(isPresented: $showFoundStray)` — no closure bound at all, so `onSubmitted` is `nil`. **Bind it** at that presentation site, firing the confirmation.
- **`appState` is already in scope** — `LandingView.swift:47` declares `@EnvironmentObject var appState: AppState`, and `:174` already re-injects it elsewhere. **No new injection, no new dependency.**
- **`AppState.showSuccess(_:)`** (`PetSafetyApp.swift:348-352`) sets `alertTitle`, `alertMessage = ""`, `showAlert = true`; consumed by `.alert(appState.alertTitle, isPresented: $appState.showAlert)` at **`ContentView.swift:65-68`** — the same root that hosts the logged-out landing, **visible logged out**. It is an existing named primitive already used for checkout successes (`:244-250`). **Acknowledge-required by construction** — an alert with OK, not a snackbar. **G-b satisfied from shipping primitives; nothing is invented.**
- **⚠️ Do NOT touch `FoundPetFormView`.** The authed site binds its own confirmation — `AlertsTabView.swift:85-87`, trailing-closure syntax (`FoundPetFormView { newReport in viewModel.prependLocalFoundReport(newReport) }`, which is why a `FoundPetFormView(` grep reads zero there, §9.13). A confirmation inside the form **double-confirms the authed path**.
- **⚠️ Presentation-timing device look — the one thing source cannot answer.** `onSubmitted` fires at `:330` **before** `dismiss()` at `:331`, so `showAlert` flips while the sheet is still up. **Alert-under-dismissing-sheet is the `Group`/`ZStack` class** (PROTOCOL §7 / §9.8): it compiles, it passes, and only hardware shows whether the alert presents, is swallowed, or arrives late. *Hypothesis if it drops, labelled as such and NOT to be pre-emptively built: the fix would live at the presentation site (e.g. the sheet's `onDismiss`), **never** in the form.*

#### Precise edit — Android (C6)

- **`LandingScreen.kt:125-131`** binds `onSubmitted = { showFoundStray = false }` — dismiss-only. **Add the confirmation there.**
- **Remove or update the in-code comment** at that site documenting the missing list-prepend equivalent. **Rule 3 inverted:** a satisfied to-do left in place is how the next session re-opens a closed question — the same call §E C4b made about the F2 to-do.
- **⚠️ `appStateViewModel.showSuccess(...)` is a snackbar and is therefore INSUFFICIENT ALONE** under the acknowledge-required ruling. The two platforms' `showSuccess` idioms genuinely differ — iOS's is a modal alert, Android's is transient. **This is the one open construction question in the chunk.**
- **Leading reuse candidate — to be read two-ended before it is chosen, not assumed:** the **C4 FIX 3 report card**, an `AlertDialog` already living in this same file (its `dismissButton` at `LandingScreen.kt:337-339`, per §E C4b). If it composes from a named primitive that can carry a success message, that is **G-b-compliant reuse on the same surface, by the same author, for the same persona**. **If it cannot, surface a gap — do not invent a styled component** (G-b). Report which.
- **⚠️ Do NOT touch `FoundPetFormScreen`.** The authed site binds its own prepend — `LostAndFoundScreen.kt:188-191` (`onSubmitted = { vm.prependLocalFoundReport(it) }`).

#### Localization

- **Mint exactly one key.** Proposed `found_pet_reported_success` — **CC confirms against the existing naming convention** and reuses the app's shipping noun for a found-pet report rather than introducing new terminology.
- **HU canonical (verbatim above) → EN derived → remaining 11 via `senra_translate.py`. No hand-written translations.**
- **⚠️ The claim boundary carries into EN and into every locale.** An earlier candidate said the team is *"working hard to find the owner."* **The chosen string deliberately drops that** — nothing has been read about whether the system notifies or matches owners against missing alerts, and copy asserting something the system may not deliver is this project's recurring genre (`INGYENES`, [[G-scan-error-raw]]). The string claims **only that the report was received.** **Do not reintroduce the stronger claim during EN derivation or translation review.**
- **⚠️ Register consistency (HU).** The chosen string uses the **informal** address (`segítséged`, te-form). If the app addresses users **formally** elsewhere (`segítségét`, ön-form), this reads as a register break — invisible to a non-native reviewer, jarring to a native one, and precisely the class §9.17 FIX 1 caught. **CC greps the shipping HU strings and reports which register dominates; Viktor rules.** Informal may well be deliberate — it suits a stranger doing a favour — but it should be a decision, not an accident.

#### Must NOT touch

**The device-bought behaviours in these two files, byte-intact:** the two `BackHandler` branches (C4 FIX 2), the report card and **both** its branches (FIX 3), `onTagNotUsable`, `onNavigateToActivation`, the close overlay at the presentation site, `ScannerSurface`, C4b's auto-present `LaunchedEffect`, and **`pendingQrCode`'s parameter name** (board §5's SEED check greps that literal — a rename false-reds as INERT).

**Plus:** both form components; both authed call sites; `resolveRootRoute` / the `RootRoute` enum / `AuthOverlay` / the `when`-block; `MainTabView` / `MainTabScaffold`; `isAuthenticated`'s derivation; the scanner internals; invoicing (§6 hard boundary). **No new dependencies.**

#### Board guards (landed 2026-07-21, board §5b — BEFORE C5, protecting exactly the files this chunk edits)

**Pinned literals — check and contract cannot disagree (the §E C4b `pendingQrCode` pattern). A rename of any of these false-reds §5b BY DESIGN; re-pin here and in the script together, never separately.** Android, `LandingScreen.kt`, each count == 1: `BackHandler { showScanner = false }` · `BackHandler { showFoundStray = false }` · `onTagNotUsable = { message -> reportPrompt = message }` · `onNavigateToActivation = { reportPrompt = notLinkedMessage }` · `onClose = { showScanner = false }` · `onClick = onClose` · `onDismissRequest = { reportPrompt = null }` · `TextButton(onClick = { reportPrompt = null })`. iOS, `LandingView.swift`: `Button { showScanner = false }` == 1 · `if wants { showScanner = false }` == 1 · the yield's OR pinned **per member**: `deepLinkService.showScannedPetProfile` == 1, `|| deepLinkService.showTagActivation` == 1, `|| deepLinkService.showPromoClaimFlow` == 1 — the `||`-prefixed literals can only match inside the OR chain at `LandingView.swift:66-70`, so each reds if its member leaves the OR even while the flag is read elsewhere in the file; a file-wide aggregate count false-greens in exactly that case (review condition (c), re-scoped per-member 2026-07-21). **Member 1 is unprefixed and pinned at == 1: a future legitimate second read of `deepLinkService.showScannedPetProfile` in this file false-reds it in the SAFE direction — the response is to RE-PIN the expected count here and in §5b together, never to relax or delete the check.** **Two residuals, named so they aren't assumed away (2026-07-21; both fail safe):** (1) the `||` pins are **formatting-dependent** — they match only while `||` and the flag share a line, so a pure reformat of the OR chain (e.g. a trailing-`||` style pass) reds members 2–3 with zero behaviour change; the response is the same RE-PIN, not a relax — and C7/C8 restyles exactly this file. (2) The pins guard the OR-chain **shape file-wide**, not membership in that specific property: a member leaving the yield's OR while the same flag appears in another `||` expression elsewhere in the file would false-green. That requires a coincidence and is far narrower than the aggregate count's hole, but it is the honest description of what the check proves — re-read this when 2.3/2.4 touch deep-link state.

**Zone-3 ship-gates (red-until-wired, whitespace-tolerant because expected-0 checks false-GREEN on renames — the unsafe direction):** `onNavigate *= *\{[[:space:]]*\}` in `PetSafetyApp.kt` == 0, and `Zone-3 intent emitted|handler lands in Phase 2` in `ContentView.swift` == 0. **OBLIGATION — recorded here so it is not forgotten: the moment `phase-2-spec.md` names the two destination handlers, both gates are RE-POINTED to positive assertions** (grep the named handler, expect 1, red-until-wired) — the d85e3d5 pattern correctly applied.

#### Tests

- Every existing landing test passes or is explicitly re-pointed with a recorded reason.
- **The confirmation is a presentation, and no test proves a surface appeared** — JVM binds neither CameraX nor Hilt; iOS is ViewInspector-free (§9.13 (1)). **No test may be named `…Presents…`** (§E C4's standing rule; this project has shipped that overclaim twice). If a closure-fired assertion is added, **state that it proves the closure, not the surface.**
- Force the run (`--rerun-tasks`; read `index.html`, never the console) and grep the artifact for every named criterion, by name (Rule 6).

#### Done-when

1. A **logged-out** finder submits a found-pet report from the landing → the confirmation appears → **it requires acknowledgement** → the landing. Both platforms.
2. String localized, **HU canonical**, base + `values-en` + 13 on Android, 13 `.lproj` on iOS. Zero hardcoded literals.
3. **The authed path is unchanged** — its list-prepend remains its only confirmation. **Verify no double-confirm** on either platform.
4. **⚠️ DEVICE LOOK, BOTH PLATFORMS (Rule 5 — no test can prove any of this).** iOS: the alert-under-dismissing-sheet timing (does it present at all, and is it legible over/after the sheet?). Android: the dialog appears after the form dismisses and is dismissible. **Plus the preservation check** — seeded auto-present, back-to-landing, the report card's both branches still work. *A confirmation that renders correctly and drops `BackHandler` passes every test in both repos.*

#### Explicitly OUT

[[G-foundform-error-raw]] (new row, §6 — different branch, different owner); [[G-session-loggedout]] (auth workstream); [[G-scan-error-raw]]; [[G-tab-scan-noparity]]; F3 (deferred); threading the scanned code into the form (deferred — touches the form signature + VM); any change to the authed confirmation.

#### Sequence

**Board guards land first** — they protect these same two files, and this chunk edits them. Then **C5 (iOS)** → surface diff + hash → byte-review → commit → CODEMAP. Then **C6 (Android)**.

---

### C7 / C8 — F3 landing restyle (iOS then Android) — **DEFERRED, not scheduled**

> **DEFERRED by ruling 2026-07-21 (plan §2):** F3 builds only after Phase 2's 2.3/2.3b/2.4 destinations are live — vertical composition can't be designed against content still being wired. **Do not produce the read plan, and do not build, until the deferral is lifted.** Numbering per the §A.1 ruling: F3 = C7 (iOS) / C8 (Android); C5/C6 = G-landing-submit. *(Pasted 2026-07-21 from the F3 transfer artifact, hash `d2a9d1d3f00a`, verbatim except: the heading and the two Files labels renamed C5→C7 / C6→C8 per that ruling; the transfer's Part 3 board guards are SUPERSEDED by board §5b — landed `25b7057` with tighter full-expression predicates; the transfer's §2 amendment is HELD at the bottom of this section rather than applied, so plan §2 keeps describing the code.)*

> **Provenance, stated because it changes what this chunk is.** F3 was a finding from the C4-Android device gate (moto e15, 2026-07-19). **Its text is lost** — it survived only as one line in `HANDOVER.md` (*"F3 — landing design (logo + vertical spacing), cross-platform, its own chunk"*), a file whose charter is to hold no facts; the full record was in `C4-DEVICE-QA-FINDINGS.md`, which has never existed anywhere on disk or in either history (§9.19). **F1 has no surviving trace at all.** So this chunk executes **Viktor's 2026-07-21 design brief**, not a recovered finding. The one grounded observation adjacent to F3 is §9.16's: the landing *"grew from a 2-button scaffold to a scrollable surface, pushing the persistent CTAs below the fold."*
>
> **Split per platform, two commits** (§G #3; every chunk since C0 has been single-platform). **iOS leads** per §A.2 — override to Android-first with one line if preferred, since the brief is authored in dp and the below-the-fold evidence is Android. Whichever leads, the second mirrors a proven pattern.
>
> **The governing constraint, Viktor 2026-07-21, verbatim:** *"There should be no change whatsoever other than a different style and re-ordering the cards. Every flow, gate etc. stays as is."* Where any item below appears to require a behavioural change, **that is a spec bug — surface and stop.**

**Files — iOS (C7):** `Views/Landing/LandingView.swift`; `Views/Landing/CommunityEntryCard.swift`; `Resources/*.lproj/Localizable.strings` ×13. *(+ the asset catalog only if the mark is not already reachable — see Read 2.)*

**Files — Android (C8):** `ui/screens/LandingScreen.kt`; `ui/components/CommunityEntryCard.kt`; `res/values*/strings.xml` — **base + `values-en` + 13** (§9.16 caught this exact chunk a file short once); `ui/theme/DesignTokens.kt` **only** for named tokens that do not exist (list every one added).

---

#### Precise edit — the seven items

**1 — Header.** Brand mark centred at **52dp/52pt**, wordmark small and letterspaced beneath it, `Belépés` as a compact text link top-right (≥48dp touch target). Mark centred to match the splash mark position; **not** left-aligned.

- **Mark = the existing `LaunchLogo` (iOS) / `splash_mark` (Android) asset.** Language-neutral, transparent, already proven at 200dp on both platforms (§9.6). **Reference it; do not edit any splash file.**
- **Wordmark = the text `SENRA`**, letterspaced. **Not** `LogoNew_<CC>` / `logo_new_<cc>` — that is the *localized image lockup*, which most likely already contains the mark and would stack two marks. CC confirms what the lockup contains before ruling this out.
- **Brand name is not localizable content.** To honour "no hardcoded string literals in composables" without minting 13 identical translations: Android `<string name="brand_wordmark" translatable="false">SENRA</string>` (the flag also keeps `senra_translate.py` off it); iOS a named constant, not an inline literal. **Zero new localized keys for the header.**
- **`Belépés` reuses the shipping `log_in` key.** §F forbids minting `landing_sign_in`; §9.13 (4) records `LandingView.swift:32/:37` has used `log_in`/`register` since C1.
- **Letterspacing:** if no token exists (iOS `Utilities/Font+App.swift`; Android `DesignTokens.kt`), that is a **G-b gap → add a *named* token and list it**, never a magic number at the call site.

**2 — Scan is the only primary CTA.** Saturated brand fill, icon + title + one-line subtitle, radius **20**. Every other saturated full-width button on this screen goes away.

- Title reuses `landing_scan_cta` (minted C3/C4).
- **⚠️ The subtitle is the one likely new key.** §F minted `landing_order_subtitle` but **no `landing_scan_subtitle`**. If the copy does not already exist, mint **one** key — HU canonical (Viktor's native eye; §9.17 FIX 1 was a mistranslation only that caught) → EN → 11 via `senra_translate.py`. **No hand-written translations.**
- **G-b:** compose from existing primitives — iOS `PrimaryPillButtonStyle` (`AppColors.swift:169-199`), Android `BrandButton` (`BrandButton.kt:42-98`) — plus tokens. A pill style may not express radius-20-with-subtitle; **if it cannot, say so and surface** rather than minting a styled component.

**3 — Found-stray becomes a single-line row.** Icon, label, trailing chevron. White surface, hairline border, radius **16**. Reuses `landing_found_stray_cta`; **no new string**. Stops being a saturated button (iOS `SecondaryPillButtonStyle` `AppColors.swift:203-222`; Android `SecondaryButton` `BrandButton.kt:105-134`).

- *Note, so nothing is invented:* this shape is `CommunityEntryCard`'s row minus the subtitle — but item 4 turns that card into a **vertical tile**, so the two genuinely diverge. **Do not force reuse, and do not mint a third row component.** If neither existing primitive fits, that is a G-b gap to surface.

**4 — Community becomes a two-column tile row.** Under a small letterspaced `KÖZÖSSÉG` label: icon, count, label, sublabel. Equal width, **10** gap. **Restyle `CommunityEntryCard` in place** (row → tile). No new component, so G-b is satisfied with no gap.

- **Blast radius must be confirmed, not assumed.** §B.3 says the card was built **standalone for the landing only** and Phase 1 deliberately did not refactor `PetsListView`/`PetsListScreen` to consume it (G10 deferred). **CC greps the callee's call sites** to confirm the landing is the sole consumer — enumerate the callee, not the name (Rule 1 corollary). If a second consumer exists, stop.
- **⚠️ Zone 3 stays data-driven — this is locked in §2 and survives the restyle.** A rendered collection, *"not two hardcoded tiles"*; appending a third descriptor must render a third tile **with no layout edit** (it wraps to a second row). `addingDescriptorRendersCard` / `addingDescriptorRendersCardNoLayoutChange` **must still pass**. A two-column grid satisfies this; two hand-placed tiles does not.
- **Re-ordering the cards = changing the order of the seed array**, nothing else.
- **`community_section_title` already exists** (minted C3/C4). ⚠️ **Do not uppercase in code.** A programmatic upper-case transform is locale-dependent and mangles some locales. Either carry the casing in the string or apply a locale-aware style, and **report any locale whose uppercase form reads wrong**.
- **Reused entry keys (grounded, §E C4 / §9.13 (4)):** Android `lost_and_found_title`, `community_lost_found_subtitle`, `pet_friendly_title`, `pet_friendly_entry_subtitle`. iOS uses `pet_friendly_entry_title` where Android uses `pet_friendly_title`. **Same strings, different key names per platform** — do not "harmonise" them here.
- **Counts:** see *The one thing that isn't cosmetic*, below.

**5 — Order-a-tag (Zone 2) demotes.** Tinted surface, `INGYENES` badge, body copy, text CTA with trailing arrow, no filled button. **This is the existing Zone-2 card restyled in place** (Viktor, 2026-07-21) — not a new surface.

- **Wiring byte-untouched:** Android `onOrderTag → nav.enterOrderTags()` → `RootRoute.ORDER_TAGS`; iOS presents `OrderMoreTagsView`.
- **⚠️ iOS crash risk — the highest-severity item in this chunk.** `OrderMoreTagsView.swift:5-6` declares **two `@EnvironmentObject`s** and **hard-crashes on render** if either is not re-injected at the presentation site (§9.13 (2), the re-injection contract — the spec's old "no authed dependencies" claim was false). Restyling this CTA **must not disturb the injection**. Two-ended cite required on the diff.
- **`INGYENES` is existing shipping copy** (Viktor: *"we have the same text on the current card"*). **Grep for it and reuse its key.** Mint only if the badge word is a fragment of a longer sentence with no key of its own — and then the claim must not change: the tag is free, shipping is paid.
  - *Out of scope, noted once:* whether a "free" claim with mandatory paid shipping needs different treatment across 13 EU markets is a **product/legal** question about copy that already ships. F3 restyles it; F3 does not adjudicate it. Worth a look sometime, by someone qualified — not this chunk, and not me.

**6 — Login/Register leave the bottom.** `Belépés` moves to the header (item 1). `Regisztráció` is removed from the landing.

- **⚠️ GATED ON READ 1. This item does not land until register-reachability comes back non-empty, two-ended.** The risk is not the published login screen — it is that C1/C2 made register an **overlay** reached by `enterRegister()` **from the landing**. If nothing inside `AuthenticationView`/`AuthScreen` reaches `AuthOverlay.REGISTER` / `RootRoute.REGISTER`, removing the landing button **orphans the state and makes registration unreachable for every new user**. Unit tests would stay green — the router half is untouched — so no test can catch this. *(2026-07-21 note, not a substitute for Read 1's two-ended re-run at build time: the Phase-2 scoping read found live cross-links on both platforms — `AuthenticationView(onNavigateToRegister:)` bound at `ContentView.swift:31`; `AuthScreen(onNavigateToRegister = { nav = nav.enterRegister() })` at `PetSafetyApp.kt:349`.)*
- **Test consequence, handled deliberately:** `landingRegisterCTAOpensRegistration` (iOS) / `landingRegisterOpensRegister` (Android) lose their subject. The **router** assertion (`enterRegister()` → `.register` / `REGISTER`) stays valid and stays. The **CTA** test either moves to the login screen or is deleted **with the reason recorded in the CODEMAP**. A named acceptance test disappearing quietly is C2's 795-green-with-a-test-missing-by-name exactly.

**7 — No elevation or shadow anywhere on this screen.** Hairline borders only.

- **⚠️ Scope this to the landing, not to the shared primitive.** iOS `.elevatedCard()` (`AppColors.swift:247-261`) carries a soft shadow; Android `BrandCard` (`BrandCard.kt:30-56`) is a cream surface with **border + shadow**. **CC greps each primitive's call sites first.** If either is used outside the landing, changing it in place has blast radius beyond this chunk — use the shadowless sibling (iOS `.softCard()`, `AppColors.swift:227-241`) or a parameter, and **surface the choice**; do not silently restyle a shared primitive.

**Spacing.** Screen padding **20**; card radius **16**; card padding **13**; gap primary↔action row **10**; between sections **20**; tile gap **10**; primary CTA radius **20**.

- **⚠️ `13` is almost certainly not on the existing scale** (`AppSpacing` / `DesignTokens.kt` are likely 4/8/12/16/20/24). Per the brief: **add a named token and list it.** Never an inline literal.

---

#### The one thing that isn't cosmetic — counts

The tiles are designed around a live number. **Do not add a network call.** CC reads whether a count is already available to this screen (e.g. on `AppStateViewModel`) and **reports which**.

- **Not available (expected):** render icon + label + sublabel — **no number, no placeholder zero**. Layout must accept a number later **without re-layout**.
- **Available:** a count of zero renders as `0`. Do not hide the tile, do not substitute an empty state.
- **Forbidden twice over.** Viktor's instruction, *and* because a request fired from the **logged-out** landing is precisely the shape of **[[G-session-loggedout]]** — the Phase-1 ship-blocker where an unconditional cold-launch call 401s into a recurring "session expired" dialog on this exact surface.
- **No location permission on this screen.** "Nearby" implies it; the brief forbids it.

---

#### Must NOT touch

**The three device gates' output, byte-intact.** These live in the two files this chunk rewrites, and **the board catches only two of them** — everything else here would ship inert and green (PROTOCOL §6's defaulted-params corollary):

- C4 **FIX 2** — `BackHandler` on **both** `when`-branches (system/edge-swipe back → landing, not app exit).
- C4 **FIX 3** — the centred finder report card (`AlertDialog`) with **both** branches: "I found a pet" → form, "Try Again" → live scan.
- `onTagNotUsable` (carve-out #1) and `onNavigateToActivation` (the G-landing-activation binding).
- The **close overlay at the presentation site** (§9.14's dismiss-mirror — its absence is how C3 shipped a camera with no exit but force-quitting).
- `ScannerSurface`; C4b's auto-present `LaunchedEffect`; the `pendingQrCode` / `onQrCodeHandled` threading.
- **⚠️ `pendingQrCode`'s parameter name is PINNED** (§E C4b): board §5's SEED check greps that literal, so a rename **false-reds as INERT**. Do not rename.

**Plus the standing walls:** `resolveRootRoute` / the `RootRoute` enum / `AuthOverlay` / the `when`-block (C2's single routing authority); `MainTabView` / `MainTabScaffold`; `QRScannerView` / `QrScannerScreen` internals; `isAuthenticated`'s derivation; splash files (**reference** the mark asset, never edit); deep-link / App Links / intent-filter handling; the navigation graph; every destination screen; `PetsListView` / `PetsListScreen` (G10 deferred); the dormant `AlertsScreens.kt` / `PricingScreen.kt`; invoicing (§6 hard boundary — a compile error there is not this chunk's to resolve). **No new dependencies. Wire nothing new — the destinations already exist.**

---

#### Tests

- **Every existing landing test passes, or is explicitly re-pointed with a recorded reason.** Android: `RootRoutingComposeTest` (its `performScrollTo()` and real-button presses may need re-finding as the layout moves — §9.16), `landingSignInRecomposesToLogin`, `AuthBackAffordanceTest`, the three community tests. iOS: `LandingContentTests` (7).
- **`addingDescriptorRendersCard*` is the data-driven guard** and must survive the grid change intact.
- **No test may be named `…Presents…`** — §E C4's standing rule; this project has shipped that overclaim twice. State per test which assertion proves the **wiring** and which proves the **value**.
- **Force the run** (`--rerun-tasks` on Android; read `index.html`, never the console) and **grep the artifact for every named criterion, by name** (Rule 6).

---

#### Done-when

1. The seven items land, and **every flow, gate and destination behaves exactly as before** — the only changes are visual style and element order.
2. Zero hardcoded colours; zero hardcoded string literals in composables **including content descriptions**.
3. New strings (expected: `landing_scan_subtitle`, possibly the `INGYENES` fragment) HU canonical → EN → 11 via `senra_translate.py`. **No hand-written translations.** `brand_wordmark` is `translatable="false"` and mints nothing.
4. **Width check reported:** 320dp × max font scale × all 13 locales. Anything wrapping past two lines is **reported, not fixed** by truncating or shrinking. Likely offenders per the brief: `Kisállatbarát hely` and its German equivalent — the half-width tile is the only change here that can genuinely break text.
5. Touch targets ≥48dp, **including** the header link and the promo text CTA. Bottom **56dp** free of interactive content (a bottom bar must be addable later with no re-layout).
6. Theme tokens added are **listed by name**; counts availability is **reported either way**.
7. **⚠️ DEVICE LOOK, BOTH PLATFORMS (Rule 5 — no test can prove any of this).** §1: an item that cannot be a board check is a **DECISION**, resolved by visual QA sign-off (C0's precedent). Two halves, and the second is the one that matters:
   - **The restyle renders correctly** — header mark centred and crisp at 52, tiles equal-width, hairlines visible, nothing clipped, bottom 56 clear.
   - **The preserved behaviour still works** — seeded auto-present (C4b D.1), back-to-landing (FIX 2), the report card's **both** branches (FIX 3), the close overlay, found-stray present/dismiss. **A restyle that renders beautifully and drops `BackHandler` passes every test in both repos.**
8. **§13 escalation, decided not drifted:** the standing row *"the mark is not recolored for dark on either platform"* has been splash-only. At 52dp on the primary logged-out surface, a dark-inked mark on a dark surface disappears. **Close it in F3's look, or defer it explicitly in writing.**

---

#### Explicitly OUT

Counts network call; location permission; nav-graph or destination edits; splash-file edits; deep-link / App Links work; new dependencies; **[[G-landing-submit]]** (C5/C6 — its own chunk, specced above); **[[G-session-loggedout]]** (auth workstream); **[[G-scan-error-raw]]** (raw-error chunk); **[[G-tab-scan-noparity]]** (unassigned); G10 dedup.

---

#### CC's Rule 2 read plan — the reads this chunk cannot be built without

Output the plan, **stop**, do not conclude before review. Re-ground every cite by symbol.

1. **Register reachability, two-ended, both platforms.** The call site inside `AuthenticationView` / `AuthScreen` **and** what it routes into. **Item 6 is blocked until this returns non-empty.** A back chevron is not a register link.
2. **The mark asset resolves from the landing's context.** §9.2 records the iOS **asset catalog is split**; confirm `LaunchLogo` is reachable where `LandingView` renders it. Android: confirm `splash_mark` is a normal drawable, not splash-theme-scoped.
3. **What `LogoNew_<CC>` / `logo_new_<cc>` actually contains** — mark + wordmark, or wordmark alone. Decides whether the text wordmark is right (it almost certainly is).
4. **Call sites of `CommunityEntryCard`, `BrandCard` / `.elevatedCard()`, `BrandButton` / `PrimaryPillButtonStyle`, `SecondaryButton` / `SecondaryPillButtonStyle`** — enumerate the **callee**, not the name. Anything with a consumer outside the landing is out of in-place-restyle bounds.
5. **Counts availability** on the screen's existing state. Report which.
6. **Token inventory** — spacing scale (is `13` on it?), radii, hairline border width, letterspacing. Everything absent becomes a **named** token, listed.
7. **The `INGYENES` string's existing key**, and whether the badge word has one of its own.
8. **The full preservation inventory in both landing files**, by symbol, so the diff can be checked against it line by line.

---

#### HELD §2 amendment — apply to plan §2 when this chunk lands, NOT before (preserved here so deleting the transfer artifact cannot lose it)

> **Amended 2026-07-21 (F3, Viktor).** Zone 2 was locked as *"first-class, styled **distinctly** from the acute actions"*; F3 demotes it to a tinted surface with a text CTA, on the reasoning that one saturated primary (Scan) beats three competing fills on a finder-first surface. **Persistent Sign-in / Register** was locked as *"quiet, secondary, always reachable"* **on the landing**; F3 moves Sign-in to a header text link and **removes Register from the landing**, reachability preserved via the login screen — **verified two-ended before the item landed** (§E F3 Read 1). Shape A's three zones, the **data-driven** Zone-3 collection, **G-a** and **G-b** are unchanged. *Recorded as an amendment rather than an edit, so §2 keeps describing the code.*

---

## F. New localization keys (HU canonical, full 13-locale)
Introduced in C3/C4; **HU is the canonical source** — derive EN + the other locales after HU is confirmed. **Mint exactly these 6** (same key names on both platforms):
`landing_scan_cta`, `landing_found_stray_cta`, `landing_order_cta`, `landing_order_subtitle`, `community_section_title`, `community_lost_found_subtitle`.
**Do NOT mint** the card title/subtitle twins (`community_lost_found_title`, `community_pet_friendly_title`, `community_pet_friendly_subtitle`) or the sign-in/register twins (`landing_sign_in`, `landing_register`) — **reuse** the existing shipping keys instead. Exact reuse names differ per platform: see the §E C3 grounded map (iOS) and §E C4 (Android). This is the §9.13 ruling — "6 new keys ×13, not 10."
*(Zero hardcoded English on any surface — these must ship localized. The account-created/OTP copy remains Q3/Phase-3.3, separate.)*
*(2026-07-21: §E C5/C6 mints a 7th key — `found_pet_reported_success`, HU canonical, per its own Localization block — and C7/C8 may mint `landing_scan_subtitle` plus the non-localizable `brand_wordmark` when its deferral lifts. The "exactly these 6" above is C3/C4's historical scope; this section stays the index.)*

---

## G. Confirmations — all resolved
1. **Release-coherence — RESOLVED (2026-07-10):** recorded as a **DEPENDENCY** in §C.0 — single coherent release; Zone-3 destinations live before any user sees the landing; revisit if the release model ever goes phased.
2. **iOS subtitle vs `ProfileMenuRow` — RESOLVED:** keep the subtitle and build `CommunityEntryCard` (per §2's locked Shape A); no subtitle-less menu-row reuse. (B.4)
3. **Splash granularity — RESOLVED:** **split per platform** — C0 is two separate per-platform build units / commits (**C0-iOS then C0-Android**), not one cross-platform commit. (A.1)

No open items remain; these were product/process confirmations, all now decided.
