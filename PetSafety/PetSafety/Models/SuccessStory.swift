import Foundation
import CoreLocation

struct SuccessStory: Codable, Identifiable {
    let id: String
    let alertId: String?
    let petId: String
    let ownerId: String
    let reunionCity: String?
    let reunionLatitude: Double?
    let reunionLongitude: Double?
    let storyText: String?
    let isPublic: Bool
    let isConfirmed: Bool
    let missingSince: String?
    let foundAt: String
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?

    // Related objects (populated from API)
    let petName: String?
    let petSpecies: String?
    let petPhotoUrl: String?
    let distanceKm: Double?
    let photos: [SuccessStoryPhoto]?

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = reunionLatitude, let lon = reunionLongitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var foundAtDate: Date? {
        ISO8601DateFormatter().date(from: foundAt)
    }

    var missingSinceDate: Date? {
        guard let missingSince = missingSince else { return nil }
        return ISO8601DateFormatter().date(from: missingSince)
    }

    var timeMissingText: String? {
        guard let found = foundAtDate, let missing = missingSinceDate else {
            return nil
        }
        let interval = found.timeIntervalSince(missing)
        let days = Int(interval / 86400)
        if days == 0 {
            let hours = Int(interval / 3600)
            return hours <= 1 ? "1 hour" : "\(hours) hours"
        } else if days == 1 {
            return "1 day"
        } else if days < 7 {
            return "\(days) days"
        } else {
            let weeks = days / 7
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case alertId = "alert_id"
        case petId = "pet_id"
        case ownerId = "owner_id"
        case reunionCity = "reunion_city"
        case reunionLatitude = "reunion_latitude"
        case reunionLongitude = "reunion_longitude"
        case storyText = "story_text"
        case isPublic = "is_public"
        case isConfirmed = "is_confirmed"
        case missingSince = "missing_since"
        case foundAt = "found_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case petName = "pet_name"
        case petSpecies = "pet_species"
        case petPhotoUrl = "pet_photo_url"
        case distanceKm = "distance_km"
        case photos
    }
}

struct SuccessStoryPhoto: Codable, Identifiable {
    let id: String
    let successStoryId: String?
    let photoUrl: String
    let displayOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case successStoryId = "success_story_id"
        case photoUrl = "photo_url"
        case displayOrder = "display_order"
    }
}

struct CreateSuccessStoryRequest: Codable {
    let petId: String
    let alertId: String?
    let reunionLatitude: Double?
    let reunionLongitude: Double?
    let reunionCity: String?
    let storyText: String?
    let autoConfirm: Bool?
    // Note: No CodingKeys - backend expects camelCase field names
}

struct UpdateSuccessStoryRequest: Codable {
    let storyText: String?
    let isPublic: Bool?
    let isConfirmed: Bool?
    // Note: No CodingKeys - backend expects camelCase field names
}

struct SuccessStoriesResponse: Codable {
    let stories: [SuccessStory]
    let total: Int
    let hasMore: Bool
    let page: Int
    let limit: Int
}
