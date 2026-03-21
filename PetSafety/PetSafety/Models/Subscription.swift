import Foundation

// MARK: - Subscription Plan
struct SubscriptionPlan: Decodable, Identifiable {
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
        case id, name, description, currency, features
        case displayName = "display_name"
        case priceMonthly = "price_monthly"
        case priceYearly = "price_yearly"
        case isPopular = "is_popular"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        if let d = try? container.decode(Double.self, forKey: .priceMonthly) {
            priceMonthly = d
        } else if let s = try? container.decode(String.self, forKey: .priceMonthly), let d = Double(s) {
            priceMonthly = d
        } else {
            priceMonthly = 0
        }
        if let d = try? container.decode(Double.self, forKey: .priceYearly) {
            priceYearly = d
        } else if let s = try? container.decode(String.self, forKey: .priceYearly), let d = Double(s) {
            priceYearly = d
        } else {
            priceYearly = 0
        }
        currency = try container.decode(String.self, forKey: .currency)
        features = try container.decode(PlanFeatures.self, forKey: .features)
        isPopular = try container.decodeIfPresent(Bool.self, forKey: .isPopular)
    }

    private func currencySymbol(for code: String) -> String {
        switch code.uppercased() {
        case "EUR": return "€"
        case "HUF": return "Ft"
        case "GBP": return "£"
        default: return "€"
        }
    }

    private func formatPrice(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = currencySymbol(for: currency)
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencySymbol(for: currency))\(String(format: "%.2f", amount))"
    }

    var formattedMonthlyPrice: String {
        if priceMonthly == 0 {
            return "Free"
        }
        return "\(formatPrice(priceMonthly))/mo"
    }

    var formattedYearlyPrice: String {
        if priceYearly == 0 {
            return "Free"
        }
        return "\(formatPrice(priceYearly))/yr"
    }

    var isFree: Bool {
        return priceMonthly == 0
    }
}

struct PlanFeatures: Decodable {
    let maxPets: Int?
    let maxPhotosPerPet: Int?
    let maxEmergencyContacts: Int?
    let smsNotifications: Bool?
    let vetAlerts: Bool?
    let communityAlerts: Bool?
    let freeTagReplacement: Bool?
    let prioritySupport: Bool?

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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let i = try? container.decodeIfPresent(Int.self, forKey: .maxPets) {
            maxPets = i
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .maxPets), let i = Int(s) {
            maxPets = i
        } else {
            maxPets = nil
        }
        if let i = try? container.decodeIfPresent(Int.self, forKey: .maxPhotosPerPet) {
            maxPhotosPerPet = i
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .maxPhotosPerPet), let i = Int(s) {
            maxPhotosPerPet = i
        } else {
            maxPhotosPerPet = nil
        }
        if let i = try? container.decodeIfPresent(Int.self, forKey: .maxEmergencyContacts) {
            maxEmergencyContacts = i
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .maxEmergencyContacts), let i = Int(s) {
            maxEmergencyContacts = i
        } else {
            maxEmergencyContacts = nil
        }
        smsNotifications = try container.decodeIfPresent(Bool.self, forKey: .smsNotifications)
        vetAlerts = try container.decodeIfPresent(Bool.self, forKey: .vetAlerts)
        communityAlerts = try container.decodeIfPresent(Bool.self, forKey: .communityAlerts)
        freeTagReplacement = try container.decodeIfPresent(Bool.self, forKey: .freeTagReplacement)
        prioritySupport = try container.decodeIfPresent(Bool.self, forKey: .prioritySupport)
    }

    var maxPetsDisplay: String {
        if let max = maxPets {
            return "\(max)"
        }
        return "Unlimited"
    }

    var resolvedMaxPhotosPerPet: Int { maxPhotosPerPet ?? 3 }
    var resolvedMaxEmergencyContacts: Int { maxEmergencyContacts ?? 1 }
}

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
        case .suspended:
            return "Suspended"
        case .unknown:
            return "Unknown"
        }
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
struct SubscriptionPlansResponse: Decodable {
    let plans: [SubscriptionPlan]
}

struct MySubscriptionResponse: Decodable {
    let subscription: UserSubscription?
}

struct CreateCheckoutRequest: Codable {
    let planName: String
    let billingPeriod: String
    let platform: String
    let countryCode: String?
    let promoCode: String?

    enum CodingKeys: String, CodingKey {
        case planName = "plan_name"
        case billingPeriod = "billing_period"
        case platform
        case countryCode = "country_code"
        case promoCode = "promo_code"
    }
}

struct SubscriptionCheckoutResponse: Codable {
    let checkout: SubscriptionCheckoutData
}

struct SubscriptionCheckoutData: Codable {
    let id: String
    let url: String
}

// MARK: - Billing Portal
struct PortalSessionResponse: Codable {
    let url: String
}

struct InvoiceItem: Decodable, Identifiable {
    let id: String
    let number: String?
    let status: String?
    let amount: Int
    let currency: String
    let date: Int
    let pdfUrl: String?
    let hostedUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, number, status, amount, currency, date
        case pdfUrl = "pdf_url"
        case hostedUrl = "hosted_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        number = try container.decodeIfPresent(String.self, forKey: .number)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        if let i = try? container.decode(Int.self, forKey: .amount) {
            amount = i
        } else if let s = try? container.decode(String.self, forKey: .amount), let i = Int(s) {
            amount = i
        } else if let d = try? container.decode(Double.self, forKey: .amount) {
            amount = Int(d)
        } else {
            amount = 0
        }
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "EUR"
        if let i = try? container.decode(Int.self, forKey: .date) {
            date = i
        } else if let s = try? container.decode(String.self, forKey: .date), let i = Int(s) {
            date = i
        } else {
            date = 0
        }
        pdfUrl = try container.decodeIfPresent(String.self, forKey: .pdfUrl)
        hostedUrl = try container.decodeIfPresent(String.self, forKey: .hostedUrl)
    }
}

struct InvoicesResponse: Decodable {
    let invoices: [InvoiceItem]
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

struct UpgradeRequest: Codable {
    let planName: String

    enum CodingKeys: String, CodingKey {
        case planName = "plan_name"
    }
}

struct UpgradeResponse: Decodable {
    let subscription: UserSubscription
    let message: String?
}

struct CancelSubscriptionResponse: Decodable {
    let subscription: UserSubscription
    let message: String?
}
