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
        "senra://tag/\(qrCode)"
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
    let pet: Pet

    enum CodingKeys: String, CodingKey {
        case pet
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

/// Response from GET /api/qr-tags/lookup/:code
/// Used by DeepLinkService to determine what to show when a QR tag is scanned
struct TagLookupResponse: Codable {
    let exists: Bool
    let status: String?
    let hasPet: Bool?
    let isOwner: Bool?
    let canActivate: Bool?
    let pet: TagLookupPet?

    enum CodingKeys: String, CodingKey {
        case exists, status, pet
        case hasPet = "has_pet"
        case isOwner = "is_owner"
        case canActivate = "can_activate"
    }
}

/// Lightweight pet data returned by the tag lookup endpoint
struct TagLookupPet: Codable {
    let id: String
    let name: String
    let species: String?
    let breed: String?
    let color: String?
    let age: String?
    let profileImage: String?
    let qrCode: String?
    let isMissing: Bool?
    let ownerPhone: String?
    let ownerEmail: String?
    let ownerAddress: String?
    let ownerAddressLine2: String?
    let ownerCity: String?
    let ownerPostalCode: String?
    let ownerCountry: String?
    let medicalInfo: String?
    let allergies: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, name, species, breed, color, age, allergies, notes
        case profileImage = "profile_image"
        case qrCode = "qr_code"
        case isMissing = "is_missing"
        case ownerPhone = "owner_phone"
        case ownerEmail = "owner_email"
        case ownerAddress = "owner_address"
        case ownerAddressLine2 = "owner_address_line2"
        case ownerCity = "owner_city"
        case ownerPostalCode = "owner_postal_code"
        case ownerCountry = "owner_country"
        case medicalInfo = "medical_info"
    }
}
