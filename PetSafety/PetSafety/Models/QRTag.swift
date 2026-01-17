import Foundation

struct QRTag: Codable, Identifiable {
    let id: String
    let qrCode: String
    let petId: String?
    let status: String
    let createdAt: String
    let updatedAt: String?

    var qrCodeURL: String {
        "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=\(qrCode)"
    }

    var deepLink: String {
        "petsafety://tag/\(qrCode)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case qrCode = "qr_code"
        case petId = "pet_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ScanResponse: Codable {
    let success: Bool
    let pet: Pet

    enum CodingKeys: String, CodingKey {
        case success, pet
    }
}

struct PetOwnerInfo: Codable {
    let email: String
    let phone: String?
    let firstName: String?
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case email, phone
        case firstName = "first_name"
        case lastName = "last_name"
    }

    var displayName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        } else if let first = firstName {
            return first
        } else if let last = lastName {
            return last
        }
        return email
    }
}

struct ActivateTagRequest: Codable {
    let qrCode: String
    let petId: String

    enum CodingKeys: String, CodingKey {
        case qrCode = "qrCode"
        case petId = "petId"
    }
}
