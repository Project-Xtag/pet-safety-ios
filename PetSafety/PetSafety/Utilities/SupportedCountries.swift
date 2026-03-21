import Foundation

struct SupportedCountry: Identifiable, Hashable {
    let code: String
    var id: String { code }

    /// Returns the country name localized to the user's current locale.
    var localizedName: String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }
}

enum SupportedCountries {
    /// ISO 3166-1 alpha-2 codes for supported shipping destinations.
    static let codes: [String] = [
        "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
        "DE", "GR", "HU", "IT", "LV", "LT", "LU", "MT", "NL", "NO",
        "PL", "PT", "RO", "SK", "SI", "ES", "SE", "CH",
    ]

    /// All supported countries as `SupportedCountry` instances.
    static let all: [SupportedCountry] = codes.map { SupportedCountry(code: $0) }

    /// Countries sorted by localized name, with `priorityCode` (if provided) placed first.
    static func sorted(priority priorityCode: String? = nil) -> [SupportedCountry] {
        let sorted = all.sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
        guard let priorityCode, let idx = sorted.firstIndex(where: { $0.code.caseInsensitiveCompare(priorityCode) == .orderedSame }) else {
            return sorted
        }
        var result = sorted
        let country = result.remove(at: idx)
        result.insert(country, at: 0)
        return result
    }

    /// Find the matching country from a code or English name string (case-insensitive).
    static func find(_ value: String) -> SupportedCountry? {
        let v = value.trimmingCharacters(in: .whitespaces)
        // Try code first
        if let match = all.first(where: { $0.code.caseInsensitiveCompare(v) == .orderedSame }) {
            return match
        }
        // Try localized name
        return all.first { $0.localizedName.caseInsensitiveCompare(v) == .orderedSame }
    }

    /// Find by code only.
    static func findByCode(_ code: String) -> SupportedCountry? {
        all.first { $0.code.caseInsensitiveCompare(code) == .orderedSame }
    }
}
