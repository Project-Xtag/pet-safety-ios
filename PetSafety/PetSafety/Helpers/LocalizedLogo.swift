import SwiftUI

/// Returns the correct logo asset name based on device locale/region.
/// Country-specific logos include automatic light/dark mode support via xcassets appearances.
enum LocalizedLogo {
    private static let countryToSuffix: [String: String] = [
        "hu": "HU", "sk": "SK", "de": "DE", "at": "DE",
        "cz": "CS", "es": "ES", "pt": "PT", "ro": "RO",
    ]

    /// The xcassets image name for the current device locale.
    static var imageName: String {
        let country = WebURLHelper.countryCode
        if let suffix = countryToSuffix[country] {
            return "LogoNew_\(suffix)"
        }
        return "LogoNew"
    }
}
