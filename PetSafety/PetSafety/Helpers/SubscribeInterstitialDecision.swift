import Foundation

/// Pricing 2026-08 (C4) — the post-first-pet subscribe interstitial predicate.
///
/// Mirror of the web's lib/subscribeInterstitial.ts and Android's
/// SubscribeInterstitialDecision — the four guards and their fail-safes must
/// stay behaviour-equivalent across platforms.
///
/// Evaluated ONLY after a successful commit (the "commit succeeded" guard is
/// positional, not an input). Every guard fails safe: a nil input can only
/// suppress, never show — a missed interstitial is caught by the C6 nudge
/// job, while a wrongly shown one would wall a grandfathered or
/// just-entitled user (INV-5).
enum SubscribeInterstitialDecision {

    /// claim-promo outcomes that GRANT entitlement — never pitch on top.
    /// "free_tag_activated" (event-gift) grants nothing and behaves like a
    /// plain activation.
    private static let grantingActions: Set<String> = [
        "upgraded_to_standard_trial",
        "override_only",
        "covered_by_maximum",
    ]

    /// - Parameters:
    ///   - postCutoverAccount: server-computed INV-5 flag from
    ///     /my-subscription (`post_cutover_account`); nil = unknown/old backend.
    ///   - preCommitPetCount: `limits.current_pet_count` snapshotted BEFORE
    ///     the commit call; nil = fetch failed.
    ///   - planName: the account's plan at commit time; only "starter" fires.
    ///   - subscriptionAction: claim-promo outcome; nil for the plain
    ///     /qr-tags/activate path.
    static func shouldShow(
        postCutoverAccount: Bool?,
        preCommitPetCount: Int?,
        planName: String?,
        subscriptionAction: String?
    ) -> Bool {
        guard postCutoverAccount == true else { return false }
        guard preCommitPetCount == 0 else { return false }
        guard planName?.lowercased() == "starter" else { return false }
        if let action = subscriptionAction, grantingActions.contains(action) {
            return false
        }
        return true
    }
}
