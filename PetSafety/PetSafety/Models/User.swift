import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let phone: String?
    let address: String?
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

    enum CodingKeys: String, CodingKey {
        case id, email, phone, address, city, country
        case firstName = "first_name"
        case lastName = "last_name"
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
    }

    var fullName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}

struct LoginRequest: Codable {
    let email: String
}

struct LoginResponse: Codable {
    let success: Bool
    let message: String
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case success, message
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
