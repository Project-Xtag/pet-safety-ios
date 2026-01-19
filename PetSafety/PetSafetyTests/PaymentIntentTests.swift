import Testing
import Foundation
@testable import PetSafety

@Suite("Payment Intent Decoding")
struct PaymentIntentTests {
    @Test("Decodes payment intent create response")
    func testDecodePaymentIntentResponse() throws {
        let json = """
        {
          "success": true,
          "data": {
            "paymentIntent": {
              "id": "pi_test_123",
              "client_secret": "secret_abc",
              "amount": 3.90,
              "currency": "gbp"
            }
          }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(PetSafety.ApiEnvelope<PetSafety.PaymentIntentResponse>.self, from: json)
        #expect(response.success == true)
        #expect(response.data?.paymentIntent.id == "pi_test_123")
        #expect(response.data?.paymentIntent.clientSecret == "secret_abc")
        #expect(response.data?.paymentIntent.amount == 3.90)
        #expect(response.data?.paymentIntent.currency == "gbp")
    }
}
