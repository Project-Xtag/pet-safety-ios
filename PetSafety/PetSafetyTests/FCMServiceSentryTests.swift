import XCTest
@testable import PetSafety

/**
 * Regression test for FCM register/unregister error escalation (audit #10).
 *
 * Why this test exists:
 *   Audit #10 flagged AuthViewModel.swift:242's FCM register call as
 *   fire-and-forget with no error telemetry — "user can be logged-in-but-
 *   pushless silently". The fix lives one layer down in FCMService:
 *   both `registerToken` and `removeToken` already wrap the APIService
 *   call in a do/catch and call `SentrySDK.capture(error:)` on failure.
 *   That contract is what stops a degraded backend from creating an
 *   invisible class of pushless users.
 *
 *   Source-level pin so a refactor that drops the Sentry capture (e.g.
 *   "let the caller handle it" without updating callers) fails CI.
 */
final class FCMServiceSentryTests: XCTestCase {

    private func loadFCMServiceSource() throws -> String {
        let testFile = #filePath
        let testDir = (testFile as NSString).deletingLastPathComponent
        let projectRoot = (testDir as NSString).deletingLastPathComponent
        let path = "\(projectRoot)/PetSafety/Services/FCMService.swift"
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    func testRegisterTokenEscalatesFailures() throws {
        let src = try loadFCMServiceSource()
        // The catch arm of registerToken must Sentry-capture the error.
        // Without this the AuthViewModel-level call site has no other
        // signal — APIService logs are already terminal.
        XCTAssertTrue(
            src.contains("fcm_register_failed"),
            "registerToken must tag the Sentry capture with operation=fcm_register_failed (audit #10)"
        )
    }

    func testRemoveTokenEscalatesFailures() throws {
        let src = try loadFCMServiceSource()
        XCTAssertTrue(
            src.contains("fcm_unregister_failed"),
            "removeToken must tag the Sentry capture with operation=fcm_unregister_failed (audit #10)"
        )
    }

    func testCaptureGuardedBySentrySDKEnabled() throws {
        let src = try loadFCMServiceSource()
        // Per memory: always guard SentrySDK calls with isEnabled to avoid
        // "SDK is disabled" noise when Sentry DSN isn't configured.
        XCTAssertTrue(
            src.contains("SentrySDK.isEnabled"),
            "Sentry calls must be guarded by SentrySDK.isEnabled"
        )
    }
}
