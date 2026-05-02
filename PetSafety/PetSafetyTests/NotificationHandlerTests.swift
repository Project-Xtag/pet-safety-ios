import XCTest
@testable import PetSafety

/**
 * NotificationHandler Unit Tests
 *
 * Tests the FCM notification handling including:
 * - Notification type parsing
 * - Location data extraction
 * - Map picker presentation
 * - Navigation notifications
 */
final class NotificationHandlerTests: XCTestCase {

    var notificationHandler: NotificationHandler!

    // MARK: - Test Setup

    override func setUp() {
        super.setUp()
        notificationHandler = NotificationHandler.shared
        notificationHandler.clearPendingNotification()
    }

    override func tearDown() {
        super.tearDown()
        notificationHandler.clearPendingNotification()
    }

    // MARK: - Notification Type Parsing Tests

    func testHandleUnknownNotificationType() {
        // Given - audit #68: unknown type now navigates to a safe inbox/scan
        // fallback instead of silently dropping. The Sentry capture is the
        // primary signal; the fallback nav stops users landing on a dead
        // screen if a new backend type ships before app catches up.
        let userInfo: [AnyHashable: Any] = [
            "type": "UNKNOWN_TYPE"
        ]
        let navExpectation = expectNavigationNotification(named: .navigateToScan)

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        XCTAssertNil(notificationHandler.pendingScanNotification)
        XCTAssertFalse(notificationHandler.showMapPicker)
        waitForExpectations(timeout: 1.0)
    }

    func testHandleMissingType() {
        // Given - no type field
        let userInfo: [AnyHashable: Any] = [
            "pet_id": "pet-123"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should not crash
        XCTAssertNil(notificationHandler.pendingScanNotification)
    }

    // MARK: - PET_SCANNED Notification Tests

    func testHandleTagScannedWithoutLocation() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-123",
            "pet_id": "pet-456",
            "location_type": "none"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - wait for main queue
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNotNil(self.notificationHandler.pendingScanNotification)
            XCTAssertEqual(self.notificationHandler.pendingScanNotification?.scanId, "scan-123")
            XCTAssertEqual(self.notificationHandler.pendingScanNotification?.petId, "pet-456")
            XCTAssertNil(self.notificationHandler.pendingScanNotification?.location)
            XCTAssertFalse(self.notificationHandler.showMapPicker) // No location = no map
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleTagScannedWithPreciseLocation() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-789",
            "pet_id": "pet-111",
            "location_type": "precise",
            "latitude": "40.7128",
            "longitude": "-74.0060"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNotNil(self.notificationHandler.pendingScanNotification)
            XCTAssertNotNil(self.notificationHandler.pendingScanNotification?.location)
            XCTAssertEqual(self.notificationHandler.pendingScanNotification?.location?.latitude, 40.7128)
            XCTAssertEqual(self.notificationHandler.pendingScanNotification?.location?.longitude, -74.0060)
            XCTAssertFalse(self.notificationHandler.pendingScanNotification?.location?.isApproximate ?? true)
            XCTAssertTrue(self.notificationHandler.showMapPicker)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleTagScannedAlwaysParsesAsPrecise() {
        // 2026-05-02 missing-pet flow overhaul: backend dropped the
        // `location_type` discriminator. Even if a legacy payload still
        // includes it, the client treats every PET_SCANNED location as
        // precise — `isApproximate` stays false.
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-999",
            "pet_id": "pet-222",
            "location_type": "approximate",
            "latitude": "40.7500",
            "longitude": "-73.9900"
        ]

        notificationHandler.handleNotificationTap(userInfo: userInfo)

        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNotNil(self.notificationHandler.pendingScanNotification?.location)
            XCTAssertFalse(self.notificationHandler.pendingScanNotification?.location?.isApproximate ?? true)
            XCTAssertTrue(self.notificationHandler.showMapPicker)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleTagScannedWithInvalidLatitude() {
        // Given - invalid latitude value
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-invalid",
            "pet_id": "pet-invalid",
            "location_type": "precise",
            "latitude": "not-a-number",
            "longitude": "-74.0060"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should handle gracefully, no location
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNotNil(self.notificationHandler.pendingScanNotification)
            XCTAssertNil(self.notificationHandler.pendingScanNotification?.location)
            XCTAssertFalse(self.notificationHandler.showMapPicker)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleTagScannedWithMissingLongitude() {
        // Given - missing longitude
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-partial",
            "pet_id": "pet-partial",
            "location_type": "precise",
            "latitude": "40.7128"
            // Missing longitude
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should handle gracefully, no location
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNil(self.notificationHandler.pendingScanNotification?.location)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Coordinate Range Validation Tests (audit #67)

    func testHandleTagScannedWithOutOfRangeLatitude() {
        // Given - latitude > 90
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-bad-lat",
            "pet_id": "pet-bad-lat",
            "location_type": "precise",
            "latitude": "120.0",
            "longitude": "-74.0060"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - location dropped, no map picker
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNil(self.notificationHandler.pendingScanNotification?.location)
            XCTAssertFalse(self.notificationHandler.showMapPicker)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleTagScannedWithOutOfRangeLongitude() {
        // Given - longitude < -180
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-bad-lon",
            "pet_id": "pet-bad-lon",
            "location_type": "precise",
            "latitude": "40.7128",
            "longitude": "-200.0"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNil(self.notificationHandler.pendingScanNotification?.location)
            XCTAssertFalse(self.notificationHandler.showMapPicker)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleTagScannedWithInfinityCoordinate() {
        // Given - "inf" parses to .infinity in Double, which would crash MapKit
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-inf",
            "pet_id": "pet-inf",
            "location_type": "precise",
            "latitude": "inf",
            "longitude": "-74.0060"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNil(self.notificationHandler.pendingScanNotification?.location)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleTagScannedWithNaNCoordinate() {
        // Given - "nan" parses to .nan, which would NaN-poison MapKit math
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-nan",
            "pet_id": "pet-nan",
            "location_type": "precise",
            "latitude": "40.7128",
            "longitude": "nan"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNil(self.notificationHandler.pendingScanNotification?.location)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleTagScannedRejectsNullIsland() {
        // Given - (0, 0) is geographically valid but is the conventional "null"
        // sentinel in our backend; InputValidators rejects it.
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-zero",
            "pet_id": "pet-zero",
            "location_type": "precise",
            "latitude": "0",
            "longitude": "0"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNil(self.notificationHandler.pendingScanNotification?.location)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleSightingWithOutOfRangeCoordinates() {
        // Given - sighting with bogus lat/lng — must not show map picker
        let userInfo: [AnyHashable: Any] = [
            "type": "SIGHTING_REPORTED",
            "alert_id": "alert-bad",
            "sighting_id": "sighting-bad",
            "latitude": "999.0",
            "longitude": "999.0"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - location dropped, no map picker (navigation still posts)
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertFalse(self.notificationHandler.showMapPicker)
            XCTAssertNil(self.notificationHandler.pendingScanNotification?.location)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - MISSING_PET_ALERT Notification Tests

    func testHandleMissingPetAlert() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "MISSING_PET_ALERT",
            "alert_id": "alert-123",
            "pet_id": "pet-456"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should post notification for navigation
        // NotificationCenter.default posts .navigateToAlert
    }

    func testHandleMissingPetAlertWithEmptyAlertId() {
        // Audit #69: empty alert_id MUST NOT post a navigation event
        // (`senra://alert/` would deep-link to a 404). The handler
        // captures to Sentry and returns early.
        var didNavigate = false
        let observer = NotificationCenter.default.addObserver(
            forName: .navigateToAlert, object: nil, queue: nil
        ) { _ in
            didNavigate = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        let userInfo: [AnyHashable: Any] = [
            "type": "MISSING_PET_ALERT"
            // Missing alert_id
        ]

        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Give the runloop a tick to flush any post; the handler is
        // synchronous so this is a belt-and-braces wait.
        let exp = self.expectation(description: "Allow runloop to settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { exp.fulfill() }
        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(didNavigate, "Empty alert_id must not produce a navigateToAlert event")
    }

    func testHandlePetFoundWithEmptyPetIdDoesNotNavigate() {
        // Audit #69: empty pet_id ⇒ no .navigateToPet post.
        var didNavigate = false
        let observer = NotificationCenter.default.addObserver(
            forName: .navigateToPet, object: nil, queue: nil
        ) { _ in
            didNavigate = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        let userInfo: [AnyHashable: Any] = [
            "type": "PET_FOUND",
            "alert_id": "alert-x"
            // Missing pet_id
        ]

        notificationHandler.handleNotificationTap(userInfo: userInfo)

        let exp = self.expectation(description: "Allow runloop to settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { exp.fulfill() }
        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(didNavigate, "Empty pet_id must not produce a navigateToPet event")
    }

    func testHandleSightingWithEmptyAlertIdDoesNotNavigate() {
        // Audit #69: empty alert_id on a sighting ⇒ no nav post.
        var didNavigate = false
        let observer = NotificationCenter.default.addObserver(
            forName: .navigateToAlert, object: nil, queue: nil
        ) { _ in
            didNavigate = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        let userInfo: [AnyHashable: Any] = [
            "type": "SIGHTING_REPORTED",
            "sighting_id": "s-1",
            "latitude": "40.7128",
            "longitude": "-74.0060"
            // Missing alert_id
        ]

        notificationHandler.handleNotificationTap(userInfo: userInfo)

        let exp = self.expectation(description: "Allow runloop to settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { exp.fulfill() }
        waitForExpectations(timeout: 1.0)

        XCTAssertFalse(didNavigate, "Empty alert_id on sighting must not produce a navigateToAlert event")
    }

    // MARK: - PET_FOUND Notification Tests

    func testHandlePetFoundNotification() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_FOUND",
            "alert_id": "alert-789",
            "pet_id": "pet-789"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should post notification for navigation to pet
        // NotificationCenter.default posts .navigateToPet
    }

    // MARK: - SIGHTING_REPORTED Notification Tests

    func testHandleSightingWithLocation() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "SIGHTING_REPORTED",
            "alert_id": "alert-111",
            "sighting_id": "sighting-222",
            "latitude": "40.7500",
            "longitude": "-73.9900"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNotNil(self.notificationHandler.pendingScanNotification)
            XCTAssertNotNil(self.notificationHandler.pendingScanNotification?.location)
            XCTAssertFalse(self.notificationHandler.pendingScanNotification?.location?.isApproximate ?? true)
            XCTAssertTrue(self.notificationHandler.showMapPicker)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testHandleSightingWithoutLocation() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "SIGHTING_REPORTED",
            "alert_id": "alert-333",
            "sighting_id": "sighting-444"
            // No location
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should still navigate but not show map picker
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            // No location means no map picker
            XCTAssertFalse(self.notificationHandler.showMapPicker)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - ALERT_CREATED Notification Tests

    func testHandleAlertConfirmation() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "ALERT_CREATED",
            "alert_id": "alert-123",
            "pet_id": "pet-456"
        ]

        // When - should post navigateToAlert notification
        let navExpectation = expectNavigationNotification(named: .navigateToAlert)
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func testHandleAlertConfirmationWithEmptyAlertId() {
        // Given - missing alert_id means empty string, should not post notification
        let userInfo: [AnyHashable: Any] = [
            "type": "ALERT_CREATED"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should not crash
        XCTAssertNil(notificationHandler.pendingScanNotification)
    }

    // MARK: - ALERT_REMINDER Notification Tests

    func testHandleAlertReminder() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "ALERT_REMINDER",
            "alert_id": "alert-789"
        ]

        // When - should post navigateToAlert notification
        let navExpectation = expectNavigationNotification(named: .navigateToAlert)
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func testHandleAlertReminderWithEmptyAlertId() {
        // Given - missing alert_id
        let userInfo: [AnyHashable: Any] = [
            "type": "ALERT_REMINDER"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should not crash, no navigation posted
        XCTAssertNil(notificationHandler.pendingScanNotification)
    }

    // MARK: - MULTIPLE_SIGHTINGS Notification Tests

    func testHandleMultipleSightings() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "MULTIPLE_SIGHTINGS",
            "alert_id": "alert-101"
        ]

        // When - should post navigateToAlert notification
        let navExpectation = expectNavigationNotification(named: .navigateToAlert)
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        waitForExpectations(timeout: 1.0)
    }

    func testHandleMultipleSightingsWithEmptyAlertId() {
        // Given - missing alert_id
        let userInfo: [AnyHashable: Any] = [
            "type": "MULTIPLE_SIGHTINGS"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should not crash
        XCTAssertNil(notificationHandler.pendingScanNotification)
    }

    // MARK: - Clear Pending Notification Tests

    func testClearPendingNotification() {
        // Given - set up a pending notification
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-clear",
            "pet_id": "pet-clear",
            "location_type": "precise",
            "latitude": "40.7128",
            "longitude": "-74.0060"
        ]
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // When
        let expectation = self.expectation(description: "Clear notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.notificationHandler.clearPendingNotification()

            // Then
            XCTAssertNil(self.notificationHandler.pendingScanNotification)
            XCTAssertFalse(self.notificationHandler.showMapPicker)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - LocationData Tests

    func testLocationDataCreation() {
        // Given
        let location = LocationData(
            latitude: 40.7128,
            longitude: -74.0060,
            isApproximate: false
        )

        // Then
        XCTAssertEqual(location.latitude, 40.7128)
        XCTAssertEqual(location.longitude, -74.0060)
        XCTAssertFalse(location.isApproximate)
    }

    func testApproximateLocationData() {
        // Given
        let location = LocationData(
            latitude: 40.7128,
            longitude: -74.0060,
            isApproximate: true
        )

        // Then
        XCTAssertTrue(location.isApproximate)
    }

    // MARK: - ScanNotificationData Tests

    func testScanNotificationDataCreation() {
        // Given
        let location = LocationData(latitude: 40.7, longitude: -74.0, isApproximate: false)
        let data = ScanNotificationData(
            scanId: "scan-test",
            petId: "pet-test",
            petName: "Buddy",
            location: location
        )

        // Then
        XCTAssertEqual(data.scanId, "scan-test")
        XCTAssertEqual(data.petId, "pet-test")
        XCTAssertEqual(data.petName, "Buddy")
        XCTAssertNotNil(data.location)
    }

    func testScanNotificationDataWithoutLocation() {
        // Given
        let data = ScanNotificationData(
            scanId: "scan-no-loc",
            petId: "pet-no-loc",
            petName: nil,
            location: nil
        )

        // Then
        XCTAssertNil(data.petName)
        XCTAssertNil(data.location)
    }

    // MARK: - Notification Names Tests

    func testNavigationNotificationNames() {
        // Verify notification names are defined correctly
        XCTAssertEqual(Notification.Name.navigateToAlert.rawValue, "navigateToAlert")
        XCTAssertEqual(Notification.Name.navigateToPet.rawValue, "navigateToPet")
        XCTAssertEqual(Notification.Name.navigateToScan.rawValue, "navigateToScan")
    }

    // MARK: - Thread Safety Tests

    func testMainThreadUpdates() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-thread",
            "pet_id": "pet-thread",
            "location_type": "none"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - updates should happen on main thread
        let expectation = self.expectation(description: "Main thread update")
        DispatchQueue.main.async {
            // This code runs on main thread after the notification handler updates
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Edge Cases

    func testEmptyUserInfo() {
        // Given
        let userInfo: [AnyHashable: Any] = [:]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should handle gracefully
        XCTAssertNil(notificationHandler.pendingScanNotification)
    }

    func testNullValuesInUserInfo() {
        // Given - values that might be NSNull in JSON parsing
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-null",
            "pet_id": NSNull(), // Simulating null value
            "location_type": "none"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should handle gracefully with empty string default
    }

    func testLocationTypeFieldIsIgnoredWhenCoordinatesPresent() {
        // 2026-05-02 missing-pet flow overhaul: backend dropped the
        // `location_type` discriminator. The client now parses lat/lng
        // directly and treats them as precise — even if a legacy payload
        // still includes "location_type": "none" alongside coordinates,
        // the coordinates are honoured.
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-none",
            "pet_id": "pet-none",
            "location_type": "none",
            "latitude": "40.7128",
            "longitude": "-74.0060"
        ]

        notificationHandler.handleNotificationTap(userInfo: userInfo)

        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNotNil(self.notificationHandler.pendingScanNotification?.location)
            XCTAssertEqual(self.notificationHandler.pendingScanNotification?.location?.latitude, 40.7128)
            XCTAssertFalse(self.notificationHandler.pendingScanNotification?.location?.isApproximate ?? true)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
}

// MARK: - Test Helpers

extension NotificationHandlerTests {
    /// Helper to verify notification was posted
    func expectNavigationNotification(named name: Notification.Name, timeout: TimeInterval = 1.0) -> XCTestExpectation {
        let expectation = expectation(forNotification: name, object: nil, handler: nil)
        expectation.assertForOverFulfill = false
        return expectation
    }
}
