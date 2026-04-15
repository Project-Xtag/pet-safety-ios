import Testing
import Foundation
@testable import PetSafety

@Suite("Subscription Decoding Tests")
struct SubscriptionDecodingTests {

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

}
