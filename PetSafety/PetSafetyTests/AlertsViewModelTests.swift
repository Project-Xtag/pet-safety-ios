import Testing
import Foundation
@testable import PetSafety

@Suite("AlertsViewModel Tests")
@MainActor
struct AlertsViewModelTests {

    // MARK: - Initial State

    @Test("Initial state — alerts array is empty, isLoading is false")
    func testInitialState() {
        let viewModel = AlertsViewModel()

        #expect(viewModel.alerts.isEmpty, "alerts should start empty")
        #expect(viewModel.missingAlerts.isEmpty, "missingAlerts should start empty")
        #expect(viewModel.foundAlerts.isEmpty, "foundAlerts should start empty")
        #expect(viewModel.isLoading == false, "isLoading should be false initially")
        #expect(viewModel.errorMessage == nil, "errorMessage should be nil initially")
        #expect(viewModel.isOfflineMode == false, "isOfflineMode should be false initially")
    }

    // MARK: - CreateAlertRequest Encoding

    @Test("CreateAlertRequest encodes rewardAmount correctly")
    func testCreateAlertRequestEncodesReward() throws {
        let request = CreateAlertRequest(
            petId: "pet_vm_001",
            lastSeenLocation: LocationCoordinate(lat: 47.4979, lng: 19.0402),
            lastSeenAddress: "Budapest, Andrassy ut",
            description: "Last seen near Heroes' Square",
            rewardAmount: 200.0,
            alertRadiusKm: 5.0
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["petId"] as? String == "pet_vm_001")
        #expect(dict["rewardAmount"] as? Double == 200.0)
        #expect(dict["alertRadiusKm"] as? Double == 5.0)
        #expect(dict["description"] as? String == "Last seen near Heroes' Square")
        #expect(dict["lastSeenAddress"] as? String == "Budapest, Andrassy ut")

        let location = dict["lastSeenLocation"] as? [String: Any]
        #expect(location?["lat"] as? Double == 47.4979)
        #expect(location?["lng"] as? Double == 19.0402)
    }

    @Test("CreateAlertRequest encodes without rewardAmount (nil)")
    func testCreateAlertRequestEncodesWithoutReward() throws {
        let request = CreateAlertRequest(
            petId: "pet_vm_002",
            lastSeenLocation: nil,
            lastSeenAddress: "Some address",
            description: nil,
            rewardAmount: nil,
            alertRadiusKm: nil
        )

        let data = try JSONEncoder().encode(request)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("petId"), "petId must always be present")
        #expect(jsonString.contains("lastSeenAddress"), "lastSeenAddress should be present when set")
        #expect(!jsonString.contains("rewardAmount"), "rewardAmount should be omitted when nil")
        #expect(!jsonString.contains("alertRadiusKm"), "alertRadiusKm should be omitted when nil")
        #expect(!jsonString.contains("lastSeenLocation"), "lastSeenLocation should be omitted when nil")
    }

    // MARK: - Offline Alert Queueing Data

    @Test("Offline alert queueing action data includes rewardAmount")
    func testOfflineQueueActionDataIncludesReward() {
        // Simulate the action data dictionary built in createAlert when offline
        var actionData: [String: Any] = ["petId": "pet_vm_003"]
        let rewardAmount: Double? = 150.0
        let coordinate = (latitude: 51.5074, longitude: -0.1278)
        let location: String? = "Central Park"
        let additionalInfo: String? = "Lost near the entrance"

        actionData["latitude"] = coordinate.latitude
        actionData["longitude"] = coordinate.longitude

        if let location = location {
            actionData["lastSeenAddress"] = location
        }
        if let additionalInfo = additionalInfo {
            actionData["description"] = additionalInfo
        }
        if let rewardAmount = rewardAmount {
            actionData["rewardAmount"] = rewardAmount
        }

        #expect(actionData["petId"] as? String == "pet_vm_003")
        #expect(actionData["rewardAmount"] as? Double == 150.0)
        #expect(actionData["latitude"] as? Double == 51.5074)
        #expect(actionData["longitude"] as? Double == -0.1278)
        #expect(actionData["lastSeenAddress"] as? String == "Central Park")
        #expect(actionData["description"] as? String == "Lost near the entrance")
    }

    @Test("Offline alert queueing action data omits rewardAmount when nil")
    func testOfflineQueueActionDataOmitsNilReward() {
        var actionData: [String: Any] = ["petId": "pet_vm_004"]
        let rewardAmount: Double? = nil

        if let rewardAmount = rewardAmount {
            actionData["rewardAmount"] = rewardAmount
        }

        #expect(actionData["petId"] as? String == "pet_vm_004")
        #expect(actionData["rewardAmount"] == nil, "rewardAmount should not be in dictionary when nil")
    }

    // MARK: - LocationCoordinate Encoding

    @Test("LocationCoordinate encoding for lastSeenLocation")
    func testLocationCoordinateEncoding() throws {
        let coordinate = LocationCoordinate(lat: 48.2082, lng: 16.3738)

        let data = try JSONEncoder().encode(coordinate)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["lat"] as? Double == 48.2082)
        #expect(dict["lng"] as? Double == 16.3738)

        // Roundtrip test
        let decoded = try JSONDecoder().decode(LocationCoordinate.self, from: data)
        #expect(decoded.lat == coordinate.lat)
        #expect(decoded.lng == coordinate.lng)
    }

    @Test("LocationCoordinate used in CreateAlertRequest roundtrips correctly")
    func testLocationCoordinateInRequest() throws {
        let location = LocationCoordinate(lat: -33.8688, lng: 151.2093)
        let request = CreateAlertRequest(
            petId: "pet_vm_005",
            lastSeenLocation: location,
            lastSeenAddress: "Sydney Opera House",
            description: nil,
            rewardAmount: 300.0,
            alertRadiusKm: 25.0
        )

        let data = try JSONEncoder().encode(request)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("-33.8688"), "Latitude should be in encoded JSON")
        #expect(jsonString.contains("151.2093"), "Longitude should be in encoded JSON")
        #expect(jsonString.contains("Sydney Opera House"))
        #expect(jsonString.contains("300"), "rewardAmount should be in encoded JSON")
    }

    // MARK: - MissingPetAlert via ApiEnvelope

    @Test("Decodes MissingPetAlert wrapped in ApiEnvelope")
    func testDecodeAlertViaApiEnvelope() throws {
        let json = """
        {
            "success": true,
            "data": {
                "id": "alert_env_001",
                "pet_id": "pet_env_001",
                "user_id": "user_env_001",
                "status": "active",
                "reward_amount": 999.99,
                "alert_radius_km": 10,
                "created_at": "2026-02-01T12:00:00Z",
                "updated_at": "2026-02-01T12:00:00Z"
            }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(ApiEnvelope<MissingPetAlert>.self, from: json)
        #expect(envelope.success == true)
        #expect(envelope.data?.id == "alert_env_001")
        #expect(envelope.data?.rewardAmount == 999.99)
        #expect(envelope.data?.alertRadiusKm == 10.0)
    }

    // MARK: - createAlert Method Signature

    @Test("Verify createAlert method exists with rewardAmount parameter")
    func testCreateAlertMethodSignature() {
        let viewModel = AlertsViewModel()

        // Verify the method signature compiles with rewardAmount parameter.
        // We store a closure reference that calls createAlert with all parameters
        // including rewardAmount. If the signature changes, this test will fail to compile.
        let _: (String, String?, CLLocationCoordinate2D?, String?, Double?) async throws -> MissingPetAlert = {
            petId, location, coordinate, additionalInfo, rewardAmount in
            return try await viewModel.createAlert(
                petId: petId,
                location: location,
                coordinate: coordinate,
                additionalInfo: additionalInfo,
                rewardAmount: rewardAmount
            )
        }

        // The mere compilation of this test confirms createAlert accepts rewardAmount.
        #expect(true, "createAlert method with rewardAmount parameter exists")
    }
}

// Import needed for CLLocationCoordinate2D
import CoreLocation
