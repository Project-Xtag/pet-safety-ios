import Foundation

/// U4 — the web-handoff exchange. `WEB-HANDOFF-CONTRACT.md` §1, FROZEN at
/// `fdf0d570c218`.
///
/// ⚠️ §8 freezes the request field **names** and the `destination` values. A
/// rename here is a store cycle, not a refactor. The decoder is a plain
/// `JSONDecoder` with no key strategy, so the snake_case wire names are spelled
/// out rather than derived.
struct WebHandoffRequest: Encodable {
    /// §2's enum. v1 sends `choose_plan` only; reserved values return 400 and
    /// the client falls back, which is deliberate — a client landing somewhere
    /// it did not ask for is worse than a client falling back.
    let destination: String

    /// §3/§9.4 — a **language** signal, never a market one. The server may use
    /// it to pick copy; it must never reach country-segment resolution. Optional
    /// by contract: absent means "no preference".
    let localeHint: String?

    enum CodingKeys: String, CodingKey {
        case destination
        case localeHint = "locale_hint"
    }
}

/// §1's 200 body. Flat, not `ApiEnvelope`-wrapped.
struct WebHandoffResponse: Decodable {
    /// The absolute URL the client opens. §8 freezes *that the response carries
    /// `url`* — the host, country segment and path inside it stay server-side
    /// and changeable without a store cycle. The client must not parse meaning
    /// out of it.
    let url: String

    /// Advisory only; the client does not enforce it. Optional so a server that
    /// stops sending it cannot break a fielded client.
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case url
        case expiresIn = "expires_in"
    }
}

/// Destination values from §2's frozen enum. Only `.choosePlan` ships in v1.
enum WebHandoffDestination: String {
    case choosePlan = "choose_plan"
    // Reserved (§2). Present so the frozen enum is visible at the call site,
    // but not sent by v1 — the server returns 400 for each and the client
    // falls back.
    case manageSubscription = "manage_subscription"
    case account
    case orders
}
