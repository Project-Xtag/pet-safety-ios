import Foundation

/// Represents a photo associated with a pet
struct PetPhoto: Codable, Identifiable, Hashable {
    let id: String
    let petId: String
    let photoUrl: String
    let isPrimary: Bool
    let displayOrder: Int
    let uploadedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case petId = "pet_id"
        case photoUrl = "photo_url"
        case isPrimary = "is_primary"
        case displayOrder = "display_order"
        case uploadedAt = "uploaded_at"
    }
}

/// Response from photo list API
struct PetPhotosResponse: Codable {
    let success: Bool
    let photos: [PetPhoto]
    // NOTE: Subscription info removed - unlimited photos for all users
}

/// Response from single photo upload
struct PhotoUploadResponse: Codable {
    let success: Bool
    let photo: PetPhoto
    let message: String?
}

/// Response from photo operations (delete, set primary, etc.)
struct PhotoOperationResponse: Codable {
    let success: Bool
    let message: String?
    let photo: PetPhoto?
}

/// Response from reorder operation
struct PhotoReorderResponse: Codable {
    let success: Bool
    let message: String?
    let photos: [PetPhoto]?
}

/// Request for reordering photos
struct PhotoReorderRequest: Codable {
    let photoOrder: [String]

    enum CodingKeys: String, CodingKey {
        case photoOrder = "photo_order"
    }
}
