import Testing
import Foundation
@testable import PetSafety

/// Tests for `ConfigurationManager.infoPlistURL(_:fallback:bundle:)` — the
/// helper that reads build-config-driven URLs from Info.plist with graceful
/// fallback when the xcconfig is absent or the value didn't resolve.
@Suite("ConfigurationManager.infoPlistURL")
struct ConfigurationManagerInfoPlistURLTests {

    /// Minimal Bundle-like stand-in that lets tests inject arbitrary
    /// Info.plist values without touching the real main bundle.
    final class FakeBundle: Bundle {
        private let values: [String: Any]
        init(values: [String: Any]) {
            self.values = values
            super.init()
        }
        override func object(forInfoDictionaryKey key: String) -> Any? {
            return values[key]
        }
    }

    @Test("returns value from Info.plist when present and resolved")
    func returnsPlistValue() {
        let bundle = FakeBundle(values: ["API_BASE_URL": "https://staging.senra.pet/api"])
        let url = ConfigurationManager.infoPlistURL(
            "API_BASE_URL", fallback: "https://fallback", bundle: bundle
        )
        #expect(url == "https://staging.senra.pet/api")
    }

    @Test("falls back when the key is missing")
    func fallsBackOnMissingKey() {
        let bundle = FakeBundle(values: [:])
        let url = ConfigurationManager.infoPlistURL(
            "API_BASE_URL", fallback: "https://fallback", bundle: bundle
        )
        #expect(url == "https://fallback")
    }

    @Test("falls back when the value is empty")
    func fallsBackOnEmptyValue() {
        let bundle = FakeBundle(values: ["API_BASE_URL": ""])
        let url = ConfigurationManager.infoPlistURL(
            "API_BASE_URL", fallback: "https://fallback", bundle: bundle
        )
        #expect(url == "https://fallback")
    }

    @Test("falls back when the value is an unresolved build variable")
    func fallsBackOnUnresolvedPlaceholder() {
        // This is what Info.plist looks like when the xcconfig hasn't been
        // wired up yet — the literal `$(API_BASE_URL)` leaks through because
        // no build setting with that name exists.
        let bundle = FakeBundle(values: ["API_BASE_URL": "$(API_BASE_URL)"])
        let url = ConfigurationManager.infoPlistURL(
            "API_BASE_URL", fallback: "https://fallback", bundle: bundle
        )
        #expect(url == "https://fallback")
    }

    @Test("falls back when the value type is unexpected")
    func fallsBackOnWrongType() {
        let bundle = FakeBundle(values: ["API_BASE_URL": 12345])
        let url = ConfigurationManager.infoPlistURL(
            "API_BASE_URL", fallback: "https://fallback", bundle: bundle
        )
        #expect(url == "https://fallback")
    }
}
