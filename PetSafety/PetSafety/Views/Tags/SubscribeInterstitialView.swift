import SwiftUI
import UIKit

/// Pricing 2026-08 (C4) — the post-first-pet forced subscribe choice.
///
/// Presented as a `.fullScreenCover`, which has no interactive dismissal on
/// iOS — the only exits are the two explicit choices (INV-8 forced choice).
/// Subscribe deep-links out to the web choose-plan page (subscriptions are
/// web-only; no IAP), country-prefixed via WebURLHelper, then closes the
/// cover so the user returns to the wizard's success step.
///
/// Copy ratified 2026-07-24 (HU canonical, te-form, claims bounded to
/// enforced gates; no pet-cap, no "free plan"). HU + EN ship; other locales
/// fall back to EN per the platform default.
struct SubscribeInterstitialView: View {
    /// Called for BOTH choices once handled — the host clears the
    /// presentation flag; Subscribe additionally opens the web checkout.
    let onDismiss: () -> Void

    @Environment(\.openURL) private var openURL
    private let brand = Color("BrandColor")

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("subscribe_interstitial_title")
                .font(.appFont(.title2))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Text("subscribe_interstitial_body")
                .font(.appFont(.subheadline))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 28)

            Spacer()

            Button {
                openURL(WebURLHelper.url(path: "/choose-plan"))
                onDismiss()
            } label: {
                Text("subscribe_interstitial_cta_subscribe")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .padding(.horizontal, 24)

            Button {
                onDismiss()
            } label: {
                Text("subscribe_interstitial_cta_not_now")
                    .font(.appFont(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemBackground))
    }
}
