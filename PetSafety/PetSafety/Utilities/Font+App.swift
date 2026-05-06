import SwiftUI
import UIKit

/// Inter as the app's typeface.
///
/// Two helpers are provided so the migration from `.font(.system(...))`
/// can sweep both the explicit-size pattern and the Dynamic Type
/// pattern without losing accessibility behaviour:
///
///   - `.appFont(size:weight:)`  — direct replacement for
///     `.font(.appFont(size: X, weight: .Y))`. Maps the SwiftUI
///     `Font.Weight` to the corresponding bundled Inter weight.
///
///   - `.appFont(_:weight:)`     — direct replacement for the named
///     Dynamic Type styles (`.font(.appFont(.body))`, `.font(.appFont(.headline))` etc.).
///     Uses `Font.custom(_:size:relativeTo:)` so the rendered size
///     still scales with Settings → Accessibility → Display & Text
///     Size, just like `Font.system` did.
///
/// Inter is OFL-licensed and bundled as static TTFs under
/// PetSafety/Resources/Fonts (rsms/inter v4.1).
extension Font {

    // MARK: Explicit-size + weight (replaces Font.system(size:weight:))
    static func appFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(interName(for: weight), size: size)
    }

    // MARK: Dynamic Type style + weight (replaces named Font.body / .headline / etc.)
    static func appFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        let (defaultSize, defaultWeight) = style.defaultMetrics
        let resolvedWeight = weight == .regular ? defaultWeight : weight
        return Font.custom(interName(for: resolvedWeight), size: defaultSize, relativeTo: style)
    }

    /// Resolve the bundled Inter PostScript name for a given SwiftUI weight.
    /// We ship four static cuts; weights between them snap to the nearest
    /// shipped weight (e.g. `.heavy` → Bold, `.thin` → Regular).
    private static func interName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light, .regular: return "Inter-Regular"
        case .medium:                               return "Inter-Medium"
        case .semibold:                             return "Inter-SemiBold"
        case .bold, .heavy, .black:                 return "Inter-Bold"
        default:                                    return "Inter-Regular"
        }
    }
}

private extension Font.TextStyle {
    /// Default size + intrinsic weight for the named Dynamic Type styles
    /// at the default Accessibility content size (UIContentSizeCategory.large).
    /// `Font.custom(..., relativeTo:)` scales these with the user's
    /// Dynamic Type preference, so the explicit numbers below are just
    /// the baseline.
    var defaultMetrics: (CGFloat, Font.Weight) {
        switch self {
        case .largeTitle:  return (34, .regular)
        case .title:       return (28, .regular)
        case .title2:      return (22, .regular)
        case .title3:      return (20, .regular)
        case .headline:    return (17, .semibold)
        case .body:        return (17, .regular)
        case .callout:     return (16, .regular)
        case .subheadline: return (15, .regular)
        case .footnote:    return (13, .regular)
        case .caption:     return (12, .regular)
        case .caption2:    return (11, .regular)
        @unknown default:  return (17, .regular)
        }
    }
}

/// UIKit equivalents — used by code paths that still hand-build a
/// UIFont (e.g. ShareCardGenerator's UIGraphicsImageRenderer attribute
/// dictionaries). Falls back to system if the font failed to register
/// at launch (shouldn't happen, but the placeholder keeps the card
/// from rendering as glyphs-of-glyphs).
extension UIFont {
    static func appFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let name: String
        switch weight {
        case .ultraLight, .thin, .light, .regular: name = "Inter-Regular"
        case .medium:                               name = "Inter-Medium"
        case .semibold:                             name = "Inter-SemiBold"
        case .bold, .heavy, .black:                 name = "Inter-Bold"
        default:                                    name = "Inter-Regular"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
}
