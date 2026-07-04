import Foundation

/// The signed-in owner's own submissions, ALL statuses (M2). Injectable for tests.
///
/// `/mine` always returns `status`, so these rows have non-nil status. Any status-driven
/// grouping added in M3 must still treat a `nil` status (a read shape that omits it) as
/// "unknown shape", NOT `.pending`, and `.unknown` as "present but unrecognized" — both
/// distinct from `.pending`.
@MainActor
final class MyPetFriendlyPlacesViewModel: ObservableObject {
    @Published private(set) var places: [PetFriendlyPlace] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            places = try await apiService.getMyPetFriendlyPlaces()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
