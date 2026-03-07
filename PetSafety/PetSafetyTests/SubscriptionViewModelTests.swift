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
                "max_pets": 1,
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
        #expect(plan.features.maxPets == 1)
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
                "max_pets": 10,
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
            "display_name": "Maximum",
            "description": null,
            "price_monthly": 9.95,
            "price_yearly": 99.50,
            "currency": "GBP",
            "features": {
                "max_pets": 10,
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
        #expect(plan.features.maxPets == 10)
        #expect(plan.features.maxPetsDisplay == "10")
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
            ("suspended", "Suspended", false),
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
            "max_pets": 10,
            "max_photos_per_pet": 20,
            "max_emergency_contacts": 10,
            "free_tag_replacement": true
        }
        """.data(using: .utf8)!

        let features = try JSONDecoder().decode(SubscriptionFeatures.self, from: json)
        #expect(features.planName == "ultimate")
        #expect(features.hasFullAlertFeatures == true)
        #expect(features.maxPets == 10)
    }

    // MARK: - Checkout & Portal Responses

    @Test("Decodes checkout response via ApiEnvelope")
    func testDecodeCheckoutResponse() throws {
        let json = """
        {
            "success": true,
            "data": {
                "checkout": {
                    "id": "cs_test_abc",
                    "url": "https://checkout.stripe.com/session/abc"
                }
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ApiEnvelope<SubscriptionCheckoutResponse>.self, from: json)
        #expect(response.success == true)
        #expect(response.data?.checkout.id == "cs_test_abc")
        #expect(response.data?.checkout.url == "https://checkout.stripe.com/session/abc")
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
        let request = CreateCheckoutRequest(planName: "standard", billingPeriod: "monthly", platform: "ios", countryCode: nil)
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(dict["plan_name"] as? String == "standard")
        #expect(dict["billing_period"] as? String == "monthly")
        #expect(dict["platform"] as? String == "ios")
    }

    // MARK: - Critical Fix: SubscriptionStatus.suspended

    @Test("Decodes suspended subscription status without crash")
    func testDecodeSuspendedStatus() throws {
        let json = """
        {
            "id": "sub_suspended",
            "user_id": "user_1",
            "plan_id": "plan_1",
            "plan_name": "standard",
            "status": "suspended"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sub = try decoder.decode(UserSubscription.self, from: json)
        #expect(sub.status == .suspended)
        #expect(sub.isActive == false)
        #expect(sub.displayStatus == "Suspended")
    }

    @Test("Decodes unknown subscription status gracefully")
    func testDecodeUnknownStatus() throws {
        let json = """
        {
            "id": "sub_future",
            "user_id": "user_1",
            "plan_id": "plan_1",
            "plan_name": "standard",
            "status": "some_future_status"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sub = try decoder.decode(UserSubscription.self, from: json)
        #expect(sub.status == .unknown)
        #expect(sub.isActive == false)
        #expect(sub.displayStatus == "Unknown")
    }

    // MARK: - Critical Fix: PlanFeatures optional fields

    @Test("Decodes PlanFeatures with missing optional fields")
    func testDecodePlanFeaturesWithMissingFields() throws {
        let json = """
        {
            "max_pets": 5
        }
        """.data(using: .utf8)!

        let features = try JSONDecoder().decode(PlanFeatures.self, from: json)
        #expect(features.maxPets == 5)
        #expect(features.maxPhotosPerPet == nil)
        #expect(features.maxEmergencyContacts == nil)
        #expect(features.smsNotifications == nil)
        #expect(features.vetAlerts == nil)
        #expect(features.resolvedMaxPhotosPerPet == 3)
        #expect(features.resolvedMaxEmergencyContacts == 1)
    }

    @Test("PlanFeatures resolved defaults are correct")
    func testPlanFeaturesResolvedDefaults() throws {
        let json = """
        {
            "max_pets": null,
            "max_photos_per_pet": 20,
            "max_emergency_contacts": 10
        }
        """.data(using: .utf8)!

        let features = try JSONDecoder().decode(PlanFeatures.self, from: json)
        #expect(features.maxPetsDisplay == "Unlimited")
        #expect(features.resolvedMaxPhotosPerPet == 20)
        #expect(features.resolvedMaxEmergencyContacts == 10)
    }

    // MARK: - Critical Fix: SubscriptionFeatures optional fields

    @Test("Decodes SubscriptionFeatures with missing optional fields")
    func testDecodeSubscriptionFeaturesWithMissingFields() throws {
        let json = """
        {
            "plan_name": "starter"
        }
        """.data(using: .utf8)!

        let features = try JSONDecoder().decode(SubscriptionFeatures.self, from: json)
        #expect(features.planName == "starter")
        #expect(features.canCreateAlerts == nil)
        #expect(features.maxPhotosPerPet == nil)
        #expect(features.resolvedMaxPhotosPerPet == 3)
        #expect(features.resolvedMaxEmergencyContacts == 1)
        #expect(features.hasFullAlertFeatures == false)
    }

    @Test("SubscriptionFeatures hasFullAlertFeatures requires all three")
    func testFullAlertFeaturesRequiresAll() throws {
        let jsonPartial = """
        {
            "plan_name": "standard",
            "can_create_alerts": true,
            "can_receive_vet_alerts": true,
            "can_receive_community_alerts": false
        }
        """.data(using: .utf8)!

        let partial = try JSONDecoder().decode(SubscriptionFeatures.self, from: jsonPartial)
        #expect(partial.hasFullAlertFeatures == false)

        let jsonFull = """
        {
            "plan_name": "ultimate",
            "can_create_alerts": true,
            "can_receive_vet_alerts": true,
            "can_receive_community_alerts": true
        }
        """.data(using: .utf8)!

        let full = try JSONDecoder().decode(SubscriptionFeatures.self, from: jsonFull)
        #expect(full.hasFullAlertFeatures == true)
    }
}

// MARK: - Upgrade/Downgrade & Feature Limits

@Suite("Subscription Upgrade/Downgrade & Feature Limits")
struct SubscriptionUpgradeDowngradeTests {

    // Helper to determine plan tier
    func planTier(_ name: String) -> Int {
        switch name.lowercased() {
        case "starter": return 0
        case "standard": return 1
        case "ultimate": return 2
        default: return -1
        }
    }

    // MARK: - Upgrade Detection

    @Test("Starter to Standard is an upgrade")
    func testStarterToStandardIsUpgrade() {
        #expect(planTier("starter") < planTier("standard"))
    }

    @Test("Starter to Ultimate is an upgrade")
    func testStarterToUltimateIsUpgrade() {
        #expect(planTier("starter") < planTier("ultimate"))
    }

    @Test("Standard to Ultimate is an upgrade")
    func testStandardToUltimateIsUpgrade() {
        #expect(planTier("standard") < planTier("ultimate"))
    }

    @Test("Ultimate to Standard is a downgrade")
    func testUltimateToStandardIsDowngrade() {
        #expect(planTier("ultimate") > planTier("standard"))
    }

    @Test("Ultimate to Starter is a downgrade")
    func testUltimateToStarterIsDowngrade() {
        #expect(planTier("ultimate") > planTier("starter"))
    }

    @Test("Standard to Starter is a downgrade")
    func testStandardToStarterIsDowngrade() {
        #expect(planTier("standard") > planTier("starter"))
    }

    @Test("Same plan is neither upgrade nor downgrade")
    func testSamePlanNoChange() {
        #expect(planTier("standard") == planTier("standard"))
        let from = planTier("standard")
        let to = planTier("standard")
        #expect(!(from < to)) // not an upgrade
        #expect(!(from > to)) // not a downgrade
    }

    // MARK: - Currency Formatting

    @Test("EUR plan formatted price contains euro sign")
    func testEURFormatting() throws {
        let json = """
        {
            "id": "plan_eur",
            "name": "standard",
            "display_name": "Standard",
            "description": "EUR plan",
            "price_monthly": 4.95,
            "price_yearly": 49.50,
            "currency": "EUR",
            "features": {
                "max_pets": 10,
                "max_photos_per_pet": 10,
                "max_emergency_contacts": 5,
                "sms_notifications": true,
                "vet_alerts": true,
                "community_alerts": true,
                "free_tag_replacement": false,
                "priority_support": false
            }
        }
        """.data(using: .utf8)!

        let plan = try JSONDecoder().decode(SubscriptionPlan.self, from: json)
        #expect(plan.formattedMonthlyPrice.contains("€"))
    }

    @Test("HUF plan formatted price contains Ft symbol")
    func testHUFFormatting() throws {
        let json = """
        {
            "id": "plan_huf",
            "name": "standard",
            "display_name": "Standard",
            "description": "HUF plan",
            "price_monthly": 1990,
            "price_yearly": 19900,
            "currency": "HUF",
            "features": {
                "max_pets": 10,
                "max_photos_per_pet": 10,
                "max_emergency_contacts": 5,
                "sms_notifications": true,
                "vet_alerts": true,
                "community_alerts": true,
                "free_tag_replacement": false,
                "priority_support": false
            }
        }
        """.data(using: .utf8)!

        let plan = try JSONDecoder().decode(SubscriptionPlan.self, from: json)
        #expect(plan.formattedMonthlyPrice.contains("Ft"))
    }

    // MARK: - Subscription Edge Cases

    @Test("Subscription with cancel_at_period_end true and active status is still active")
    func testCancelAtPeriodEndStillActive() throws {
        let json = """
        {
            "id": "sub_cancel",
            "user_id": "user_1",
            "plan_id": "plan_1",
            "plan_name": "standard",
            "status": "active",
            "cancel_at_period_end": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sub = try decoder.decode(UserSubscription.self, from: json)
        #expect(sub.isActive == true)
        #expect(sub.cancelAtPeriodEnd == true)
    }

    @Test("Decode CancelSubscriptionResponse with subscription and message")
    func testDecodeCancelSubscriptionResponse() throws {
        let json = """
        {
            "subscription": {
                "id": "sub_cancelled",
                "user_id": "user_1",
                "plan_id": "plan_1",
                "plan_name": "standard",
                "status": "cancelled"
            },
            "message": "Subscription cancelled successfully"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(CancelSubscriptionResponse.self, from: json)
        #expect(response.subscription.id == "sub_cancelled")
        #expect(response.subscription.status == .cancelled)
        #expect(response.message == "Subscription cancelled successfully")
    }

    // MARK: - Feature Limit Check Logic

    @Test("maxPets=10, currentCount=10 should NOT allow more")
    func testPetLimitReached() {
        let maxPets: Int? = 10
        let currentCount = 10
        #expect(!(currentCount < (maxPets ?? Int.max)))
    }

    @Test("maxPets=10, currentCount=9 should allow more")
    func testPetLimitNotReached() {
        let maxPets: Int? = 10
        let currentCount = 9
        #expect(currentCount < (maxPets ?? Int.max))
    }

    @Test("maxPets=10 (maximum plan) should allow up to 10")
    func testMaximumPlanPets() {
        let maxPets: Int? = 10
        let currentCount = 5
        #expect(currentCount < (maxPets ?? Int.max))
    }

    @Test("maxPhotosPerPet limit check at boundary and below")
    func testPhotoLimitBoundary() {
        let maxPhotos = 10
        #expect(!(10 < maxPhotos)) // at limit, should NOT allow
        #expect(9 < maxPhotos)     // below limit, should allow
    }
}
