import Foundation

struct SupportedCountry: Identifiable, Hashable {
    let code: String
    let name: String
    var id: String { code }
}

enum SupportedCountries {
    static let all: [SupportedCountry] = [
        SupportedCountry(code: "AT", name: "Austria"),
        SupportedCountry(code: "BE", name: "Belgium"),
        SupportedCountry(code: "BG", name: "Bulgaria"),
        SupportedCountry(code: "HR", name: "Croatia"),
        SupportedCountry(code: "CY", name: "Cyprus"),
        SupportedCountry(code: "CZ", name: "Czech Republic"),
        SupportedCountry(code: "DK", name: "Denmark"),
        SupportedCountry(code: "EE", name: "Estonia"),
        SupportedCountry(code: "FI", name: "Finland"),
        SupportedCountry(code: "FR", name: "France"),
        SupportedCountry(code: "DE", name: "Germany"),
        SupportedCountry(code: "GR", name: "Greece"),
        SupportedCountry(code: "HU", name: "Hungary"),
        SupportedCountry(code: "IT", name: "Italy"),
        SupportedCountry(code: "LV", name: "Latvia"),
        SupportedCountry(code: "LT", name: "Lithuania"),
        SupportedCountry(code: "LU", name: "Luxembourg"),
        SupportedCountry(code: "MT", name: "Malta"),
        SupportedCountry(code: "NL", name: "Netherlands"),
        SupportedCountry(code: "NO", name: "Norway"),
        SupportedCountry(code: "PL", name: "Poland"),
        SupportedCountry(code: "PT", name: "Portugal"),
        SupportedCountry(code: "RO", name: "Romania"),
        SupportedCountry(code: "SK", name: "Slovakia"),
        SupportedCountry(code: "SI", name: "Slovenia"),
        SupportedCountry(code: "ES", name: "Spain"),
        SupportedCountry(code: "SE", name: "Sweden"),
        SupportedCountry(code: "CH", name: "Switzerland"),
    ]

    /// Find the matching country from a code or name string (case-insensitive).
    static func find(_ value: String) -> SupportedCountry? {
        let v = value.trimmingCharacters(in: .whitespaces)
        return all.first { $0.code.caseInsensitiveCompare(v) == .orderedSame }
            ?? all.first { $0.name.caseInsensitiveCompare(v) == .orderedSame }
    }

    /// Find by code only.
    static func findByCode(_ code: String) -> SupportedCountry? {
        all.first { $0.code.caseInsensitiveCompare(code) == .orderedSame }
    }
}
