import SwiftUI

/// Returns the correct logo asset name based on the device's preferred language.
/// Country-specific logos include automatic light/dark mode support via xcassets appearances.
enum LocalizedLogo {
    /// Maps language codes to logo asset suffixes.
    /// Uses language (not region) so the logo matches the UI language the user chose.
    private static let languageToSuffix: [String: String] = [
        "hu": "HU",
        "sk": "SK",
        "de": "DE",
        "cs": "CS",
        "es": "ES",
        "pt": "PT",
        "ro": "RO",
    ]

    /// The xcassets image name for the current device language.
    /// Falls back to LogoNew_EN which has proper light/dark mode variants.
    static var imageName: String {
        // Prefer the app's resolved language from the main bundle (respects the user's
        // language preference list intersected with the app's available localizations).
        // Falls back to Locale.current which reflects the same on iOS 16+.
        let languageCode: String = {
            if let preferred = Bundle.main.preferredLocalizations.first {
                // preferredLocalizations returns codes like "hu", "cs", "de", "en"
                return preferred.lowercased()
            }
            return Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        }()

        if let suffix = languageToSuffix[languageCode] {
            return "LogoNew_\(suffix)"
        }
        return "LogoNew_EN"
    }
}
