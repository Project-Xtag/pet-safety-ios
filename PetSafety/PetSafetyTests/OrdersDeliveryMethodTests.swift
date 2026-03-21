import Testing
import Foundation
@testable import PetSafety

// MARK: - Helpers

private func decodeJSON<T: Decodable>(_ json: [String: Any]) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: json)
    return try JSONDecoder().decode(T.self, from: data)
}

private func encodeToDict<T: Encodable>(_ value: T) throws -> [String: Any] {
    let data = try JSONEncoder().encode(value)
    return try JSONSerialization.jsonObject(with: data) as! [String: Any]
}

// MARK: - PostaPointDetails Tests

@Suite("PostaPointDetails Model Tests")
struct PostaPointDetailsTests {

    @Test("PostaPointDetails encodes all fields")
    func testEncodeAllFields() throws {
        let details = PostaPointDetails(id: "pp-1", name: "Budapest Posta 1", address: "Kossuth u. 10")
        let dict = try encodeToDict(details)

        #expect(dict["id"] as? String == "pp-1")
        #expect(dict["name"] as? String == "Budapest Posta 1")
        #expect(dict["address"] as? String == "Kossuth u. 10")
    }

    @Test("PostaPointDetails encodes with nil address")
    func testEncodeNilAddress() throws {
        let details = PostaPointDetails(id: "pp-2", name: "Test Point", address: nil)
        let dict = try encodeToDict(details)

        #expect(dict["id"] as? String == "pp-2")
        #expect(dict["name"] as? String == "Test Point")
    }

    @Test("PostaPointDetails decodes from JSON")
    func testDecode() throws {
        let json: [String: Any] = ["id": "pp-3", "name": "Decoded Point", "address": "Test St 5"]
        let details: PostaPointDetails = try decodeJSON(json)

        #expect(details.id == "pp-3")
        #expect(details.name == "Decoded Point")
        #expect(details.address == "Test St 5")
    }
}

// MARK: - DeliveryPoint Tests

@Suite("DeliveryPoint Model Tests")
struct DeliveryPointTests {

    @Test("DeliveryPoint decodes all fields")
    func testDecodeAllFields() throws {
        let json: [String: Any] = [
            "id": "dp-1",
            "name": "Budapest Posta 72",
            "address": "Petőfi S. u. 17-19",
            "city": "Budapest",
            "postcode": "1052",
            "openingHours": "H-P: 8:00-18:00"
        ]
        let point: DeliveryPoint = try decodeJSON(json)

        #expect(point.id == "dp-1")
        #expect(point.name == "Budapest Posta 72")
        #expect(point.address == "Petőfi S. u. 17-19")
        #expect(point.city == "Budapest")
        #expect(point.postcode == "1052")
        #expect(point.openingHours == "H-P: 8:00-18:00")
    }

    @Test("DeliveryPoint decodes with missing optional fields")
    func testDecodeMinimalFields() throws {
        let json: [String: Any] = [
            "id": "dp-2",
            "name": "Minimal Point"
        ]
        let point: DeliveryPoint = try decodeJSON(json)

        #expect(point.id == "dp-2")
        #expect(point.name == "Minimal Point")
        #expect(point.address == nil)
        #expect(point.city == nil)
        #expect(point.postcode == nil)
        #expect(point.openingHours == nil)
    }

    @Test("DeliveryPoint conforms to Identifiable")
    func testIdentifiable() throws {
        let json: [String: Any] = ["id": "dp-unique", "name": "Test"]
        let point: DeliveryPoint = try decodeJSON(json)

        #expect(point.id == "dp-unique")
    }
}

// MARK: - CreateTagCheckoutRequest Tests

@Suite("CreateTagCheckoutRequest Delivery Method Tests")
struct CreateTagCheckoutRequestTests {

    @Test("Request encodes without delivery method")
    func testEncodeWithoutDeliveryMethod() throws {
        let request = CreateTagCheckoutRequest(
            quantity: 2,
            countryCode: "HU",
            platform: "ios",
            deliveryMethod: nil,
            postapointDetails: nil
        )
        let dict = try encodeToDict(request)

        #expect(dict["quantity"] as? Int == 2)
        #expect(dict["country_code"] as? String == "HU")
        #expect(dict["platform"] as? String == "ios")
    }

    @Test("Request encodes with home_delivery method")
    func testEncodeHomeDelivery() throws {
        let request = CreateTagCheckoutRequest(
            quantity: 1,
            countryCode: "HU",
            platform: "ios",
            deliveryMethod: "home_delivery",
            postapointDetails: nil
        )
        let dict = try encodeToDict(request)

        #expect(dict["delivery_method"] as? String == "home_delivery")
    }

    @Test("Request encodes with postapoint method and details")
    func testEncodePostapointDelivery() throws {
        let request = CreateTagCheckoutRequest(
            quantity: 1,
            countryCode: "HU",
            platform: "ios",
            deliveryMethod: "postapoint",
            postapointDetails: PostaPointDetails(id: "pp-1", name: "Posta 1", address: "Test St")
        )
        let dict = try encodeToDict(request)

        #expect(dict["delivery_method"] as? String == "postapoint")

        let details = dict["postapoint_details"] as? [String: Any]
        #expect(details?["id"] as? String == "pp-1")
        #expect(details?["name"] as? String == "Posta 1")
        #expect(details?["address"] as? String == "Test St")
    }

    @Test("Request encodes country_code with snake_case key")
    func testCountryCodeSnakeCase() throws {
        let request = CreateTagCheckoutRequest(
            quantity: 3,
            countryCode: "SK",
            platform: "ios",
            deliveryMethod: nil,
            postapointDetails: nil
        )
        let dict = try encodeToDict(request)

        #expect(dict["country_code"] as? String == "SK")
        #expect(dict["countryCode"] == nil) // should use snake_case
    }
}

// MARK: - CreateReplacementOrderRequest Tests

@Suite("CreateReplacementOrderRequest Delivery Method Tests")
struct CreateReplacementOrderRequestTests {

    @Test("Request encodes with delivery method")
    func testEncodeWithDeliveryMethod() throws {
        let request = CreateReplacementOrderRequest(
            shippingAddress: ShippingAddress(
                street1: "Test St 1",
                street2: nil,
                city: "Budapest",
                province: nil,
                postCode: "1011",
                country: "HU",
                phone: nil
            ),
            deliveryMethod: "postapoint",
            postapointDetails: PostaPointDetails(id: "pp-5", name: "Point 5", address: "Address 5")
        )
        let dict = try encodeToDict(request)

        #expect(dict["deliveryMethod"] as? String == "postapoint")
        #expect(dict["platform"] as? String == "ios")

        let details = dict["postapointDetails"] as? [String: Any]
        #expect(details?["id"] as? String == "pp-5")
    }

    @Test("Request encodes without delivery method (backward compat)")
    func testEncodeWithoutDeliveryMethod() throws {
        let request = CreateReplacementOrderRequest(
            shippingAddress: ShippingAddress(
                street1: "Main St",
                street2: nil,
                city: "Vienna",
                province: nil,
                postCode: "1010",
                country: "AT",
                phone: nil
            ),
            deliveryMethod: nil,
            postapointDetails: nil
        )
        let dict = try encodeToDict(request)

        #expect(dict["platform"] as? String == "ios")
        // deliveryMethod should be null/absent for non-HU
    }
}

// MARK: - TagCheckoutResponse Tests

@Suite("TagCheckoutResponse Tests")
struct TagCheckoutResponseTests {

    @Test("TagCheckoutResponse decodes checkout data")
    func testDecodeCheckout() throws {
        let json: [String: Any] = [
            "checkout": [
                "id": "cs_test_123",
                "url": "https://checkout.stripe.com/c/pay/cs_test_123"
            ]
        ]
        let response: TagCheckoutResponse = try decodeJSON(json)

        #expect(response.checkout.id == "cs_test_123")
        #expect(response.checkout.url == "https://checkout.stripe.com/c/pay/cs_test_123")
    }
}

// MARK: - AddressDetails Tests (Delivery Context)

@Suite("AddressDetails Encoding Tests")
struct AddressDetailsEncodingTests {

    @Test("AddressDetails encodes Hungarian address")
    func testHungarianAddress() throws {
        let address = AddressDetails(
            street1: "Kossuth Lajos u. 10",
            street2: "2. emelet",
            city: "Budapest",
            province: nil,
            postCode: "1055",
            country: "HU"
        )
        let dict = try encodeToDict(address)

        #expect(dict["country"] as? String == "HU")
        #expect(dict["postCode"] as? String == "1055")
        #expect(dict["city"] as? String == "Budapest")
    }

    @Test("AddressDetails encodes international address")
    func testInternationalAddress() throws {
        let address = AddressDetails(
            street1: "Hlavná 1",
            street2: nil,
            city: "Bratislava",
            province: nil,
            postCode: "81101",
            country: "SK"
        )
        let dict = try encodeToDict(address)

        #expect(dict["country"] as? String == "SK")
    }
}
