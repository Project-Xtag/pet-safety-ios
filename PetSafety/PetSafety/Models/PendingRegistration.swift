import Foundation

struct PendingRegistration: Codable, Identifiable {
    var id: String { orderItemId }
    let orderItemId: String
    let orderId: String
    let petName: String
    let createdAt: String
    let orderStatus: String
    let mplTrackingNumber: String?
    let deliveryMethod: String?

    var trackingURL: URL? {
        guard let tracking = mplTrackingNumber, !tracking.isEmpty else { return nil }
        return URL(string: "https://nyomkovetes.posta.hu/international?itemNumber=\(tracking)")
    }

    enum CodingKeys: String, CodingKey {
        case orderItemId = "order_item_id"
        case orderId = "order_id"
        case petName = "pet_name"
        case createdAt = "created_at"
        case orderStatus = "order_status"
        case mplTrackingNumber = "mpl_tracking_number"
        case deliveryMethod = "delivery_method"
    }
}

struct PendingRegistrationsResponse: Codable {
    let pending: [PendingRegistration]
}
