import Foundation

/// Maps device locale to Senra country code and builds country-prefixed web URLs.
enum WebURLHelper {
    private static let regionToCountry: [String: String] = [
        "GB": "uk", "US": "uk",
        "HU": "hu", "SK": "sk",
        "AT": "at", "DE": "de", "CH": "de",
        "CZ": "cz",
        "ES": "es", "MX": "es", "AR": "es", "CO": "es", "CL": "es",
        "PT": "pt", "BR": "pt",
        "FR": "fr",
        "IT": "it",
        "PL": "pl",
        "RO": "ro", "MD": "ro",
        "HR": "hr",
    ]

    static var countryCode: String {
        if let region = Locale.current.region?.identifier {
            return regionToCountry[region] ?? "uk"
        }
        return "uk"
    }

    static func url(path: String) -> URL {
        let clean = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: "https://senra.pet/\(countryCode)\(clean)")!
    }

    static var termsURL: URL { url(path: "/terms-conditions") }
    static var privacyURL: URL { url(path: "/privacy-policy") }

    /// Valid country codes for stripping from universal link paths
    static let validCountryCodes: Set<String> = [
        "uk", "hu", "sk", "at", "de", "cz", "es", "pt", "fr", "it", "pl", "ro", "hr"
    ]

    /// Strips a valid country prefix from a path, e.g. "/hu/qr/ABC" -> "/qr/ABC"
    static func stripCountryPrefix(from path: String) -> String {
        let components = path.split(separator: "/", maxSplits: 2)
        if components.count >= 1 {
            let first = String(components[0])
            if validCountryCodes.contains(first) {
                let rest = components.count > 1 ? "/\(components[1])" : "/"
                return rest
            }
        }
        return path
    }
}
