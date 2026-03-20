import Foundation

/// Translates raw English database values (species, breed, sex) to the current device locale.
/// Falls back to the original value if no translation key exists.
enum PetLocalizer {

    // MARK: - Species

    /// Maps English species name from DB → localized display string.
    static func localizeSpecies(_ raw: String?) -> String {
        guard let raw = raw, !raw.isEmpty else { return "" }
        let key = "species_\(raw.lowercased())"
        let localized = NSLocalizedString(key, comment: "")
        return localized == key ? raw.capitalized : localized
    }

    // MARK: - Breed

    /// Maps English breed name from DB → localized display string.
    /// Tries species-prefixed keys first, then common names.
    static func localizeBreed(_ raw: String?, species: String? = nil) -> String {
        guard let raw = raw, !raw.isEmpty else { return "" }

        let normalized = raw.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "-", with: "_")

        // Try species-prefixed key (e.g., "breed_cat_domestic_shorthair")
        let speciesLower = (species ?? "").lowercased()
        if !speciesLower.isEmpty {
            let prefixedKey = "breed_\(speciesLower)_\(normalized)"
            let localized = NSLocalizedString(prefixedKey, comment: "")
            if localized != prefixedKey { return localized }
        }

        // Try without species prefix
        let plainKey = "breed_\(normalized)"
        let localized = NSLocalizedString(plainKey, comment: "")
        if localized != plainKey { return localized }

        // Special aliases
        let aliases: [String: String] = [
            "dsh": "breed_cat_domestic_shorthair",
            "domestic shorthair": "breed_cat_domestic_shorthair",
            "dlh": "breed_cat_domestic_longhair",
            "domestic longhair": "breed_cat_domestic_longhair",
            "cross": "breed_mixed",
            "crossbreed": "breed_mixed",
            "mixed": "breed_mixed",
            "mixed breed": "breed_mixed",
        ]
        if let aliasKey = aliases[normalized] {
            let aliasLocalized = NSLocalizedString(aliasKey, comment: "")
            if aliasLocalized != aliasKey { return aliasLocalized }
        }

        return raw
    }

    // MARK: - Sex

    /// Maps English sex value from DB → localized display string.
    /// Sex terms are species-dependent (e.g., HU dog male = "hím", cat male = "kandúr").
    static func localizeSex(_ raw: String?, species: String? = nil) -> String {
        guard let raw = raw, !raw.isEmpty else { return "" }
        let sexLower = raw.lowercased()

        if sexLower == "unknown" {
            return NSLocalizedString("sex_unknown", comment: "")
        }

        let speciesLower = (species ?? "").lowercased()

        // Try species-specific key first (e.g., "sex_dog_male", "sex_cat_female")
        if speciesLower == "dog" || speciesLower == "cat" {
            let speciesKey = "sex_\(speciesLower)_\(sexLower)"
            let localized = NSLocalizedString(speciesKey, comment: "")
            if localized != speciesKey { return localized }
        }

        // Fall back to generic key (e.g., "sex_male", "sex_female")
        let genericKey = "sex_\(sexLower)"
        let localized = NSLocalizedString(genericKey, comment: "")
        return localized == genericKey ? raw.capitalized : localized
    }
}
