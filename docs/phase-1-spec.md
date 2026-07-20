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

## F. New localization keys (HU canonical, full 13-locale)
Introduced in C3/C4; **HU is the canonical source** — derive EN + the other locales after HU is confirmed. **Mint exactly these 6** (same key names on both platforms):
`landing_scan_cta`, `landing_found_stray_cta`, `landing_order_cta`, `landing_order_subtitle`, `community_section_title`, `community_lost_found_subtitle`.
**Do NOT mint** the card title/subtitle twins (`community_lost_found_title`, `community_pet_friendly_title`, `community_pet_friendly_subtitle`) or the sign-in/register twins (`landing_sign_in`, `landing_register`) — **reuse** the existing shipping keys instead. Exact reuse names differ per platform: see the §E C3 grounded map (iOS) and §E C4 (Android). This is the §9.13 ruling — "6 new keys ×13, not 10."
*(Zero hardcoded English on any surface — these must ship localized. The account-created/OTP copy remains Q3/Phase-3.3, separate.)*

---

## G. Confirmations — all resolved
1. **Release-coherence — RESOLVED (2026-07-10):** recorded as a **DEPENDENCY** in §C.0 — single coherent release; Zone-3 destinations live before any user sees the landing; revisit if the release model ever goes phased.
2. **iOS subtitle vs `ProfileMenuRow` — RESOLVED:** keep the subtitle and build `CommunityEntryCard` (per §2's locked Shape A); no subtitle-less menu-row reuse. (B.4)
3. **Splash granularity — RESOLVED:** **split per platform** — C0 is two separate per-platform build units / commits (**C0-iOS then C0-Android**), not one cross-platform commit. (A.1)

No open items remain; these were product/process confirmations, all now decided.
