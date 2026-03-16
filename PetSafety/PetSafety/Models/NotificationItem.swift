import Foundation

struct NotificationItem: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String
    let isRead: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, type, title, body
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
