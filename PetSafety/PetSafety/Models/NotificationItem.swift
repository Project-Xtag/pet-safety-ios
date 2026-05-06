import Foundation

/// Subset of the inbox notification's `data` payload we actually
/// need on the client to deep-link a tap. Backend sends a heterogeneous
/// dict (string ids + numeric distances + locationType strings); we
/// only decode the ids — anything else is ignored by Codable.
struct NotificationDataDict: Codable {
    let alertId: String?
    let petId: String?
    let sightingId: String?
    let scanId: String?
}

struct NotificationItem: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String
    let isRead: Bool
    let createdAt: String
    let data: NotificationDataDict?

    enum CodingKeys: String, CodingKey {
        case id, type, title, body, data
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

struct NotificationsPageResponse: Codable {
    let notifications: [NotificationItem]
    let pagination: PaginationInfo
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

struct UnreadCountResponse: Codable {
    let count: Int
}
