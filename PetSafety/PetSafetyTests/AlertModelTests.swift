import Testing
import Foundation
@testable import PetSafety

@Suite("Alert Model Tests")
struct AlertModelTests {

    // MARK: - MissingPetAlert Decoding

    @Test("Decodes MissingPetAlert from JSON with all fields including rewardAmount")
    func testDecodeAlertWithAllFields() throws {
        let json = """
        {
            "id": "alert_001",
            "pet_id": "pet_001",
            "user_id": "user_001",
            "status": "active",
            "last_seen_location": "Central Park, London",
            "last_seen_latitude": 51.5074,
            "last_seen_longitude": -0.1278,
            "additional_info": "Wearing red collar",
            "alert_radius_km": 15.0,
            "reward_amount": 250.0,
            "last_seen_at": "2026-01-10T14:30:00Z",
            "found_at": null,
            "created_at": "2026-01-10T14:00:00Z",
            "updated_at": "2026-01-10T14:00:00Z",
            "pet": {
                "id": "pet_001",
                "owner_id": "user_001",
                "name": "Max",
                "species": "Dog",
                "breed": "Golden Retriever",
                "color": "Golden",
                "is_missing": true,
                "created_at": "2025-06-01T00:00:00Z",
                "updated_at": "2026-01-10T14:00:00Z"
            },
            "sightings": []
        }
        """.data(using: .utf8)!

        let alert = try JSONDecoder().decode(MissingPetAlert.self, from: json)
        #expect(alert.id == "alert_001")
        #expect(alert.petId == "pet_001")
        #expect(alert.userId == "user_001")
        #expect(alert.status == "active")
        #expect(alert.lastSeenLocation == "Central Park, London")
        #expect(alert.lastSeenLatitude == 51.5074)
        #expect(alert.lastSeenLongitude == -0.1278)
        #expect(alert.additionalInfo == "Wearing red collar")
        #expect(alert.alertRadiusKm == 15.0)
        #expect(alert.rewardAmount == 250.0)
        #expect(alert.lastSeenAt == "2026-01-10T14:30:00Z")
        #expect(alert.foundAt == nil)
        #expect(alert.pet?.name == "Max")
        #expect(alert.pet?.breed == "Golden Retriever")
        #expect(alert.sightings?.isEmpty == true)
    }

    @Test("Decodes MissingPetAlert with null/missing rewardAmount")
    func testDecodeAlertWithNullReward() throws {
        let json = """
        {
            "id": "alert_002",
            "pet_id": "pet_002",
            "user_id": "user_002",
            "status": "active",
            "reward_amount": null,
            "created_at": "2026-01-10T14:00:00Z",
            "updated_at": "2026-01-10T14:00:00Z"
        }
        """.data(using: .utf8)!

        let alert = try JSONDecoder().decode(MissingPetAlert.self, from: json)
        #expect(alert.rewardAmount == nil, "rewardAmount should be nil when JSON has null")

        // Also test with rewardAmount missing entirely
        let jsonMissing = """
        {
            "id": "alert_003",
            "pet_id": "pet_003",
            "user_id": "user_003",
            "status": "active",
            "created_at": "2026-01-11T10:00:00Z",
            "updated_at": "2026-01-11T10:00:00Z"
        }
        """.data(using: .utf8)!

        let alertMissing = try JSONDecoder().decode(MissingPetAlert.self, from: jsonMissing)
        #expect(alertMissing.rewardAmount == nil, "rewardAmount should be nil when key is absent")
    }

    @Test("Encodes MissingPetAlert with rewardAmount")
    func testEncodeAlertWithReward() throws {
        let alert = MissingPetAlert(
            id: "alert_010",
            petId: "pet_010",
            userId: "user_010",
            status: "active",
            lastSeenLatitude: 48.2082,
            lastSeenLongitude: 16.3738,
            rewardAmount: 100.0,
            createdAt: "2026-01-12T00:00:00Z",
            updatedAt: "2026-01-12T00:00:00Z"
        )

        let data = try JSONEncoder().encode(alert)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["reward_amount"] as? Double == 100.0)
        #expect(dict["pet_id"] as? String == "pet_010")
        #expect(dict["last_seen_latitude"] as? Double == 48.2082)
    }

    @Test("Encodes MissingPetAlert without rewardAmount — key omitted from JSON")
    func testEncodeAlertWithoutReward() throws {
        let alert = MissingPetAlert(
            id: "alert_011",
            petId: "pet_011",
            userId: "user_011",
            status: "active",
            rewardAmount: nil,
            createdAt: "2026-01-12T00:00:00Z",
            updatedAt: "2026-01-12T00:00:00Z"
        )

        let data = try JSONEncoder().encode(alert)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(!jsonString.contains("reward_amount"), "reward_amount should be omitted when nil (encodeIfPresent)")
    }

    @Test("Decodes alert with integer rewardAmount (50 vs 50.0)")
    func testDecodeAlertWithIntegerReward() throws {
        let json = """
        {
            "id": "alert_020",
            "pet_id": "pet_020",
            "user_id": "user_020",
            "status": "active",
            "reward_amount": 50,
            "created_at": "2026-01-13T00:00:00Z",
            "updated_at": "2026-01-13T00:00:00Z"
        }
        """.data(using: .utf8)!

        let alert = try JSONDecoder().decode(MissingPetAlert.self, from: json)
        #expect(alert.rewardAmount == 50.0, "Integer 50 should decode as Double 50.0")
    }

    @Test("Decodes alert with string rewardAmount")
    func testDecodeAlertWithStringReward() throws {
        let json = """
        {
            "id": "alert_021",
            "pet_id": "pet_021",
            "user_id": "user_021",
            "status": "active",
            "reward_amount": "100.00",
            "created_at": "2026-01-13T00:00:00Z",
            "updated_at": "2026-01-13T00:00:00Z"
        }
        """.data(using: .utf8)!

        let alert = try JSONDecoder().decode(MissingPetAlert.self, from: json)
        #expect(alert.rewardAmount == 100.0, "String reward should decode as Double")
    }

    @Test("Decodes alert from /alerts/nearby response with flat pet fields")
    func testDecodeAlertWithFlatPetFields() throws {
        let json = """
        {
            "id": "alert_030",
            "pet_id": "pet_030",
            "user_id": "user_030",
            "status": "active",
            "pet_name": "Buddy",
            "species": "Dog",
            "breed": "Labrador",
            "color": "Black",
            "profile_image": "https://example.com/buddy.jpg",
            "qr_code": "QR_030",
            "lat": 47.4979,
            "lng": 19.0402,
            "last_seen_address": "Budapest, Hungary",
            "description": "Very friendly dog",
            "reward_amount": 75.0,
            "created_at": "2026-01-14T08:00:00Z",
            "updated_at": "2026-01-14T08:00:00Z"
        }
        """.data(using: .utf8)!

        let alert = try JSONDecoder().decode(MissingPetAlert.self, from: json)

        // Pet should be constructed from flat fields
        #expect(alert.pet != nil, "Pet should be built from flat fields")
        #expect(alert.pet?.name == "Buddy")
        #expect(alert.pet?.species == "Dog")
        #expect(alert.pet?.breed == "Labrador")
        #expect(alert.pet?.color == "Black")
        #expect(alert.pet?.profileImage == "https://example.com/buddy.jpg")
        #expect(alert.pet?.qrCode == "QR_030")
        #expect(alert.pet?.isMissing == true, "Pet isMissing should be true when status is active")

        // Location should come from lat/lng keys
        #expect(alert.lastSeenLatitude == 47.4979)
        #expect(alert.lastSeenLongitude == 19.0402)

        // Address should come from last_seen_address
        #expect(alert.lastSeenLocation == "Budapest, Hungary")

        // Description should map to additionalInfo
        #expect(alert.additionalInfo == "Very friendly dog")

        #expect(alert.rewardAmount == 75.0)
    }

    @Test("Decodes sightings array within alert")
    func testDecodeSightingsArray() throws {
        let json = """
        {
            "id": "alert_040",
            "pet_id": "pet_040",
            "user_id": "user_040",
            "status": "active",
            "created_at": "2026-01-10T00:00:00Z",
            "updated_at": "2026-01-12T00:00:00Z",
            "sightings": [
                {
                    "id": "sight_001",
                    "alert_id": "alert_040",
                    "reporter_name": "Jane Doe",
                    "reporter_phone": "+44123456789",
                    "reporter_email": "jane@example.com",
                    "sighting_location": "Hyde Park",
                    "sighting_latitude": 51.5073,
                    "sighting_longitude": -0.1657,
                    "sighting_notes": "Spotted near the fountain",
                    "photo_url": "https://example.com/sighting1.jpg",
                    "created_at": "2026-01-11T15:30:00Z"
                },
                {
                    "id": "sight_002",
                    "alert_id": "alert_040",
                    "reporter_name": "John Smith",
                    "sighting_address": "Regent's Park",
                    "sighting_latitude": 51.5313,
                    "sighting_longitude": -0.1570,
                    "description": "Running near the lake",
                    "reported_at": "2026-01-12T09:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let alert = try JSONDecoder().decode(MissingPetAlert.self, from: json)
        #expect(alert.sightings?.count == 2)

        let first = alert.sightings![0]
        #expect(first.id == "sight_001")
        #expect(first.alertId == "alert_040")
        #expect(first.reporterName == "Jane Doe")
        #expect(first.reporterPhone == "+44123456789")
        #expect(first.reporterEmail == "jane@example.com")
        #expect(first.sightingLocation == "Hyde Park")
        #expect(first.sightingLatitude == 51.5073)
        #expect(first.sightingLongitude == -0.1657)
        #expect(first.sightingNotes == "Spotted near the fountain")
        #expect(first.photoUrl == "https://example.com/sighting1.jpg")
        #expect(first.createdAt == "2026-01-11T15:30:00Z")

        // Second sighting uses legacy keys: sighting_address, description, reported_at
        let second = alert.sightings![1]
        #expect(second.id == "sight_002")
        #expect(second.sightingLocation == "Regent's Park", "sighting_address should map to sightingLocation")
        #expect(second.sightingNotes == "Running near the lake", "description should map to sightingNotes")
        #expect(second.createdAt == "2026-01-12T09:00:00Z", "reported_at should map to createdAt")
    }

    @Test("Coordinate computed property returns correct lat/lng")
    func testCoordinateComputedProperty() throws {
        let alertWithCoords = MissingPetAlert(
            id: "alert_050",
            petId: "pet_050",
            userId: "user_050",
            status: "active",
            lastSeenLatitude: 48.8566,
            lastSeenLongitude: 2.3522,
            createdAt: "2026-01-15T00:00:00Z",
            updatedAt: "2026-01-15T00:00:00Z"
        )

        let coord = alertWithCoords.coordinate
        #expect(coord != nil, "Coordinate should not be nil when lat/lng are present")
        #expect(coord?.latitude == 48.8566)
        #expect(coord?.longitude == 2.3522)

        // Alert without coordinates
        let alertWithoutCoords = MissingPetAlert(
            id: "alert_051",
            petId: "pet_051",
            userId: "user_051",
            status: "active",
            createdAt: "2026-01-15T00:00:00Z",
            updatedAt: "2026-01-15T00:00:00Z"
        )

        #expect(alertWithoutCoords.coordinate == nil, "Coordinate should be nil when lat/lng are missing")
    }

    @Test("Default alertRadiusKm is 10")
    func testDefaultAlertRadiusKm() throws {
        // From JSON without alert_radius_km
        let json = """
        {
            "id": "alert_060",
            "pet_id": "pet_060",
            "user_id": "user_060",
            "status": "active",
            "created_at": "2026-01-15T00:00:00Z",
            "updated_at": "2026-01-15T00:00:00Z"
        }
        """.data(using: .utf8)!

        let alert = try JSONDecoder().decode(MissingPetAlert.self, from: json)
        #expect(alert.alertRadiusKm == 10.0, "Default alertRadiusKm should be 10 when not provided")

        // From memberwise init default
        let alertInit = MissingPetAlert(
            id: "alert_061",
            petId: "pet_061",
            userId: "user_061",
            status: "active",
            createdAt: "2026-01-15T00:00:00Z",
            updatedAt: "2026-01-15T00:00:00Z"
        )

        #expect(alertInit.alertRadiusKm == 10.0, "Default alertRadiusKm should be 10 from memberwise init")
    }

    // MARK: - CreateAlertRequest Encoding

    @Test("CreateAlertRequest encoding with rewardAmount")
    func testCreateAlertRequestWithReward() throws {
        let request = CreateAlertRequest(
            petId: "pet_070",
            lastSeenLocation: LocationCoordinate(lat: 51.5074, lng: -0.1278),
            lastSeenAddress: "Baker Street, London",
            description: "Last seen near the park",
            rewardAmount: 500.0,
            alertRadiusKm: 20.0
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["petId"] as? String == "pet_070")
        #expect(dict["rewardAmount"] as? Double == 500.0)
        #expect(dict["description"] as? String == "Last seen near the park")
        #expect(dict["lastSeenAddress"] as? String == "Baker Street, London")
        #expect(dict["alertRadiusKm"] as? Double == 20.0)

        // Verify lastSeenLocation is encoded as nested object
        let locationDict = dict["lastSeenLocation"] as? [String: Any]
        #expect(locationDict != nil, "lastSeenLocation should be a nested object")
        #expect(locationDict?["lat"] as? Double == 51.5074)
        #expect(locationDict?["lng"] as? Double == -0.1278)
    }

    @Test("CreateAlertRequest encoding without rewardAmount")
    func testCreateAlertRequestWithoutReward() throws {
        let request = CreateAlertRequest(
            petId: "pet_071",
            lastSeenLocation: nil,
            lastSeenAddress: nil,
            description: nil,
            rewardAmount: nil,
            alertRadiusKm: nil
        )

        let data = try JSONEncoder().encode(request)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("petId"), "petId should always be present")
        #expect(!jsonString.contains("rewardAmount"), "rewardAmount should be omitted when nil")
        #expect(!jsonString.contains("lastSeenLocation"), "lastSeenLocation should be omitted when nil")
        #expect(!jsonString.contains("alertRadiusKm"), "alertRadiusKm should be omitted when nil")
    }

    // MARK: - Sighting Model

    @Test("Sighting coordinate computed property")
    func testSightingCoordinate() throws {
        let sighting = Sighting(
            id: "sight_100",
            alertId: "alert_100",
            sightingLatitude: 40.7128,
            sightingLongitude: -74.0060,
            createdAt: "2026-01-15T12:00:00Z"
        )

        let coord = sighting.coordinate
        #expect(coord != nil)
        #expect(coord?.latitude == 40.7128)
        #expect(coord?.longitude == -74.0060)

        // Without coordinates
        let sightingNoCoord = Sighting(
            id: "sight_101",
            alertId: "alert_100",
            createdAt: "2026-01-15T12:00:00Z"
        )

        #expect(sightingNoCoord.coordinate == nil)
    }

    @Test("Sighting roundtrip encode/decode")
    func testSightingRoundtrip() throws {
        let sighting = Sighting(
            id: "sight_110",
            alertId: "alert_110",
            reporterName: "Alice",
            reporterPhone: "+36201234567",
            reporterEmail: "alice@example.com",
            sightingLocation: "Margit Island",
            sightingLatitude: 47.5286,
            sightingLongitude: 19.0500,
            sightingNotes: "Seen eating near a bench",
            photoUrl: "https://example.com/photo.jpg",
            createdAt: "2026-01-15T16:00:00Z"
        )

        let data = try JSONEncoder().encode(sighting)
        let decoded = try JSONDecoder().decode(Sighting.self, from: data)

        #expect(decoded.id == sighting.id)
        #expect(decoded.alertId == sighting.alertId)
        #expect(decoded.reporterName == sighting.reporterName)
        #expect(decoded.reporterPhone == sighting.reporterPhone)
        #expect(decoded.reporterEmail == sighting.reporterEmail)
        #expect(decoded.sightingLocation == sighting.sightingLocation)
        #expect(decoded.sightingLatitude == sighting.sightingLatitude)
        #expect(decoded.sightingLongitude == sighting.sightingLongitude)
        #expect(decoded.sightingNotes == sighting.sightingNotes)
        #expect(decoded.photoUrl == sighting.photoUrl)
        #expect(decoded.createdAt == sighting.createdAt)
    }
}
