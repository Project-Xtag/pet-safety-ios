import Testing
import Foundation
@testable import PetSafety

@Suite("Subscription Models")
struct SubscriptionModelTests {

    // MARK: - SubscriptionPlan

    @Test("Decodes subscription plan from JSON")
    func testDecodeSubscriptionPlan() throws {
        let json = """
        {
            "id": "plan_1",
            "name": "standard",
            "display_name": "Standard",
            "description": "Best for pet owners",
            "price_monthly": 4.95,
            "price_yearly": 49.50,
            "currency": "GBP",
            "features": {
                "max_pets": 5,
                "max_photos_per_pet": 10,
                "max_emergency_contacts": 5,
                "sms_notifications": true,
                "vet_alerts": true,
                "community_alerts": true,
                "free_tag_replacement": false,
                "priority_support": false
            },
            "is_popular": true
        }
        """.data(using: .utf8)!

        let plan = try JSONDecoder().decode(SubscriptionPlan.self, from: json)
        #expect(plan.id == "plan_1")
        #expect(plan.name == "standard")
        #expect(plan.displayName == "Standard")
        #expect(plan.priceMonthly == 4.95)
        #expect(plan.priceYearly == 49.50)
        #expect(plan.currency == "GBP")
        #expect(plan.isPopular == true)
        #expect(plan.isFree == false)
        #expect(plan.features.maxPets == 5)
        #expect(plan.features.smsNotifications == true)
        #expect(plan.features.vetAlerts == true)
    }

    @Test("Free plan properties")
    func testFreePlanProperties() throws {
        let json = """
        {
            "id": "plan_0",
            "name": "starter",
            "display_name": "Starter",
            "description": "Free forever",
            "price_monthly": 0,
            "price_yearly": 0,
            "currency": "GBP",
            "features": {
                "max_pets": 1,
                "max_photos_per_pet": 3,
                "max_emergency_contacts": 2,
                "sms_notifications": false,
                "vet_alerts": false,
                "community_alerts": false,
                "free_tag_replacement": false,
                "priority_support": false
            }
        }
        """.data(using: .utf8)!

        let plan = try JSONDecoder().decode(SubscriptionPlan.self, from: json)
        #expect(plan.isFree == true)
        #expect(plan.formattedMonthlyPrice == "Free")
        #expect(plan.formattedYearlyPrice == "Free")
        #expect(plan.isPopular == nil)
    }

    @Test("Paid plan formatted prices")
    func testPaidPlanFormattedPrices() throws {
        let json = """
        {
            "id": "plan_2",
            "name": "ultimate",
            "display_name": "Ultimate",
            "description": null,
            "price_monthly": 9.95,
            "price_yearly": 99.50,
            "currency": "GBP",
            "features": {
                "max_pets": null,
                "max_photos_per_pet": 20,
                "max_emergency_contacts": 10,
                "sms_notifications": true,
                "vet_alerts": true,
                "community_alerts": true,
                "free_tag_replacement": true,
                "priority_support": true
            }
        }
        """.data(using: .utf8)!

        let plan = try JSONDecoder().decode(SubscriptionPlan.self, from: json)
        #expect(plan.formattedMonthlyPrice == "£9.95/mo")
        #expect(plan.formattedYearlyPrice == "£99.50/yr")
        #expect(plan.features.maxPets == nil)
        #expect(plan.features.maxPetsDisplay == "Unlimited")
    }

    // MARK: - UserSubscription

    @Test("Decodes user subscription")
    func testDecodeUserSubscription() throws {
        let json = """
        {
            "id": "sub_123",
            "user_id": "user_456",
            "plan_id": "plan_1",
            "plan_name": "standard",
            "status": "active",
            "billing_period": "monthly",
            "cancel_at_period_end": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sub = try decoder.decode(UserSubscription.self, from: json)
        #expect(sub.id == "sub_123")
        #expect(sub.planName == "standard")
        #expect(sub.status == .active)
        #expect(sub.isActive == true)
        #expect(sub.isPaid == true)
        #expect(sub.displayStatus == "Active")
    }

    @Test("Starter plan is not paid")
    func testStarterNotPaid() throws {
        let json = """
        {
            "id": "sub_789",
            "user_id": "user_456",
            "plan_id": "plan_0",
            "plan_name": "starter",
            "status": "active"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sub = try decoder.decode(UserSubscription.self, from: json)
        #expect(sub.isPaid == false)
        #expect(sub.isActive == true)
    }

    @Test("Subscription status display values")
    func testSubscriptionStatusDisplay() throws {
        let statuses: [(String, String, Bool)] = [
            ("active", "Active", true),
            ("trialing", "Trial", true),
            ("past_due", "Past Due", false),
            ("cancelled", "Cancelled", false),
            ("expired", "Expired", false),
        ]

        for (raw, display, isActive) in statuses {
            let json = """
            {
                "id": "sub_1",
                "user_id": "u1",
                "plan_id": "p1",
                "plan_name": "standard",
                "status": "\(raw)"
            }
            """.data(using: .utf8)!

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let sub = try decoder.decode(UserSubscription.self, from: json)
            #expect(sub.displayStatus == display)
            #expect(sub.isActive == isActive)
        }
    }

    // MARK: - SubscriptionFeatures

    @Test("Decodes subscription features")
    func testDecodeFeatures() throws {
        let json = """
        {
            "plan_name": "ultimate",
            "can_create_alerts": true,
            "can_receive_vet_alerts": true,
            "can_receive_community_alerts": true,
            "can_use_sms_notifications": true,
            "max_pets": null,
            "max_photos_per_pet": 20,
            "max_emergency_contacts": 10,
            "free_tag_replacement": true
        }
        """.data(using: .utf8)!

        let features = try JSONDecoder().decode(SubscriptionFeatures.self, from: json)
        #expect(features.planName == "ultimate")
        #expect(features.hasFullAlertFeatures == true)
        #expect(features.maxPets == nil)
    }

    // MARK: - Checkout & Portal Responses

    @Test("Decodes checkout response via ApiEnvelope")
    func testDecodeCheckoutResponse() throws {
        let json = """
        {
            "success": true,
            "data": {
                "session_id": "cs_test_abc",
                "url": "https://checkout.stripe.com/session/abc"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ApiEnvelope<SubscriptionCheckoutResponse>.self, from: json)
        #expect(response.success == true)
        #expect(response.data?.sessionId == "cs_test_abc")
        #expect(response.data?.url == "https://checkout.stripe.com/session/abc")
    }

    @Test("Decodes portal session response")
    func testDecodePortalResponse() throws {
        let json = """
        {
            "url": "https://billing.stripe.com/session/portal_abc"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(PortalSessionResponse.self, from: json)
        #expect(response.url == "https://billing.stripe.com/session/portal_abc")
    }

    // MARK: - Invoice

    @Test("Decodes invoice item")
    func testDecodeInvoice() throws {
        let json = """
        {
            "id": "inv_123",
            "number": "INV-0001",
            "status": "paid",
            "amount": 495,
            "currency": "gbp",
            "date": 1700000000,
            "pdfUrl": "https://invoice.stripe.com/pdf/inv_123",
            "hostedUrl": "https://invoice.stripe.com/inv_123"
        }
        """.data(using: .utf8)!

        let invoice = try JSONDecoder().decode(InvoiceItem.self, from: json)
        #expect(invoice.id == "inv_123")
        #expect(invoice.number == "INV-0001")
        #expect(invoice.status == "paid")
        #expect(invoice.amount == 495)
        #expect(invoice.currency == "gbp")
        #expect(invoice.pdfUrl != nil)
    }

    // MARK: - Referral

    @Test("Decodes referral code response")
    func testDecodeReferralCode() throws {
        let json = """
        {
            "code": "REF-ABCD1234",
            "expires_at": "2026-05-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ReferralCodeResponse.self, from: json)
        #expect(response.code == "REF-ABCD1234")
        #expect(response.expiresAt == "2026-05-01T00:00:00Z")
    }

    @Test("Decodes referral status response")
    func testDecodeReferralStatus() throws {
        let json = """
        {
            "code": "REF-XYZ",
            "expires_at": null,
            "referrals": [
                {
                    "id": "ref_1",
                    "refereeEmail": "friend@example.com",
                    "status": "subscribed",
                    "redeemedAt": "2026-01-15T10:00:00Z",
                    "rewardedAt": null
                }
            ]
        }
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(ReferralStatusResponse.self, from: json)
        #expect(status.code == "REF-XYZ")
        #expect(status.referrals.count == 1)
        #expect(status.referrals[0].refereeEmail == "friend@example.com")
        #expect(status.referrals[0].status == "subscribed")
        #expect(status.referrals[0].rewardedAt == nil)
    }

    // MARK: - CreateCheckoutRequest

    @Test("Encodes checkout request with platform")
    func testEncodeCheckoutRequest() throws {
        let request = CreateCheckoutRequest(planName: "standard", billingPeriod: "monthly", platform: "ios")
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(dict["plan_name"] as? String == "standard")
        #expect(dict["billing_period"] as? String == "monthly")
        #expect(dict["platform"] as? String == "ios")
    }
}
