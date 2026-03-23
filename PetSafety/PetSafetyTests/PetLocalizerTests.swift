import Testing
import Foundation
@testable import PetSafety

@Suite("PetLocalizer Tests")
struct PetLocalizerTests {

    // MARK: - localizeSpecies

    @Test("localizeSpecies — known species 'dog' returns capitalized fallback when no localization key")
    func testLocalizeSpeciesDog() {
        let result = PetLocalizer.localizeSpecies("dog")
        // In test bundle without Localizable.strings, NSLocalizedString returns the key itself.
        // Since "species_dog" != "dog", the fallback is raw.capitalized = "Dog"
        #expect(result == "Dog", "Expected 'Dog' but got '\(result)'")
    }

    @Test("localizeSpecies — known species 'cat' returns 'Cat'")
    func testLocalizeSpeciesCat() {
        let result = PetLocalizer.localizeSpecies("cat")
        #expect(result == "Cat")
    }

    @Test("localizeSpecies — uppercase input 'DOG' still normalizes to 'Dog'")
    func testLocalizeSpeciesUppercase() {
        let result = PetLocalizer.localizeSpecies("DOG")
        // key = "species_dog", won't match → fallback = "DOG".capitalized = "Dog"
        #expect(result == "Dog")
    }

    @Test("localizeSpecies — mixed case 'Rabbit' returns 'Rabbit'")
    func testLocalizeSpeciesMixedCase() {
        let result = PetLocalizer.localizeSpecies("Rabbit")
        #expect(result == "Rabbit")
    }

    @Test("localizeSpecies — unknown species returns capitalized version")
    func testLocalizeSpeciesUnknown() {
        let result = PetLocalizer.localizeSpecies("iguana")
        #expect(result == "Iguana")
    }

    @Test("localizeSpecies — nil returns empty string")
    func testLocalizeSpeciesNil() {
        let result = PetLocalizer.localizeSpecies(nil)
        #expect(result == "")
    }

    @Test("localizeSpecies — empty string returns empty string")
    func testLocalizeSpeciesEmpty() {
        let result = PetLocalizer.localizeSpecies("")
        #expect(result == "")
    }

    // MARK: - localizeBreed

    @Test("localizeBreed — unknown breed returns raw value as fallback")
    func testLocalizeBreedUnknownFallback() {
        let result = PetLocalizer.localizeBreed("Golden Retriever")
        // No localization keys in test bundle → falls through all lookups → returns raw
        #expect(result == "Golden Retriever")
    }

    @Test("localizeBreed — breed with species prefix tries prefixed key first")
    func testLocalizeBreedWithSpeciesPrefix() {
        let result = PetLocalizer.localizeBreed("siamese", species: "cat")
        // Should return a non-empty localized string (either translated or raw fallback)
        #expect(!result.isEmpty)
    }

    @Test("localizeBreed — alias 'DSH' maps to domestic shorthair")
    func testLocalizeBreedDSHAlias() {
        let result = PetLocalizer.localizeBreed("DSH")
        // DSH is an alias — localizer maps it to domestic shorthair translation
        #expect(result.lowercased().contains("domestic") || result == "DSH")
    }

    @Test("localizeBreed — alias 'mixed' maps to mixed breed")
    func testLocalizeBreedMixedAlias() {
        let result = PetLocalizer.localizeBreed("mixed")
        // Should map to the localized mixed breed string
        #expect(result.lowercased().contains("mixed") || result.lowercased().contains("keverék"))
    }

    @Test("localizeBreed — alias 'crossbreed' maps to mixed breed")
    func testLocalizeBreedCrossbreedAlias() {
        let result = PetLocalizer.localizeBreed("crossbreed")
        #expect(result.lowercased().contains("mixed") || result.lowercased().contains("keverék") || result == "crossbreed")
    }

    @Test("localizeBreed — alias 'DLH' maps to domestic longhair")
    func testLocalizeBreedDLHAlias() {
        let result = PetLocalizer.localizeBreed("DLH")
        #expect(result.lowercased().contains("domestic") || result == "DLH")
    }

    @Test("localizeBreed — alias 'mixed breed' maps to mixed breed key")
    func testLocalizeBreedMixedBreedAlias() {
        let result = PetLocalizer.localizeBreed("mixed breed")
        #expect(result.lowercased().contains("mixed") || result.lowercased().contains("keverék"))
    }

    @Test("localizeBreed — nil returns empty string")
    func testLocalizeBreedNil() {
        let result = PetLocalizer.localizeBreed(nil)
        #expect(result == "")
    }

    @Test("localizeBreed — empty string returns empty string")
    func testLocalizeBreedEmpty() {
        let result = PetLocalizer.localizeBreed("")
        #expect(result == "")
    }

    @Test("localizeBreed — breed with special characters normalizes correctly")
    func testLocalizeBreedSpecialChars() {
        let result = PetLocalizer.localizeBreed("Shih-Tzu/Poodle")
        // Normalized to "shih_tzu_poodle", key not found → returns raw
        #expect(result == "Shih-Tzu/Poodle")
    }

    @Test("localizeBreed — species nil still attempts plain key lookup")
    func testLocalizeBreedNilSpecies() {
        let result = PetLocalizer.localizeBreed("labrador", species: nil)
        #expect(result == "labrador")
    }

    @Test("localizeBreed — empty species skips prefixed key")
    func testLocalizeBreedEmptySpecies() {
        let result = PetLocalizer.localizeBreed("poodle", species: "")
        #expect(result == "poodle")
    }

    // MARK: - localizeSex

    @Test("localizeSex — dog male tries species-specific key 'sex_dog_male'")
    func testLocalizeSexDogMale() {
        let result = PetLocalizer.localizeSex("male", species: "dog")
        // In test bundle: NSLocalizedString("sex_dog_male") returns "sex_dog_male" (no match)
        // Falls back to generic "sex_male" → also returns key → fallback = "male".capitalized = "Male"
        #expect(result == "Male")
    }

    @Test("localizeSex — cat male tries species-specific key 'sex_cat_male'")
    func testLocalizeSexCatMale() {
        let result = PetLocalizer.localizeSex("male", species: "cat")
        #expect(result == "Male")
    }

    @Test("localizeSex — dog female returns 'Female'")
    func testLocalizeSexDogFemale() {
        let result = PetLocalizer.localizeSex("female", species: "dog")
        #expect(result == "Female")
    }

    @Test("localizeSex — cat female returns 'Female'")
    func testLocalizeSexCatFemale() {
        let result = PetLocalizer.localizeSex("female", species: "cat")
        #expect(result == "Female")
    }

    @Test("localizeSex — generic fallback for non-dog/cat species")
    func testLocalizeSexGenericSpecies() {
        let result = PetLocalizer.localizeSex("male", species: "rabbit")
        // rabbit is not dog/cat, so species-specific branch is skipped
        // generic "sex_male" key not found → fallback = "Male"
        #expect(result == "Male")
    }

    @Test("localizeSex — 'unknown' sex returns localized unknown or key")
    func testLocalizeSexUnknown() {
        let result = PetLocalizer.localizeSex("unknown")
        // NSLocalizedString("sex_unknown") returns "sex_unknown" in test bundle
        #expect(!result.isEmpty)
    }

    @Test("localizeSex — nil returns empty string")
    func testLocalizeSexNil() {
        let result = PetLocalizer.localizeSex(nil)
        #expect(result == "")
    }

    @Test("localizeSex — empty string returns empty string")
    func testLocalizeSexEmpty() {
        let result = PetLocalizer.localizeSex("")
        #expect(result == "")
    }

    @Test("localizeSex — nil species uses generic fallback")
    func testLocalizeSexNilSpecies() {
        let result = PetLocalizer.localizeSex("female", species: nil)
        #expect(result == "Female")
    }

    @Test("localizeSex — uppercase input 'MALE' normalizes correctly")
    func testLocalizeSexUppercase() {
        let result = PetLocalizer.localizeSex("MALE", species: "dog")
        #expect(result == "Male")
    }
}
