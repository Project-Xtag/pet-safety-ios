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
            postapointDetails: nil
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["quantity"] as? Int == 2)
        #expect(dict["country_code"] as? String == "SK")
        #expect(dict["platform"] as? String == "ios")
    }
}
