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
    let currency: String?
    let orderStatus: String
    let createdAt: String
    let updatedAt: String
    let items: [OrderItem]?

    var formattedAmount: String {
        let currencyCode = (currency ?? "EUR").uppercased()
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "€\(totalAmount)"
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

    var trackingURL: URL? {
        guard let tracking = mplTrackingNumber, !tracking.isEmpty else { return nil }
        return URL(string: "https://nyomkovetes.posta.hu/international?itemNumber=\(tracking)")
    }

    let isGift: Bool?
    let mplTrackingNumber: String?
    let mplShipmentStatus: String?
    let deliveryMethod: String?

    enum CodingKeys: String, CodingKey {
        case id, items, currency
        case userId = "user_id"
        case petName = "pet_name"
        case totalAmount = "total_amount"
        case shippingCost = "shipping_cost"
        case shippingAddress = "shipping_address"
        case billingAddress = "billing_address"
        case paymentMethod = "payment_method"
        case paymentStatus = "payment_status"
        case paymentIntentId = "payment_intent_id"
        case isGift = "is_gift"
        case orderStatus = "order_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case mplTrackingNumber = "mpl_tracking_number"
        case mplShipmentStatus = "mpl_shipment_status"
        case deliveryMethod = "delivery_method"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        petName = try container.decodeIfPresent(String.self, forKey: .petName) ?? ""
        totalAmount = try container.decodeIfPresent(Double.self, forKey: .totalAmount) ?? 0
        shippingCost = try container.decodeIfPresent(Double.self, forKey: .shippingCost) ?? 0
        shippingAddress = try container.decodeIfPresent(AddressDetails.self, forKey: .shippingAddress)
        billingAddress = try container.decodeIfPresent(AddressDetails.self, forKey: .billingAddress)
        paymentMethod = try container.decodeIfPresent(String.self, forKey: .paymentMethod) ?? "card"
        paymentStatus = try container.decodeIfPresent(String.self, forKey: .paymentStatus) ?? "pending"
        paymentIntentId = try container.decodeIfPresent(String.self, forKey: .paymentIntentId)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        orderStatus = try container.decodeIfPresent(String.self, forKey: .orderStatus) ?? "pending"
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        isGift = try container.decodeIfPresent(Bool.self, forKey: .isGift)
        items = try container.decodeIfPresent([OrderItem].self, forKey: .items)
        mplTrackingNumber = try container.decodeIfPresent(String.self, forKey: .mplTrackingNumber)
        mplShipmentStatus = try container.decodeIfPresent(String.self, forKey: .mplShipmentStatus)
        deliveryMethod = try container.decodeIfPresent(String.self, forKey: .deliveryMethod)
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
    let petNames: [String]?
    let ownerName: String
    let email: String
    let shippingAddress: AddressDetails
    let billingAddress: AddressDetails?
    let paymentMethod: String?
    let shippingCost: Double?
    var isGift: Bool? = nil
    var giftRecipientName: String? = nil
    var giftMessage: String? = nil
    var quantity: Int? = nil
    var deliveryMethod: String? = nil
    var postapointDetails: PostaPointDetails? = nil
    var locale: String? = nil
}

struct AddressDetails: Codable {
    let street1: String
    let street2: String?
    let city: String
    let province: String?
    let postCode: String
    let country: String
    var phone: String? = nil
}

// MARK: - Tag Checkout (Stripe Checkout redirect)
struct CreateTagCheckoutRequest: Codable {
    let quantity: Int
    let countryCode: String?
    let platform: String
    let deliveryMethod: String?
    let postapointDetails: PostaPointDetails?

    enum CodingKeys: String, CodingKey {
        case quantity
        case countryCode = "country_code"
        case platform
        case deliveryMethod = "delivery_method"
        case postapointDetails = "postapoint_details"
    }
}

struct PostaPointDetails: Codable {
    let id: String
    let name: String
    let address: String?
}

struct DeliveryPoint: Codable, Identifiable {
    let id: String
    let name: String
    let address: String?
    let city: String?
    let postcode: String?
    let openingHours: String?
}

struct TagCheckoutResponse: Codable {
    let checkout: TagCheckoutData
}

struct TagCheckoutData: Codable {
    let id: String
    let url: String
}


