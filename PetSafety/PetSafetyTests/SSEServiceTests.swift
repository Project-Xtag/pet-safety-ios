import Testing
import Foundation
@testable import PetSafety

/// Tests for SSEService - Real-time notification system
@Suite("SSEService Tests")
struct SSEServiceTests {

    // MARK: - Connection Management Tests

    @Test("SSEService should be a singleton")
    func testSingletonInstance() {
        let instance1 = SSEService.shared
        let instance2 = SSEService.shared

        #expect(instance1 === instance2)
    }

    @Test("SSEService should initialize with disconnected state")
    func testInitialState() {
        let service = SSEService.shared
        #expect(service.isConnected == false)
        #expect(service.connectionError == nil)
        #expect(service.lastEvent == nil)
    }

    @Test("SSEService connect requires auth token")
    func testConnectWithoutToken() {
        // Clear any existing token
        KeychainService.shared.deleteAuthToken()

        let service = SSEService.shared
        service.connect()

        // Should set connection error
        #expect(service.connectionError != nil)
        #expect(service.connectionError?.contains("Authentication") == true)
    }

    @Test("SSEService disconnect should clear connection state")
    func testDisconnect() {
        let service = SSEService.shared
        service.disconnect()

        #expect(service.isConnected == false)
    }

    // MARK: - Event Handler Tests

    @Test("SSEService should register tag scanned handler")
    func testTagScannedHandler() {
        let service = SSEService.shared
        var handlerCalled = false
        var receivedEvent: TagScannedEvent?

        service.onTagScanned = { event in
            handlerCalled = true
            receivedEvent = event
        }

        // Simulate event (in real tests, this would come from network)
        let testEvent = TagScannedEvent(
            petId: "pet_123",
            petName: "Max",
            qrCode: "QR_123",
            location: TagScannedEvent.Location(lat: 51.5074, lng: -0.1278),
            address: "Test Location",
            scannedAt: Date()
        )

        // Trigger handler directly for testing
        service.onTagScanned?(testEvent)

        #expect(handlerCalled == true)
        #expect(receivedEvent?.petName == "Max")
        #expect(receivedEvent?.petId == "pet_123")
    }

    @Test("SSEService should register sighting reported handler")
    func testSightingReportedHandler() {
        let service = SSEService.shared
        var handlerCalled = false
        var receivedEvent: SightingReportedEvent?

        service.onSightingReported = { event in
            handlerCalled = true
            receivedEvent = event
        }

        let testEvent = SightingReportedEvent(
            alertId: "alert_123",
            petId: "pet_123",
            petName: "Max",
            sightingId: "sighting_123",
            location: SightingReportedEvent.Location(lat: 51.5074, lng: -0.1278),
            address: "Test Location",
            reportedAt: Date(),
            reporterName: "John Doe"
        )

        service.onSightingReported?(testEvent)

        #expect(handlerCalled == true)
        #expect(receivedEvent?.petName == "Max")
        #expect(receivedEvent?.alertId == "alert_123")
    }

    @Test("SSEService should register pet found handler")
    func testPetFoundHandler() {
        let service = SSEService.shared
        var handlerCalled = false
        var receivedEvent: PetFoundEvent?

        service.onPetFound = { event in
            handlerCalled = true
            receivedEvent = event
        }

        let testEvent = PetFoundEvent(
            petId: "pet_123",
            petName: "Max",
            alertId: "alert_123",
            foundAt: Date()
        )

        service.onPetFound?(testEvent)

        #expect(handlerCalled == true)
        #expect(receivedEvent?.petName == "Max")
        #expect(receivedEvent?.petId == "pet_123")
    }

    @Test("SSEService should register alert created handler")
    func testAlertCreatedHandler() {
        let service = SSEService.shared
        var handlerCalled = false

        service.onAlertCreated = { event in
            handlerCalled = true
        }

        let testEvent = AlertCreatedEvent(
            alertId: "alert_123",
            petId: "pet_123",
            petName: "Max",
            location: AlertCreatedEvent.Location(lat: 51.5074, lng: -0.1278),
            address: "Test Location",
            createdAt: Date()
        )

        service.onAlertCreated?(testEvent)

        #expect(handlerCalled == true)
    }

    @Test("SSEService should register alert updated handler")
    func testAlertUpdatedHandler() {
        let service = SSEService.shared
        var handlerCalled = false

        service.onAlertUpdated = { event in
            handlerCalled = true
        }

        let testEvent = AlertUpdatedEvent(
            alertId: "alert_123",
            petId: "pet_123",
            petName: "Max",
            status: "found",
            updatedAt: Date()
        )

        service.onAlertUpdated?(testEvent)

        #expect(handlerCalled == true)
    }

    @Test("SSEService should register connection handler")
    func testConnectionHandler() {
        let service = SSEService.shared
        var handlerCalled = false
        var receivedUserId: String?

        service.onConnected = { event in
            handlerCalled = true
            receivedUserId = event.userId
        }

        let testEvent = ConnectionEvent(
            userId: "user_123",
            connectedAt: Date()
        )

        service.onConnected?(testEvent)

        #expect(handlerCalled == true)
        #expect(receivedUserId == "user_123")
    }

    // MARK: - Event Model Tests

    @Test("TagScannedEvent should encode and decode correctly")
    func testTagScannedEventCodable() throws {
        let event = TagScannedEvent(
            petId: "pet_123",
            petName: "Max",
            qrCode: "QR_123",
            location: TagScannedEvent.Location(lat: 51.5074, lng: -0.1278),
            address: "London, UK",
            scannedAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TagScannedEvent.self, from: data)

        #expect(decoded.petId == event.petId)
        #expect(decoded.petName == event.petName)
        #expect(decoded.qrCode == event.qrCode)
        #expect(decoded.location.lat == event.location.lat)
        #expect(decoded.location.lng == event.location.lng)
        #expect(decoded.address == event.address)
    }

    @Test("SightingReportedEvent should encode and decode correctly")
    func testSightingReportedEventCodable() throws {
        let event = SightingReportedEvent(
            alertId: "alert_123",
            petId: "pet_123",
            petName: "Max",
            sightingId: "sighting_123",
            location: SightingReportedEvent.Location(lat: 51.5074, lng: -0.1278),
            address: "London, UK",
            reportedAt: Date(),
            reporterName: "John Doe"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SightingReportedEvent.self, from: data)

        #expect(decoded.alertId == event.alertId)
        #expect(decoded.petId == event.petId)
        #expect(decoded.petName == event.petName)
        #expect(decoded.sightingId == event.sightingId)
        #expect(decoded.reporterName == event.reporterName)
    }

    @Test("SightingReportedEvent should handle optional fields")
    func testSightingReportedEventOptionalFields() throws {
        let jsonString = """
        {
            "alertId": "alert_123",
            "petId": "pet_123",
            "petName": "Max",
            "sightingId": "sighting_123",
            "location": {
                "lat": 51.5074,
                "lng": -0.1278
            },
            "reportedAt": "2026-01-12T10:00:00Z"
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(SightingReportedEvent.self, from: data)

        #expect(decoded.petName == "Max")
        #expect(decoded.address == nil)
        #expect(decoded.reporterName == nil)
    }

    @Test("PetFoundEvent should encode and decode correctly")
    func testPetFoundEventCodable() throws {
        let event = PetFoundEvent(
            petId: "pet_123",
            petName: "Max",
            alertId: "alert_123",
            foundAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PetFoundEvent.self, from: data)

        #expect(decoded.petId == event.petId)
        #expect(decoded.petName == event.petName)
        #expect(decoded.alertId == event.alertId)
    }

    @Test("AlertCreatedEvent should encode and decode correctly")
    func testAlertCreatedEventCodable() throws {
        let event = AlertCreatedEvent(
            alertId: "alert_123",
            petId: "pet_123",
            petName: "Max",
            location: AlertCreatedEvent.Location(lat: 51.5074, lng: -0.1278),
            address: "London, UK",
            createdAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AlertCreatedEvent.self, from: data)

        #expect(decoded.alertId == event.alertId)
        #expect(decoded.petId == event.petId)
        #expect(decoded.petName == event.petName)
        #expect(decoded.address == event.address)
    }

    @Test("ConnectionEvent should encode and decode correctly")
    func testConnectionEventCodable() throws {
        let event = ConnectionEvent(
            userId: "user_123",
            connectedAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ConnectionEvent.self, from: data)

        #expect(decoded.userId == event.userId)
    }

    // MARK: - Integration Tests

    @Test("SSEService should clean up on disconnect")
    func testCleanupOnDisconnect() {
        let service = SSEService.shared

        // Set some state
        service.onTagScanned = { _ in }

        // Disconnect
        service.disconnect()

        #expect(service.isConnected == false)
        // Handlers should remain (they're set by app, not connection)
        #expect(service.onTagScanned != nil)
    }
}
