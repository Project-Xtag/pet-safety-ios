import Foundation
import SwiftUI
import UserNotifications
import Sentry

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
        guard let type = userInfo["type"] as? String else {
            // Payload arrived without a `type` discriminator — the user tapped
            // a notification we don't know how to route. Surface to Sentry so
            // we notice if backend ever ships an untyped payload, instead of
            // the silent no-op pre-fix (audit #68).
            Self.captureUnknownNotification(type: "<missing>", userInfo: userInfo)
            return
        }

        switch type {
        case "PET_SCANNED", "TAG_INITIAL_SCAN":
            handleTagScannedNotification(userInfo)
        case "TAG_ACTIVATED":
            // Navigate to pet list — tag activation confirmed
            NotificationCenter.default.post(name: .navigateToPet, object: nil, userInfo: userInfo as? [String: Any] ?? [:])
        case "MISSING_PET_ALERT":
            handleMissingPetAlert(userInfo)
        case "PET_FOUND":
            handlePetFoundNotification(userInfo)
        case "SIGHTING_REPORTED":
            handleSightingNotification(userInfo)
        case "ALERT_CREATED":
            handleAlertConfirmation(userInfo)
        case "ALERT_REMINDER":
            handleAlertReminder(userInfo)
        case "MULTIPLE_SIGHTINGS":
            handleMultipleSightings(userInfo)
        default:
            // Unknown discriminator — usually means the backend rolled out a
            // new event type before the iOS app knows how to render it. The
            // user already tapped, so silently dropping leaves them on a
            // dead-end screen with no telemetry. Capture to Sentry and post
            // a generic navigation so they at least land somewhere sensible
            // (audit #68).
            Self.captureUnknownNotification(type: type, userInfo: userInfo)
            NotificationCenter.default.post(name: .navigateToScan, object: nil, userInfo: ["type": type])
        }
    }

    /// Telemetry helper: report an unrecognised FCM payload to Sentry.
    /// Includes the keys but not the values (some keys carry PII).
    private static func captureUnknownNotification(type: String, userInfo: [AnyHashable: Any]) {
        #if DEBUG
        print("Unknown notification type: \(type)")
        #endif
        if SentrySDK.isEnabled {
            SentrySDK.capture(message: "Unknown FCM notification type: \(type)") { scope in
                scope.setLevel(.warning)
                scope.setTag(value: "notification_unknown_type", key: "operation")
                scope.setContext(
                    value: ["type": type, "keys": userInfo.keys.compactMap { $0 as? String }],
                    key: "notification",
                )
            }
        }
    }

    // MARK: - Tag Scanned Notification

    private func handleTagScannedNotification(_ userInfo: [AnyHashable: Any]) {
        let scanId = userInfo["scan_id"] as? String ?? ""
        let petId = userInfo["pet_id"] as? String ?? ""
        let locationType = userInfo["location_type"] as? String ?? "none"

        let location: LocationData? = locationType == "none"
            ? nil
            : Self.parseLocation(userInfo, isApproximate: locationType == "approximate")

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

        // Audit #69: never construct or post a deep link with an empty id.
        // `senra://alert/` would deep-link to the list page (or worse, a
        // 404 detail screen) and feels like a broken notification. Surface
        // the malformed payload to Sentry instead.
        guard !alertId.isEmpty else {
            Self.captureMalformedPayload(reason: "missing_alert_id", type: "MISSING_PET_ALERT", userInfo: userInfo)
            return
        }

        #if DEBUG
        print("Missing pet alert notification: alertId=\(alertId), petId=\(petId)")
        print("Deep link: senra://alert/\(alertId)")
        #endif

        NotificationCenter.default.post(
            name: .navigateToAlert,
            object: nil,
            userInfo: ["alertId": alertId, "petId": petId]
        )
    }

    /// Telemetry helper: report a known-type payload that arrived missing
    /// fields the route handler requires (audit #69).
    private static func captureMalformedPayload(reason: String, type: String, userInfo: [AnyHashable: Any]) {
        #if DEBUG
        print("Malformed \(type) payload: \(reason)")
        #endif
        if SentrySDK.isEnabled {
            SentrySDK.capture(message: "Malformed FCM payload: \(type) — \(reason)") { scope in
                scope.setLevel(.warning)
                scope.setTag(value: "notification_malformed_payload", key: "operation")
                scope.setContext(
                    value: ["type": type, "reason": reason, "keys": userInfo.keys.compactMap { $0 as? String }],
                    key: "notification",
                )
            }
        }
    }

    // MARK: - Pet Found Notification

    private func handlePetFoundNotification(_ userInfo: [AnyHashable: Any]) {
        let alertId = userInfo["alert_id"] as? String ?? ""
        let petId = userInfo["pet_id"] as? String ?? ""

        // Audit #69: pet_id is required to deep-link to the pet detail page.
        // An empty id would route to the empty-state pet list which is not
        // what a "pet found" notification is communicating.
        guard !petId.isEmpty else {
            Self.captureMalformedPayload(reason: "missing_pet_id", type: "PET_FOUND", userInfo: userInfo)
            return
        }

        #if DEBUG
        print("Pet found notification: alertId=\(alertId), petId=\(petId)")
        #endif

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

        // Audit #69: alert_id is the routing primary-key for the navigation
        // target. An empty id would deep-link to a 404 alert detail.
        guard !alertId.isEmpty else {
            Self.captureMalformedPayload(reason: "missing_alert_id", type: "SIGHTING_REPORTED", userInfo: userInfo)
            return
        }

        let location: LocationData? = Self.parseLocation(userInfo, isApproximate: false)

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

    // MARK: - Alert Confirmation

    private func handleAlertConfirmation(_ userInfo: [AnyHashable: Any]) {
        let alertId = userInfo["alert_id"] as? String ?? ""
        let petId = userInfo["pet_id"] as? String ?? ""

        guard !alertId.isEmpty else {
            Self.captureMalformedPayload(reason: "missing_alert_id", type: "ALERT_CREATED", userInfo: userInfo)
            return
        }

        NotificationCenter.default.post(
            name: .navigateToAlert,
            object: nil,
            userInfo: ["alertId": alertId, "petId": petId]
        )
    }

    // MARK: - Alert Reminder

    private func handleAlertReminder(_ userInfo: [AnyHashable: Any]) {
        let alertId = userInfo["alert_id"] as? String ?? ""

        guard !alertId.isEmpty else {
            Self.captureMalformedPayload(reason: "missing_alert_id", type: "ALERT_REMINDER", userInfo: userInfo)
            return
        }

        NotificationCenter.default.post(
            name: .navigateToAlert,
            object: nil,
            userInfo: ["alertId": alertId]
        )
    }

    // MARK: - Multiple Sightings

    private func handleMultipleSightings(_ userInfo: [AnyHashable: Any]) {
        let alertId = userInfo["alert_id"] as? String ?? ""

        guard !alertId.isEmpty else {
            Self.captureMalformedPayload(reason: "missing_alert_id", type: "MULTIPLE_SIGHTINGS", userInfo: userInfo)
            return
        }

        NotificationCenter.default.post(
            name: .navigateToAlert,
            object: nil,
            userInfo: ["alertId": alertId]
        )
    }

    // MARK: - Clear Pending Notification

    func clearPendingNotification() {
        pendingScanNotification = nil
        showMapPicker = false
    }

    // MARK: - Coordinate Parsing

    /// Parse latitude/longitude strings from a notification payload, validating
    /// that both are well-formed numbers within geographic ranges and not the
    /// `(0, 0)` null-island sentinel. Returns nil for any invalid input — this
    /// guards MapKit (`MKCoordinateRegion`, `CLLocationCoordinate2D`) from
    /// NaN / Inf / out-of-range values that crash on use.
    static func parseLocation(_ userInfo: [AnyHashable: Any], isApproximate: Bool) -> LocationData? {
        guard let latString = userInfo["latitude"] as? String,
              let lonString = userInfo["longitude"] as? String,
              let lat = Double(latString),
              let lon = Double(lonString),
              InputValidators.isValidCoordinate(latitude: lat, longitude: lon)
        else {
            return nil
        }
        return LocationData(latitude: lat, longitude: lon, isApproximate: isApproximate)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToAlert = Notification.Name("navigateToAlert")
    static let navigateToPet = Notification.Name("navigateToPet")
    static let navigateToScan = Notification.Name("navigateToScan")
}
