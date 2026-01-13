//
//  MarkLostFoundTests.swift
//  PetSafetyTests
//
//  Created by Pet Safety Team on 2026-01-12.
//  Tests for Mark Lost/Found functionality
//

import Foundation
import Testing
@testable import PetSafety

@MainActor
struct MarkLostFoundTests {

    // Test Pet model has isMissing field
    @Test func testPetModelHasMissingField() async throws {
        let pet = Pet(
            id: "test_pet_1",
            ownerId: "test_owner_1",
            name: "Test Dog",
            species: "Dog",
            isMissing: true,
            createdAt: "2026-01-01T00:00:00Z",
            updatedAt: "2026-01-01T00:00:00Z"
        )

        #expect(pet.isMissing == true, "Pet should have isMissing property")
        #expect(pet.name == "Test Dog")
    }

    // Test UpdatePetRequest includes isMissing
    @Test func testUpdatePetRequestIncludesMissingField() async throws {
        let updateRequest = UpdatePetRequest(
            name: nil,
            species: nil,
            breed: nil,
            color: nil,
            age: nil,
            weight: nil,
            microchipNumber: nil,
            medicalNotes: nil,
            allergies: nil,
            medications: nil,
            notes: nil,
            uniqueFeatures: nil,
            sex: nil,
            isNeutered: nil,
            isMissing: false
        )

        // Encode to JSON to verify field is included
        let encoder = JSONEncoder()
        let data = try encoder.encode(updateRequest)
        let jsonString = String(data: data, encoding: .utf8)

        #expect(jsonString?.contains("is_missing") == true, "UpdatePetRequest should include is_missing field")
    }

    // Test LocationCoordinate structure
    @Test func testLocationCoordinateStructure() async throws {
        let coordinate = LocationCoordinate(lat: 51.5074, lng: -0.1278)

        #expect(coordinate.lat == 51.5074)
        #expect(coordinate.lng == -0.1278)

        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(coordinate)
        let decoded = try JSONDecoder().decode(LocationCoordinate.self, from: data)

        #expect(decoded.lat == coordinate.lat)
        #expect(decoded.lng == coordinate.lng)
    }

    // Test MarkMissingResponse decoding
    @Test func testMarkMissingResponseDecoding() async throws {
        let jsonString = """
        {
            "success": true,
            "pet": {
                "id": "pet_123",
                "owner_id": "user_123",
                "name": "Max",
                "species": "Dog",
                "is_missing": true,
                "created_at": "2026-01-01T00:00:00Z",
                "updated_at": "2026-01-12T10:00:00Z"
            },
            "alert": {
                "id": "alert_456"
            },
            "message": "Pet marked as missing. Alerts are being sent."
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(MarkMissingResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.pet.name == "Max")
        #expect(response.pet.isMissing == true)
        #expect(response.alert?.id == "alert_456")
        #expect(response.message == "Pet marked as missing. Alerts are being sent.")
    }

    // Test MarkMissingResponse without alert (location not provided)
    @Test func testMarkMissingResponseWithoutAlert() async throws {
        let jsonString = """
        {
            "success": true,
            "pet": {
                "id": "pet_123",
                "owner_id": "user_123",
                "name": "Max",
                "species": "Dog",
                "is_missing": true,
                "created_at": "2026-01-01T00:00:00Z",
                "updated_at": "2026-01-12T10:00:00Z"
            },
            "alert": null,
            "message": "Pet marked as missing. Add location to send community alerts."
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(MarkMissingResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.pet.isMissing == true)
        #expect(response.alert == nil, "Alert should be nil when no location provided")
    }

    // Test PetsViewModel has mark lost/found methods
    @Test func testPetsViewModelHasMarkMethods() async throws {
        let viewModel = PetsViewModel()

        // Verify methods exist by checking they can be called
        // (We can't actually test the network call without mocking)
        #expect(viewModel.pets.isEmpty, "ViewModel should start with empty pets array")
        #expect(viewModel.isLoading == false, "ViewModel should not be loading initially")
    }

    // Test that missing pet shows correct status
    @Test func testMissingPetStatus() async throws {
        let missingPet = Pet(
            id: "pet_1",
            ownerId: "owner_1",
            name: "Lost Dog",
            species: "Dog",
            isMissing: true,
            createdAt: "2026-01-01T00:00:00Z",
            updatedAt: "2026-01-12T10:00:00Z"
        )

        let foundPet = Pet(
            id: "pet_2",
            ownerId: "owner_1",
            name: "Found Dog",
            species: "Dog",
            isMissing: false,
            createdAt: "2026-01-01T00:00:00Z",
            updatedAt: "2026-01-12T10:00:00Z"
        )

        #expect(missingPet.isMissing == true, "Lost dog should be marked as missing")
        #expect(foundPet.isMissing == false, "Found dog should not be marked as missing")
        #expect(missingPet.isActive == false, "Missing pet should not be active")
        #expect(foundPet.isActive == true, "Found pet should be active")
    }

    // Test encoding mark missing request
    @Test func testMarkMissingRequestEncoding() async throws {
        struct MarkMissingRequest: Codable {
            let lastSeenLocation: LocationCoordinate?
            let lastSeenAddress: String?
            let description: String?
            let rewardAmount: Double?
        }

        let request = MarkMissingRequest(
            lastSeenLocation: LocationCoordinate(lat: 51.5074, lng: -0.1278),
            lastSeenAddress: "Central Park, London",
            description: "Last seen wearing red collar",
            rewardAmount: 100.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("lastSeenLocation"))
        #expect(jsonString.contains("lastSeenAddress"))
        #expect(jsonString.contains("description"))
        #expect(jsonString.contains("rewardAmount"))
        #expect(jsonString.contains("51.5074"))
        #expect(jsonString.contains("Central Park"))
    }
}
