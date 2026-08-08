import SwiftUI
import UIKit

/// Pricing 2026-08 (C4) — the post-first-pet forced subscribe choice.
///
/// Presented as a `.fullScreenCover`, which has no interactive dismissal on
/// iOS — the only exits are the two explicit choices (INV-8 forced choice).
///
/// **U4 (chunk 3): Subscribe now calls the handoff endpoint and opens whatever
/// comes back**, per `WEB-HANDOFF-CONTRACT.md` §5. Any failure — non-200,
/// timeout, malformed body, or a 200 whose `url` is not absolute https — falls
/// back to `WebURLHelper.url(path: "/choose-plan")`, which is never worse than
/// the pre-U4 behaviour. Until U1 is deployed every call 404s and every user
/// gets exactly today's flow.
///
/// ⚠️ **Dismiss ordering is B: the cover stays up until the call resolves.**
/// The rejected ordering (dismiss first, open later) drops the user back on the
/// wizard success step and then launches a browser over whatever they started
/// doing up to 3s later — an unexplained interruption on a payment path. It
/// would also leave the pre-redirect notice with no surface to live on, since
/// the notice would be torn down with the cover before the call resolved.
///
/// B's own failure mode is "apparently frozen", and the forced-choice invariant
/// means the user cannot escape it — so the wait MUST show motion, not just
/// copy. That is what `ProgressView` beside the notice is for; a static notice
/// here would be a screen the user is trapped in with no evidence anything is
/// happening.
///
/// Copy ratified 2026-07-24 (HU canonical, te-form, claims bounded to
/// enforced gates; no pet-cap, no "free plan"). HU + EN ship; the notice is the
/// fifth key of this HU-scoped surface and is allowlisted in
/// `LocalizationParityTests.huOnlyKeys`.
struct SubscribeInterstitialView: View {
    /// Called for BOTH choices once handled — the host clears the
    /// presentation flag; Subscribe additionally opens the web checkout.
    let onDismiss: () -> Void

    /// Seams, defaulted so no call site changes (PROTOCOL §6: supplying a
    /// dependency through a defaulted parameter is a seam, not a derivation
    /// change). Tests drive both branches without a network.
    var handoff: () async throws -> URL = { try await APIService.shared.webHandoff() }
    var fallbackURL: () -> URL = { WebURLHelper.url(path: "/choose-plan") }

    @Environment(\.openURL) private var openURL
    @State private var isRedirecting = false

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

            // The pre-redirect notice owns the wait. Reserved with `opacity`
            // rather than inserted conditionally so the CTA does not jump down
            // the screen the instant it is tapped.
            HStack(spacing: 8) {
                ProgressView()
                Text("subscribe_interstitial_redirect_notice")
                    .font(.appFont(.footnote))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
            .opacity(isRedirecting ? 1 : 0)
            .accessibilityHidden(!isRedirecting)

            Button {
                startHandoff()
            } label: {
                Text("subscribe_interstitial_cta_subscribe")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .padding(.horizontal, 24)
            .disabled(isRedirecting)

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
            // Declining mid-flight would tear the cover down and then open a
            // browser over the wizard — ordering A's failure mode reached by a
            // different button.
            .disabled(isRedirecting)
        }
        .background(Color(UIColor.systemBackground))
    }

    /// One in-flight call at a time. §4 rate-limits the issue endpoint per
    /// user, so a double-tap would burn a second handoff token for a URL that
    /// is never opened. `.disabled` already blocks the second tap; the guard
    /// makes it true of the logic rather than of the styling.
    private func startHandoff() {
        guard !isRedirecting else { return }
        isRedirecting = true
        Task {
            let destination: URL
            do {
                destination = try await handoff()
            } catch {
                destination = fallbackURL()
            }
            openURL(destination)
            isRedirecting = false
            onDismiss()
        }
    }
}
