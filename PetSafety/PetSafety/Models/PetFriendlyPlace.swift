import Foundation
import CoreLocation

/// A community-submitted pet-friendly place (café/bar, restaurant, hotel, beach, other).
///
/// ONE Codable model shared across the three read shapes the backend serves
/// (`petFriendlyPlace.routes.ts`): the nearby list, the id-detail, and `/mine`.
/// Which optional fields are populated depends on the endpoint:
///   - nearby → `distanceKm` present; `postcode`/`country`/`status`/timestamps absent
///   - detail → `postcode`/`country` present; `distanceKm`/`status`/timestamps absent
///   - /mine  → `status`/`createdAt`/`updatedAt` present; `distanceKm` absent
///
/// NIL-COLLAPSE: optional fields use Swift's synthesized optional decoding
/// (`decodeIfPresent`), so an ABSENT key and an explicit `null` both collapse to
/// `nil` — the model can't (and needn't) distinguish "this endpoint omits the field"
/// from "the field is null".
///
/// REQUIRED vs optional: `id`, `category`, `name`, `address`, `latitude`, `longitude`
/// are NON-optional — the backend guarantees them on every read (`address` is
/// required-on-submit and never nulled by an edit, so every stored row has one), so a
/// missing one is real shape drift and SHOULD fail decode (→ `APIError.decodingError`)
/// rather than silently defaulting. Same stance as the web `|| []` un-mask.
struct PetFriendlyPlace: Codable, Identifiable, Hashable {
    let id: String
    let category: Category
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

    let introduction: String?
    let phone: String?
    let website: String?
    let city: String?
    let postcode: String?
    let country: String?
    /// Nearby endpoint only — great-circle distance from the query point (km).
    let distanceKm: Double?
    /// `/mine` only — the owner may see their own moderation state.
    let status: Status?
    let createdAt: Date?
    let updatedAt: Date?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Backend `category` enum (20260701_01 CHECK). `.unknown` is a SYNTHETIC fallback:
    /// an unrecognised value (e.g. a category added server-side later) decodes here
    /// instead of throwing, so one new category can't break the whole list decode. Never
    /// sent by the client. (The existing `CommunityFoundPet` enums throw on unknowns —
    /// this is a deliberate hardening.)
    enum Category: String, Codable, CaseIterable, Hashable {
        case cafeBar = "cafe_bar"
        case restaurant
        case hotel
        case beach
        case other
        case unknown

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Category(rawValue: raw) ?? .unknown
        }
    }

    /// Owner-visible moderation state (`/mine`). `.unknown` fallback as above.
    enum Status: String, Codable, Hashable {
        case pending
        case approved
        case rejected
        case unknown

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Status(rawValue: raw) ?? .unknown
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, category, name, introduction, phone, website, address, city, postcode, country, status
        case latitude = "lat"
        case longitude = "lng"
        case distanceKm = "distance_km"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Flat `{ success, places }` wrapper. Pet-friendly endpoints are web-style FLAT
/// responses, NOT the `ApiEnvelope<T>` `{ data }` shape the mobile-era endpoints use —
/// which is why the API methods pass `enveloped: false`. `places` is REQUIRED: a
/// renamed/missing key fails decode and surfaces an error instead of a silent empty
/// map — the mobile mirror of the web `|| []` un-mask.
struct PetFriendlyPlacesResponse: Decodable {
    let success: Bool
    let places: [PetFriendlyPlace]
}

/// Flat `{ success, place }` wrapper (id-detail + create 201).
struct PetFriendlyPlaceResponse: Decodable {
    let success: Bool
    let place: PetFriendlyPlace
}
