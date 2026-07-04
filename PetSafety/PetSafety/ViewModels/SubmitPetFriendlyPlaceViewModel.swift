import Foundation

/// Owner submission form state + submit (M2). The three failure surfaces are DISTINCT
/// (per review): `duplicate` (409, dedicated dialog), `addressError` (422 geocode,
/// pinned to the address field), and `formError` (everything else). A 409/422 is NEVER
/// collapsed into the generic error, and the backend 409 string is never shown
/// (`APIError.duplicatePlace` already reduced it to `existing`).
@MainActor
final class SubmitPetFriendlyPlaceViewModel: ObservableObject {
    // Form fields (the View binds these).
    @Published var category: PetFriendlyPlace.Category?
    @Published var name = ""
    @Published var address = ""
    @Published var phone = ""
    @Published var website = ""
    @Published var introduction = ""
    @Published var city = ""
    @Published var postcode = ""

    @Published private(set) var isSubmitting = false
    @Published private(set) var formError: String?
    @Published private(set) var addressError: String?
    @Published private(set) var duplicate: DuplicateMatch?
    /// 429 daily-cap hit — drives a prominent "limit reached" popup, distinct from formError.
    @Published private(set) var rateLimited = false

    /// 409 dedup result for the dialog. `existingName == nil` is the place_id 23505
    /// backstop shape (no name); the dialog shows generic copy in that case.
    struct DuplicateMatch: Identifiable, Equatable {
        let id = UUID()
        let existingName: String?
    }

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    /// category chosen + name/address non-empty. `.unknown` is never offered, so a nil
    /// category is the only "not chosen" state.
    var canSubmit: Bool {
        category != nil
        && !name.trimmed.isEmpty
        && !address.trimmed.isEmpty
    }

    /// Clears the 409 result once its dialog is acknowledged (the View can't write a
    /// `private(set)` property directly).
    func acknowledgeDuplicate() {
        duplicate = nil
    }

    /// Clears the 429 popup once acknowledged (the View can't write a `private(set)` property).
    func acknowledgeRateLimited() {
        rateLimited = false
    }

    /// Submits and returns the created pending place, or nil on failure (state published).
    func submit() async -> SubmittedPetFriendlyPlace? {
        formError = nil
        addressError = nil
        duplicate = nil
        rateLimited = false

        guard let category, category != .unknown else {
            formError = String(localized: "pet_friendly_submit_error_category_required")
            return nil
        }

        let payload = CreatePetFriendlyPlaceRequest(
            category: category.rawValue,
            name: name.trimmed,
            address: address.trimmed,
            phone: phone.trimmedOrNil,
            website: website.trimmedOrNil,
            introduction: introduction.trimmedOrNil,
            city: city.trimmedOrNil,
            postcode: postcode.trimmedOrNil,
            country: nil    // HU-implicit, Phase 1 (matches the web submit page)
        )

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            return try await apiService.createPetFriendlyPlace(payload)
        } catch APIError.duplicatePlace(let existing) {
            duplicate = DuplicateMatch(existingName: existing)   // distinct — dialog
            return nil
        } catch APIError.geocodeFailed(let message) {
            addressError = message                                // distinct — address field
            return nil
        } catch APIError.rateLimited {
            rateLimited = true                                    // distinct — daily-cap popup
            return nil
        } catch {
            formError = error.localizedDescription
            return nil
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedOrNil: String? {
        let t = trimmed
        return t.isEmpty ? nil : t
    }
}
