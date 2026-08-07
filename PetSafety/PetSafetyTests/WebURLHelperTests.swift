import Testing
import Foundation
@testable import PetSafety

/// Pins the two halves of `WEB-HANDOFF-CONTRACT.md` §3/§5 that shipped wrong:
/// the market segment and the host.
///
/// ⚠️ The two halves are asserted INDEPENDENTLY, on purpose. Market assertions
/// read `URL.path`, which ignores the host; host assertions never mention the
/// path. That is what lets each half be reverted on its own and fail alone — an
/// assertion on the whole URL string would fail for either mutation and so prove
/// neither.
///
/// ⚠️ Why the market assertions cannot vary a region here. `WebURLHelper` no
/// longer takes a region input at all — that *is* the fix, and there is nothing
/// left to sweep. Android can vary it (`Locale.setDefault`) and does, because
/// Android keeps `countryCode` for `LocalizedLogo` while iOS deleted it. The
/// asymmetry is real and deliberate; the guard against reintroduction here is
/// the board pin plus the mutation run.
@Suite("WebURLHelper — host and market")
struct WebURLHelperTests {

    /// Same stand-in as `ConfigurationManagerInfoPlistURLTests`, so the seam is
    /// exercised the way its owner already tests it.
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

    private let staging = FakeBundle(values: ["WEB_BASE_URL": "https://staging-app.senra.pet"])

    @Test("nonHURegionStillYieldsHUPath")
    func nonHURegionStillYieldsHUPath() {
        // ⚠️ ASSERTED, not merely recorded — this is the test's discriminating
        // precondition and it must be loud.
        //
        // The helper takes no region input, so these assertions hold on any host.
        // But the MUTATION that guards them does not: revert the helper to a
        // device-region lookup and this test fails only if the host's region is
        // not HU. On an HU-region machine the mutation yields /hu/ anyway, the
        // test passes, and the mutation goes green while proving nothing — a
        // checked=0 wearing a test suite.
        //
        // Failing loudly on an HU-region host is the correct outcome. Passing
        // vacuously is not. Set the simulator's region to anything but HU.
        let region = Locale.current.region?.identifier ?? "none"
        #expect(
            region != "HU",
            """
            This test only discriminates on a NON-HU host; region is \(region). \
            On an HU-region host a reverted (region-derived) helper would still \
            produce /hu/ and this test would pass vacuously. Change the simulator \
            region, do not weaken the assertion.
            """
        )

        for path in ["/choose-plan", "/terms-conditions", "/privacy-policy", "/anything"] {
            #expect(
                WebURLHelper.url(path: path, bundle: staging).path == "/hu\(path)",
                "market must be the /hu/ literal for \(path) (host region: \(region))"
            )
        }

        // The bug's namesake, by path so a host mutation cannot mask it.
        #expect(!WebURLHelper.url(path: "/choose-plan", bundle: staging).path.hasPrefix("/uk/"))
    }

    @Test("webHostFollowsBuildConfiguration")
    func webHostFollowsBuildConfiguration() {
        // Host only — no path assertion, so a market mutation cannot fail this.
        #expect(WebURLHelper.host(bundle: staging) == "https://staging-app.senra.pet")
        #expect(WebURLHelper.host(bundle: FakeBundle(values: ["WEB_BASE_URL": "https://senra.pet"]))
                == "https://senra.pet")

        let host = WebURLHelper.url(path: "/choose-plan", bundle: staging).host
        #expect(host == "staging-app.senra.pet",
                "a staging build must land on staging web, not production")
    }

    @Test("host falls back to prod when the key is missing or unresolved")
    func hostFallsBackToProd() {
        // Matches apiBaseURL's contract: a build whose xcconfig isn't wired must
        // still work, and must land on prod rather than on nothing.
        #expect(WebURLHelper.host(bundle: FakeBundle(values: [:])) == "https://senra.pet")
        #expect(WebURLHelper.host(bundle: FakeBundle(values: ["WEB_BASE_URL": "$(WEB_BASE_URL)"]))
                == "https://senra.pet")
    }

    @Test("termsAndPrivacyURLsCarryHUPath")
    func termsAndPrivacyURLsCarryHUPath() {
        // The seven legal links move with the helper; two of them are shown at
        // the moment a user agrees to the terms. By path, so this pins the market
        // half only.
        #expect(WebURLHelper.termsURL.path == "/hu/terms-conditions")
        #expect(WebURLHelper.privacyURL.path == "/hu/privacy-policy")
    }

    @Test("validCountryCodes remains for INBOUND link parsing only")
    func validCountryCodesIsInboundOnly() {
        // Kept because DeepLinkService strips a country prefix off links the
        // SERVER sent (/hu/qr/ABC -> /qr/ABC). That is parsing, not market
        // selection — the distinction that let regionToCountry be deleted while
        // this survived.
        #expect(WebURLHelper.validCountryCodes.contains("hu"))
        #expect(WebURLHelper.validCountryCodes.contains("uk"))
        #expect(WebURLHelper.validCountryCodes.count == 13)
    }
}
