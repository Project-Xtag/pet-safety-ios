import Foundation

// MARK: - Subscription Plan
struct SubscriptionPlan: Codable, Identifiable {
    let id: String
    let name: String
    let displayName: String
    let description: String?
    let priceMonthly: Double
    let priceYearly: Double
    let currency: String
    let features: PlanFeatures
    let isPopular: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName = "display_name"
        case description
        case priceMonthly = "price_monthly"
        case priceYearly = "price_yearly"
        case currency
        case features
        case isPopular = "is_popular"
    }

    var formattedMonthlyPrice: String {
        if priceMonthly == 0 {
            return "Free"
        }
        return String(format: "£%.2f/mo", priceMonthly)
    }

    var formattedYearlyPrice: String {
        if priceYearly == 0 {
            return "Free"
        }
        return String(format: "£%.2f/yr", priceYearly)
    }

    var isFree: Bool {
        return priceMonthly == 0
    }
}

struct PlanFeatures: Codable {
    let maxPets: Int?
    let maxPhotosPerPet: Int
    let maxEmergencyContacts: Int
    let smsNotifications: Bool
    let vetAlerts: Bool
    let communityAlerts: Bool
    let freeTagReplacement: Bool
    let prioritySupport: Bool

    enum CodingKeys: String, CodingKey {
        case maxPets = "max_pets"
        case maxPhotosPerPet = "max_photos_per_pet"
        case maxEmergencyContacts = "max_emergency_contacts"
        case smsNotifications = "sms_notifications"
        case vetAlerts = "vet_alerts"
        case communityAlerts = "community_alerts"
        case freeTagReplacement = "free_tag_replacement"
        case prioritySupport = "priority_support"
    }

    var maxPetsDisplay: String {
        if let max = maxPets {
            return "\(max)"
        }
        return "Unlimited"
    }
}

// MARK: - User Subscription
struct UserSubscription: Codable {
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
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case planId = "plan_id"
        case planName = "plan_name"
        case status
        case billingPeriod = "billing_period"
        case currentPeriodStart = "current_period_start"
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
        case stripeSubscriptionId = "stripe_subscription_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isActive: Bool {
        return status == .active || status == .trialing
    }

    var isPaid: Bool {
        return planName.lowercased() != "starter"
    }

    var displayStatus: String {
        switch status {
        case .active:
            return "Active"
        case .trialing:
            return "Trial"
        case .pastDue:
            return "Past Due"
        case .cancelled:
            return "Cancelled"
        case .expired:
            return "Expired"
        }
    }
}

enum SubscriptionStatus: String, Codable {
    case active
    case trialing
    case pastDue = "past_due"
    case cancelled
    case expired
}

// MARK: - Subscription Features
struct SubscriptionFeatures: Codable {
    let planName: String
    let canCreateAlerts: Bool
    let canReceiveVetAlerts: Bool
    let canReceiveCommunityAlerts: Bool
    let canUseSmsNotifications: Bool
    let maxPets: Int?
    let maxPhotosPerPet: Int
    let maxEmergencyContacts: Int
    let freeTagReplacement: Bool

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

    var hasFullAlertFeatures: Bool {
        return canCreateAlerts && canReceiveVetAlerts && canReceiveCommunityAlerts
    }
}

// MARK: - API Response Types
struct SubscriptionPlansResponse: Codable {
    let plans: [SubscriptionPlan]
}

struct MySubscriptionResponse: Codable {
    let subscription: UserSubscription?
}

struct CreateCheckoutRequest: Codable {
    let planName: String
    let billingPeriod: String

    enum CodingKeys: String, CodingKey {
        case planName = "plan_name"
        case billingPeriod = "billing_period"
    }
}

struct SubscriptionCheckoutResponse: Codable {
    let sessionId: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case url
    }
}

struct UpgradeRequest: Codable {
    let planName: String

    enum CodingKeys: String, CodingKey {
        case planName = "plan_name"
    }
}

struct UpgradeResponse: Codable {
    let subscription: UserSubscription
    let message: String?
}

struct CancelSubscriptionResponse: Codable {
    let subscription: UserSubscription
    let message: String?
}
