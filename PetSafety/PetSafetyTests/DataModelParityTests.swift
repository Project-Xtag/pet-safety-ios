import Testing
import Foundation
@testable import PetSafety

@Suite("Data Model Parity Tests")
struct DataModelParityTests {

    // MARK: - User: preferredLanguage

    @Test("User decodes preferred_language field")
    func testUserPreferredLanguage() throws {
        let json = """
        {
            "id": "user_1",
            "email": "test@example.com",
            "preferred_language": "hu"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)
        #expect(user.preferredLanguage == "hu")
    }

    @Test("User decodes without preferred_language")
    func testUserWithoutPreferredLanguage() throws {
        let json = """
        {
            "id": "user_2",
            "email": "test@example.com"
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)
        #expect(user.preferredLanguage == nil)
    }

    @Test("User decodes secondary contact visibility fields")
    func testUserSecondaryContactVisibility() throws {
        let json = """
        {
            "id": "user_3",
            "email": "test@example.com",
            "show_secondary_phone_publicly": true,
            "show_secondary_email_publicly": false
        }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)
        #expect(user.showSecondaryPhonePublicly == true)
        #expect(user.showSecondaryEmailPublicly == false)
    }

    // MARK: - Order: AddressDetails phone field

    @Test("AddressDetails decodes phone field")
    func testAddressDetailsPhone() throws {
        let json = """
        {
            "street1": "123 Main St",
            "city": "Budapest",
            "postCode": "1010",
            "country": "HU",
            "phone": "+36301234567"
        }
        """.data(using: .utf8)!

        let address = try JSONDecoder().decode(AddressDetails.self, from: json)
        #expect(address.phone == "+36301234567")
    }

    @Test("AddressDetails decodes without phone")
    func testAddressDetailsWithoutPhone() throws {
        let json = """
        {
            "street1": "123 Main St",
            "city": "Budapest",
            "postCode": "1010",
            "country": "HU"
        }
        """.data(using: .utf8)!

        let address = try JSONDecoder().decode(AddressDetails.self, from: json)
        #expect(address.phone == nil)
    }

    // MARK: - Order: currency uppercasing

    @Test("Order formattedAmount handles lowercase currency code")
    func testOrderFormattedAmountLowercaseCurrency() throws {
        let json = """
        {
            "id": "order_1",
            "total_amount": 29.95,
            "currency": "eur",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let order = try JSONDecoder().decode(Order.self, from: json)
        #expect(order.formattedAmount.contains("29"))
    }

    @Test("Order formattedAmount handles uppercase currency code")
    func testOrderFormattedAmountUppercaseCurrency() throws {
        let json = """
        {
            "id": "order_2",
            "total_amount": 29.95,
            "currency": "EUR",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let order = try JSONDecoder().decode(Order.self, from: json)
        #expect(order.formattedAmount.contains("29"))
    }

    // MARK: - SuccessStory: dual coordinate conventions

    @Test("SuccessStory resolves reunion_latitude/reunion_longitude")
    func testSuccessStoryFullCoordinateNames() throws {
        let json = """
        {
            "id": "story_1",
            "pet_id": "pet_1",
            "reunion_latitude": 47.4979,
            "reunion_longitude": 19.0402,
            "is_public": true,
            "is_confirmed": true,
            "found_at": "2026-01-15T10:00:00Z",
            "created_at": "2026-01-15T10:00:00Z",
            "updated_at": "2026-01-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let story = try JSONDecoder().decode(SuccessStory.self, from: json)
        #expect(story.resolvedLatitude == 47.4979)
        #expect(story.resolvedLongitude == 19.0402)
        #expect(story.coordinate != nil)
    }

    @Test("SuccessStory resolves reunion_lat/reunion_lng")
    func testSuccessStoryShortCoordinateNames() throws {
        let json = """
        {
            "id": "story_2",
            "pet_id": "pet_2",
            "reunion_lat": 48.2082,
            "reunion_lng": 16.3738,
            "is_public": true,
            "is_confirmed": false,
            "found_at": "2026-02-01T12:00:00Z",
            "created_at": "2026-02-01T12:00:00Z",
            "updated_at": "2026-02-01T12:00:00Z"
        }
        """.data(using: .utf8)!

        let story = try JSONDecoder().decode(SuccessStory.self, from: json)
        #expect(story.resolvedLatitude == 48.2082)
        #expect(story.resolvedLongitude == 16.3738)
    }

    @Test("SuccessStory prefers reunion_latitude over reunion_lat")
    func testSuccessStoryCoordinatePrecedence() throws {
        let json = """
        {
            "id": "story_3",
            "pet_id": "pet_3",
            "reunion_latitude": 47.0,
            "reunion_longitude": 19.0,
            "reunion_lat": 48.0,
            "reunion_lng": 16.0,
            "is_public": true,
            "is_confirmed": true,
            "found_at": "2026-03-01T00:00:00Z",
            "created_at": "2026-03-01T00:00:00Z",
            "updated_at": "2026-03-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let story = try JSONDecoder().decode(SuccessStory.self, from: json)
        #expect(story.resolvedLatitude == 47.0)
        #expect(story.resolvedLongitude == 19.0)
    }

    @Test("SuccessStory coordinate is nil when no coordinates provided")
    func testSuccessStoryNoCoordinates() throws {
        let json = """
        {
            "id": "story_4",
            "pet_id": "pet_4",
            "is_public": false,
            "is_confirmed": false,
            "found_at": "2026-03-01T00:00:00Z",
            "created_at": "2026-03-01T00:00:00Z",
            "updated_at": "2026-03-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let story = try JSONDecoder().decode(SuccessStory.self, from: json)
        #expect(story.resolvedLatitude == nil)
        #expect(story.resolvedLongitude == nil)
        #expect(story.coordinate == nil)
    }

    // MARK: - Breed: alternateNames

    @Test("Breed decodes alternate_names from API")
    func testBreedAlternateNames() throws {
        let json = """
        {
            "id": "dog-labrador",
            "name": "Labrador Retriever",
            "species": "dog",
            "alternate_names": ["Lab", "Labrador"]
        }
        """.data(using: .utf8)!

        let breed = try JSONDecoder().decode(Breed.self, from: json)
        #expect(breed.alternateNames == ["Lab", "Labrador"])
    }

    @Test("Breed decodes without alternate_names")
    func testBreedWithoutAlternateNames() throws {
        let json = """
        {
            "id": "cat-persian",
            "name": "Persian",
            "species": "cat"
        }
        """.data(using: .utf8)!

        let breed = try JSONDecoder().decode(Breed.self, from: json)
        #expect(breed.alternateNames == nil)
    }

    @Test("Breed convenience init sets alternateNames to nil")
    func testBreedConvenienceInit() {
        let breed = Breed(id: "dog-pug", name: "Pug", species: "dog")
        #expect(breed.alternateNames == nil)
        #expect(breed.name == "Pug")
    }

    @Test("BreedData search returns matching breeds")
    func testBreedSearch() {
        let results = BreedData.search("lab", species: "dog")
        #expect(results.count >= 1)
        #expect(results.contains(where: { $0.name == "Labrador Retriever" }))
    }

    // MARK: - SuccessStory: timeMissingText

    @Test("timeMissingText returns correct duration for days")
    func testTimeMissingTextDays() throws {
        let json = """
        {
            "id": "story_time",
            "pet_id": "pet_1",
            "is_public": true,
            "is_confirmed": true,
            "missing_since": "2026-01-01T00:00:00Z",
            "found_at": "2026-01-04T00:00:00Z",
            "created_at": "2026-01-04T00:00:00Z",
            "updated_at": "2026-01-04T00:00:00Z"
        }
        """.data(using: .utf8)!

        let story = try JSONDecoder().decode(SuccessStory.self, from: json)
        #expect(story.timeMissingText == "3 days")
    }
}
