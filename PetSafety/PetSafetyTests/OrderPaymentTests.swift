import Testing
import Foundation
@testable import PetSafety

// Helper to create Order instances from JSON for testing
private func makeOrder(
    id: String = "test",
    userId: String? = nil,
    petName: String = "",
    totalAmount: Double = 0,
    shippingCost: Double = 0,
    paymentMethod: String = "stripe",
    paymentStatus: String = "pending",
    paymentIntentId: String? = nil,
    currency: String? = nil,
    orderStatus: String = "pending",
    createdAt: String = "",
    updatedAt: String = ""
) -> Order {
    var json: [String: Any] = [
        "id": id,
        "pet_name": petName,
        "total_amount": totalAmount,
        "shipping_cost": shippingCost,
        "payment_method": paymentMethod,
        "payment_status": paymentStatus,
        "order_status": orderStatus,
        "created_at": createdAt,
        "updated_at": updatedAt
    ]
    if let userId { json["user_id"] = userId }
    if let paymentIntentId { json["payment_intent_id"] = paymentIntentId }
    if let currency { json["currency"] = currency }
    let data = try! JSONSerialization.data(withJSONObject: json)
    return try! JSONDecoder().decode(Order.self, from: data)
}

@Suite("Order Payment Fixes Tests")
struct OrderPaymentTests {

    // MARK: - Order Model Currency Tests

    @Test("Order formattedAmount uses EUR, not GBP")
    func testOrderFormattedAmountUsesEUR() {
        let order = makeOrder(
            id: "test-1",
            userId: "user-1",
            petName: "Buddy",
            totalAmount: 3.90,
            shippingCost: 3.90,
            paymentStatus: "paid",
            orderStatus: "completed",
            createdAt: "2026-01-01T00:00:00Z",
            updatedAt: "2026-01-01T00:00:00Z"
        )

        let formatted = order.formattedAmount
        #expect(!formatted.contains("GBP"), "formattedAmount should not contain GBP")
        #expect(!formatted.contains("£"), "formattedAmount should not contain £")
        // Should contain EUR symbol (€) or EUR text
        #expect(formatted.contains("€") || formatted.contains("EUR"), "formattedAmount should use EUR currency")
    }

    @Test("Order formattedAmount formats zero correctly")
    func testOrderFormattedAmountZero() {
        let order = makeOrder(
            id: "test-2",
            userId: "user-1",
            petName: "Max"
        )

        let formatted = order.formattedAmount
        #expect(!formatted.contains("GBP"), "Zero amount should not use GBP")
    }

    // MARK: - Order Status Color Tests

    @Test("Order status colors map correctly")
    func testOrderStatusColors() {
        let statuses: [(String, String)] = [
            ("completed", "green"),
            ("pending", "orange"),
            ("failed", "red"),
            ("processing", "blue"),
            ("unknown", "gray"),
        ]

        for (status, expectedColor) in statuses {
            let order = makeOrder(orderStatus: status)
            #expect(order.statusColor == expectedColor, "Status '\(status)' should map to '\(expectedColor)'")
        }
    }

    // MARK: - Notification Name Tests

    @Test("Checkout notification names exist")
    func testNotificationNamesExist() {
        #expect(Notification.Name.checkoutCompleted.rawValue == "checkoutCompleted")
        #expect(Notification.Name.tagOrderCompleted.rawValue == "tagOrderCompleted")
        #expect(Notification.Name.replacementCompleted.rawValue == "replacementCompleted")
    }

    @Test("All three notification names are distinct")
    func testNotificationNamesDistinct() {
        let names: Set<Notification.Name> = [
            .checkoutCompleted,
            .tagOrderCompleted,
            .replacementCompleted,
        ]
        #expect(names.count == 3, "All notification names should be distinct")
    }

    // MARK: - Deep Link Checkout Type Extraction Tests

    @Test("Checkout deep link extracts subscription type")
    func testCheckoutTypeSubscription() {
        let url = URL(string: "senra://checkout/success?session_id=cs_test&type=subscription")!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let type = components?.queryItems?.first(where: { $0.name == "type" })?.value
        #expect(type == "subscription")
    }

    @Test("Checkout deep link extracts qr_tag_order type")
    func testCheckoutTypeTagOrder() {
        let url = URL(string: "senra://checkout/success?session_id=cs_test&type=qr_tag_order")!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let type = components?.queryItems?.first(where: { $0.name == "type" })?.value
        #expect(type == "qr_tag_order")
    }

    @Test("Checkout deep link extracts replacement_shipping type")
    func testCheckoutTypeReplacement() {
        let url = URL(string: "senra://checkout/success?session_id=cs_test&type=replacement_shipping")!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let type = components?.queryItems?.first(where: { $0.name == "type" })?.value
        #expect(type == "replacement_shipping")
    }

    @Test("Checkout deep link without type returns nil")
    func testCheckoutNoType() {
        let url = URL(string: "senra://checkout/success?session_id=cs_test")!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let type = components?.queryItems?.first(where: { $0.name == "type" })?.value
        #expect(type == nil)
    }

    @Test("Checkout deep link extracts success path")
    func testCheckoutSuccessPath() {
        let url = URL(string: "senra://checkout/success?session_id=cs_test&type=subscription")!
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        #expect(path == "success")
    }

    @Test("Checkout deep link extracts cancelled path")
    func testCheckoutCancelledPath() {
        let url = URL(string: "senra://checkout/cancelled")!
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        #expect(path == "cancelled")
    }

    @Test("Checkout deep link host is checkout")
    func testCheckoutHost() {
        let url = URL(string: "senra://checkout/success?type=subscription")!
        #expect(url.host == "checkout")
        #expect(url.scheme == "senra")
    }

    // MARK: - Address Model Tests

    @Test("AddressDetails encodes country field")
    func testAddressDetailsCountry() throws {
        let address = AddressDetails(
            street1: "123 Main St",
            street2: nil,
            city: "Budapest",
            province: nil,
            postCode: "1011",
            country: "HU"
        )

        let data = try JSONEncoder().encode(address)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["country"] as? String == "HU")
        #expect(dict["street1"] as? String == "123 Main St")
        #expect(dict["city"] as? String == "Budapest")
    }
}
