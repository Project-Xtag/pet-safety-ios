import Testing
import Foundation
@testable import PetSafety

// Reusable test addresses matching web E2E helpers
private let huAddress = AddressDetails(
    street1: "Kossuth Lajos utca 10",
    street2: "2. emelet 5. ajto",
    city: "Budapest",
    province: nil,
    postCode: "1055",
    country: "HU"
)

private let deAddress = AddressDetails(
    street1: "Berliner Str. 45",
    street2: "Wohnung 3",
    city: "Berlin",
    province: nil,
    postCode: "10115",
    country: "DE"
)

private let esAddress = AddressDetails(
    street1: "Calle Mayor 1",
    street2: "Piso 2",
    city: "Madrid",
    province: nil,
    postCode: "28013",
    country: "ES"
)

@Suite("Order Flow Tests")
struct OrderFlowTests {

    // MARK: - CreateTagCheckoutRequest Encoding (Scenarios 1–3)

    @Test("Scenario 1: HU, 1 pet, home_delivery checkout request")
    func testHU1PetHomeDeliveryCheckout() throws {
        let request = CreateTagCheckoutRequest(
            quantity: 1,
            countryCode: "HU",
            platform: "ios",
            deliveryMethod: "home_delivery",
            postapointDetails: nil
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["quantity"] as? Int == 1)
        #expect(dict["country_code"] as? String == "HU")
        #expect(dict["platform"] as? String == "ios")
        #expect(dict["deliveryMethod"] as? String == "home_delivery")
        #expect(dict["postapointDetails"] == nil)
    }

    @Test("Scenario 2: HU, 2 pets, PostaPoint checkout request")
    func testHU2PetsPostapointCheckout() throws {
        let postaPoint = PostaPointDetails(
            id: "pp-1",
            name: "Budapest Posta 1",
            address: "Kossuth u. 10"
        )
        let request = CreateTagCheckoutRequest(
            quantity: 2,
            countryCode: "HU",
            platform: "ios",
            deliveryMethod: "postapoint",
            postapointDetails: postaPoint
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["quantity"] as? Int == 2)
        #expect(dict["country_code"] as? String == "HU")
        #expect(dict["deliveryMethod"] as? String == "postapoint")

        let ppDict = dict["postapointDetails"] as? [String: Any]
        #expect(ppDict?["id"] as? String == "pp-1")
        #expect(ppDict?["name"] as? String == "Budapest Posta 1")
        #expect(ppDict?["address"] as? String == "Kossuth u. 10")
    }

    @Test("Scenario 3: DE, 3 pets, no delivery method (EU)")
    func testDE3PetsNoDeliveryMethod() throws {
        let request = CreateTagCheckoutRequest(
            quantity: 3,
            countryCode: "DE",
            platform: "ios",
            deliveryMethod: nil,
            postapointDetails: nil
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["quantity"] as? Int == 3)
        #expect(dict["country_code"] as? String == "DE")
        #expect(dict["platform"] as? String == "ios")
        #expect(dict["deliveryMethod"] == nil)
    }

    // MARK: - CreateOrderRequest Round-Trip (Scenario 4)

    @Test("Scenario 4: CreateOrderRequest round-trip encode/decode")
    func testCreateOrderRequestRoundTrip() throws {
        let request = CreateOrderRequest(
            petNames: ["Buddy", "Luna"],
            ownerName: "Teszt Elek",
            email: "test@example.com",
            shippingAddress: huAddress,
            billingAddress: nil,
            paymentMethod: "card",
            shippingCost: 2490.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoded = try JSONDecoder().decode(CreateOrderRequest.self, from: data)

        #expect(decoded.petNames == ["Buddy", "Luna"])
        #expect(decoded.ownerName == "Teszt Elek")
        #expect(decoded.email == "test@example.com")
        #expect(decoded.shippingAddress.country == "HU")
        #expect(decoded.shippingAddress.street1 == "Kossuth Lajos utca 10")
        #expect(decoded.shippingAddress.city == "Budapest")
        #expect(decoded.shippingAddress.postCode == "1055")
        #expect(decoded.paymentMethod == "card")
        #expect(decoded.shippingCost == 2490.0)
        #expect(decoded.billingAddress == nil)
    }

    // MARK: - TagCheckoutResponse Decoding (Scenarios 5–6)

    @Test("Scenario 5: TagCheckoutResponse with Stripe URL")
    func testCheckoutResponseWithURL() throws {
        let json = """
        {
            "checkout": {
                "id": "cs_test_abc123",
                "url": "https://checkout.stripe.com/c/pay/cs_test_abc123"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TagCheckoutResponse.self, from: json)
        #expect(response.checkout.id == "cs_test_abc123")
        #expect(response.checkout.url.hasPrefix("https://checkout.stripe.com"))
    }

    @Test("Scenario 6: TagCheckoutResponse missing URL throws")
    func testCheckoutResponseMissingURL() {
        let json = """
        {
            "checkout": {}
        }
        """.data(using: .utf8)!

        // Both id and url are required (non-optional), so decoding should fail
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(TagCheckoutResponse.self, from: json)
        }
    }

    // MARK: - CreateOrderRequest Address Encoding

    @Test("CreateOrderRequest encodes all address fields")
    func testCreateOrderRequestAllAddressFields() throws {
        let request = CreateOrderRequest(
            petNames: ["Max"],
            ownerName: "Max Mustermann",
            email: "max@example.com",
            shippingAddress: deAddress,
            billingAddress: esAddress,
            paymentMethod: nil,
            shippingCost: 9.95
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let shipping = dict["shippingAddress"] as! [String: Any]
        #expect(shipping["street1"] as? String == "Berliner Str. 45")
        #expect(shipping["street2"] as? String == "Wohnung 3")
        #expect(shipping["city"] as? String == "Berlin")
        #expect(shipping["postCode"] as? String == "10115")
        #expect(shipping["country"] as? String == "DE")

        let billing = dict["billingAddress"] as! [String: Any]
        #expect(billing["country"] as? String == "ES")
    }

    @Test("CreateOrderRequest omits null billingAddress")
    func testCreateOrderRequestNullBilling() throws {
        let request = CreateOrderRequest(
            petNames: ["Spot"],
            ownerName: "Jan Novak",
            email: "jan@example.com",
            shippingAddress: huAddress,
            billingAddress: nil,
            paymentMethod: nil,
            shippingCost: nil
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["billingAddress"] == nil)
        #expect(dict["paymentMethod"] == nil)
        #expect(dict["shippingCost"] == nil)
    }

    // MARK: - PostaPointDetails Encoding

    @Test("PostaPointDetails encodes correctly")
    func testPostapointDetailsEncoding() throws {
        let details = PostaPointDetails(
            id: "pp-42",
            name: "Budapest Posta 42",
            address: "Andrassy ut 42"
        )

        let data = try JSONEncoder().encode(details)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["id"] as? String == "pp-42")
        #expect(dict["name"] as? String == "Budapest Posta 42")
        #expect(dict["address"] as? String == "Andrassy ut 42")
    }

    @Test("PostaPointDetails with nil address")
    func testPostapointDetailsNilAddress() throws {
        let details = PostaPointDetails(
            id: "pp-1",
            name: "Test Point",
            address: nil
        )

        let data = try JSONEncoder().encode(details)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["id"] as? String == "pp-1")
        #expect(dict["address"] == nil)
    }

    // MARK: - Deep Link Parsing

    @Test("Deep link: success tag order parsed correctly")
    func testDeepLinkSuccessTagOrder() {
        let url = URL(string: "senra://checkout/success?session_id=cs_test_123&type=qr_tag_order")!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        #expect(url.scheme == "senra")
        #expect(url.host == "checkout")
        #expect(url.path.contains("success"))

        let type = components.queryItems?.first(where: { $0.name == "type" })?.value
        #expect(type == "qr_tag_order")

        let sessionId = components.queryItems?.first(where: { $0.name == "session_id" })?.value
        #expect(sessionId == "cs_test_123")
    }

    @Test("Deep link: cancelled checkout parsed correctly")
    func testDeepLinkCancelledCheckout() {
        let url = URL(string: "senra://checkout/cancelled")!

        #expect(url.scheme == "senra")
        #expect(url.host == "checkout")

        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        #expect(path == "cancelled")
    }

    // MARK: - Order Model Status Colors & Formatting

    @Test("Order statusColor for all statuses")
    func testOrderStatusColors() {
        let cases: [(String, String)] = [
            ("completed", "green"),
            ("pending", "orange"),
            ("failed", "red"),
            ("processing", "blue"),
            ("unknown_status", "gray"),
        ]

        for (status, expected) in cases {
            let order = makeTestOrder(orderStatus: status)
            #expect(order.statusColor == expected, "Status '\(status)' → '\(expected)'")
        }
    }

    @Test("Order defaults: missing fields use sensible defaults")
    func testOrderDefaults() throws {
        let minimalJson = """
        { "id": "ord-1" }
        """.data(using: .utf8)!

        let order = try JSONDecoder().decode(Order.self, from: minimalJson)
        #expect(order.id == "ord-1")
        #expect(order.petName == "")
        #expect(order.totalAmount == 0)
        #expect(order.shippingCost == 0)
        #expect(order.paymentMethod == "card")
        #expect(order.paymentStatus == "pending")
        #expect(order.orderStatus == "pending")
    }
}

// MARK: - Test Helper

private func makeTestOrder(
    id: String = "test",
    orderStatus: String = "pending"
) -> Order {
    let json: [String: Any] = [
        "id": id,
        "order_status": orderStatus,
    ]
    let data = try! JSONSerialization.data(withJSONObject: json)
    return try! JSONDecoder().decode(Order.self, from: data)
}
