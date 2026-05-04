import Testing
import Foundation
@testable import PetSafety

/**
 * M10 — pin the iOS App Check enforcement seam. The pre-fix client
 * always proceeded without the X-Firebase-AppCheck header when token
 * retrieval failed, even if Remote Config's `app_check_enforce_client_ios`
 * was flipped on. Once the backend's WS8.7 enforcement ships, that would
 * silently break iOS clients with no client-side override.
 *
 * The fix:
 *   1. Adds `app_check_enforce_client_ios` to ConfigurationManager defaults
 *      (default `false` — fail-open until backend ready).
 *   2. Adds `shouldEnforceAppCheckClient()` synchronous getter for the flag.
 *   3. Adds `APIError.appCheckRequired` and has APIService throw it when
 *      Release + token unavailable + flag on.
 *
 * These tests pin (1)–(3) as pure-logic seams; the actual networking
 * branch is covered by a source-regression assertion since URLSession
 * stubbing is heavyweight in iOS.
 */
@Suite("App Check enforcement (M10)")
struct AppCheckEnforcementTests {

    @Test("APIError.appCheckRequired carries a non-empty user-visible description")
    func appCheckErrorHasDescription() {
        let error = APIError.appCheckRequired
        let description = error.errorDescription
        #expect(description != nil)
        #expect(!(description ?? "").isEmpty)
        // Should NOT be the literal localization key — that means the .strings
        // entry is missing and the user would see "api_error_app_check_required"
        // verbatim.
        #expect(description != "api_error_app_check_required")
    }

    @Test("shouldEnforceAppCheckClient defaults to false on a cold start")
    func enforcementDefaultsFalseColdStart() {
        // Singleton — on a fresh process before fetchConfiguration() lands,
        // remoteConfig is nil and the getter must NOT throw or return true.
        // Otherwise every cold-start request would synthesise a 503.
        let result = ConfigurationManager.shared.shouldEnforceAppCheckClient()
        #expect(result == false)
    }

    @Test("source — ConfigurationManager registers the enforce flag default")
    func sourceRegistersEnforceFlagDefault() throws {
        let url = try sourceFile("Services/ConfigurationManager.swift")
        let source = try String(contentsOf: url, encoding: .utf8)
        #expect(source.contains("\"app_check_enforce_client_ios\""),
                "ConfigurationManager defaults must include app_check_enforce_client_ios")
        #expect(source.contains("shouldEnforceAppCheckClient"),
                "ConfigurationManager must expose shouldEnforceAppCheckClient()")
    }

    @Test("source — APIService fails closed via APIError.appCheckRequired in Release")
    func sourceFailsClosedInRelease() throws {
        let url = try sourceFile("Services/APIService.swift")
        let source = try String(contentsOf: url, encoding: .utf8)
        // The fail-closed branch must throw the dedicated error case; a
        // generic .invalidResponse or .unauthorized would not be retryable
        // by the client and would mislead Sentry triage.
        #expect(source.contains("throw APIError.appCheckRequired"),
                "APIService must throw appCheckRequired when enforcement is on and token is missing")
        // The branch must be guarded by !DEBUG so debug builds never
        // synthesise 503s — the backend doesn't enforce in dev anyway and
        // Firebase debug-token exchanges 403 noisily.
        #expect(source.contains("#if !DEBUG"),
                "Fail-closed branch must be gated behind !DEBUG")
        #expect(source.contains("shouldEnforceAppCheckClient()"),
                "Fail-closed branch must consult ConfigurationManager.shouldEnforceAppCheckClient()")
    }

    @Test("source — Localizable.strings includes the user-visible enforcement message")
    func sourceLocalisableStringsHaveKey() throws {
        let url = try sourceFile("Resources/en.lproj/Localizable.strings")
        let source = try String(contentsOf: url, encoding: .utf8)
        #expect(source.contains("\"api_error_app_check_required\""))
    }

    /// Resolves a path inside the PetSafety app source tree relative to
    /// this test file's location at compile time. xcodebuild test runs
    /// in a sandbox where FileManager.currentDirectoryPath isn't the
    /// project root, so #filePath is the only reliable anchor — same
    /// pattern as LocalizationParityTests.loadKeysViaPath.
    private func sourceFile(_ relativePath: String) throws -> URL {
        let testFile = URL(fileURLWithPath: #filePath)
        let candidate = testFile
            .deletingLastPathComponent()           // PetSafetyTests/
            .deletingLastPathComponent()           // PetSafety/ (xcodeproj level)
            .appendingPathComponent("PetSafety")
            .appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: candidate.path) else {
            throw NSError(
                domain: "AppCheckEnforcementTests",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not locate \(relativePath) at \(candidate.path)"]
            )
        }
        return candidate
    }
}
