import Foundation

/**
 * Notification-related data models
 *
 * Shared types used by NotificationHandler and MapAppPickerView
 */

/// Location data from push notification
struct LocationData: Equatable {
    let latitude: Double
    let longitude: Double
    let isApproximate: Bool
}

/// Scan notification data for presenting map picker
struct ScanNotificationData: Identifiable {
    let id = UUID()
    let scanId: String
    let petId: String
    let petName: String?
    let location: LocationData?
}
