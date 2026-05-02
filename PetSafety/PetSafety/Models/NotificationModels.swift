import Foundation

/**
 * Notification-related data models
 *
 * Shared types used by NotificationHandler and MapAppPickerView
 */

/// Location data from push notification.
/// Always precise after the 2026-05-02 missing-pet flow overhaul —
/// `isApproximate` is retained as a defaulted field for binary
/// compatibility with `MapAppPickerView` callers but new code paths
/// never set it to `true`.
struct LocationData: Equatable {
    let latitude: Double
    let longitude: Double
    let isApproximate: Bool

    init(latitude: Double, longitude: Double, isApproximate: Bool = false) {
        self.latitude = latitude
        self.longitude = longitude
        self.isApproximate = isApproximate
    }
}

/// Scan notification data for presenting map picker
struct ScanNotificationData: Identifiable {
    let id = UUID()
    let scanId: String
    let petId: String
    let petName: String?
    let location: LocationData?
}
