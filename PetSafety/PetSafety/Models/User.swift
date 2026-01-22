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
    let showPhonePublicly: Bool?
    let showEmailPublicly: Bool?
    let showAddressPublicly: Bool?

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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case showPhonePublicly = "show_phone_publicly"
        case showEmailPublicly = "show_email_publicly"
        case showAddressPublicly = "show_address_publicly"
    }

    var fullName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}

struct LoginRequest: Codable {
    let email: String
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

    enum CodingKeys: String, CodingKey {
        case email
        case otp = "otp"
    }

    init(email: String, code: String) {
        self.email = email
        self.otp = code
    }
}

struct VerifyOTPResponse: Codable {
    let token: String
    let user: User
}
