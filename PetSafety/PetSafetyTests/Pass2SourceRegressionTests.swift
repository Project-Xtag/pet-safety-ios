import Testing
import Foundation

/// Pass 2 audit fix regression tests.
///
/// These tests read source files and assert that the specific shapes the
/// audit introduced are still in place — a cheaper alternative to full
/// XCUI / integration tests for guards that live in function bodies
/// (e.g. "the Verify OTP button has an isLoading re-entrancy guard").
///
/// If any of these assertions fail, someone has regressed a Pass 2 fix
/// and should re-read /Users/viktorszasz/.claude/plans/tender-kindling-boole.md
/// before touching the affected file.
@Suite("Pass 2 — source regression guards")
struct Pass2SourceRegressionTests {

    private static let projectRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // .../PetSafetyTests/
        .deletingLastPathComponent()  // .../PetSafety/
        .appendingPathComponent("PetSafety")

    private static func readSource(_ relativePath: String) throws -> String {
        let url = projectRoot.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Double-tap guards

    @Test("AuthenticationView.verifyOTP() has an isLoading re-entrancy guard")
    func testAuthenticationViewDoubleTapGuard() throws {
        let src = try Self.readSource("Views/Auth/AuthenticationView.swift")
        #expect(
            src.contains("guard !authViewModel.isLoading else { return }"),
            "verifyOTP must early-return when a verify is already in-flight"
        )
    }

    @Test("RegistrationView.verifyOTP() has an isLoading re-entrancy guard")
    func testRegistrationViewDoubleTapGuard() throws {
        let src = try Self.readSource("Views/Auth/RegistrationView.swift")
        #expect(
            src.contains("guard !authViewModel.isLoading else { return }"),
            "Registration verifyOTP must early-return when a verify is already in-flight"
        )
    }

    // MARK: - Logout / FCM ordering

    @Test("AuthViewModel.logout is async and awaits FCM unregister")
    func testLogoutIsAsync() throws {
        let src = try Self.readSource("ViewModels/AuthViewModel.swift")
        // The signature must be async so callers can await it before
        // dropping local auth state. Fire-and-forget left a window where
        // the next login could inherit stale pushes.
        #expect(
            src.contains("func logout() async"),
            "AuthViewModel.logout() must be async"
        )
        #expect(
            src.contains("await unregisterFCMToken()"),
            "logout() must await the FCM unregister call, not fire-and-forget it"
        )
        #expect(
            src.contains("private func unregisterFCMToken() async"),
            "unregisterFCMToken must be async so logout can await it"
        )
    }

    @Test("Account deletion awaits logout() instead of calling MainActor.run")
    func testAccountDeletionAwaitsLogout() throws {
        let src = try Self.readSource("Views/Profile/HelpAndSupportView.swift")
        #expect(
            src.contains("await authViewModel.logout()"),
            "performDeleteAccount must await logout so FCM cleanup completes"
        )
        // Regression: the old MainActor.run { authViewModel.logout() } shape
        // is gone — it fired logout sync, which returned before FCM had
        // been revoked on the backend.
        #expect(
            !src.contains("await MainActor.run {\n                    authViewModel.logout()\n                }"),
            "old MainActor.run { authViewModel.logout() } pattern must be removed"
        )
    }

    // MARK: - AppCheck observability

    @Test("APIService logs to Sentry when App Check token is unavailable")
    func testAppCheckTokenMissingLogged() throws {
        let src = try Self.readSource("Services/APIService.swift")
        // We don't want a silent failure when Firebase App Check drifts.
        #expect(
            src.contains("SentrySDK.capture(message: \"App Check token unavailable\")"),
            "APIService must surface missing App Check token via Sentry"
        )
    }

    // MARK: - Referral code validation

    @Test("ReferralView filters friend code input + caps length")
    func testReferralFriendCodeFilter() throws {
        let src = try Self.readSource("Views/Subscription/ReferralView.swift")
        // Filter to letters + digits, upper-cased, max 32 chars.
        #expect(
            src.contains(".filter { $0.isLetter || $0.isNumber }"),
            "ReferralView must filter non-alphanumeric input"
        )
        #expect(
            src.contains("String(filtered.prefix(32))"),
            "ReferralView must cap friend code length to 32 characters"
        )
        // Apply-button guard must require a minimum non-empty length.
        #expect(
            src.contains(".disabled(friendCode.count < 4"),
            "Apply button must require at least 4 characters"
        )
    }
}
