import Foundation

/// A pet from a tag order that still needs setup — auto-registered
/// (name only) at order time, with no active tag yet. The setup wizard
/// completes the pet's details and activates the scanned tag for it.
struct UnactivatedOrderItem: Codable, Identifiable {
    var id: String { petId }
    let petId: String
    let petName: String

    enum CodingKeys: String, CodingKey {
        case petId = "pet_id"
        case petName = "pet_name"
    }
}

struct UnactivatedTagsResponse: Codable {
    let unactivated: [UnactivatedOrderItem]
}
