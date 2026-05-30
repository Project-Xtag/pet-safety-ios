import Foundation

/// One entry in the admin-curated vaccine catalog, as returned by
/// `GET /api/vaccines/catalog?species=&country=`.
///
/// The endpoint is locale-aware: `display_name` / `description` are already
/// resolved server-side from the request's `Accept-Language`, so the client
/// just renders them. Pickers show `display_name` and submit `code` verbatim
/// (the code is opaque — never parse or construct it).
struct VaccineCatalogEntry: Codable, Identifiable, Hashable {
    /// The opaque catalog code (e.g. "rabies_dog_hu") doubles as the stable id.
    var id: String { code }

    let code: String
    let displayName: String
    let description: String?
    let isCore: Bool
    let defaultValidityMonths: Int?
    let minAgeWeeks: Int?
    let rabiesSpecific: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case code
        case displayName = "display_name"
        case description
        case isCore = "is_core"
        case defaultValidityMonths = "default_validity_months"
        case minAgeWeeks = "min_age_weeks"
        case rabiesSpecific = "rabies_specific"
        case sortOrder = "sort_order"
    }
}

/// Envelope contents for the catalog endpoint (`data.vaccines`).
struct VaccineCatalogResponse: Codable {
    let vaccines: [VaccineCatalogEntry]
}
