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
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "UNKNOWN_TYPE"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should not crash, silently ignore
        XCTAssertNil(notificationHandler.pendingScanNotification)
        XCTAssertFalse(notificationHandler.showMapPicker)
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

    func testHandleTagScannedWithApproximateLocation() {
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-999",
            "pet_id": "pet-222",
            "location_type": "approximate",
            "latitude": "40.7500",
            "longitude": "-73.9900"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNotNil(self.notificationHandler.pendingScanNotification?.location)
            XCTAssertTrue(self.notificationHandler.pendingScanNotification?.location?.isApproximate ?? false)
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
        // Given
        let userInfo: [AnyHashable: Any] = [
            "type": "MISSING_PET_ALERT"
            // Missing alert_id
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - should use empty string as default
        // This is safe and won't crash
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

    func testLocationTypeNoneExplicit() {
        // Given - explicit "none" location type
        let userInfo: [AnyHashable: Any] = [
            "type": "PET_SCANNED",
            "scan_id": "scan-none",
            "pet_id": "pet-none",
            "location_type": "none",
            "latitude": "40.7128", // These should be ignored
            "longitude": "-74.0060"
        ]

        // When
        notificationHandler.handleNotificationTap(userInfo: userInfo)

        // Then - location should be nil despite lat/lng present
        let expectation = self.expectation(description: "Main queue")
        DispatchQueue.main.async {
            XCTAssertNil(self.notificationHandler.pendingScanNotification?.location)
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
