import Testing
import Foundation
@testable import PetSafety

/// U4 — `WEB-HANDOFF-CONTRACT.md` §1/§5.
///
/// ⚠️ **What is NOT tested here, and why — read before adding a timeout test.**
///
/// The 3s budget's *behavioural* half — that the value actually reaches the
/// transport — has no unit test on iOS. `APIService` sends through
/// `CertificatePinningService.shared.pinnedSession`, a custom `URLSession`
/// whose configuration never sets `protocolClasses`, and a throwaway probe
/// **measured** that `URLProtocol.registerClass` does not intercept it
/// (`didIntercept=false`, 2026-08-07). Making it interceptable means putting a
/// test seam through certificate-pinning code, which is a real decision rather
/// than a detail.
///
/// So the property is covered by two other means and it is worth knowing which:
///   * **structural** — two board pins, one on the wrapper expression and one
///     on the literal `Double = 3.0`. It took two, because a single pin on
///     `request.timeoutInterval = 3` was green on code that hung forever, and a
///     single pin on the wrapper stays green with the value edited to 30.
///   * **behavioural** — the device pass, under a blackholed network, observing
///     the fallback fire at the budget rather than at 30s. Same shape as chunk 2
///     reading the installed `Info.plist`: the observation the unit tests
///     structurally cannot make.
///
/// ⚠️ **Measured limit of the test below, stated so nobody over-reads it.**
/// `budgetBoundsAHangingTokenFetch` calls `withBudget` *directly*. It proves the
/// helper bounds a hang; it proves nothing about whether `webHandoff` still
/// calls it. Mutation-verified 2026-08-07: deleting the wrapper from
/// `webHandoff` leaves all 387 tests passing and only the board pin red. So on
/// iOS the wiring's sole automated guard is that pin — a fact about the seam,
/// not about this file, and the reason the pin's exact text is load-bearing.
///
/// Android has both halves as real tests (`WebHandoffTest`) because its
/// transport is reachable via MockWebServer. The asymmetry is deliberate and
/// measured, not an oversight.
@Suite("Web handoff (U4)")
struct WebHandoffTests {

    @Test("budgetBoundsAHangingTokenFetch", .timeLimit(.minutes(1)))
    func budgetBoundsAHangingTokenFetch() async {
        // ⚠️ THIS IS THE DEFECT THAT SHIPPED PAST EVERY GREEN CHECK.
        //
        // `buildRequest` awaits `getAppCheckToken()` → `AppCheck.token(...)`, a
        // network call with no timeout, BEFORE any request object exists. So
        // `URLRequest.timeoutInterval` could not bound it, and with no route to
        // Firebase the interstitial hung forever — on a forced-choice surface
        // with no dismissal gesture, on a payment path. Found on a device.
        //
        // The `URLProtocol` probe established the transport is unreachable from
        // tests (custom URLSession, no `protocolClasses`), but this defect lives
        // at the seam BEFORE the transport — so a work closure that never
        // returns reproduces it, without going near certificate pinning.
        //
        // ⚠️ THE STAND-IN HAS TO BE UNCANCELLABLE, AND THE FIRST VERSION WAS NOT.
        //
        // This test used `try await Task.sleep(nanoseconds: 60_000_000_000)`,
        // above a comment claiming a closure that "never returns reproduces it
        // exactly." Task.sleep DOES return — by throwing, the instant it is
        // cancelled. So it exercised the one case the old task-group
        // implementation could handle, and passed at ~3s while the budget was
        // inert against a real Firebase bridge. Measured both ways: cancellable
        // 3.024s, uncancellable ran to this test's 60s time limit.
        //
        // A continuation that is never resumed has no cancellation handler and
        // therefore cannot be cancelled — which is what an ObjC
        // completion-handler bridge looks like to Swift concurrency, and what
        // `AppCheck.appCheck().token(...)` is.
        let started = Date()

        await #expect(throws: (any Error).self) {
            try await APIService.withBudget(seconds: APIService.handoffBudgetSeconds) {
                // Stands in for a token fetch that never returns AND cannot be
                // cancelled. Do not "simplify" this back to Task.sleep.
                await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in }
                return URL(string: "https://never.example")!
            }
        }

        let elapsed = Date().timeIntervalSince(started)
        // Upper bound: it must not run to the inherited 30s, and a hang must
        // surface as a failed test rather than a stalled suite (hence the
        // .timeLimit trait as well).
        #expect(elapsed < 10, "budget did not bound the hang — took \(elapsed)s")
        // Lower bound, and it matters as much: without it, a throw for the
        // WRONG reason (a compile-time-immediate failure, a cancelled group)
        // would satisfy the assertion above. This proves it actually waited the
        // budget out.
        #expect(elapsed >= 2.5, "returned in \(elapsed)s — too fast to have waited the 3s budget")
    }

    @Test("the budget lets fast work through untouched")
    func budgetPassesFastWork() async throws {
        // Control for the test above: if the budget threw unconditionally, that
        // test would pass while proving nothing.
        let value = try await APIService.withBudget(seconds: APIService.handoffBudgetSeconds) {
            URL(string: "https://senra.pet/hu/choose-plan")!
        }
        #expect(value.absoluteString == "https://senra.pet/hu/choose-plan")
    }

    @Test("malformed200FallsBackToDirectURL")
    func malformed200FallsBackToDirectURL() {
        // A 200 whose `url` is not an absolute https URL is a FAILURE per §5's
        // "malformed body" — the caller falls back exactly as it does for 4xx.
        // Every shape below is one a lenient parser would accept.
        for raw in [
            "/hu/choose-plan",                     // relative path
            "http://senra.pet/hu/choose-plan",     // wrong scheme
            "https:///hu/choose-plan",             // empty host
            "not a url at all",                    // junk
            "",                                    // empty
        ] {
            #expect(
                APIService.usableHandoffURL(raw) == nil,
                "a 200 carrying url=\"\(raw)\" must be treated as a failure"
            )
        }
    }

    @Test("a well-formed https URL is accepted")
    func wellFormedURLAccepted() {
        // The control: if the validator rejected everything, the test above
        // would pass while proving nothing.
        let ok = APIService.usableHandoffURL("https://senra.pet/hu/choose-plan?handoff=abc")
        #expect(ok != nil)
        #expect(ok?.host == "senra.pet")
    }

    @Test("locale_hint is a language subtag and can never carry a region")
    func localeHintIsLanguageOnly() {
        // §3/§9.4. `.language.languageCode` cannot express a region, which is
        // what keeps the ban structural rather than conventional — `.region` is
        // one word away and is the /uk/ bug.
        let hint = APIService.localeHint()
        if let hint {
            #expect(!hint.contains("-"), "locale_hint must be a bare language subtag, got \(hint)")
            #expect(!hint.contains("_"), "locale_hint must be a bare language subtag, got \(hint)")
            #expect(hint == hint.lowercased())
        }
    }

    @Test("the destination enum carries §2's frozen wire values")
    func destinationWireValues() {
        // §8 freezes these strings. A rename is a store cycle, not a refactor.
        #expect(WebHandoffDestination.choosePlan.rawValue == "choose_plan")
        #expect(WebHandoffDestination.manageSubscription.rawValue == "manage_subscription")
        #expect(WebHandoffDestination.account.rawValue == "account")
        #expect(WebHandoffDestination.orders.rawValue == "orders")
    }

    @Test("the request encodes locale_hint as snake_case on the wire")
    func requestEncodesSnakeCase() throws {
        // The decoder/encoder use no key strategy, so the wire names are only
        // correct because CodingKeys spells them out. A silent rename here
        // would be a wire-shape mismatch with unit tests green — the family the
        // byte-review protocol exists for.
        let data = try JSONEncoder().encode(
            WebHandoffRequest(destination: "choose_plan", localeHint: "hu")
        )
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"locale_hint\""))
        #expect(!json.contains("\"localeHint\""))
    }
}
