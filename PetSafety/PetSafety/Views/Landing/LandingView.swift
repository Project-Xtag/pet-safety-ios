import SwiftUI

/// Logged-out landing surface (C1 — 1.1a scaffold).
///
/// Minimal but real: the persistent Sign-in / Register CTAs make this a
/// routable default (they drive `RootNavState.enterLogin()` / `enterRegister()`
/// via the closures below). Zone 2 (features) and Zone 3 (community cards) are
/// populated in C3 (1.1b) — they are intentionally absent here, not stubbed
/// with placeholders (G-a: no "coming soon", no zero-height filler).
struct LandingView: View {
    /// Sign-in CTA → `nav.enterLogin()`.
    let onSignIn: () -> Void
    /// Register CTA → `nav.enterRegister()`.
    let onRegister: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Wordmark. `.primary` (not `.ink`) so it stays legible on the dark
            // `BackgroundColor` variant.
            Text("SENRA")
                .font(.appFont(size: 34, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            // Persistent CTAs — the functional core of the C1 scaffold. Reuse
            // the existing button primitives (G-b): brand primary + secondary.
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
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Dark-mode-aware redesign background (light cream / dark navy), the
        // same asset the splash uses — not the light-only `Color.cream`.
        .background(Color("BackgroundColor").ignoresSafeArea())
    }
}

#Preview {
    LandingView(onSignIn: {}, onRegister: {})
}
