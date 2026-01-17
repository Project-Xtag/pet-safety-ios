import Foundation

struct NotificationPreferences: Codable {
    var notifyByEmail: Bool
    var notifyBySms: Bool
    var notifyByPush: Bool

    enum CodingKeys: String, CodingKey {
        case notifyByEmail
        case notifyBySms
        case notifyByPush
    }

    // Default values
    static let `default` = NotificationPreferences(
        notifyByEmail: true,
        notifyBySms: true,
        notifyByPush: true
    )

    // Validation: At least one method must be enabled
    var isValid: Bool {
        return notifyByEmail || notifyBySms || notifyByPush
    }

    var enabledCount: Int {
        var count = 0
        if notifyByEmail { count += 1 }
        if notifyBySms { count += 1 }
        if notifyByPush { count += 1 }
        return count
    }
}

// API Response wrapper
struct NotificationPreferencesResponse: Codable {
    let preferences: NotificationPreferences
    let message: String?
}
