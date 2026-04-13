import Foundation

/// Public runtime config from GET /api/config.
///
/// Drives client-side gating for behavior the backend can toggle without a
/// release — currently just `tagsAvailable`. Add new flags here as the
/// server gains more remotely-toggled features. Older app builds silently
/// ignore unknown keys (Codable default behavior).
struct AppConfig: Codable {
    let tagsAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case tagsAvailable
    }
}
