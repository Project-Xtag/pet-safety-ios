import Foundation

// MARK: - User Subscription
struct UserSubscription: Decodable {
    let id: String
    let userId: String
    let planId: String
    let planName: String
    let status: SubscriptionStatus
    let billingPeriod: String?
    let currentPeriodStart: Date?
    let currentPeriodEnd: Date?
    let cancelAtPeriodEnd: Bool?
    let stripeSubscriptionId: String?
    let trialEndsAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    /// Nested plan object returned by the API
    private struct NestedPlan: Codable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case planId = "plan_id"
        case planName = "plan_name"
        case plan
        case tier
        case status
        case billingPeriod = "billing_period"
        case currentPeriodStart = "current_period_start"
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
        case stripeSubscriptionId = "stripe_subscription_id"
        case trialEndsAt = "trial_ends_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        planId = try container.decodeIfPresent(String.self, forKey: .planId) ?? ""
        status = try container.decode(SubscriptionStatus.self, forKey: .status)
        billingPeriod = try container.decodeIfPresent(String.self, forKey: .billingPeriod)
        currentPeriodStart = try container.decodeIfPresent(Date.self, forKey: .currentPeriodStart)
        currentPeriodEnd = try container.decodeIfPresent(Date.self, forKey: .currentPeriodEnd)
        cancelAtPeriodEnd = try container.decodeIfPresent(Bool.self, forKey: .cancelAtPeriodEnd)
        stripeSubscriptionId = try container.decodeIfPresent(String.self, forKey: .stripeSubscriptionId)
        trialEndsAt = try container.decodeIfPresent(Date.self, forKey: .trialEndsAt)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        // plan_name can come from: flat "plan_name", nested "plan.name", or "tier"
        if let flat = try container.decodeIfPresent(String.self, forKey: .planName) {
            planName = flat
        } else if let nested = try container.decodeIfPresent(NestedPlan.self, forKey: .plan) {
            planName = nested.name
        } else if let tier = try container.decodeIfPresent(String.self, forKey: .tier) {
            planName = tier
        } else {
            planName = "starter"
        }
    }

    var isActive: Bool {
        return status == .active || status == .trialing
    }

    var isTrialing: Bool {
        return status == .trialing
    }

    var trialEndFormatted: String? {
        guard let trialEndsAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: trialEndsAt)
    }

    var trialDaysLeft: Int? {
        guard let trialEndsAt else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: trialEndsAt).day
        return days
    }

    var isPaid: Bool {
        return planName.lowercased() != "starter"
    }
}

enum SubscriptionStatus: String, Codable {
    case active
    case trialing
    case pastDue = "past_due"
    case cancelled
    case expired
    case suspended
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SubscriptionStatus(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Subscription Features
struct SubscriptionFeatures: Decodable {
    let planName: String?
    let canCreateAlerts: Bool?
    let canReceiveVetAlerts: Bool?
    let canReceiveCommunityAlerts: Bool?
    let canUseSmsNotifications: Bool?
    let maxPets: Int?
    let maxPhotosPerPet: Int?
    let maxEmergencyContacts: Int?
    let freeTagReplacement: Bool?

    enum CodingKeys: String, CodingKey {
        case planName = "plan_name"
        case canCreateAlerts = "can_create_alerts"
        case canReceiveVetAlerts = "can_receive_vet_alerts"
        case canReceiveCommunityAlerts = "can_receive_community_alerts"
        case canUseSmsNotifications = "can_use_sms_notifications"
        case maxPets = "max_pets"
        case maxPhotosPerPet = "max_photos_per_pet"
        case maxEmergencyContacts = "max_emergency_contacts"
        case freeTagReplacement = "free_tag_replacement"
    }

    var resolvedMaxPhotosPerPet: Int { maxPhotosPerPet ?? 3 }
    var resolvedMaxEmergencyContacts: Int { maxEmergencyContacts ?? 1 }

    var hasFullAlertFeatures: Bool {
        return (canCreateAlerts ?? false) && (canReceiveVetAlerts ?? false) && (canReceiveCommunityAlerts ?? false)
    }
}

// MARK: - API Response Types
struct MySubscriptionResponse: Decodable {
    let subscription: UserSubscription?
}

// MARK: - Referral
struct ReferralCodeResponse: Codable {
    let code: String
    let expiresAt: String?

    enum CodingKeys: String, CodingKey {
        case code
        case expiresAt = "expires_at"
    }
}

struct ReferralItem: Codable, Identifiable {
    let id: String
    let refereeEmail: String?
    let status: String
    let redeemedAt: String?
    let rewardedAt: String?
}

struct ReferralStatusResponse: Codable {
    let code: String?
    let expiresAt: String?
    let referrals: [ReferralItem]

    enum CodingKeys: String, CodingKey {
        case code
        case expiresAt = "expires_at"
        case referrals
    }
}

struct ReferralApplyRequest: Codable {
    let code: String
}

struct ReferralApplyResponse: Codable {
    let message: String
    let stripePromoCodeId: String?

    enum CodingKeys: String, CodingKey {
        case message
        case stripePromoCodeId = "stripe_promo_code_id"
    }
}

struct ShelterCodeRedeemRequest: Codable {
    let code: String
}

struct ShelterCodeRedeemResponse: Codable {
    let message: String
    let orderId: String?

    enum CodingKeys: String, CodingKey {
        case message
        case orderId = "order_id"
    }
}
