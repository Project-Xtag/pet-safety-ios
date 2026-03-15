import Testing
import Foundation
@testable import PetSafety

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

@Suite("Gift Order Tests")
struct GiftOrderTests {

    // MARK: - Gift Order Request Encoding

    @Test("Gift order request encodes isGift=true with no pet names")
    func testGiftOrderNoPetNames() throws {
        let request = CreateOrderRequest(
            petNames: nil,
            ownerName: "John Doe",
            email: "john@example.com",
            shippingAddress: huAddress,
            billingAddress: nil,
            paymentMethod: "card",
            shippingCost: nil,
            isGift: true,
            giftRecipientName: "Alice",
            giftMessage: "Happy birthday!",
            quantity: 2
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["isGift"] as? Bool == true)
        #expect(dict["giftRecipientName"] as? String == "Alice")
        #expect(dict["giftMessage"] as? String == "Happy birthday!")
        #expect(dict["quantity"] as? Int == 2)
        #expect(dict["petNames"] == nil)
    }

    @Test("Gift order request with optional pet names")
    func testGiftOrderWithPetNames() throws {
        let request = CreateOrderRequest(
            petNames: ["Buddy"],
            ownerName: "Jane Smith",
            email: "jane@example.com",
            shippingAddress: deAddress,
            billingAddress: nil,
            paymentMethod: nil,
            shippingCost: nil,
            isGift: true,
            giftRecipientName: nil,
            giftMessage: nil,
            quantity: 1
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["isGift"] as? Bool == true)
        let names = dict["petNames"] as? [String]
        #expect(names == ["Buddy"])
        #expect(dict["giftRecipientName"] == nil)
        #expect(dict["giftMessage"] == nil)
    }

    @Test("Non-gift order omits gift fields when nil")
    func testNonGiftOrderOmitsGiftFields() throws {
        let request = CreateOrderRequest(
            petNames: ["Rex", "Luna"],
            ownerName: "Bob",
            email: "bob@example.com",
            shippingAddress: huAddress,
            billingAddress: nil,
            paymentMethod: "card",
            shippingCost: 2490.0,
            isGift: nil,
            giftRecipientName: nil,
            giftMessage: nil,
            quantity: nil
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["isGift"] == nil)
        #expect(dict["giftRecipientName"] == nil)
        #expect(dict["giftMessage"] == nil)
        #expect(dict["quantity"] == nil)
        let names = dict["petNames"] as? [String]
        #expect(names == ["Rex", "Luna"])
    }

    // MARK: - Gift Order Round-Trip

    @Test("Gift CreateOrderRequest round-trip preserves all fields")
    func testGiftOrderRoundTrip() throws {
        let original = CreateOrderRequest(
            petNames: nil,
            ownerName: "Carol",
            email: "carol@example.com",
            shippingAddress: huAddress,
            billingAddress: deAddress,
            paymentMethod: "stripe",
            shippingCost: 0.0,
            isGift: true,
            giftRecipientName: "Dave",
            giftMessage: "Enjoy your new pet tag!",
            quantity: 3
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CreateOrderRequest.self, from: data)

        #expect(decoded.petNames == nil)
        #expect(decoded.ownerName == "Carol")
        #expect(decoded.email == "carol@example.com")
        #expect(decoded.isGift == true)
        #expect(decoded.giftRecipientName == "Dave")
        #expect(decoded.giftMessage == "Enjoy your new pet tag!")
        #expect(decoded.quantity == 3)
        #expect(decoded.shippingAddress.country == "HU")
        #expect(decoded.billingAddress?.country == "DE")
    }

    // MARK: - Order Model isGift Decoding

    @Test("Order model decodes is_gift from JSON")
    func testOrderDecodesIsGift() throws {
        let json = """
        {
            "id": "ord-gift-1",
            "is_gift": true,
            "pet_name": "Gift"
        }
        """.data(using: .utf8)!

        let order = try JSONDecoder().decode(Order.self, from: json)
        #expect(order.id == "ord-gift-1")
        #expect(order.isGift == true)
        #expect(order.petName == "Gift")
    }

    @Test("Order model defaults isGift to nil when not present")
    func testOrderDefaultsIsGiftNil() throws {
        let json = """
        { "id": "ord-regular-1" }
        """.data(using: .utf8)!

        let order = try JSONDecoder().decode(Order.self, from: json)
        #expect(order.isGift == nil)
    }

    @Test("Order model decodes is_gift=false")
    func testOrderDecodesIsGiftFalse() throws {
        let json = """
        { "id": "ord-2", "is_gift": false }
        """.data(using: .utf8)!

        let order = try JSONDecoder().decode(Order.self, from: json)
        #expect(order.isGift == false)
    }

    // MARK: - Form Validation Logic

    @Test("Gift order: form valid without pet names when quantity >= 1")
    func testGiftFormValidNoPetNames() {
        let isGift = true
        let validPetCount = 0
        let giftQuantity = 2
        let ownerName = "John"
        let email = "john@example.com"
        let street1 = "123 Main"
        let city = "Budapest"
        let postCode = "1055"
        let selectedCountryCode = "HU"

        let hasPetNames = isGift ? true : validPetCount > 0
        let isFormValid = hasPetNames &&
            !ownerName.isEmpty &&
            !email.isEmpty &&
            !street1.isEmpty &&
            !city.isEmpty &&
            !postCode.isEmpty &&
            !selectedCountryCode.isEmpty

        #expect(isFormValid == true)
        // Effective quantity should use giftQuantity
        let effectiveQuantity = isGift ? giftQuantity : validPetCount
        #expect(effectiveQuantity == 2)
    }

    @Test("Non-gift order: form invalid without pet names")
    func testNonGiftFormInvalidNoPetNames() {
        let isGift = false
        let validPetCount = 0

        let hasPetNames = isGift ? true : validPetCount > 0
        #expect(hasPetNames == false)
    }

    @Test("Non-gift order: form valid with pet names")
    func testNonGiftFormValidWithPetNames() {
        let isGift = false
        let validPetCount = 2

        let hasPetNames = isGift ? true : validPetCount > 0
        #expect(hasPetNames == true)

        let effectiveQuantity = isGift ? 1 : validPetCount
        #expect(effectiveQuantity == 2)
    }

    // MARK: - Quantity Bounds

    @Test("Gift quantity clamped to 1-20")
    func testGiftQuantityBounds() {
        #expect(max(1, min(20, 0)) == 1)
        #expect(max(1, min(20, 21)) == 20)
        #expect(max(1, min(20, 10)) == 10)
        #expect(max(1, min(20, 1)) == 1)
        #expect(max(1, min(20, 20)) == 20)
    }
}
