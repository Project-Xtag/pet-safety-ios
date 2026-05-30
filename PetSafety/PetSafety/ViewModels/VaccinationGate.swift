import Foundation
import SwiftUI

/// Single source of truth for whether the Senra vaccination feature is available
/// to the current user. Resolved **once** from the home-summary call and shared
/// app-wide.
///
/// Why one app-level object: three surfaces gate on the same answer — the home
/// summary card, the pet-detail vaccinations section, and every "add record"
/// affordance. Per Stage B decision #2, the feature-off signal (a 404 from the
/// summary endpoint) must be interpreted in exactly ONE place and shared, never
/// re-derived per surface. Scattered 404 checks are how the gate leaks.
///
/// The distinction this object encodes (Stage B decisions #2 & #6):
///   • summary 404            → `.off` → hide EVERY vaccination surface
///   • summary 200 (any data) → `.on`  → surfaces available; emptiness is a
///                                        per-surface DISPLAY concern, not a gate
///
/// A 404 from any *other* vaccination call (CRUD `GET/PUT/DELETE /:id`, list,
/// catalog) is a genuine resource/ownership not-found and is NOT interpreted
/// here — only the summary call drives feature availability.
@MainActor
final class VaccinationGate: ObservableObject {

    /// The resolved availability. Starts `.unknown` (fail-closed: every surface
    /// stays hidden until we have a definitive answer).
    @Published private(set) var availability: VaccinationAvailability = .unknown

    /// True when the last `resolve()` failed for a transient reason (network /
    /// decoding / 5xx) rather than a definitive 404. Lets a surface offer a quiet
    /// retry without flipping a previously-known answer to off.
    @Published private(set) var lastLoadFailed = false

    private let apiService = APIService.shared

    /// Resolve the gate from the summary call. Idempotent and safe to call from
    /// multiple surfaces (home appears, pet-detail appears) — the last successful
    /// resolution wins.
    ///
    /// - A **404** (`APIError.notFound`) is the feature-off signal — the ONLY
    ///   place we treat a 404 as "off".
    /// - Any **other** failure leaves `availability` unchanged (we never clobber a
    ///   known answer on a transient error) and sets `lastLoadFailed`.
    func resolve() async {
        do {
            let summary = try await apiService.fetchVaccinationSummary()
            availability = .on(summary)
            lastLoadFailed = false
        } catch let error as APIError {
            if case .notFound = error {
                availability = .off          // feature off for this user/country
                lastLoadFailed = false
            } else {
                lastLoadFailed = true        // transient API error — keep prior answer
            }
        } catch {
            lastLoadFailed = true            // network / decoding — keep prior answer
        }
    }

    /// Re-resolve after a mutation (create/update/delete/cert on any pet) so the
    /// home card reflects new urgent rows / counts. Same path as `resolve()`.
    func refresh() async { await resolve() }

    /// Clear back to `.unknown` on sign-out / account switch.
    ///
    /// The gate must be resolved **per auth session**, not once per process: the
    /// device litmus walk logs out of one account and into another on the same
    /// handset, and a sticky answer would let the second account inherit the
    /// first's state (a false read). The composition layer resets here on logout
    /// and re-`resolve()`s on the new session. `.unknown` (not `.off`) is correct
    /// — the new account's availability is genuinely not-yet-known and should be
    /// re-fetched, not assumed off.
    func reset() {
        availability = .unknown
        lastLoadFailed = false
    }
}

/// The three states a surface gates on. Derived solely from the summary call.
enum VaccinationAvailability: Equatable {
    /// Not yet resolved (initial / after a transient failure). Treated as hidden.
    case unknown
    /// Summary returned 404 — feature off for this user (flag / country gate).
    case off
    /// Summary returned 200 — feature on; payload carries counts + `urgent[]`.
    case on(VaccinationHomeSummary)

    /// Is the feature reachable at all? Gates the **pet-detail section** and
    /// **every add CTA**. `.unknown` and `.off` both hide (fail-closed).
    var isOn: Bool {
        if case .on = self { return true }
        return false
    }

    /// The summary payload when on, else nil.
    var summary: VaccinationHomeSummary? {
        if case .on(let s) = self { return s }
        return nil
    }

    /// Should the HOME summary card render?
    ///
    /// Decision #6: feature-on-but-empty (no pets with any vaccination records)
    /// hides the home card — but NOT the pet-detail section / add CTA (that's
    /// `isOn`). Any records present → show the card.
    ///
    /// `VaccinationHomeSummary.isEmpty` is exactly the on-empty case
    /// (`totalPetsWithVaccinations == 0`). The card's internal
    /// variants when shown ("X expiring" rows vs an "all up to date ✓"
    /// reassurance state when records exist but none are urgent) are a screen
    /// concern for the home-card build; the gate only answers off / on-empty /
    /// on-populated.
    var showsHomeCard: Bool {
        guard case .on(let s) = self else { return false }
        return !s.isEmpty
    }
}
