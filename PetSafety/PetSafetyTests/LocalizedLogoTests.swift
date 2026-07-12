import Testing
import UIKit
@testable import PetSafety

/// Coverage for `LocalizedLogo` and the 13 `LogoNew_*` lockup assets it resolves
/// to (used on the content screens — auth / home). This restores the all-13-asset
/// existence check that moved out of `SplashScreenViewTests` when the C0 splash
/// switched to the plain `LaunchLogo` mark (round 2); the localized lockups are
/// still live, so their catalog coverage belongs here.
@Suite("LocalizedLogo")
struct LocalizedLogoTests {

    /// The 13 language logo assets `LocalizedLogo` can resolve to (12 language
    /// suffixes + the `LogoNew_EN` fallback). Hand-mirror of the (private)
    /// `LocalizedLogo.languageToSuffix` map — see the note in `resolvedLogoIsKnown`.
    private static let expectedLogoAssets: [String] = [
        "LogoNew_EN", "LogoNew_HU", "LogoNew_SK", "LogoNew_DE",
        "LogoNew_CS", "LogoNew_ES", "LogoNew_PT", "LogoNew_RO",
        "LogoNew_FR", "LogoNew_IT", "LogoNew_PL", "LogoNew_NO", "LogoNew_HR",
    ]

    private static let appBundle = Bundle(for: KeychainService.self)

    @Test("every localized LogoNew_* lockup asset exists in the compiled catalog")
    func everyLocalizedLogoAssetExists() {
        for name in Self.expectedLogoAssets {
            let image = UIImage(named: name, in: Self.appBundle, compatibleWith: nil)
            #expect(image != nil, "Missing localized logo asset: \(name)")
        }
    }

    @Test("LocalizedLogo resolves this host's locale to one of the known assets")
    func resolvedLogoIsKnown() {
        // NOTE (inconclusive by design): the list above is a hand-mirror of
        // `LocalizedLogo.languageToSuffix`, which is `private` and so isn't reachable
        // via `@testable import`. Making it (or an `allLogoAssetNames`) `internal`
        // would let this assert against the source of truth.
        let name = LocalizedLogo.imageName
        #expect(name.hasPrefix("LogoNew_"))
        #expect(Self.expectedLogoAssets.contains(name))
    }
}
