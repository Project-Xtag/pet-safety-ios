# Senra Mobile Redesign — Tracked Plan

> **Home:** this doc lives in the **iOS repo** (`pet-safety-ios/`) as the reference platform, but it is **cross-cutting** and governs both `pet-safety-ios` and `pet-safety-android`. Android-specific refs are pathed from `pet-safety-android/`.
> **Status:** Unit 0 complete (investigation + this doc). No feature code written, no branch created.

---

## 1. Purpose & current status

Restructure the Senra mobile apps so that surfaces which are **already anonymous-capable server-side** (scan → public profile, found-stray report, community / lost-&-found reads, pet-friendly-places discovery) become reachable **without logging in**, behind a new logged-out **landing** screen. Fix the guest tag-ordering dead-end (mobile drops the `userId` the checkout needs) and correct inaccurate OTP copy.

**Current status:** Phase 0 (read-only investigation) is **done** — findings in §5, gaps in §6. Nothing is built. Next unit is Phase 1 (shell + splash + landing), pending review of this doc.

**Working model (two-seat):** CC investigates/builds/surfaces; chat reviews diffs byte-level; **Viktor owns all git**. One reviewed unit per commit. Unit N+1 does not start until unit N is reviewed, tested, and committed.

---

## 2. Scope

### In scope
- Guest/public pre-login access to surfaces that are **already anonymous-capable server-side**: scan → public profile, found-stray report, community / lost-&-found reads, pet-friendly-places discovery.
- New **landing** screen (default logged-out state) + refreshed splash.
- **Guest tag-ordering wiring:** capture `userId`/`email` from `createOrder` and thread into `CreateTagCheckoutRequest` on the **guest path only** (authed order path untouched).
- **OTP copy fix** ("check your email for a code" is inaccurate — no code is sent until the user requests OTP at login).

### Out of scope / deferred
- **ANYTHING that reads, writes, or maps into the NAV / Számla invoicing flow.** Separate, parallel work. Invoicing gaps are **documented here (see §6), never actioned here.**
- **Separate billing/shipping ADDRESS CAPTURE (Phase 4)** — DEFERRED until the invoicing work lands, because its only value is on the invoice, which is across the boundary.
- **B2B invoicing identity** (future `orders.billing_info` column) — out.
- Any net-new feature beyond access-restructuring.

### Locked decisions
- **Shell approach = Option A:** add a logged-out-default branch so a new `LandingView` becomes the default unauthenticated state, leaving `MainTabView` / `MainTabScaffold` untouched.
  - iOS: near-drop-in at `ContentView.swift:15–33`, gated solely on `authViewModel.isAuthenticated`.
  - Android: near-drop-in at `PetSafetyApp.kt:275–318` — a single `screenKey` `when`-block. Add a `"landing"` case; no nav-graph rewrite.
- **Public surfaces gate at the ACTION level, not the screen level:** view public; actions like create-alert / submit-place / activate-tag prompt login at the point of action, reusing the existing deep-link-sheet pattern (iOS `ContentView.swift:53/:84`; Android the existing activation/login-prompt route).
- **Small, independently testable chunks; one surface per chunk in Phase 2.**
- **Logged-out affordances are strictly limited (Q1 — decided 2026-07-09):** an unregistered / logged-out finder gets exactly **two** actions and no others — (1) **Report a sighting** (the existing sighting flow) and (2) **Scan a tag** (the existing scan flow → the found pet's public profile page). No edit, no mark-found, no other owner/account actions are shown to logged-out users. On the missing-pet **alert detail** this means it renders as a public read exposing **only** those two actions; every `currentUser`-gated affordance is hidden when logged out.
- **Landing structure = Shape A, "three-zone community home base" (Q5 — decided 2026-07-10):** the default logged-out landing is a three-zone layout designed so future community features **append to an existing structure** rather than trigger a landing redesign:
  - **Zone 1 — Act now** (compact action row, top): **Scan a tag** + **I-found-a-stray** — prominent, fast, visually tight (the urgent-finder entry). Both trivial/anonymous (§4 2.1 / 2.2).
  - **Zone 2 — Order a tag** (distinct product CTA, at the seam): first-class, styled **distinctly** from the acute actions (product/conversion intent, not finder intent). Entry to Phase 3.
  - **Zone 3 — Community** (the growable body): a titled section that **renders a list of community entries** — seeded with two today (Lost & Found board, Pet-friendly places). Built as a **data-driven rendered collection** (array of entry descriptors → cards), **not** two hardcoded tiles. Adding a future community feature = appending an entry, **no landing-layout change**. Board/places reads are anonymous (§4 2.3 / 2.4).
  - **Persistent — Sign in / Register:** quiet, secondary, always reachable.
  - Two guardrails are the point of Shape A: **(G-a)** **no empty "coming soon" placeholders** in the community section — "room to grow" means the list is *extensible* (structural, invisible until used), presenting as a complete two-entry section, not visible empty slots; **(G-b)** community card/list styling **must reuse existing components** from the §5.3 inventory — Shape A leans harder on shared components than a flat landing, so the Phase-1 spec must **name** which existing components the community cards reuse, and if none fit cleanly that is a finding **CC surfaces before building**, not a new component minted mid-chunk.

---

## 3. Working discipline

- Read-only tracing precedes every build unit; findings land here before code.
- One surface per Phase-2 chunk; each chunk ships with tests (harness confirmed strong on both platforms — §5.5).
- **iOS and Android ship the same UX iteration** unless explicitly scoped down (feature exists on both).
- Invoicing findings are **documented in §6 and never actioned** in this workstream.
- No guessing: inconclusive traces are marked "inconclusive" with what would resolve them.

---

## 4. Plan — phases & chunk skeleton

> Phase 0 is complete, so most chunk internals below are now **specifiable** (see §5). Items still needing a decision are flagged and tracked in §7.

### Phase 0 — Investigation ✅ (this unit)
Auth-boundary trios (both platforms), public-surface dependency audit (both), design-token inventory (both), OTP copy audit, test-harness confirmation. → §5.

### Phase 1 — Shell + splash + landing
> **Buildable chunk spec:** [`docs/phase-1-spec.md`](docs/phase-1-spec.md) — finalized a/b split + a leading splash chunk + build order, the G-b component-reuse resolution (`CommunityEntryCard`), the cross-phase seam (Zone-3 intent + Phase-2 destination edge), the Community entry-descriptor shape, and per-chunk files/tests/done-when.
- **1.1 iOS shell/landing** — the new `LandingView` renders the **Shape-A three zones** (§2): Act-now row (Scan + found-stray), a distinct Order-a-tag CTA, and the data-driven Community list (Lost & Found + Pet-friendly, rendered from an entry-descriptor array). Reuse `WelcomeView.swift` structure + `PrimaryPillButtonStyle` + `LocalizedLogo` + `AppSpacing`/`AppColors` (§5.3); the chunk spec must name the components the Community cards reuse (G-b). **Split steer** (to finalize when the Phase-1 chunk spec is written):
  - **1.1a — shell/routing + splash:** add the logged-out-default branch to `ContentView.swift:15–33` (Option A) with `LandingView` as the default unauthenticated state and `AuthenticationView` reached from a landing CTA; refresh `SplashScreenView.swift` **in place**. Carries the **existing** logout/session-expiry acceptance checks (below) — structural, testable in isolation.
  - **1.1b — landing content/layout:** the three-zone layout + the data-driven Community collection (the iterative visual design).
  - *Rationale:* keep the structural routing change (testable in isolation) separate from the iterative visual landing design — don't couple a structural diff to a design diff.
  - **Done-when (acceptance — 1.1a, mandatory before build sign-off):** default logged-out launch shows `LandingView`; **logout routes to `LandingView`** (not the old `AuthenticationView`, not a blank screen); **session-expiry routes to `LandingView`**. This is a behavioral change riding along with the gate edit and must be tested **explicitly**, because the iOS **optimistic** path (`checkAuthStatus` sets `isAuthenticated=true` on token presence, then `logout()` on a failed `getCurrentUser`) can bounce a user **mid-session** — that bounce must land on `LandingView`. Cover both the explicit-logout and the mid-session-expiry transitions with XCTest/UI test.
- **1.2 Android shell/landing** — the new Landing composable renders the **Shape-A three zones** (§2): Act-now row (Scan + found-stray), a distinct Order-a-tag CTA, and the data-driven Community list (rendered from an entry-descriptor array). Reuse `BrandButton`, `BrandCard`, `LocalizedLogo`, `DesignTokens`/`Color.kt` (§5.3); the chunk spec must name the components the Community cards reuse (G-b). **Split steer** (to finalize when the Phase-1 chunk spec is written):
  - **1.2a — shell/routing + splash:** add a `"landing"` case to the `PetSafetyApp.kt:275–318` `screenKey` `when`; refresh splash via the system SplashScreen theme (`themes.xml` `Theme.PetSafety.Splash`) and/or a new post-splash composable. Carries the **existing** logout/session-expiry acceptance checks (below).
  - **1.2b — landing content/layout:** **build the new Landing composable** (none exists) with the three zones + the data-driven Community collection.
  - *Rationale:* keep the structural routing change separate from the iterative visual landing design.
  - **Done-when (acceptance — 1.2a, mandatory before build sign-off):** default logged-out launch shows the new Landing; **logout routes to Landing** (not `AuthScreen`, not blank); **session-expiry routes to Landing** — today `TokenAuthenticator`'s one-shot expiry drives the non-dismissible "Session Expired" dialog + logout, so verify that after that path `screenKey` resolves to the new landing branch, **not** the old `"auth"`/`AuthScreen`. Cover both transitions with the Robolectric / `compose.ui.test` harness.
- *Asymmetry:* iOS has `SplashScreenView` **and** `WelcomeView` to refresh in place; Android has **neither** a Compose splash nor a landing composable — both built new from shared tokens.

### Phase 2 — Route public surfaces (one surface per chunk, ordered trivial→heavy)
Each chunk = hoist the surface out of the authed shell + optionalize any soft `currentUser` read + gate authed actions at action level. Mirror on both platforms.
- **2.1 Scan → public profile** — *Trivial.* iOS live views carry no `@EnvironmentObject`; `DeepLinkScannedPetView` already renders at `ContentView` level (works logged-out today). Android: hoist `QrScannerScreen`/`ScannedPetSheet`/`PublicPetProfileScreen` out of `MainTabScaffold`; make `PublicPetProfileScreen` take `currentUser: User?` (nullable) and drop its unused `appStateViewModel` param. **Side task:** delete/quarantine dead iOS `ScannedPetView` (§6-G7).
- **2.2 Found-stray report** — *Trivial.* Both platforms auth-optional by design (anonymous manage token). Wire entry from landing/board.
- **2.3 Lost & Found board** — *Light.* iOS `AlertsTabView`: optionalize the `currentUser` GPS-fallback geocode + rework the `AddressRequiredView` CTA. Android: render `LostAndFoundScreen` directly with a device `userLocation`, or drop the 2 unused VMs + optionalize the fallback in `AlertsTabScreen`. **Kill dormant legacy alerts views first** (§6-G6).
- **2.3b Missing-pet alert detail (public read)** — Per the locked decision (§2), the detail (`AlertDetailView` / Android detail) renders publicly with **only Report-a-sighting + Scan-a-tag** for logged-out users; the `currentUser?.id` ownership branches (Edit, Mark-Found) are hidden when logged out. Split from 2.3 because those ownership branches must be optionalized. **Q2 RESOLVED → fully client-only** — the backend `POST /alerts/:alertId/sightings` is already `optionalAuth` with a nullable `reporter_id` and user-less client DTOs (§5.6); **no backend change**. **Report-sighting entry differs by platform:** iOS **relocates existing UI** (`ReportSightingView`, reached today from the authed `AlertDetailView:274`) into the public detail; Android **builds the entry** from the anonymous-capable repo method (`AlertsRepository.reportSighting`), **lifting the form logic from the dormant `ReportSightingDialog` per G6 — not resurrecting the dead `AlertsScreens.kt`**. Scan-a-tag reuses the existing scanner / deep-link path.
- **2.4 Pet-friendly places discovery** — *Light read + one authed action.* Read is anonymous; derive `market` from `Locale.current.region`/device country. **Gate submit-place behind an action-level login prompt** (`createPetFriendlyPlace` is `requiresAuth:true`). **Parity note:** the two platforms derive `market` slightly differently today (iOS `Locale.current.region`; Android `currentUser.country ?? Locale`), so the **logged-out/anonymous path on both must fall back to the device locale identically** — a logged-out user in HU must get HU places on both apps (do not let one platform diverge to a hardcoded/empty market when `currentUser` is null).

### Phase 3 — Guest-order wiring + copy fix
- **3.1 iOS guest-order wiring** — Capture `userId` (+ `email`) from the `createOrder` response and add `user_id`/`email` to `CreateTagCheckoutRequest` (`Order.swift:194`), threaded on the **guest path only**. Mirrors web `GetYourTag.tsx:444→458`. Authed path untouched. No backend change (route is `optionalAuth`).
- **3.2 Android guest-order wiring** — Same: `OrdersViewModel.createOrder` captures `response.userId`; extend `CreateTagCheckoutRequest` (`Requests.kt:279`) + `OrdersViewModel.createTagCheckout` signature; thread on guest path.
- **3.3 OTP copy fix** — On mobile there is **no inaccurate string today** (§5.4); the fix is to ensure the guest-order success/account-created surface built in 3.1/3.2 uses **accurate** copy (never claims a code was emailed). Wording pending HU canonical (§7-Q3). Web inaccuracy + backend response message documented (§6-G4), out of mobile-build scope.

### Phase 4 — DEFERRED
Separate billing/shipping **address capture**. Blocked until invoicing work lands (its only value is on the invoice, across the boundary). Do not build here.

---

## 5. Current-state findings (Phase 0)

### 5.1 Auth-boundary trio — iOS (reference) vs Android

| Concern | iOS | Android |
|---|---|---|
| **Shell / gate** | `PetSafetyApp` → Splash → `ContentView` → `MainTabView`. Gate: `if authViewModel.isAuthenticated { MainTabView } else if showRegistration {…} else { AuthenticationView }` — `ContentView.swift:15–33`. | `MainActivity:50–68` → `PetSafetyApp` → `MainTabScaffold`. Gate: `screenKey` `when`-block `PetSafetyApp.kt:275–318` (`isAuthenticated→"main"`, `showOrderTagsScreen→"order_tags"`, `showRegisterScreen→"register"`, else `"auth"`=`AuthScreen`), via `AnimatedContent` crossfade. |
| **Logged-out default** | `AuthenticationView` | `AuthScreen` (order-tags/register are toggled sub-branches) |
| **Session store** | `AuthViewModel.isAuthenticated` (`@Published`), backed by Keychain (`KeychainService.isAuthenticated = exists(.authToken)`, `KeychainService.swift:231`). **Optimistic**: set true on token presence, then revalidated async via `getCurrentUser()`; failure → `logout()`. | `AuthTokenStore` (EncryptedSharedPreferences, AES256) is source of truth; `AuthRepository.isAuthenticated = authToken.map { !isNullOrBlank() }` (`AuthRepository.kt:44`); `AuthViewModel` mirrors. **Reactive, not optimistic-revalidate** — a failed `users/me` only logs; demotion happens **only** via a real 401. `AppStateViewModel` holds **no** auth. |
| **Token attachment** | Central `buildRequest(requiresAuth: Bool = true)` (`APIService.swift:225–303`); `Bearer` attached only `if requiresAuth, let token`. **Per-call opt-out on 17 endpoints.** App Check header on all; 401 auto-refresh via `TokenRefreshCoordinator` actor. | **Global `AuthInterceptor`** (`AuthInterceptor.kt:12–33`) attaches `Bearer` to **ALL** requests whenever a token exists — **no per-call `requiresAuth`** (verified: no `@Header`/`requiresAuth` in `ApiService.kt`). 401 → OkHttp `TokenAuthenticator` (refresh + one-shot expiry dialog). Also unconditional `AppCheckInterceptor` (can fail-closed 503) + Remote-Config base-URL rewrite. |
| **Token-less calls** | 17 endpoints pass `requiresAuth:false` (auth bootstrap, config, qr lookup/scan, share-location, community found-pets, pet-friendly reads, nearby alerts, vaccine catalog, guest order create/validate-promo/shipping-prices). | Same endpoints go through the shared client; anonymous = simply no stored token. **No client-side auth gate on the call** — the backend's `optionalAuth` decides. |

**Key divergence for the redesign:** Android attaches the token to every request via one interceptor (no `requiresAuth` seam), so anonymous behavior is purely "no token present." Both platforms' gate is a single-branch decision → **Option A landing is near-drop-in on both.**

**Reachability hazard (both):** most public-endpoint-backed screens live *inside* the authed shell (`MainTabView` / `MainTabScaffold`), so they're gated at the **navigation** level even though their endpoints need no token. Phase 2 = hoist them out.

### 5.2 Public-surface dependency audit → Phase-2 chunk list

Ground truth: **every public surface's own ViewModel is auth-free**, and every read works anonymously at the transport layer. Only soft, null-safe `currentUser` reads exist, all degrading gracefully.

| Chunk | Surface | iOS status | Android status | Weight |
|---|---|---|---|---|
| 2.1 | Scan → public profile | `QRScannerView` (no env obj), `DeepLinkScannedPetView` (already renders at `ContentView` level, logged-out today), `ShareLocationView` — all anonymous | `QrScannerScreen` (appState snackbar param only), `ScannedPetSheet` (stateless), `PublicPetProfileScreen` (reads `currentUser` **null-safe** `:91,183`, + unused `appState` param) | **Trivial** |
| 2.2 | Found-stray report | `FoundPetFormView` / `FoundPetDetailView` — no env obj, auth-optional, manage token | `FoundPetFormScreen` / `FoundPetDetailScreen` — VM injects repo + `FoundPetManageTokenStore`, no auth | **Trivial** |
| 2.3 | Lost & Found board (LIVE) | `AlertsTabView` (`ContentView.swift:221/:272`) reads `authViewModel.currentUser` **only** for GPS-fallback geocode (soft); `LostAndFoundViewModel` fully auth-free. ⚠️ row → `AlertDetailView` has **hard** `currentUser?.id` ownership dep | `LostAndFoundScreen` + `LostAndFoundViewModel` fully public; wrapper `AlertsTabScreen` reads `currentUser` (fallback only) + instantiates **2 unused VMs** | **Light** (board) |
| 2.4 | Pet-friendly places | `PetFriendlyPlacesView` reads `currentUser` for `market` (has `Locale` fallback) + geocode fallback; **submit-place = `createPetFriendlyPlace` `requiresAuth:true`** → action-level login | `PetFriendlyPlacesScreen` + VM auth-free; `market` derived caller-side from `currentUser.country ?? Locale`; submit-place is the authed action | **Light read + 1 authed action** |

**Action-level login prompts belong on:** activate-tag / promo-claim (scanner) and submit-place (pet-friendly). iOS additionally: viewing the missing-pet **detail** (`AlertDetailView`) is authed today — scope decision in §7-Q1.

### 5.3 Design-token / shared-component inventory (reuse, don't reinvent)

**iOS** (`PetSafety/PetSafety/`):
- Colors — `Utilities/AppColors.swift`: `brandOrange` (asset `BrandColor` #FF914D, :26), `brandOrangeDeep` (#E5662C, :37), `brandGradient` (:42–48), plus asset-catalog colors `cream`/`ink`/`softBorder`/`mutedText`/`tealAccent`/`peachBackground`/`goldenAccent`/`cardBackground`; `BackgroundColor` (splash bg).
- Spacing/Radius — `AppSpacing` (:61–68), `AppRadius` (:70–76).
- Type — `Font+App.swift`: `Font.appFont(size:weight:)` (Inter).
- Components — `PrimaryPillButtonStyle` (**new default CTA**, AppColors.swift:169–199), `SecondaryPillButtonStyle`, `.softCard`/`.elevatedCard`, `BrandButtonStyle` (legacy), `Views/Components/CachedAsyncImage.swift`.
- Logo — `Helpers/LocalizedLogo.swift` (`LogoNew_<CC>`, fallback `_EN`).
- **Refresh in place:** `Views/SplashScreenView.swift` (splash) and `Views/Pets/WelcomeView.swift` (the existing landing pattern — mirror it).

**Android** (`app/src/main/java/com/petsafety/app/`):
- Colors — `ui/theme/Color.kt`: `BrandOrange` #FF914D (:21), `BrandOrangeDeep` #E5662C (:26), `Cream`/`Ink`/`SoftBorder`/`TealAccent`/`PeachBackground`/`GoldenAccent` + dark variants; `Theme.kt` `PetSafetyTheme`.
- Type — `ui/theme/Type.kt` (Inter, phone/tablet/adaptive).
- Tokens — `ui/theme/DesignTokens.kt`: `AppSpacing`, `AppRadius`, `brandGradient()`, `Modifier.softCard()/elevatedCard()`; `Shape.kt`; `WindowSizeUtils.kt` (`AdaptiveLayout`).
- Components — `ui/components/`: `BrandButton` (primary gradient pill), `SecondaryButton`, `TealButton`, `BrandCard`, `BrandTextField`, `AdaptiveContainer`.
- Logo — `util/LocalizedLogo.kt` (`R.drawable.logo_new_<cc>`).
- **Build new:** no Compose splash (only system SplashScreen theme `themes.xml` `Theme.PetSafety.Splash`) and **no landing/welcome composable** — both created new from the above.

### 5.4 OTP copy audit (⚠️ refines the seeded gap)

**The inaccurate "check your email for a code" post-order copy does NOT exist on mobile.** It is **web-only**:
- `tagme-now/src/pages/redesign7/GetYourTag.tsx:448` — hardcoded HU `defaultValue: "Fiók létrehozva. Ellenőrizd az e-mail fiókodat a megerősítő kódért."`
- `tagme-now/src/i18n/locales/hu.json:351` — `"account_created": "Fiók létrehozva! Ellenőrizd az e-mailedet a további lépésekhez"`
- (Origin also server-side: the `POST /orders` response `message` at `backend/src/routes/order.routes.ts:211–213` — "Account created. Please check your email for verification code.")

On **iOS + Android**, every "code"/"verification" string found is **accurate login-OTP copy** — `verify_code`, `enter_email_subtitle` ("…receive a login code"), Android `code_sent_to_email` ("Code sent to %1$s"), FAQ `help_faq_a15`. None claims a code is emailed after ordering, because the mobile guest-order flow currently dies at checkout (§6-G5) and never reaches an account-created message.

→ **On mobile the copy fix is latent, coupled to Phase 3** (nothing to edit until the success surface exists). **To-verify (§7-Q4):** whether Android's `createOrder` callback surfaces the backend English `message` (iOS discards it).

### 5.5 Test-harness confirmation

- **iOS** — XCTest. **43** test files in `PetSafety/PetSafetyTests/` + 3 UI tests (incl. `AccessibilityAuditTests`). Directly relevant precedents: `AuthViewModelTests`, `AlertsViewModelTests`, `OrdersViewModelTests`, `PetFriendlyPlacesViewModelTests`, `DeepLinkTests`, `LocalizationParityTests`.
- **Android** — JUnit + **MockK + Turbine + Robolectric 4.14.1 + `compose.ui.test` (JVM)**; **59** unit tests in `app/src/test/` (incl. `AuthViewModelTest`, `AlertsViewModelTest`, `OrdersViewModelTest`, `PublicPetProfileViewModelTest`, `QrScannerViewModelTest`, `AppStateViewModelTest`, screen tests like `MarkAsMissingScreenTest`), + **2** Espresso instrumented tests in `androidTest/`.
- **Verdict:** per-chunk "tested before we proceed" is concrete on both — ViewModel + Compose/SwiftUI-view unit tests. Instrumented/E2E is thin on Android (2), but unit coverage is the lever.

### 5.6 Q2 + Q4 verification (2026-07-10)

**Q2 — report-a-sighting is anonymous-capable end-to-end → verdict (A): no backend change.** Chain verified backend → DB → both clients:
- `POST /alerts/:alertId/sightings` (`backend/src/routes/alert.routes.ts:281`) is **`optionalAuth`** (`:282`), not `authenticateToken` (contrast: `/missing`, `/found`, `PUT /:id`, and owner-only `GET`/`DELETE /:id/sightings` are all `authenticateToken`). Handler: `reporterId = req.user ? req.user.userId : undefined` (`:321`); activity log runs only `if (reporterId)` (`:336`); no ownership check.
- `alertService.reportSighting` takes `reporterId?` optional + null-safes the reporter email; the DB column is **nullable** — `reporter_id UUID REFERENCES users(id) ON DELETE SET NULL` (`backend/migrations/00000000_base_schema.sql:242`). An anonymous sighting inserts cleanly.
- Both client DTOs carry only reporter-contact + location, **no user field** (`iOS Models/Alert.swift:324`; `Android Requests.kt:89`). iOS `reportSighting` (`APIService.swift:947`) keeps the default `requiresAuth:true` but that attaches a token only if one exists, so a logged-out call goes token-less; Android sends via `AuthInterceptor` (token only if present). → the sole blocker is UI reachability, which 2.3b decouples. **Android caveat:** report-sighting UI lives only in the dormant `ReportSightingDialog` today (not on the live `LostAndFoundScreen`), so Android 2.3b builds the entry from the repo method (see §4 2.3b + G6).

**Q4 — Android discards the backend order `message`, matching iOS.** `OrdersViewModel.createOrder`'s callback `message` param is the *error* string (`ex.localizedMessage`), never `response.message`; `OrderMoreTagsScreen.kt:818–832 / 853–865` reads `response` only to proceed to checkout. The post-order success toast is a local, accurate string (`R.string.checkout_tag_order_success`, `:119/:130`), not the backend copy. → no live inaccurate mobile string; G4 stays latent (folded into Phase-3.3).

---

## 6. Gaps register — documented, NOT fixed

> Invoicing items are **out of scope** for this workstream (§2). Recorded here only so they aren't lost; route any action to the separate invoicing work.

- **G1 — Invoice mapper ignores `billing_address`** *(invoicing territory — document only).* The order invoice buyer is assembled from `orders.shipping_address` **exclusively**; `billing_address` is never read (`backend/src/services/invoicing/orderSourceAssembler.ts:61`, `:64–76`). Distinct B2C billing is captured but never invoiced. Confirmed this investigation.
- **G2 — `orders.billing_address` is unstructured** *(invoicing territory).* `createOrderSchema` types it as free-form `z.record(z.string(), z.unknown()).nullish()` (`backend/src/routes/order.routes.ts:79`). Needs a structured shape before it could be safely mapped.
- **G3 — B2B invoice branch awaits a future column** *(out of scope).* The mapper's B2B branch exists (`backend/src/services/invoicing/orderInvoiceMapper.ts:114–125`) but reads a future `orders.billing_info` (companyName/taxNumber), **distinct from `billing_address`**.
- **G4 — Inaccurate "check your email for a code" copy** *(copy fix IN scope for mobile).* Guest order creates a **silent passwordless account** (`users.password_hash = null`, `backend/src/services/orderService.ts:180`); **no OTP is sent at order time** — "Account created silently … OTP will be sent on-demand when the user requests to log in" (`orderService.ts:192–194`). Inaccurate copy lives in **web** (`GetYourTag.tsx:448`, `hu.json:351`) and the **backend response message** (`order.routes.ts:211–213`); **mobile has none today** (§5.4). Mobile fix is Phase 3 (accurate copy on the new success surface).
- **G5 — Guest tag-order dead-ends at checkout on mobile** *(fix IN scope — Phase 3).* Backend `POST /orders/create-checkout` is `optionalAuth` and accepts body `user_id`/`email` for unauthenticated checkout (`order.routes.ts:983–1008`), but **both mobile clients discard the `userId` from `createOrder` and their `CreateTagCheckoutRequest` has no `user_id`/`email` field** (`iOS Order.swift:194–210`; `Android Requests.kt:279–286`) → guest checkout 401s. Web threads it correctly (`GetYourTag.tsx:444→458`). Guest ends up **token-less with a real account**, OTP-in later (never auto-logged-in). `delivery-points` is also `optionalAuth` → **not** a guest wall (earlier assumption corrected).
- **G6 — Dormant alerts/pricing screens** *(wiring hazard for Phase 2.3 — confirmed).*
  - iOS: `AlertsListView`, `MissingAlertsView`, `FoundAlertsView`, `SuccessStoriesView`, **and** `SuccessStoriesTabView` — each referenced **only** in its own `#Preview`; all carry live `authViewModel`/`appState`/`currentUser` couplings. The LIVE board is `AlertsTabView`.
  - Android: `AlertsScreens.kt` (`MissingAlertsScreen`/`FoundAlertsScreen`/`AlertDetailScreen`/`ReportSightingDialog`) and `PricingScreen.kt` — zero live nav references. The LIVE board is `LostAndFoundScreen`.
  - **Must wire to the LIVE unified board; delete/quarantine the dead views so none is mistaken for it.**
- **G7 — Dead iOS `ScannedPetView`** *(new, Phase-2.1 hazard).* `Views/QRScanner/QRScannerView.swift:299` — a parallel unused scan-result variant (fed by `ScanResponse`); only self-reference. Live scan-result path is `DeepLinkScannedPetView` (fed by `TagLookupPet`). Decide delete vs. adopt.
- **G8 — Android `AlertsTabScreen` unused VMs** *(new, minor).* Instantiates `QrScannerViewModel` + `SuccessStoriesViewModel` that are never used; drop during Phase 2.3.
- **G9 — iOS deep-nav gap** *(document; relevant if landing deep-links these on iOS).* `NotificationHandler` posts `navigateToAlert`/`navigateToPet`/`navigateToScan` but **no view consumes them** (Android does). If the landing/public flow ever relies on those routes on iOS, they'd be no-ops until wired.
- **G10 — Home entry-card duplication (deferred dedup)** *(surfaced by the Phase-1 G-b traces; documented, not actioned).* The icon+title+subtitle+chevron entry-card pattern is duplicated **inline** on both platforms — iOS `PetsListView.swift:436-465` (Success Stories) + `:477-522` (Pet-Friendly); Android `PetsListScreen.kt:855-935` (`SuccessStoriesSection`) + `:941-1015` (`PetFriendlyPlacesSection`) — none extracted. Phase 1 builds a shared `CommunityEntryCard` for the **landing only** and deliberately does **not** refactor the authed home to consume it (that touches `MainTabView`/`MainTabScaffold` internals — out of Phase-1 scope, minimal blast radius). Future dedup: have the authed home consume `CommunityEntryCard`. → separate refactor, not this workstream.

---

## 7. Open questions / decisions pending

- **Q1 — RESOLVED 2026-07-09 → promoted to Locked decisions (§2).** Logged-out finders get exactly **Report-a-sighting + Scan-a-tag** on the missing-pet detail and nothing else; the detail becomes a public read with owner actions hidden when logged out. Implemented as sub-chunk **2.3b** (§4). (Recorded as a decision in §2, not left as an open recommendation here.)
- **Q2 — RESOLVED 2026-07-10 → outcome (A): anonymous-capable as-is, fully client-only** (§5.6). `POST /alerts/:alertId/sightings` is already `optionalAuth` with a nullable `reporter_id`, both client DTOs carry no user field, and a logged-out call is accepted — **no backend change**. 2.3b proceeds client-only; note the iOS-relocates / Android-builds-from-repo (per G6) asymmetry (§4 2.3b).
- **Q3 — Corrected OTP/account-created copy wording (HU canonical).** What should the Phase-3 success surface say? Must not claim a code was emailed. Needs the HU source string (HU is canonical) before EN + 12 locales are derived.
- **Q4 — RESOLVED 2026-07-10: Android discards `response.message`, matches iOS** (§5.6). No live inaccurate mobile string today; the copy fix stays folded into the Phase-3.3 success surface (G4 unchanged).
- **Q5 — RESOLVED 2026-07-10 → Shape A (three-zone community home base)** (§2). Zone 1 Act-now (Scan + found-stray), Zone 2 distinct Order-a-tag CTA, Zone 3 data-driven Community list (Lost & Found + Pet-friendly, extensible), persistent quiet Sign-in/Register; guardrails G-a (no empty placeholders) + G-b (reuse §5.3 components). **Q3 remains the only open decision on the critical path.**
- **Q6 — RESOLVED 2026-07-09.** Single home at `pet-safety-ios/SENRA-MOBILE-REDESIGN.md` (per instruction). No mirror or symlink; Android refs are pathed from `pet-safety-android/` inside this doc.

---

## 8. Specifiable vs. blocked (Unit-0 close-out)

**Now specifiable (Phase 0 resolved them):**
- **Phase 1.1 / 1.2** (shell + splash + landing) — gate insertion points + reusable tokens/components mapped (§5.1, §5.3); landing content locked to **Shape A** (§2). Each splits **a = shell/routing + splash** (carries the logout/expiry acceptance checks) and **b = three-zone landing content** (Act-now / Order / data-driven Community list). This is the **heaviest Phase-1 work** and leans hardest on §5.3 components (G-b — the spec must name the Community-card components, or surface a gap first). iOS refreshes `SplashScreenView` + mirrors `WelcomeView`; Android builds both new. Critical-path open decisions: **Q3 only** (Phase 3.3).
- **Phase 2.1 (scan)** and **2.2 (found-stray)** — trivial, no authed deps; concrete file targets listed (§5.2). Includes the G7/G8 cleanups.
- **Phase 2.4 (pet-friendly)** — read decoupling + the single authed action (submit-place) are pinned; only the login-prompt UX detail remains (reuse deep-link-sheet pattern).
- **Phase 3.1 / 3.2 (guest-order wiring)** — exact edits known: capture `userId`/`email` from `createOrder`, extend `CreateTagCheckoutRequest` (`Order.swift:194` / `Requests.kt:279`), thread on guest path; backend already supports it (G5). No backend change.
- **Phase 2.3 (board) + 2.3b (detail)** — now specifiable and **fully client-only** (Q2 resolved → outcome A, §5.6; no backend change). iOS relocates `ReportSightingView`; Android builds the sighting entry from `AlertsRepository.reportSighting`, lifting from the dormant dialog per G6. Prerequisite: dormant-view deletion (G6).

**Still blocked / needs a decision before the chunk is final:**
- **Phase 3.3 (copy fix)** — blocked on **Q3** (HU canonical wording). *(Q4 resolved — §5.6/§7 — no live mobile string; the copy work stays folded into the Phase-3.3 success surface.)*
- **Phase 4** — deferred by scope (invoicing boundary); do not plan internals yet.

---

## 9. Build-time codebase-verified findings (living log)

> Opened **2026-07-12** at Phase-1 build kickoff. **Refreshed as each chunk is built** — records where the live codebase differs from what the Phase-0 plan/spec assumed, verified by reading the actual files (never trusting the docs). Newest notes first.

### 9.0 Git / branch state (verified 2026-07-12)
- **Billing/invoicing "C7" is now MERGED into `main`.** `main == origin/main == szamla/c7-tag-billing-address == origin/szamla/…`, all at **`6cbf6bb`** (fast-forward on `a942338`). The earlier "off-limits parallel workstream" has landed; building on `main` now includes it. Its **source files** (`OrderMoreTagsView`, `OrderReplacementTagView`, `APIService`, `Localizable.strings`) don't overlap any redesign C0–C4 **source** file — **but that is NOT zero overlap** (corrected 2026-07-12 per the C0-iOS review; the earlier "zero overlap, verified" claim was wrong). The redesign and invoicing **share the `PetSafetyTests` build target**, so an invoicing-only compile error blocks the redesign's tests from compiling/running — which is exactly what happened (billing C7 → stale `OrdersDeliveryMethodTests`, see **§9.5**). The overlap lives at the **shared test target**, not the file list. *(origin/main has since advanced to `bc090fc` — the §9.5 test fix, then refined to model billing = shipping; local `main` still lags at `6cbf6bb`.)*
- **Build branch = `feat/mobile-redesign-phase1`** (per repo), created off `origin/main` (`6cbf6bb`). **One reviewed commit per chunk** (iOS repo carries C0-iOS/C1/C3; Android repo carries C0-Android/C2/C4) — this **supersedes the earlier per-chunk-branch steer** in the handovers.
- `docs/mobile-redesign` had carried a **duplicate billing cherry-pick** (`253e9ff`) on top of the spec `ed418a6`. **Reverted in `a1f0f60`** (2026-07-12) — the branch tree is back to `ed418a6` (docs-only), and §9 now lives here as the canonical repo-root master (Q6, no mirror). Spec/plan content unchanged since `ed418a6`, verified.

### 9.1 Test harness — Swift Testing, not (only) XCTest ⚠️ corrects the spec/handovers
- The spec (§E) and both handovers say **"XCTest."** Actual `PetSafety/PetSafetyTests/`: **33 files use Swift Testing** (`import Testing`, `@Suite`, `@Test`, `#expect`) vs **7 files `import XCTest`**. New chunk tests should be authored in **Swift Testing** to match the dominant style.
- **No ViewInspector** dependency present. SwiftUI view internals (`.onAppear`, the body subtree, which `Image` is drawn) are **not introspectable** in unit tests → view smoke tests assert on **constructable API + stored closures + helper contracts**; rendered pixels and animation timing are **visual-QA** (exactly what the spec's C0 note anticipates). A thin **`PetSafetyUITests`** XCUITest target exists (2 files) for launch/E2E if ever needed.

### 9.2 Asset catalog is split (verified 2026-07-12)
- **Not** a single `Assets.xcassets`. Two catalogs under `PetSafety/PetSafety/Resources/`: **`Colors.xcassets`** (colorsets) + **`Images.xcassets`** (imagesets).
- Confirmed present: colorsets `BackgroundColor`, `BrandColor`, `BrandColorDeep`, `Cream`, `Ink`, `SoftBorder`; **13 `LogoNew_*`** imagesets (incl. the `LogoNew_EN` fallback); `LaunchLogo`.

### 9.3 C0-iOS contract sites (verified) — spec is accurate
- `Views/SplashScreenView.swift`: minimal — `Color("BackgroundColor")` + `Image(LocalizedLogo.imageName)` (`.resizable().scaledToFit()`) + `DispatchQueue.main.asyncAfter(0.8) { onFinished() }`.
- Gate/handoff owner: **`App/PetSafetyApp.swift:31`** `@State private var showSplash = true`; **`:127-132`** `if showSplash { SplashScreenView { withAnimation(.easeInOut(duration: 0.4)) { showSplash = false } } } else { ContentView()… }`. C0 must preserve both the 0.8s→`onFinished()` handoff and this gate.
- `LocalizedLogo.imageName` maps 12 language suffixes → `LogoNew_<SUFFIX>`, fallback `LogoNew_EN`. (`WelcomeView` uses a *different* hero asset, `LaunchLogo`.)

### 9.4 C1 gate line-drift (note for the C1 build)
- Spec §E C1 cites `ContentView.swift:15-33` for the gate. Actual: the auth branch `if authViewModel.isAuthenticated {` is at **`:16`**; `.animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)` at **`:38`**; `isAuthenticated` deep-link-sheet reads at `:53` and `:84`. Structure matches the spec; **re-confirm exact lines when building C1** (numbers drifted slightly).

### 9.5 ✅ RESOLVED (was a BLOCKER) — `PetSafetyTests` target red on `main` (billing C7, invoicing territory)
- **Discovered** while running the C0-iOS smoke tests (2026-07-12). Billing/invoicing **C7** (`6cbf6bb`) added a **required** `let billingAddress: ShippingAddress?` to `CreateReplacementOrderRequest` (`Services/APIService.swift:1543`) but did **not** update `PetSafetyTests/OrdersDeliveryMethodTests.swift`, which constructed that type without the arg → `:195`/`:219` failed (`missing argument for parameter 'billingAddress'`) with a `:205` cascade, the whole `PetSafetyTests` target failed to compile, and **no test could run** (C0-iOS's three included). **Independent of C0-iOS** — `SplashScreenView.swift` and `SplashScreenViewTests.swift` both compiled clean in the same run (confirming the SourceKit errors were false positives).
- **CORRECT FIX — test-only, ZERO production lines. Landed in two steps:** `f48d122` first supplied `billingAddress: nil` at the two `OrdersDeliveryMethodTests` call sites; **`bc090fc` (2026-07-12 14:23) then superseded that to model billing = _shipping_.** **Why `= shipping` beat `nil`:** `nil` billing is **not a sanctioned production state** — C7's billing-primary design *always* collects billing, defaulting to the "same as shipping" tickbox, so a test asserting `nil` would model (and propagate) a state the app never produces; `= shipping` models the path C7 actually ships. *(For the record: the `bc090fc` refinement was the better call than the `nil` fix the review originally signed off on — recorded, not quietly improved.)*
- **⛔ Do NOT "fix" this by defaulting the model (`= nil` on `APIService.swift:1543`).** A `let` optional gets **no** synthesized memberwise default, and that omission is **deliberate**: it forces every call site to supply billing. A nil default would silently remove the **compile-time forcing function** that C7's **billing-primary / never-infer / gift-null → dead-letter** design depends on. Recorded here so nobody applies it later as a "cleanup." *(This reverses this section's earlier draft, which wrongly recommended the default — corrected per the C0-iOS review.)*
- **Invoicing boundary honored** — the redesign seat touched no invoicing file; the fix was Viktor's. C0-iOS tests can now execute on a green target.

---

## Change log
- **2026-07-09** — Unit 0: doc created; Phase 0 traces 0.1–0.5 run and recorded (§5); gaps register seeded + G6/G7/G8/G9 added from findings (§6); open questions Q1–Q6 opened (§7); specifiable/blocked close-out (§8). No feature code, no branch. Surfaced for review; not yet committed (Viktor owns git).
- **2026-07-09 (rev 2, post-review)** — **Q1 resolved and promoted to Locked decisions (§2)**: logged-out finders get only Report-a-sighting + Scan-a-tag on the missing-pet detail; folded into §4 (2.3 + new sub-chunk 2.3b), §7-Q1 (marked resolved, recommendation removed), and §8. Added **logout/session-expiry → landing acceptance check** to the 1.1/1.2 done-definitions (§4), incl. the iOS mid-session optimistic-bounce case. Added **2.4 cross-platform `market` device-locale fallback parity note** (§4). **Q6 resolved** (single doc home, no mirror). No feature code, no branch. Re-surfaced for review; not committed.
- **2026-07-10 (rev 3, post-review)** — Q2 + Q4 read-only checks run and recorded (§5.6). **Q2 RESOLVED → outcome (A)**: report-a-sighting is anonymous-capable as-is (`optionalAuth` route + nullable `reporter_id` + user-less client DTOs), so 2.3b is **fully client-only** — no backend sub-unit spawned; §4 2.3b now records the **iOS-relocates / Android-builds-from-repo-per-G6** report-sighting asymmetry. **Q4 RESOLVED**: Android discards the backend order `message`, matching iOS — no live inaccurate mobile string, G4 stays latent. Updated §4 (2.3b), §5 (new §5.6), §7 (Q2/Q4), §8. No feature code, no branch, no build. Surfaced for review; not yet committed.
- **2026-07-10 (rev 4)** — **Q5 RESOLVED → Shape A** recorded as a locked decision (§2): landing = three-zone "community home base" (Zone 1 Act-now: Scan + found-stray; Zone 2 distinct Order-a-tag CTA; Zone 3 **data-driven, extensible** Community list; persistent quiet Sign-in/Register), with guardrails **G-a** (no empty "coming soon" placeholders) + **G-b** (Community cards reuse §5.3 components — named in the spec or surfaced as a gap first). Folded the three zones + an **a/b split steer** (a = shell/routing + splash carrying the logout/expiry checks; b = landing content/layout) into §4 1.1/1.2; §7-Q5 marked resolved; §8 Phase-1 bullet updated. **Q3** is now the only open decision on the critical path. Doc-only; no feature code, no branch, no build. Surfaced for review; not committed.
- **2026-07-12 (Phase-1 build kickoff)** — Created build branch **`feat/mobile-redesign-phase1`** off `origin/main` (`6cbf6bb`; billing/invoicing C7 now merged to `main`). Reconciled git state and opened **§9 build-time codebase-verified findings** (Swift Testing harness — *not* XCTest; no ViewInspector; split `Colors`/`Images` xcassets; C0/C1 contract sites verified). Branch convention changed to **one per-repo Phase-1 branch, one reviewed commit per chunk** (both handovers updated).
- **2026-07-12 (C0-iOS build + review round 1)** — Built **C0-iOS**: a pure-visual splash refresh in `SplashScreenView.swift` (soft brand glow + fade/scale entrance + Reduce-Motion guard; the `BackgroundColor` / `LocalizedLogo` / `0.8s → onFinished()` / `showSplash`-gate contracts all preserved) plus a 4-test Swift Testing smoke suite. Running it surfaced a **blocker (§9.5):** billing C7 had left `OrdersDeliveryMethodTests` stale, so the shared `PetSafetyTests` target was red — which **falsified the earlier "zero overlap" claim (§9.0 corrected):** the overlap is the shared test target, not the file list. **Resolved** test-only by Viktor (`f48d122`, then refined in `bc090fc` to model billing = shipping — see §9.5; **not** the model `= nil` default, which §9.5 explicitly forbids and explains). C0-iOS **review = CHANGES REQUESTED**; all addressed: §9.0/§9.5 corrections; splash `maxWidth 320 → 360` (binds on iPad only — no current iPhone binds) and entrance `0.5s → 0.32s` (a settled dwell, not a flicker); honest test names/comments + an all-13-`LogoNew_*`-asset existence check (with the inconclusive-on-`private`-mapping limitation recorded); the duplicate billing cherry-pick reverted off `docs/mobile-redesign`; and **§9 ported to this canonical repo-root home with the `docs/` mirror deleted (Q6 upheld, not amended).** C0-iOS visual QA (Xcode canvas — 3 device classes × light/dark, the §E C0 done-when gate) + commit **pending; not yet committed.**
