import Foundation

/// A pet from a tag order that still needs setup. Post the 2026-05-24
/// auto-create revert, the pet row does NOT yet exist — `petId` will
/// be nil and the wizard's atomic /qr-tags/activate call (with a
/// petData payload) creates the pet AND activates the tag in one
/// shot. Pre-revert TestFlight users may still hit servers that
/// return a non-nil placeholder petId; the wizard falls back to the
/// update-then-activate path in that case.
struct UnactivatedOrderItem: Codable, Identifiable {
    var id: String { petId ?? petName }
    let petId: String?
    let petName: String

    enum CodingKeys: String, CodingKey {
        case petId = "pet_id"
        case petName = "pet_name"
    }
}

struct UnactivatedTagsResponse: Codable {
    let unactivated: [UnactivatedOrderItem]
}
