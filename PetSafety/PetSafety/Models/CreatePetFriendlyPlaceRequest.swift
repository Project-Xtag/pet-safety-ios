import Foundation

/// Body for `POST /api/pet-friendly-places` (authenticated owner submission). Plain
/// JSON — no multipart (unlike the found-pet report). Field caps are enforced
/// server-side (`createPlaceSchema` in `petFriendlyPlace.routes.ts`): `name` ≤150 and
/// `address` ≤500 required; `phone` ≤32, `website` ≤500, `introduction` ≤2000,
/// `city` ≤120, `postcode` ≤20, `country` ≤80 optional. `category` is the raw slug
/// (e.g. "cafe_bar"); the submit form only offers real categories, never `.unknown`.
///
/// `country` is deliberately still sendable here (the backend accepts it) but Phase-1
/// submit omits it — HU-implicit, matching the web submit page; the server stores
/// `country = null` and geocodes bare. Revisit for market #2.
struct CreatePetFriendlyPlaceRequest: Codable {
    let category: String
    let name: String
    let address: String
    let phone: String?
    let website: String?
    let introduction: String?
    let city: String?
    let postcode: String?
    let country: String?
}
