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

/// `{ success, data: { places } }` wrapper. Pet-friendly now uses the STANDARD app-wide
/// `{ success, data }` envelope like every other endpoint — verified against prod
/// 2026-07-04 (it originally shipped flat `{ success, places }`; the backend converged it
/// onto the envelope). The methods stay on `enveloped: false` so create's typed 409/422
/// handling (the `where !enveloped` branches) is preserved, and model the `data` wrapper
/// here. `places` is REQUIRED inside `data`: a renamed/missing key fails decode and surfaces
/// an error instead of a silent empty map — the mobile mirror of the web `|| []` un-mask.
struct PetFriendlyPlacesResponse: Decodable {
    let success: Bool
    let data: DataBlock
    struct DataBlock: Decodable { let places: [PetFriendlyPlace] }
}

/// `{ success, data: { place } }` wrapper for the id-detail read (returns full coords).
struct PetFriendlyPlaceResponse: Decodable {
    let success: Bool
    let data: DataBlock
    struct DataBlock: Decodable { let place: PetFriendlyPlace }
}

/// The create-201 body's `place`. DELIBERATELY separate from `PetFriendlyPlace`: the backend's
/// `INSERT … RETURNING` (`petFriendlyPlace.routes.ts:218`) echoes only
///   `id, category, name, introduction, phone, website, address, city, postcode, country, status`
/// — NO lat/lng/timestamps — so decoding it into the coord-required `PetFriendlyPlace` throws
/// (`keyNotFound` on `lat`). We only need it to confirm the pending submit (id/name/status), so we
/// model exactly what the wire returns. `id`, `category`, `name`, `address`, `status` are NOT-NULL
/// columns → non-optional; the rest nullable. Field names match the JSON keys, so no CodingKeys.
///
/// (This is the fix for the pre-existing latent throw: the old code reused `PetFriendlyPlace` here
/// and would have failed decode on a real 201 — masked by the test mocks' pre-built objects.)
struct SubmittedPetFriendlyPlace: Decodable, Equatable {
    let id: String
    let category: PetFriendlyPlace.Category
    let name: String
    let address: String
    let status: PetFriendlyPlace.Status

    let introduction: String?
    let phone: String?
    let website: String?
    let city: String?
    let postcode: String?
    let country: String?
}

/// `{ success, data: { place } }` wrapper for the create 201. `place` is REQUIRED (same un-mask).
struct SubmitPetFriendlyPlaceResponse: Decodable {
    let success: Bool
    let data: DataBlock
    struct DataBlock: Decodable { let place: SubmittedPetFriendlyPlace }
}
