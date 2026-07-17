import SwiftUI

/// Logged-out landing surface — the three-zone community home base (plan §2,
/// Shape A). C1 (1.1a) built the routable scaffold; C3 (1.1b) populates it.
///
/// Zone 1 (Act now) and Zone 2 (Order) are wired **live** — their destinations
/// are anonymous-reachable today (spec §C.1). Zone 3's cards are fully built and
/// emit their nav intent; the destinations are resolved by Phase 2 (spec §C.2).
///
/// ## Three things here that the spec's §C.1 did not say, all found by reading
/// the code and ruled 2026-07-17:
///
/// 1. **The scanner is a one-way door if presented bare.** `QRScannerView` has
///    zero dismiss affordances (no `dismiss`, no `toolbar`, and
///    `QRScannerView.swift:136` sets `.navigationBarHidden(true)`) — it has never
///    needed one, because it is a *tab* (`ContentView.swift:229/:282`). Presented
///    modally it would recreate the C1 dead-end (§9.11). So the dismiss lives
///    **here, at the presentation site** — a `NavigationStack` + toolbar chevron,
///    mirroring the C1/C2 chevron precedent. `QRScannerView` is untouched.
///
/// 2. **Modal-over-modal.** A scan calls `DeepLinkService.shared.handleScannedCode`
///    (`QRScannerView.swift:20`), which sets one of three flags whose sheets hang
///    on `ContentView`'s `Group` *above* the route switch
///    (`ContentView.swift:64/:80/:95`). Those sheets are correctly placed and
///    correctly auth-branched — but nothing is presented when they fire today,
///    because the scanner is a tab. Presenting the scanner modally from here is
///    what introduces the conflict, so we **dismiss on flag** (below) to hand the
///    presentation context back before the sheet lands.
///
/// 3. **`OrderMoreTagsView` is NOT dependency-free**, contrary to spec §C.1:64:
///    it declares `@EnvironmentObject appState` + `authViewModel`
///    (`OrderMoreTagsView.swift:5-6`). It is logged-out-reachable *because*
///    `AuthenticationView.swift:271-273` re-injects them. Zone 2 mirrors that
///    exactly. Both are re-injected below; an uninjected `@EnvironmentObject` is
///    a hard crash on render, not a layout nit.
///
/// ⚠️ The scanner-dismiss → sheet-present handshake is a **presentation-timing**
/// question. It compiles, and no test settles it (this is the `Group`/`ZStack`
/// class of bug, §9.8). C3's done-when carries a device-QA gate covering all four
/// scan outcomes × three assertions each.
struct LandingView: View {
    // Required to re-inject into OrderMoreTagsView (see 3. above). ContentView
    // is always inside PetSafetyApp's injection (`PetSafetyApp.swift:135-136`),
    // so these are always populated here. This reads auth state; it does not
    // compute it — `isAuthenticated`'s derivation stays untouched (§2 boundary).
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState

    /// The same singleton `ContentView` observes (`ContentView.swift:10`) — so
    /// the flags we watch are the flags whose sheets it presents.
    @ObservedObject private var deepLinkService = DeepLinkService.shared

    /// Sign-in CTA → `nav.enterLogin()`.
    let onSignIn: () -> Void
    /// Register CTA → `nav.enterRegister()`.
    let onRegister: () -> Void
    /// Zone-3 nav intent. C3 emits; Phase 2 resolves (spec §C.2).
    let onNavigate: (CommunityDestination) -> Void

    @State private var showScanner = false
    @State private var showFoundStray = false
    @State private var showOrderTags = false

    /// True while any of `ContentView`'s three deep-link sheets wants the screen.
    /// Watched so the scanner can get out of the way — see 2. above.
    private var deepLinkWantsPresentation: Bool {
        deepLinkService.showScannedPetProfile
            || deepLinkService.showTagActivation
            || deepLinkService.showPromoClaimFlow
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                Text("SENRA")
                    .font(.appFont(size: 34, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, AppSpacing.xxl)

                zoneOneActNow
                zoneTwoOrder
                zoneThreeCommunity
                persistentAuthCTAs
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor").ignoresSafeArea())
        .fullScreenCover(isPresented: $showScanner) {
            NavigationStack {
                QRScannerView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button { showScanner = false } label: {
                                Image(systemName: "chevron.left")
                            }
                            .accessibilityLabel(Text("back"))
                        }
                    }
            }
        }
        .sheet(isPresented: $showFoundStray) {
            // Provides its own NavigationView (FoundPetFormView.swift:51) and
            // carries no @EnvironmentObject — present it bare.
            FoundPetFormView()
        }
        .sheet(isPresented: $showOrderTags) {
            // NavigationView wrapper + both re-injections mirror
            // AuthenticationView.swift:269-274 exactly.
            NavigationView {
                OrderMoreTagsView()
                    .environmentObject(appState)
                    .environmentObject(authViewModel)
            }
        }
        // Dismiss-on-flag. A scan sets one of ContentView's three flags; get the
        // scanner out of the presentation context so its sheet can land.
        .onChange(of: deepLinkWantsPresentation) { _, wants in
            if wants { showScanner = false }
        }
    }

    // MARK: - Zone 1 — Act now

    private var zoneOneActNow: some View {
        VStack(spacing: AppSpacing.sm) {
            Button { showScanner = true } label: {
                Text(String(localized: "landing_scan_cta"))
            }
            .buttonStyle(PrimaryPillButtonStyle())

            Button { showFoundStray = true } label: {
                Text(String(localized: "landing_found_stray_cta"))
            }
            .buttonStyle(SecondaryPillButtonStyle())
        }
    }

    // MARK: - Zone 2 — Order a tag

    private var zoneTwoOrder: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "tag.fill")
                    .font(.appFont(size: 22))
                    .foregroundColor(.brandOrange)
                    .accessibilityHidden(true)
                Text(String(localized: "landing_order_subtitle"))
                    .font(.appFont(size: 14))
                    .foregroundColor(.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button { showOrderTags = true } label: {
                Text(String(localized: "landing_order_cta"))
            }
            .buttonStyle(PrimaryPillButtonStyle())
        }
        .elevatedCard(padding: AppSpacing.lg)
    }

    // MARK: - Zone 3 — Community (data-driven; G-a holds by construction)

    private var zoneThreeCommunity: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "community_section_title"))
                .font(.appFont(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(CommunityEntry.seed) { entry in
                CommunityEntryCard(entry: entry) { onNavigate(entry.destination) }
            }
        }
    }

    // MARK: - Persistent — Sign in / Register

    private var persistentAuthCTAs: some View {
        // Reuses the SHIPPING `log_in` / `register` keys (13/13 locales), which
        // C1 already used here. Spec §F names `landing_sign_in`/`landing_register`;
        // minting those would be a second key for the same string.
        VStack(spacing: AppSpacing.sm) {
            Button(action: onSignIn) {
                Text(String(localized: "log_in"))
            }
            .buttonStyle(BrandButtonStyle())

            Button(action: onRegister) {
                Text(String(localized: "register"))
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.top, AppSpacing.sm)
    }
}

#Preview {
    LandingView(onSignIn: {}, onRegister: {}, onNavigate: { _ in })
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
