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
    let alertRadiusKm: Double?
    let lastSeenAt: String?
    let foundAt: String?
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
        case lastSeenAddress = "last_seen_address"
        case lastSeenLatitude = "last_seen_latitude"
        case lastSeenLongitude = "last_seen_longitude"
        case lat
        case lng
        case additionalInfo = "additional_info"
        case description
        case alertRadiusKm = "alert_radius_km"
        case lastSeenAt = "last_seen_at"
        case foundAt = "found_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Memberwise initializer (required since custom decoder/encoder removes auto-synthesis)
    init(
        id: String,
        petId: String,
        userId: String,
        status: String,
        lastSeenLocation: String? = nil,
        lastSeenLatitude: Double? = nil,
        lastSeenLongitude: Double? = nil,
        additionalInfo: String? = nil,
        alertRadiusKm: Double? = 10.0,
        lastSeenAt: String? = nil,
        foundAt: String? = nil,
        createdAt: String,
        updatedAt: String,
        pet: Pet? = nil,
        sightings: [Sighting]? = nil
    ) {
        self.id = id
        self.petId = petId
        self.userId = userId
        self.status = status
        self.lastSeenLocation = lastSeenLocation
        self.lastSeenLatitude = lastSeenLatitude
        self.lastSeenLongitude = lastSeenLongitude
        self.additionalInfo = additionalInfo
        self.alertRadiusKm = alertRadiusKm
        self.lastSeenAt = lastSeenAt
        self.foundAt = foundAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pet = pet
        self.sightings = sightings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        petId = try container.decode(String.self, forKey: .petId)
        userId = try container.decode(String.self, forKey: .userId)
        status = try container.decode(String.self, forKey: .status)
        pet = try container.decodeIfPresent(Pet.self, forKey: .pet)
        sightings = try container.decodeIfPresent([Sighting].self, forKey: .sightings)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)

        let address = try container.decodeIfPresent(String.self, forKey: .lastSeenAddress)
        let legacyLocation = try container.decodeIfPresent(String.self, forKey: .lastSeenLocation)
        lastSeenLocation = address ?? legacyLocation

        let latitude = try container.decodeIfPresent(Double.self, forKey: .lastSeenLatitude)
        let longitude = try container.decodeIfPresent(Double.self, forKey: .lastSeenLongitude)
        let lat = try container.decodeIfPresent(Double.self, forKey: .lat)
        let lng = try container.decodeIfPresent(Double.self, forKey: .lng)
        lastSeenLatitude = latitude ?? lat
        lastSeenLongitude = longitude ?? lng

        let info = try container.decodeIfPresent(String.self, forKey: .additionalInfo)
        let description = try container.decodeIfPresent(String.self, forKey: .description)
        additionalInfo = info ?? description

        // Parse alert radius (default to 10km if not provided)
        alertRadiusKm = try container.decodeIfPresent(Double.self, forKey: .alertRadiusKm) ?? 10.0

        // Parse timestamps
        lastSeenAt = try container.decodeIfPresent(String.self, forKey: .lastSeenAt)
        foundAt = try container.decodeIfPresent(String.self, forKey: .foundAt)
    }

    // Custom encoder (extra CodingKeys are only used for decoding legacy API responses)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(petId, forKey: .petId)
        try container.encode(userId, forKey: .userId)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(lastSeenLocation, forKey: .lastSeenLocation)
        try container.encodeIfPresent(lastSeenLatitude, forKey: .lastSeenLatitude)
        try container.encodeIfPresent(lastSeenLongitude, forKey: .lastSeenLongitude)
        try container.encodeIfPresent(additionalInfo, forKey: .additionalInfo)
        try container.encodeIfPresent(alertRadiusKm, forKey: .alertRadiusKm)
        try container.encodeIfPresent(lastSeenAt, forKey: .lastSeenAt)
        try container.encodeIfPresent(foundAt, forKey: .foundAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(pet, forKey: .pet)
        try container.encodeIfPresent(sightings, forKey: .sightings)
    }
}

struct CreateAlertRequest: Codable {
    let petId: String
    let lastSeenLocation: LocationCoordinate?
    let lastSeenAddress: String?
    let description: String?
    let rewardAmount: Double?
    let alertRadiusKm: Double?

    enum CodingKeys: String, CodingKey {
        case petId = "petId"
        case lastSeenLocation = "lastSeenLocation"
        case lastSeenAddress = "lastSeenAddress"
        case description
        case rewardAmount
        case alertRadiusKm
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
        case sightingAddress = "sighting_address"
        case sightingLatitude = "sighting_latitude"
        case sightingLongitude = "sighting_longitude"
        case sightingNotes = "sighting_notes"
        case description
        case photoUrl = "photo_url"
        case createdAt = "created_at"
        case reportedAt = "reported_at"
    }

    // Memberwise initializer (required since custom decoder/encoder removes auto-synthesis)
    init(
        id: String,
        alertId: String,
        reporterName: String? = nil,
        reporterPhone: String? = nil,
        reporterEmail: String? = nil,
        sightingLocation: String? = nil,
        sightingLatitude: Double? = nil,
        sightingLongitude: Double? = nil,
        sightingNotes: String? = nil,
        photoUrl: String? = nil,
        createdAt: String
    ) {
        self.id = id
        self.alertId = alertId
        self.reporterName = reporterName
        self.reporterPhone = reporterPhone
        self.reporterEmail = reporterEmail
        self.sightingLocation = sightingLocation
        self.sightingLatitude = sightingLatitude
        self.sightingLongitude = sightingLongitude
        self.sightingNotes = sightingNotes
        self.photoUrl = photoUrl
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        alertId = try container.decode(String.self, forKey: .alertId)
        reporterName = try container.decodeIfPresent(String.self, forKey: .reporterName)
        reporterPhone = try container.decodeIfPresent(String.self, forKey: .reporterPhone)
        reporterEmail = try container.decodeIfPresent(String.self, forKey: .reporterEmail)
        let created = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        let reported = try? container.decodeIfPresent(String.self, forKey: .reportedAt)
        createdAt = created ?? reported ?? ""
        photoUrl = try? container.decodeIfPresent(String.self, forKey: .photoUrl)

        let address = try? container.decodeIfPresent(String.self, forKey: .sightingAddress)
        let location = try? container.decodeIfPresent(String.self, forKey: .sightingLocation)
        sightingLocation = address ?? location ?? nil

        sightingLatitude = try? container.decodeIfPresent(Double.self, forKey: .sightingLatitude)
        sightingLongitude = try? container.decodeIfPresent(Double.self, forKey: .sightingLongitude)

        let notes = try? container.decodeIfPresent(String.self, forKey: .sightingNotes)
        let description = try? container.decodeIfPresent(String.self, forKey: .description)
        sightingNotes = notes ?? description ?? nil
    }

    // Custom encoder (extra CodingKeys are only used for decoding legacy API responses)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(alertId, forKey: .alertId)
        try container.encodeIfPresent(reporterName, forKey: .reporterName)
        try container.encodeIfPresent(reporterPhone, forKey: .reporterPhone)
        try container.encodeIfPresent(reporterEmail, forKey: .reporterEmail)
        try container.encodeIfPresent(sightingLocation, forKey: .sightingLocation)
        try container.encodeIfPresent(sightingLatitude, forKey: .sightingLatitude)
        try container.encodeIfPresent(sightingLongitude, forKey: .sightingLongitude)
        try container.encodeIfPresent(sightingNotes, forKey: .sightingNotes)
        try container.encodeIfPresent(photoUrl, forKey: .photoUrl)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

struct ReportSightingRequest: Codable {
    let reporterName: String?
    let reporterPhone: String?
    let reporterEmail: String?
    let location: LocationCoordinate?
    let address: String?
    let description: String?
    let photoUrl: String?
    let sightedAt: String?

    enum CodingKeys: String, CodingKey {
        case reporterName
        case reporterPhone
        case reporterEmail
        case location
        case address
        case description
        case photoUrl
        case sightedAt
    }
}
