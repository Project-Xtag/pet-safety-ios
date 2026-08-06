import Testing
@testable import PetSafety

/// Pricing 2026-08 (C4) — the four-guard interstitial predicate.
///
/// This matrix must stay in sync with the web (subscribeInterstitial.test.ts)
/// and Android (SubscribeInterstitialDecisionTest) — the predicate is the
/// cross-platform contract. Baseline = a post-cutover Starter account
/// committing its first pet via plain activation.
@Suite("Subscribe Interstitial Decision")
struct SubscribeInterstitialDecisionTests {

    private func decide(
        postCutoverAccount: Bool? = true,
        preCommitPetCount: Int? = 0,
        planName: String? = "starter",
        subscriptionAction: String? = nil
    ) -> Bool {
        SubscribeInterstitialDecision.shouldShow(
            postCutoverAccount: postCutoverAccount,
            preCommitPetCount: preCommitPetCount,
            planName: planName,
            subscriptionAction: subscriptionAction
        )
    }

    // MARK: Firing cases

    @Test("fires for a plain activation (no subscription_action)")
    func firesForPlainActivation() {
        #expect(decide() == true)
    }

    @Test("fires for an event-gift claim (free_tag_activated grants nothing)")
    func firesForEventGiftClaim() {
        #expect(decide(subscriptionAction: "free_tag_activated") == true)
    }

    // MARK: Full subscription_action matrix — granting actions suppress

    @Test("suppresses on entitlement-granting claims", arguments: [
        "upgraded_to_standard_trial",
        "override_only",
        "covered_by_maximum",
    ])
    func suppressesGrantingActions(action: String) {
        #expect(decide(subscriptionAction: action) == false)
    }

    // MARK: INV-5 guard

    @Test("suppresses for a pre-cutover account")
    func suppressesPreCutover() {
        #expect(decide(postCutoverAccount: false) == false)
    }

    @Test("fail-safe-suppresses when the cutover flag is unknown")
    func failSafeUnknownCutover() {
        #expect(decide(postCutoverAccount: nil) == false)
    }

    // MARK: First-pet guard

    @Test("suppresses for an Nth pet")
    func suppressesNthPet() {
        #expect(decide(preCommitPetCount: 1) == false)
        #expect(decide(preCommitPetCount: 5) == false)
    }

    @Test("fail-safe-suppresses when the pre-commit count is unknown")
    func failSafeUnknownCount() {
        #expect(decide(preCommitPetCount: nil) == false)
    }

    // MARK: Entitlement guard

    @Test("suppresses already-entitled plans", arguments: ["standard", "maximum"])
    func suppressesEntitledPlans(plan: String) {
        #expect(decide(planName: plan) == false)
    }

    @Test("fail-safe-suppresses when the plan is unknown")
    func failSafeUnknownPlan() {
        #expect(decide(planName: nil) == false)
    }
}
