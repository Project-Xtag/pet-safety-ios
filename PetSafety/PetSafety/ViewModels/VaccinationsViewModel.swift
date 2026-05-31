import Foundation
import SwiftUI

/// Per-pet vaccination data (list + catalog + CRUD) for the pet-detail
/// vaccinations section and its child screens.
///
/// IMPORTANT — this VM does **not** decide whether the feature is available.
/// That is `VaccinationGate`'s job (the single source of truth, derived from the
/// summary call). The pet-detail section and add CTA are rendered by the view
/// only when `VaccinationGate.isOn`, so this VM is only ever driven while the
/// feature is on.
///
/// Consequently a 404 from any call here is a **genuine** resource/ownership
/// not-found, never a feature-off signal (Stage B locked decision). We surface a
/// generic `loadFailed` flag — never the server's localized 404 string — so no
/// surface can accidentally render "Vaccination record not found." as UI copy.
@MainActor
final class VaccinationsViewModel: ObservableObject {

    @Published private(set) var vaccinations: [Vaccination] = []
    @Published private(set) var catalog: [VaccineCatalogEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadFailed = false   // generic; localized copy lives in the view
    @Published private(set) var inFlight = false      // create/update/delete in progress
    /// Localized, user-facing message for a failed mutation (create/update) — set
    /// from the server's 400 (e.g. the rabies-floor `age_too_young`). Distinct
    /// from `loadFailed`: a *load* 404 = feature-off/not-found and must NEVER
    /// surface the server string, whereas a *create* 400 is a validation result
    /// the server localized for the user. Settable so a form can clear it.
    @Published var actionError: String?

    private let apiService = APIService.shared
    let petId: String

    /// Fired once after **any** successful CRUD mutation (create/update/delete).
    /// The VM stays gate-agnostic — it doesn't know what this does. The view
    /// binds it once to `{ Task { await gate.refresh() } }`, so one hook keeps the
    /// home card in sync instead of scattering `gate.refresh()` across call sites
    /// (and forgetting one). The server already busts the summary cache on all
    /// five mutation paths, so the client just needs this single re-fetch.
    var onDidMutate: (() -> Void)?

    init(petId: String) { self.petId = petId }

    // MARK: - Reads

    func load() async {
        isLoading = true
        loadFailed = false
        defer { isLoading = false }
        do {
            vaccinations = try await apiService.fetchVaccinations(petId: petId)
        } catch {
            // A 404 here is genuine not-found / ownership — NOT feature-off. The
            // gate already established the feature is on before this rendered.
            loadFailed = true
        }
    }

    /// Catalog for the add/edit form picker. A failure is non-fatal: the form can
    /// fall back to its no-catalog state rather than blocking entry.
    func loadCatalog(species: String, country: String) async {
        do {
            catalog = try await apiService.fetchVaccineCatalog(species: species, country: country)
        } catch {
            catalog = []
        }
    }

    /// Client-side status for a CRUD list row. Rows carry **no** server status, so
    /// we derive it (same `<30`-day boundary the server uses on `summary.urgent[]`,
    /// verified against the server's `7` / `-2`). Thin passthrough to the model's
    /// own derivation so there's a single boundary definition.
    func status(for vaccination: Vaccination) -> VaccinationStatus {
        vaccination.status
    }

    // MARK: - Writes
    //
    // Thin, gate-agnostic wrappers over the (already-shipped) API layer. They
    // return success so the view can drive its own dismissal / error copy, and
    // the composition layer can trigger `VaccinationGate.refresh()` on success to
    // keep the home card in sync (see review note — refresh ownership is the one
    // open question).

    /// Returns the created record on success (so the caller can chain a
    /// certificate upload against its id), nil on failure (with `actionError` set
    /// to a user-facing message — the rabies-floor 400 surfaces here).
    func create(_ body: CreateVaccinationRequest) async -> Vaccination? {
        inFlight = true
        actionError = nil
        defer { inFlight = false }
        do {
            let created = try await apiService.createVaccination(petId: petId, body: body)
            vaccinations.insert(created, at: 0)
            onDidMutate?()
            return created
        } catch {
            actionError = Self.actionMessage(for: error)
            return nil
        }
    }

    @discardableResult
    func update(id: String, _ body: UpdateVaccinationRequest) async -> Bool {
        inFlight = true
        actionError = nil
        defer { inFlight = false }
        do {
            let updated = try await apiService.updateVaccination(petId: petId, vaccinationId: id, body: body)
            if let i = vaccinations.firstIndex(where: { $0.id == id }) {
                vaccinations[i] = updated
            }
            onDidMutate?()
            return true
        } catch {
            actionError = Self.actionMessage(for: error)
            return false
        }
    }

    @discardableResult
    func delete(id: String) async -> Bool {
        inFlight = true
        actionError = nil
        defer { inFlight = false }
        do {
            try await apiService.deleteVaccination(petId: petId, vaccinationId: id)
            vaccinations.removeAll { $0.id == id }
            onDidMutate?()
            return true
        } catch {
            actionError = Self.actionMessage(for: error)
            return false
        }
    }

    /// Upload a certificate image for a record. Updates the local row from the
    /// response so the attachment shows immediately in the list/detail — and
    /// deliberately does NOT fire `onDidMutate`: a certificate doesn't change the
    /// home summary (expiry/status are untouched), so a refresh would be wasted.
    @discardableResult
    func uploadCertificate(vaccinationId: String, data: Data, mime: String) async -> Bool {
        inFlight = true
        defer { inFlight = false }
        do {
            let url = try await apiService.uploadVaccinationCertificate(
                petId: petId, vaccinationId: vaccinationId, data: data, mime: mime
            )
            if let i = vaccinations.firstIndex(where: { $0.id == vaccinationId }) {
                vaccinations[i] = vaccinations[i].withCertificate(url: url, mime: mime)
            }
            return true
        } catch {
            return false
        }
    }

    /// Map a mutation error to a user-facing message. A 404 here is
    /// feature-off / not-found — never surface the server's localized 404 string
    /// (Stage B rule); everything else (notably a validation 400 such as the
    /// rabies floor) carries the server's localized message, meant for the user.
    private static func actionMessage(for error: Error) -> String {
        if case APIError.notFound = error { return String(localized: "vaccinations_action_failed") }
        return (error as? APIError)?.errorDescription ?? String(localized: "vaccinations_action_failed")
    }
}
