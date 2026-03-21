import Testing
import Foundation
@testable import PetSafety

@Suite("OrdersViewModel Tests")
@MainActor
struct OrdersViewModelTests {

    // MARK: - Initial State

    @Test("Initial state — orders empty, isLoading false, no error")
    func testInitialState() {
        let viewModel = OrdersViewModel()

        #expect(viewModel.orders.isEmpty, "orders should start empty")
        #expect(viewModel.isLoading == false, "isLoading should be false initially")
        #expect(viewModel.errorMessage == nil, "errorMessage should be nil initially")
    }

    // MARK: - CreateOrderRequest Encoding

    @Test("CreateOrderRequest encodes all fields correctly")
    func testCreateOrderRequestEncoding() throws {
        let address = AddressDetails(
            street1: "Kossuth u. 1",
            street2: "2. emelet",
            city: "Budapest",
            province: nil,
            postCode: "1055",
            country: "HU"
        )
        let request = CreateOrderRequest(
            petNames: ["Buddy", "Max"],
            ownerName: "John Doe",
            email: "john@test.com",
            shippingAddress: address,
            billingAddress: nil,
            paymentMethod: "card",
            shippingCost: 2490.0
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["ownerName"] as? String == "John Doe")
        #expect(dict["email"] as? String == "john@test.com")
        #expect((dict["petNames"] as? [String])?.count == 2)
        #expect(dict["shippingCost"] as? Double == 2490.0)

        let shipping = dict["shippingAddress"] as? [String: Any]
        #expect(shipping?["street1"] as? String == "Kossuth u. 1")
        #expect(shipping?["city"] as? String == "Budapest")
        #expect(shipping?["postCode"] as? String == "1055")
        #expect(shipping?["country"] as? String == "HU")
    }

    @Test("CreateOrderRequest omits nil billing address")
    func testCreateOrderRequestOmitsNilBilling() throws {
        let address = AddressDetails(
            street1: "Test St",
            street2: nil,
            city: "London",
            province: nil,
            postCode: "SW1A",
            country: "UK"
        )
        let request = CreateOrderRequest(
            petNames: ["Rex"],
            ownerName: "Jane",
            email: "jane@test.com",
            shippingAddress: address,
            billingAddress: nil,
            paymentMethod: nil,
            shippingCost: nil
        )

        let data = try JSONEncoder().encode(request)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("shippingAddress"))
        #expect(!jsonString.contains("billingAddress"), "billingAddress should be omitted when nil")
    }

    // MARK: - CreateTagCheckoutRequest Encoding (with delivery method)

    @Test("CreateTagCheckoutRequest encodes deliveryMethod and postapointDetails")
    func testCreateTagCheckoutRequestWithDelivery() throws {
        let postapoint = PostaPointDetails(
            id: "pp-123",
            name: "PostaPont Budapest 1",
            address: "Váci u. 10"
        )
        let request = CreateTagCheckoutRequest(
            quantity: 1,
            countryCode: "HU",
            platform: "ios",
            deliveryMethod: "postapoint",
            postapointDetails: postapoint
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["quantity"] as? Int == 1)
        #expect(dict["country_code"] as? String == "HU")
        #expect(dict["delivery_method"] as? String == "postapoint")

        let ppDetails = dict["postapoint_details"] as? [String: Any]
        #expect(ppDetails?["id"] as? String == "pp-123")
        #expect(ppDetails?["name"] as? String == "PostaPont Budapest 1")
    }

    @Test("CreateTagCheckoutRequest encodes home_delivery without postapointDetails")
    func testCreateTagCheckoutRequestHomeDelivery() throws {
        let request = CreateTagCheckoutRequest(
            quantity: 2,
            countryCode: "HU",
            platform: "ios",
            deliveryMethod: "home_delivery",
            postapointDetails: nil
        )

        let data = try JSONEncoder().encode(request)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("home_delivery"))
        #expect(!jsonString.contains("postapointDetails"), "postapointDetails should be omitted when nil")
    }

    // MARK: - Order Decoding (via custom decoder)

    @Test("Order decodes with all fields from API JSON")
    func testOrderDecoding() throws {
        let json = """
        {
            "id": "order-100",
            "user_id": "user-100",
            "pet_name": "Luna",
            "total_amount": 24.99,
            "shipping_cost": 9.95,
            "shipping_address": {
                "street1": "Baker St 221B",
                "city": "London",
                "postCode": "NW1 6XE",
                "country": "UK"
            },
            "payment_method": "card",
            "payment_status": "paid",
            "order_status": "shipped",
            "created_at": "2026-01-15T08:00:00Z",
            "updated_at": "2026-01-16T10:00:00Z"
        }
        """.data(using: .utf8)!

        let order = try JSONDecoder().decode(Order.self, from: json)

        #expect(order.id == "order-100")
        #expect(order.petName == "Luna")
        #expect(order.totalAmount == 24.99)
        #expect(order.shippingCost == 9.95)
        #expect(order.orderStatus == "shipped")
        #expect(order.shippingAddress?.street1 == "Baker St 221B")
        #expect(order.shippingAddress?.country == "UK")
    }

    @Test("Order decodes with minimal fields using defaults")
    func testOrderDecodingMinimal() throws {
        let json = """
        {
            "id": "order-min"
        }
        """.data(using: .utf8)!

        let order = try JSONDecoder().decode(Order.self, from: json)

        #expect(order.id == "order-min")
        #expect(order.petName == "", "petName should default to empty string")
        #expect(order.totalAmount == 0, "totalAmount should default to 0")
        #expect(order.paymentMethod == "card", "paymentMethod should default to card")
        #expect(order.orderStatus == "pending", "orderStatus should default to pending")
    }

    @Test("Order statusColor returns correct values")
    func testOrderStatusColor() throws {
        func decodeOrder(status: String) throws -> Order {
            let json = """
            { "id": "test", "order_status": "\(status)" }
            """.data(using: .utf8)!
            return try JSONDecoder().decode(Order.self, from: json)
        }

        #expect(try decodeOrder(status: "completed").statusColor == "green")
        #expect(try decodeOrder(status: "pending").statusColor == "orange")
        #expect(try decodeOrder(status: "failed").statusColor == "red")
        #expect(try decodeOrder(status: "processing").statusColor == "blue")
        #expect(try decodeOrder(status: "unknown").statusColor == "gray")
    }

    // MARK: - DeliveryPoint Decoding

    @Test("DeliveryPoint decodes from API response")
    func testDeliveryPointDecoding() throws {
        let json = """
        {
            "id": "pp-456",
            "name": "PostaPont Váci út",
            "address": "Váci út 10",
            "city": "Budapest",
            "postcode": "1055"
        }
        """.data(using: .utf8)!

        let point = try JSONDecoder().decode(DeliveryPoint.self, from: json)

        #expect(point.id == "pp-456")
        #expect(point.name == "PostaPont Váci út")
        #expect(point.address == "Váci út 10")
        #expect(point.city == "Budapest")
        #expect(point.postcode == "1055")
    }

    @Test("DeliveryPoint decodes with optional fields nil")
    func testDeliveryPointMinimal() throws {
        let json = """
        { "id": "pp-1", "name": "Test Point" }
        """.data(using: .utf8)!

        let point = try JSONDecoder().decode(DeliveryPoint.self, from: json)

        #expect(point.id == "pp-1")
        #expect(point.name == "Test Point")
        #expect(point.address == nil)
        #expect(point.city == nil)
        #expect(point.openingHours == nil)
    }

    // MARK: - PostaPointDetails Encoding

    @Test("PostaPointDetails roundtrip encoding/decoding")
    func testPostapointDetailsRoundtrip() throws {
        let original = PostaPointDetails(
            id: "pp-789",
            name: "Posta Debrecen",
            address: "Piac u. 20"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PostaPointDetails.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.address == original.address)
    }

    // MARK: - CreateTagOrderResponse Decoding

    @Test("CreateTagOrderResponse decodes with userCreated flag")
    func testCreateTagOrderResponseDecoding() throws {
        let json = """
        {
            "order": {
                "id": "order-001",
                "pet_name": "Buddy",
                "total_amount": 19.99,
                "shipping_cost": 4.99,
                "payment_status": "pending",
                "order_status": "processing",
                "created_at": "2026-02-01T10:00:00Z",
                "updated_at": "2026-02-01T10:00:00Z"
            },
            "userCreated": true,
            "userId": "user-001",
            "message": "Order created successfully"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CreateTagOrderResponse.self, from: json)

        #expect(response.order.id == "order-001")
        #expect(response.userCreated == true)
        #expect(response.userId == "user-001")
        #expect(response.message == "Order created successfully")
    }
}
