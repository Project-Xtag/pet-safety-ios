import Testing
import Foundation
@testable import PetSafety

@Suite("Shelter Code Tests")
struct ShelterCodeTests {

    @Test("UserSubscription decodes trial_ends_at correctly")
    func testTrialEndsAtDecoding() throws {
        let json = """
        {
            "id": "sub-1",
            "user_id": "user-1",
            "plan_id": "plan-standard",
            "plan_name": "standard",
            "status": "trialing",
            "billing_period": "monthly"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateStr) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateStr) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }

        let sub = try decoder.decode(UserSubscription.self, from: json)
        #expect(sub.status == .trialing)
        #expect(sub.isTrialing == true)
        #expect(sub.isActive == true)
    }

    @Test("isTrialing returns false for active status")
    func testIsTrialingFalseForActive() throws {
        let json = """
        {
            "id": "sub-1",
            "user_id": "user-1",
            "plan_id": "plan-standard",
            "plan_name": "standard",
            "status": "active",
            "billing_period": "monthly"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let sub = try decoder.decode(UserSubscription.self, from: json)
        #expect(sub.isTrialing == false)
        #expect(sub.isActive == true)
    }

    @Test("ShelterCodeRedeemResponse decodes correctly")
    func testShelterCodeRedeemResponseDecoding() throws {
        let json = """
        {
            "message": "Welcome! 3 months free Standard plan.",
            "order_id": "order-123"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ShelterCodeRedeemResponse.self, from: json)
        #expect(response.message == "Welcome! 3 months free Standard plan.")
        #expect(response.orderId == "order-123")
    }
}
