import Foundation

struct Order: Codable, Identifiable {
    let id: String
    let userId: String?
    let petName: String
    let totalAmount: Double
    let shippingCost: Double
    let shippingAddress: AddressDetails?
    let billingAddress: AddressDetails?
    let paymentMethod: String
    let paymentStatus: String
    let paymentIntentId: String?
    let orderStatus: String
    let createdAt: String
    let updatedAt: String
    let items: [OrderItem]?

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "GBP \(totalAmount)"
    }

    var statusColor: String {
        switch orderStatus {
        case "completed": return "green"
        case "pending": return "orange"
        case "failed": return "red"
        case "processing": return "blue"
        default: return "gray"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, items
        case userId = "user_id"
        case petName = "pet_name"
        case totalAmount = "total_amount"
        case shippingCost = "shipping_cost"
        case shippingAddress = "shipping_address"
        case billingAddress = "billing_address"
        case paymentMethod = "payment_method"
        case paymentStatus = "payment_status"
        case paymentIntentId = "payment_intent_id"
        case orderStatus = "order_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct OrderItem: Codable, Identifiable {
    let id: String
    let orderId: String
    let itemType: String
    let quantity: Int
    let price: Double
    let petId: String?
    let qrTagId: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, price
        case orderId = "order_id"
        case itemType = "item_type"
        case quantity
        case petId = "pet_id"
        case qrTagId = "qr_tag_id"
        case createdAt = "created_at"
    }
}

struct CreateOrderRequest: Codable {
    let petNames: [String]
    let ownerName: String
    let email: String
    let shippingAddress: AddressDetails
    let billingAddress: AddressDetails?
    let paymentMethod: String?
    let shippingCost: Double?
}

struct AddressDetails: Codable {
    let street1: String
    let street2: String?
    let city: String
    let province: String?
    let postCode: String
    let country: String
}
