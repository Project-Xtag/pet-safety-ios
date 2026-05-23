import Foundation

/// A community-submitted "I found this stray" report.
///
/// Mirrors the web app's `CommunityFoundPet` interface and the backend's
/// `community_found_pets` table. Optional contact fields are nullable
/// because anonymous reporters are allowed.
struct CommunityFoundPet: Codable, Identifiable, Hashable {
    let id: String
    let species: Species
    let sex: Sex
    let breed: String?
    let color: String?
    let description: String?
    let photoUrl: String?
    let foundAt: Date
    let foundLatitude: Double
    let foundLongitude: Double
    let foundAddress: String?
    let status: Status
    let reporterName: String?
    let reporterEmail: String?
    let reporterPhone: String?
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date
    /// Only populated when fetched via the "nearby" endpoint.
    let distanceKm: Double?

    enum Species: String, Codable, CaseIterable, Hashable {
        case dog
        case cat
        case other
    }

    enum Sex: String, Codable, CaseIterable, Hashable {
        case male
        case female
        case unknown
    }

    enum Status: String, Codable, Hashable {
        case active
        case reunited
        case expired
        case removed
    }

    enum CodingKeys: String, CodingKey {
        case id, species, sex, breed, color, description
        case photoUrl
        case foundAt
        case foundLatitude
        case foundLongitude
        case foundAddress
        case status
        case reporterName
        case reporterEmail
        case reporterPhone
        case createdAt
        case updatedAt
        case expiresAt
        case distanceKm
    }
}

/// Persistence helper for the "I can manage what I submitted" UX:
/// the backend issues a single-use `manageToken` per anonymous submission
/// that lets the same device cancel/mark-reunited later without an account.
/// Stored in UserDefaults under key "senra_found_pet_tokens" — mirrors the
/// web's localStorage entry of the same name.
struct FoundPetManageToken: Codable, Hashable {
    let id: String
    let token: String
}

enum FoundPetManageTokenStore {
    private static let userDefaultsKey = "senra_found_pet_tokens"

    static func load() -> [FoundPetManageToken] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let tokens = try? JSONDecoder().decode([FoundPetManageToken].self, from: data) else {
            return []
        }
        return tokens
    }

    static func append(_ entry: FoundPetManageToken) {
        var current = load()
        // De-dupe on id — a re-submission for the same report shouldn't
        // grow the array unbounded.
        current.removeAll { $0.id == entry.id }
        current.append(entry)
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    static func remove(id: String) {
        let filtered = load().filter { $0.id != id }
        if let data = try? JSONEncoder().encode(filtered) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
