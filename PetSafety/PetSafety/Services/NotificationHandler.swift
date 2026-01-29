import Foundation
import SwiftUI
import UserNotifications

/**
 * Notification Handler for FCM Push Notifications
 *
 * Handles incoming push notifications and manages the map picker presentation.
 * Supports 3-tier location:
 * - No location (scan only notification)
 * - Approximate location (~500m accuracy)
 * - Precise location (exact GPS)
 */

// MARK: - Notification Handler

class NotificationHandler: ObservableObject {
    static let shared = NotificationHandler()

    /// Pending notification that should show the map picker
    @Published var pendingScanNotification: ScanNotificationData?

    /// Whether to show the map picker sheet
    @Published var showMapPicker = false

    private init() {}

    /// Handle notification tap from FCM
    /// - Parameter userInfo: The notification payload
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "PET_SCANNED":
            handleTagScannedNotification(userInfo)
        case "MISSING_PET_ALERT":
            handleMissingPetAlert(userInfo)
        case "PET_FOUND":
            handlePetFoundNotification(userInfo)
        case "SIGHTING_REPORTED":
            handleSightingNotification(userInfo)
        default:
            #if DEBUG
            print("Unknown notification type: \(type)")
            #endif
        }
    }

    // MARK: - Tag Scanned Notification

    private func handleTagScannedNotification(_ userInfo: [AnyHashable: Any]) {
        let scanId = userInfo["scan_id"] as? String ?? ""
        let petId = userInfo["pet_id"] as? String ?? ""
        let locationType = userInfo["location_type"] as? String ?? "none"

        var location: LocationData?
        if locationType != "none",
           let latString = userInfo["latitude"] as? String,
           let lonString = userInfo["longitude"] as? String,
           let lat = Double(latString),
           let lon = Double(lonString) {
            location = LocationData(
                latitude: lat,
                longitude: lon,
                isApproximate: locationType == "approximate"
            )
        }

        DispatchQueue.main.async { [weak self] in
            self?.pendingScanNotification = ScanNotificationData(
                scanId: scanId,
                petId: petId,
                petName: nil, // Will be loaded from pet details
                location: location
            )

            // If there's a location, show the map picker
            if location != nil {
                self?.showMapPicker = true
            }
        }

        #if DEBUG
        print("Tag scanned notification handled: petId=\(petId), location=\(locationType)")
        #endif
    }

    // MARK: - Missing Pet Alert

    private func handleMissingPetAlert(_ userInfo: [AnyHashable: Any]) {
        let alertId = userInfo["alert_id"] as? String ?? ""
        let petId = userInfo["pet_id"] as? String ?? ""

        // Navigate to alert details
        // This will be handled by the DeepLinkService
        let deepLink = "petsafety://alert/\(alertId)"

        #if DEBUG
        print("Missing pet alert notification: alertId=\(alertId), petId=\(petId)")
        print("Deep link: \(deepLink)")
        #endif

        // Post notification to navigate
        NotificationCenter.default.post(
            name: .navigateToAlert,
            object: nil,
            userInfo: ["alertId": alertId, "petId": petId]
        )
    }

    // MARK: - Pet Found Notification

    private func handlePetFoundNotification(_ userInfo: [AnyHashable: Any]) {
        let alertId = userInfo["alert_id"] as? String ?? ""
        let petId = userInfo["pet_id"] as? String ?? ""

        #if DEBUG
        print("Pet found notification: alertId=\(alertId), petId=\(petId)")
        #endif

        // Navigate to pet details
        NotificationCenter.default.post(
            name: .navigateToPet,
            object: nil,
            userInfo: ["petId": petId]
        )
    }

    // MARK: - Sighting Notification

    private func handleSightingNotification(_ userInfo: [AnyHashable: Any]) {
        let alertId = userInfo["alert_id"] as? String ?? ""
        let sightingId = userInfo["sighting_id"] as? String ?? ""

        var location: LocationData?
        if let latString = userInfo["latitude"] as? String,
           let lonString = userInfo["longitude"] as? String,
           let lat = Double(latString),
           let lon = Double(lonString) {
            location = LocationData(
                latitude: lat,
                longitude: lon,
                isApproximate: false
            )
        }

        #if DEBUG
        print("Sighting notification: alertId=\(alertId), sightingId=\(sightingId)")
        #endif

        // If there's a location, show map picker with sighting location
        if let location = location {
            DispatchQueue.main.async { [weak self] in
                self?.pendingScanNotification = ScanNotificationData(
                    scanId: sightingId,
                    petId: "",
                    petName: nil,
                    location: location
                )
                self?.showMapPicker = true
            }
        }

        // Also post notification to navigate to alert
        NotificationCenter.default.post(
            name: .navigateToAlert,
            object: nil,
            userInfo: ["alertId": alertId, "sightingId": sightingId]
        )
    }

    // MARK: - Clear Pending Notification

    func clearPendingNotification() {
        pendingScanNotification = nil
        showMapPicker = false
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToAlert = Notification.Name("navigateToAlert")
    static let navigateToPet = Notification.Name("navigateToPet")
    static let navigateToScan = Notification.Name("navigateToScan")
}
