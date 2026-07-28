import Testing
import Foundation
@testable import PetSafety

@Suite("Checkout Response Decoding")
struct PaymentIntentTests {
    @Test("Decodes tag checkout response with session URL")
    func testDecodeTagCheckoutResponse() throws {
        let json = """
        {
          "success": true,
          "data": {
            "checkout": {
              "id": "cs_test_abc123",
              "url": "https://checkout.stripe.com/c/pay/cs_test_abc123"
            }
          }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(ApiEnvelope<TagCheckoutResponse>.self, from: json)
        #expect(response.success == true)
        #expect(response.data?.checkout.id == "cs_test_abc123")
        #expect(response.data?.checkout.url.contains("stripe.com") == true)
    }

    @Test("CreateTagCheckoutRequest encodes country_code correctly")
    func testCreateTagCheckoutRequestEncoding() throws {
        let request = CreateTagCheckoutRequest(
            quantity: 2,
            countryCode: "SK",
            platform: "ios",
            deliveryMethod: nil,
            postapointDetails: nil,
            promoCode: nil,
            userId: nil,
            email: nil
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["quantity"] as? Int == 2)
        #expect(dict["country_code"] as? String == "SK")
        #expect(dict["platform"] as? String == "ios")
        // Guest-checkout fields: nil optionals must be OMITTED from the wire
        // (absent user_id = the backend's unauthenticated-legacy path), and
        // when present, userId must ride as snake_case user_id.
        #expect(dict["user_id"] == nil)
        #expect(dict["email"] == nil)
    }

    @Test("guest checkout fields encode as user_id / email when present")
    func testGuestCheckoutFieldsEncoding() throws {
        let request = CreateTagCheckoutRequest(
            quantity: 1,
            countryCode: "HU",
            platform: "ios",
            deliveryMethod: "postapoint",
            postapointDetails: nil,
            promoCode: nil,
            userId: "9dd2f919-85a5-4eb9-a609-a30c645b4c61",
            email: "buyer@example.com"
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["user_id"] as? String == "9dd2f919-85a5-4eb9-a609-a30c645b4c61")
        #expect(dict["email"] as? String == "buyer@example.com")
        #expect(dict["delivery_method"] as? String == "postapoint")
        #expect(dict["userId"] == nil)
    }
}
