import Foundation

/// Cross-pet vaccination summary for the home screen, from
/// `GET /api/users/me/vaccinations/summary` (envelope: `data.summary`).
///
/// Surface rules (Stage B decisions #2/#6) are driven off this call:
/// - HTTP **404** → feature is OFF for this user; hide every vaccination
///   surface (handled at the `APIService` layer by throwing, not here).
/// - **200** with `totalPetsWithVaccinations == 0` and empty `urgent` →
///   feature is ON but the user has no records yet; hide only the home card,
///   keep the pet-detail section + add CTAs.
struct VaccinationHomeSummary: Codable, Hashable {
    let totalPetsWithVaccinations: Int
    let expiredCount: Int
    let expiring30dCount: Int
    let validCount: Int
    /// Up to 3 most-urgent records across all pets (expired first, then
    /// soonest-expiring). Empty when nothing is within 30 days of expiry.
    let urgent: [UrgentVaccination]

    enum CodingKeys: String, CodingKey {
        case totalPetsWithVaccinations = "total_pets_with_vaccinations"
        case expiredCount = "expired_count"
        case expiring30dCount = "expiring_30d_count"
        case validCount = "valid_count"
        case urgent
    }

    /// True when the feature is on but there's nothing to show on the home
    /// card (no records at all). Distinct from the 404 feature-off case.
    ///
    /// Keyed off `totalPetsWithVaccinations` (are there ANY records?), **never**
    /// off `urgent`. An "all valid" user — records exist, none within 30 days —
    /// must stay NON-empty so the home card still shows its "all up to date"
    /// state (Stage B decision #6). Keying off `urgent.isEmpty` would silently
    /// flip that case to hidden and half-collapse #6. Do not change this line.
    var isEmpty: Bool {
        totalPetsWithVaccinations == 0
    }

    struct UrgentVaccination: Codable, Identifiable, Hashable {
        var id: String { vaccinationId }

        let petId: String
        let petName: String
        let petProfileImage: String?
        let vaccinationId: String
        let vaccineName: String
        let expiresAt: String
        /// Signed: negative = overdue. Branch on `status`; use the magnitude
        /// for "N days overdue" copy (never render "expires in −3 days").
        let daysUntilExpiry: Int
        let status: VaccinationStatus

        enum CodingKeys: String, CodingKey {
            case petId = "pet_id"
            case petName = "pet_name"
            case petProfileImage = "pet_profile_image"
            case vaccinationId = "vaccination_id"
            case vaccineName = "vaccine_name"
            case expiresAt = "expires_at"
            case daysUntilExpiry = "days_until_expiry"
            case status
        }
    }
}

/// Envelope contents for the summary endpoint (`data.summary`).
struct VaccinationSummaryResponse: Codable {
    let summary: VaccinationHomeSummary
}
