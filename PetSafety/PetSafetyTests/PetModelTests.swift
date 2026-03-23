import Testing
import Foundation
@testable import PetSafety

@Suite("Pet Model Tests")
struct PetModelTests {

    // MARK: - Helper

    /// Creates a Pet with the given age fields, all other fields set to minimal defaults.
    private func makePet(
        ageYears: Int? = nil,
        ageMonths: Int? = nil,
        ageIsApproximate: Bool? = nil
    ) -> Pet {
        Pet(
            id: "pet-1",
            ownerId: "owner-1",
            name: "Buddy",
            species: "dog",
            isMissing: false,
            createdAt: "2025-01-01T00:00:00Z",
            updatedAt: "2025-01-01T00:00:00Z",
            ageYears: ageYears,
            ageMonths: ageMonths,
            ageIsApproximate: ageIsApproximate
        )
    }

    // MARK: - age computed property

    @Test("age — years only (1 year)")
    func testAgeSingleYear() {
        let pet = makePet(ageYears: 1)
        let age = pet.age
        #expect(age != nil)
        #expect(age?.contains("1") == true || age == NSLocalizedString("age_1_year", comment: ""))
    }

    @Test("age — years only (5 years)")
    func testAgeMultipleYears() {
        let pet = makePet(ageYears: 5)
        let age = pet.age
        #expect(age != nil)
        #expect(age?.contains("5") == true)
    }

    @Test("age — months only (1 month)")
    func testAgeSingleMonth() {
        let pet = makePet(ageMonths: 1)
        let age = pet.age
        #expect(age != nil)
        #expect(age?.contains("1") == true || age == NSLocalizedString("age_1_month", comment: ""))
    }

    @Test("age — months only (6 months)")
    func testAgeMultipleMonths() {
        let pet = makePet(ageMonths: 6)
        let age = pet.age
        #expect(age != nil)
        #expect(age?.contains("6") == true)
    }

    @Test("age — years and months combined")
    func testAgeYearsAndMonths() {
        let pet = makePet(ageYears: 2, ageMonths: 3)
        let age = pet.age
        #expect(age != nil)
        #expect(age?.contains("2") == true)
        #expect(age?.contains("3") == true)
    }

    @Test("age — approximate flag adds tilde prefix")
    func testAgeApproximatePrefix() {
        let pet = makePet(ageYears: 3, ageIsApproximate: true)
        let age = pet.age
        #expect(age != nil)
        #expect(age?.hasPrefix("~") == true, "Approximate age should start with ~")
    }

    @Test("age — non-approximate has no tilde prefix")
    func testAgeNotApproximateNoTilde() {
        let pet = makePet(ageYears: 3, ageIsApproximate: false)
        let age = pet.age
        #expect(age != nil)
        #expect(age?.hasPrefix("~") == false)
    }

    @Test("age — nil years and nil months returns nil")
    func testAgeNilBoth() {
        let pet = makePet()
        #expect(pet.age == nil)
    }

    @Test("age — zero years and zero months returns nil")
    func testAgeZeroBoth() {
        let pet = makePet(ageYears: 0, ageMonths: 0)
        #expect(pet.age == nil)
    }

    @Test("age — zero years with valid months shows months only")
    func testAgeZeroYearsWithMonths() {
        let pet = makePet(ageYears: 0, ageMonths: 4)
        let age = pet.age
        #expect(age != nil)
        #expect(age?.contains("4") == true)
    }

    // MARK: - JSON Decoding

    @Test("Decodes weight as Double")
    func testDecodeWeightAsDouble() throws {
        let json = """
        {
            "id": "p1",
            "owner_id": "o1",
            "name": "Rex",
            "species": "dog",
            "weight": 12.5,
            "is_missing": false,
            "created_at": "2025-01-01",
            "updated_at": "2025-01-01"
        }
        """.data(using: .utf8)!

        let pet = try JSONDecoder().decode(Pet.self, from: json)
        #expect(pet.weight == 12.5)
    }

    @Test("Decodes weight as String and converts to Double")
    func testDecodeWeightAsString() throws {
        let json = """
        {
            "id": "p1",
            "owner_id": "o1",
            "name": "Rex",
            "species": "dog",
            "weight": "8.3",
            "is_missing": false,
            "created_at": "2025-01-01",
            "updated_at": "2025-01-01"
        }
        """.data(using: .utf8)!

        let pet = try JSONDecoder().decode(Pet.self, from: json)
        #expect(pet.weight == 8.3)
    }

    @Test("Decodes profile_image field")
    func testDecodeProfileImage() throws {
        let json = """
        {
            "id": "p1",
            "owner_id": "o1",
            "name": "Luna",
            "species": "cat",
            "profile_image": "https://example.com/luna.jpg",
            "is_missing": false,
            "created_at": "2025-01-01",
            "updated_at": "2025-01-01"
        }
        """.data(using: .utf8)!

        let pet = try JSONDecoder().decode(Pet.self, from: json)
        #expect(pet.profileImage == "https://example.com/luna.jpg")
    }

    @Test("Decodes photo_url field as profileImage fallback")
    func testDecodePhotoUrlFallback() throws {
        let json = """
        {
            "id": "p1",
            "owner_id": "o1",
            "name": "Luna",
            "species": "cat",
            "photo_url": "https://example.com/luna-old.jpg",
            "is_missing": false,
            "created_at": "2025-01-01",
            "updated_at": "2025-01-01"
        }
        """.data(using: .utf8)!

        let pet = try JSONDecoder().decode(Pet.self, from: json)
        #expect(pet.profileImage == "https://example.com/luna-old.jpg")
    }

    @Test("profile_image takes priority over photo_url when both present")
    func testDecodeProfileImagePriority() throws {
        let json = """
        {
            "id": "p1",
            "owner_id": "o1",
            "name": "Luna",
            "species": "cat",
            "profile_image": "https://example.com/new.jpg",
            "photo_url": "https://example.com/old.jpg",
            "is_missing": false,
            "created_at": "2025-01-01",
            "updated_at": "2025-01-01"
        }
        """.data(using: .utf8)!

        let pet = try JSONDecoder().decode(Pet.self, from: json)
        #expect(pet.profileImage == "https://example.com/new.jpg")
    }

    @Test("Decodes minimal JSON with all optional fields absent")
    func testDecodeMinimalJSON() throws {
        let json = """
        {
            "id": "p1",
            "name": "NoOwner"
        }
        """.data(using: .utf8)!

        let pet = try JSONDecoder().decode(Pet.self, from: json)
        #expect(pet.id == "p1")
        #expect(pet.name == "NoOwner")
        #expect(pet.ownerId == "")
        #expect(pet.species == "")
        #expect(pet.breed == nil)
        #expect(pet.weight == nil)
        #expect(pet.profileImage == nil)
        #expect(pet.isMissing == false)
        #expect(pet.ageYears == nil)
        #expect(pet.ageMonths == nil)
        #expect(pet.sex == nil)
    }

    // MARK: - Computed properties (backward compatibility)

    @Test("photoUrl computed property returns profileImage")
    func testPhotoUrlComputed() {
        let pet = Pet(
            id: "p1", ownerId: "o1", name: "Buddy", species: "dog",
            profileImage: "https://example.com/img.jpg",
            isMissing: false, createdAt: "2025-01-01", updatedAt: "2025-01-01"
        )
        #expect(pet.photoUrl == "https://example.com/img.jpg")
    }

    @Test("userId computed property returns ownerId")
    func testUserIdComputed() {
        let pet = Pet(
            id: "p1", ownerId: "owner-42", name: "Buddy", species: "dog",
            isMissing: false, createdAt: "2025-01-01", updatedAt: "2025-01-01"
        )
        #expect(pet.userId == "owner-42")
    }

    @Test("isActive is inverse of isMissing")
    func testIsActiveComputed() {
        let activePet = makePet()
        #expect(activePet.isActive == true)

        let missingPet = Pet(
            id: "p2", ownerId: "o1", name: "Lost", species: "dog",
            isMissing: true, createdAt: "2025-01-01", updatedAt: "2025-01-01"
        )
        #expect(missingPet.isActive == false)
    }
}
