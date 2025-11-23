import Foundation

struct QRTag: Codable, Identifiable {
    let id: Int
    let tagCode: String
    let petId: Int?
    let isActivated: Bool
    let createdAt: String
    let updatedAt: String
    let pet: Pet?

    var qrCodeURL: String {
        "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=\(tagCode)"
    }

    var deepLink: String {
        "petsafety://tag/\(tagCode)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case tagCode = "tag_code"
        case petId = "pet_id"
        case isActivated = "is_activated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pet
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
    let tagCode: String
    let petId: Int

    enum CodingKeys: String, CodingKey {
        case tagCode = "tag_code"
        case petId = "pet_id"
    }
}
