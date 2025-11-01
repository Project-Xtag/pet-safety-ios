import Foundation

struct Order: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let guestEmail: String?
    let status: String
    let totalAmount: Double
    let currency: String
    let paymentIntentId: String?
    let createdAt: String
    let updatedAt: String
    let items: [OrderItem]?
    let user: User?

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "\(currency) \(totalAmount)"
    }

    var statusColor: String {
        switch status {
        case "completed": return "green"
        case "pending": return "orange"
        case "failed": return "red"
        case "processing": return "blue"
        default: return "gray"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, status, currency, items, user
        case userId = "user_id"
        case guestEmail = "guest_email"
        case totalAmount = "total_amount"
        case paymentIntentId = "payment_intent_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct OrderItem: Codable, Identifiable {
    let id: Int
    let orderId: Int
    let petName: String
    let petSpecies: String
    let petBreed: String?
    let qrTagId: Int?
    let price: Double
    let createdAt: String
    let qrTag: QRTag?

    enum CodingKeys: String, CodingKey {
        case id, price
        case orderId = "order_id"
        case petName = "pet_name"
        case petSpecies = "pet_species"
        case petBreed = "pet_breed"
        case qrTagId = "qr_tag_id"
        case createdAt = "created_at"
        case qrTag = "qr_tag"
    }
}

struct CreateOrderRequest: Codable {
    let guestEmail: String?
    let items: [OrderItemRequest]
}

struct OrderItemRequest: Codable {
    let petName: String
    let petSpecies: String
    let petBreed: String?
    let price: Double

    enum CodingKeys: String, CodingKey {
        case price
        case petName = "pet_name"
        case petSpecies = "pet_species"
        case petBreed = "pet_breed"
    }
}

struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let orderId: Int

    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case orderId = "order_id"
    }
}
