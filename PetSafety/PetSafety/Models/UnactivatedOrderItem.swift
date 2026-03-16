import Foundation

struct UnactivatedOrderItem: Codable, Identifiable {
    var id: String { orderItemId }
    let orderItemId: String
    let petName: String?
    let qrCode: String?
    let tagStatus: String?

    enum CodingKeys: String, CodingKey {
        case orderItemId = "order_item_id"
        case petName = "pet_name"
        case qrCode = "qr_code"
        case tagStatus = "tag_status"
    }
}

struct UnactivatedTagsResponse: Codable {
    let unactivated: [UnactivatedOrderItem]
}
