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

// Seed:
val communitySeed = listOf(
    CommunityEntry("lost_and_found", Icons.Filled.Warning, R.string.community_lost_found_title,
                   R.string.community_lost_found_subtitle, CommunityDestination.LOST_AND_FOUND),
    CommunityEntry("pet_friendly", Icons.Filled.Place, R.string.community_pet_friendly_title,
                   R.string.community_pet_friendly_subtitle, CommunityDestination.PET_FRIENDLY_PLACES),
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
- **Done-when:** three zones render per Shape A; `CommunityEntryCard` built from the B.1 primitives (G-b); Zone 1 + Zone 2 present live destinations; Zone-3 cards emit tested nav intents; **no "coming soon" (G-a)**; new strings localized (HU canonical).

### C4 — 1.2b Android landing content (+ `CommunityEntryCard`)
- **Files:** `ui/screens/LandingScreen.kt` (populate); new `ui/components/CommunityEntryCard.kt`; new `ui/screens/CommunityEntry.kt` (descriptor + enum + seed); `res/values*/strings.xml` (all locales, HU canonical).
- **Precise edit:**
  - `CommunityEntryCard(icon, title, subtitle, onClick)` per B.2 (`BrandCard(onClick)` + the `PetFriendlyPlacesScreen.kt:404-422` row template).
  - **Zone 1:** `BrandButton` "Scan a tag" (presents `QrScannerScreen`, passing app-level `AppStateViewModel`) + `SecondaryButton` "I found a stray" (presents `FoundPetFormScreen`).
  - **Zone 2:** distinct Order CTA → the `showOrderTagsScreen` pre-auth branch.
  - **Zone 3:** titled Community section + `communitySeed.forEach { CommunityEntryCard(…) { onNavigate(it.destination) } }`.
- **Must NOT touch:** `PetsListScreen` (no dedup refactor — G10); the dormant `AlertsScreens.kt`/`PricingScreen.kt` (do not wire); `MainTabScaffold`.
- **Tests (`compose.ui.test` + JUnit):**
  - `communityListRendersSeededEntries`; `communityCardTapEmitsDestination`; `addingDescriptorRendersCard`.
  - `zoneOneScanPresentsScanner`; `zoneOneFoundStrayPresentsForm`; `zoneTwoOrderOpensOrder`.
- **Done-when:** mirrors iOS C3; three zones; `CommunityEntryCard` from B.2 primitives; Zone 1/2 live; Zone-3 tested intents; no "coming soon"; localized (HU canonical).

---

## F. New localization keys (HU canonical, full 12-locale)
Introduced in C3/C4; **HU is the canonical source** — derive EN + the other locales after HU is confirmed. Keys:
`landing_scan_cta`, `landing_found_stray_cta`, `landing_order_cta` (+ any Zone-2 supporting copy), `community_section_title`, `community_lost_found_title`, `community_lost_found_subtitle`, `community_pet_friendly_title`, `community_pet_friendly_subtitle`, `landing_sign_in`, `landing_register`.
*(Zero hardcoded English on any surface — these must ship localized. The account-created/OTP copy remains Q3/Phase-3.3, separate.)*

---

## G. Confirmations — all resolved
1. **Release-coherence — RESOLVED (2026-07-10):** recorded as a **DEPENDENCY** in §C.0 — single coherent release; Zone-3 destinations live before any user sees the landing; revisit if the release model ever goes phased.
2. **iOS subtitle vs `ProfileMenuRow` — RESOLVED:** keep the subtitle and build `CommunityEntryCard` (per §2's locked Shape A); no subtitle-less menu-row reuse. (B.4)
3. **Splash granularity — RESOLVED:** **split per platform** — C0 is two separate per-platform build units / commits (**C0-iOS then C0-Android**), not one cross-platform commit. (A.1)

No open items remain; these were product/process confirmations, all now decided.
