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

    /// Cached breed lookup map: lowercased English name → native name
    private static var breedLookupCache: (locale: String, map: [String: String])?

    private static func breedLookup() -> [String: String] {
        let lang = Locale.current.language.languageCode?.identifier.lowercased().prefix(2).description ?? "en"
        if let cache = breedLookupCache, cache.locale == lang { return cache.map }
        var map: [String: String] = [:]
        for species in ["dog", "cat"] {
            for breed in BreedData.breeds(for: species, locale: lang) {
                map[breed.name.lowercased()] = breed.nativeName
            }
        }
        breedLookupCache = (locale: lang, map: map)
        return map
    }

    /// Maps English breed name from DB → localized display string.
    /// Looks up the breed in the per-locale breed data.
    static func localizeBreed(_ raw: String?, species: String? = nil) -> String {
        guard let raw = raw, !raw.isEmpty else { return "" }
        let lookup = breedLookup()

        if let native = lookup[raw.lowercased()] { return native }

        // Special aliases for common abbreviations
        let aliases: [String: String] = [
            "dsh": "european shorthair",
            "domestic shorthair": "european shorthair",
            "dlh": "european shorthair",
            "domestic longhair": "european shorthair",
            "cross": "mixed / crossbreed",
            "crossbreed": "mixed / crossbreed",
            "mixed": "mixed / crossbreed",
            "mixed breed": "mixed / crossbreed",
        ]
        if let alias = aliases[raw.lowercased()], let native = lookup[alias] {
            return native
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
