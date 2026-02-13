import Foundation

// MARK: - Base SSE Event
struct SSEEvent: Codable {
    let type: String
    let timestamp: Date?
}

// MARK: - Tag Scanned Event
struct TagScannedEvent: Codable {
    let petId: String
    let petName: String
    let qrCode: String
    let location: Location
    let address: String?
    let scannedAt: Date

    struct Location: Codable {
        let lat: Double
        let lng: Double
    }
}

// MARK: - Sighting Reported Event
struct SightingReportedEvent: Codable {
    let alertId: String
    let petId: String
    let petName: String
    let sightingId: String
    let location: Location
    let address: String?
    let reportedAt: Date
    let reporterName: String?

    struct Location: Codable {
        let lat: Double
        let lng: Double
    }
}

// MARK: - Pet Found Event
struct PetFoundEvent: Codable {
    let petId: String
    let petName: String
    let alertId: String?
    let foundAt: Date
}

// MARK: - Alert Created Event
struct AlertCreatedEvent: Codable {
    let alertId: String
    let petId: String
    let petName: String
    let location: Location
    let address: String
    let createdAt: Date

    struct Location: Codable {
        let lat: Double
        let lng: Double
    }
}

// MARK: - Alert Updated Event
struct AlertUpdatedEvent: Codable {
    let alertId: String
    let petId: String
    let petName: String
    let status: String
    let updatedAt: Date
}

// MARK: - Subscription Changed Event
struct SubscriptionChangedEvent: Codable {
    let planName: String
    let status: String
    let billingPeriod: String?
    let expiresAt: String?
}

// MARK: - Referral Used Event
struct ReferralUsedEvent: Codable {
    let refereeName: String?
    let refereeEmail: String?
}

// MARK: - Connection Event
struct ConnectionEvent: Codable {
    let userId: String
    let connectedAt: Date
}
