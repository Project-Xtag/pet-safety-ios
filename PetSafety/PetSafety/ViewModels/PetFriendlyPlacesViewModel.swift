import Foundation

/// Nearby pet-friendly places for the public discovery map/list (M2). Injectable
/// `apiService` for testability (mirrors `AlertsViewModel`, NOT the untestable
/// `LostAndFoundViewModel`). `market` is resolved by the caller from the user's country.
@MainActor
final class PetFriendlyPlacesViewModel: ObservableObject {
    @Published private(set) var places: [PetFriendlyPlace] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// 404 from the flag gate = feature not launched for this market — a DISTINCT state
    /// from an empty result (`200 + []`), so the UI shows region copy, not an error.
    @Published private(set) var notInMarket = false
    /// nil = all categories. `.unknown` is never offered as a filter.
    @Published var selectedCategory: PetFriendlyPlace.Category?

    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    /// Client-side category filter — the nearby list is radius-bounded, so we fetch all
    /// and filter locally (instant toggling, no refetch).
    var filteredPlaces: [PetFriendlyPlace] {
        guard let selectedCategory else { return places }
        return places.filter { $0.category == selectedCategory }
    }

    func loadNearby(latitude: Double, longitude: Double, radiusKm: Double = 10, market: String) async {
        isLoading = true
        errorMessage = nil
        notInMarket = false
        do {
            places = try await apiService.getNearbyPetFriendlyPlaces(
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm,
                category: nil,          // fetch all; filter client-side
                market: market
            )
        } catch APIError.notFound {
            // Flag off for this market (distinct from `200 + []`).
            notInMarket = true
            places = []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
