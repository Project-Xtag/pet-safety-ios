import Foundation
import CoreLocation

struct MissingPetAlert: Codable, Identifiable {
    let id: String
    let petId: String
    let userId: String
    let status: String
    let lastSeenLocation: String?
    let lastSeenLatitude: Double?
    let lastSeenLongitude: Double?
    let additionalInfo: String?
    let createdAt: String
    let updatedAt: String
    let pet: Pet?
    let sightings: [Sighting]?

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = lastSeenLatitude, let lon = lastSeenLongitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    enum CodingKeys: String, CodingKey {
        case id, status, pet, sightings
        case petId = "pet_id"
        case userId = "user_id"
        case lastSeenLocation = "last_seen_location"
        case lastSeenLatitude = "last_seen_latitude"
        case lastSeenLongitude = "last_seen_longitude"
        case additionalInfo = "additional_info"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreateAlertRequest: Codable {
    let petId: String
    let lastSeenLocation: String?
    let lastSeenLatitude: Double?
    let lastSeenLongitude: Double?
    let additionalInfo: String?

    enum CodingKeys: String, CodingKey {
        case petId = "pet_id"
        case lastSeenLocation = "last_seen_location"
        case lastSeenLatitude = "last_seen_latitude"
        case lastSeenLongitude = "last_seen_longitude"
        case additionalInfo = "additional_info"
    }
}

struct Sighting: Codable, Identifiable {
    let id: String
    let alertId: String
    let reporterName: String?
    let reporterPhone: String?
    let reporterEmail: String?
    let sightingLocation: String?
    let sightingLatitude: Double?
    let sightingLongitude: Double?
    let sightingNotes: String?
    let photoUrl: String?
    let createdAt: String

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = sightingLatitude, let lon = sightingLongitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case alertId = "alert_id"
        case reporterName = "reporter_name"
        case reporterPhone = "reporter_phone"
        case reporterEmail = "reporter_email"
        case sightingLocation = "sighting_location"
        case sightingLatitude = "sighting_latitude"
        case sightingLongitude = "sighting_longitude"
        case sightingNotes = "sighting_notes"
        case photoUrl = "photo_url"
        case createdAt = "created_at"
    }
}

struct ReportSightingRequest: Codable {
    let reporterName: String?
    let reporterPhone: String?
    let reporterEmail: String?
    let sightingLocation: String?
    let sightingLatitude: Double?
    let sightingLongitude: Double?
    let sightingNotes: String?

    enum CodingKeys: String, CodingKey {
        case reporterName = "reporter_name"
        case reporterPhone = "reporter_phone"
        case reporterEmail = "reporter_email"
        case sightingLocation = "sighting_location"
        case sightingLatitude = "sighting_latitude"
        case sightingLongitude = "sighting_longitude"
        case sightingNotes = "sighting_notes"
    }
}
