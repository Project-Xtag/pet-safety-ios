import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let firstName: String?
    let lastName: String?
    let phone: String?
    let address: String?
    let city: String?
    let postalCode: String?
    let country: String?
    let isServiceProvider: Bool
    let serviceProviderType: String?
    let organizationName: String?
    let vetLicenseNumber: String?
    let isVerified: Bool
    let createdAt: String
    let updatedAt: String

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
}

struct VerifyOTPRequest: Codable {
    let email: String
    let code: String
}

struct VerifyOTPResponse: Codable {
    let token: String
    let user: User
}
