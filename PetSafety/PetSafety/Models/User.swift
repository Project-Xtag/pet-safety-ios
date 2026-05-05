import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let role: String?
    let firstName: String?
    let lastName: String?
    let phone: String?
    let secondaryPhone: String?
    let secondaryEmail: String?
    let address: String?
    let addressLine2: String?
    let city: String?
    let postalCode: String?
    let country: String?
    let isServiceProvider: Bool?
    let serviceProviderType: String?
    let organizationName: String?
    let vetLicenseNumber: String?
    let isVerified: Bool?
    let createdAt: String?
    let updatedAt: String?
    let showNamePublicly: Bool?
    let showPhonePublicly: Bool?
    let showEmailPublicly: Bool?
    let showAddressPublicly: Bool?
    let preferredLanguage: String?
    let showSecondaryPhonePublicly: Bool?
    let showSecondaryEmailPublicly: Bool?
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case id, email, role, phone, address, city, country
        case firstName = "first_name"
        case lastName = "last_name"
        case secondaryPhone = "secondary_phone"
        case secondaryEmail = "secondary_email"
        case addressLine2 = "address_line_2"
        case postalCode = "postal_code"
        case isServiceProvider = "is_service_provider"
        case serviceProviderType = "service_provider_type"
        case organizationName = "organization_name"
        case vetLicenseNumber = "vet_license_number"
        case isVerified = "is_verified"
        case preferredLanguage = "preferred_language"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case showNamePublicly = "show_name_publicly"
        case showPhonePublicly = "show_phone_publicly"
        case showEmailPublicly = "show_email_publicly"
        case showAddressPublicly = "show_address_publicly"
        case showSecondaryPhonePublicly = "show_secondary_phone_publicly"
        case showSecondaryEmailPublicly = "show_secondary_email_publicly"
        case profileImage = "profile_image"
    }

    var fullName: String {
        InputValidators.formatDisplayName(firstName: firstName, lastName: lastName)
    }
}

struct LoginRequest: Codable {
    let email: String
    let locale: String?
}

struct LoginResponse: Codable {
    let message: String
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case expiresIn = "expiresIn"
    }
}

struct VerifyOTPRequest: Codable {
    let email: String
    let otp: String
    let firstName: String?
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case email
        case otp
        case firstName = "first_name"
        case lastName = "last_name"
    }

    init(email: String, code: String, firstName: String? = nil, lastName: String? = nil) {
        self.email = email
        self.otp = code
        self.firstName = firstName?.isEmpty == true ? nil : firstName
        self.lastName = lastName?.isEmpty == true ? nil : lastName
    }
}

struct VerifyOTPResponse: Codable {
    let token: String
    let refreshToken: String?
    let user: User
    let isNewUser: Bool?
}
