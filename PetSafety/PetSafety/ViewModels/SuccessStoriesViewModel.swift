import Foundation
import CoreLocation

@MainActor
class SuccessStoriesViewModel: ObservableObject {
    @Published var stories: [SuccessStory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMore = false
    @Published var currentPage = 1
    @Published var totalStories = 0

    private let apiService = APIService.shared
    private let offlineManager = OfflineDataManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private let syncService = SyncService.shared

    /// Fetch success stories near a location
    func fetchSuccessStories(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 10,
        page: Int = 1,
        loadMore: Bool = false
    ) async {
        // Prevent multiple simultaneous loads
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            if networkMonitor.isConnected {
                // Fetch from API when online
                let response = try await apiService.getPublicSuccessStories(
                    latitude: latitude,
                    longitude: longitude,
                    radiusKm: radiusKm,
                    page: page,
                    limit: 10
                )

                if loadMore {
                    // Append to existing stories
                    stories.append(contentsOf: response.stories)
                } else {
                    // Replace stories
                    stories = response.stories
                }

                hasMore = response.hasMore
                currentPage = response.page
                totalStories = response.total

                // Cache the data locally
                for story in response.stories {
                    try? offlineManager.saveSuccessStory(story)
                }
            } else {
                // Load from local cache when offline
                stories = try offlineManager.fetchSuccessStories()
                errorMessage = "Showing cached data (offline)"
            }

            isLoading = false
        } catch {
            isLoading = false
            // Try to load from cache if API fails
            do {
                stories = try offlineManager.fetchSuccessStories()
                errorMessage = "Showing cached data (failed to connect)"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Load more stories (pagination)
    func loadMore(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 10
    ) async {
        guard hasMore && !isLoading else { return }
        await fetchSuccessStories(
            latitude: latitude,
            longitude: longitude,
            radiusKm: radiusKm,
            page: currentPage + 1,
            loadMore: true
        )
    }

    /// Get success stories for a specific pet
    func fetchStoriesForPet(petId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            stories = try await apiService.getSuccessStoriesForPet(petId: petId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    /// Create a new success story
    func createSuccessStory(
        petId: String,
        alertId: String? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        city: String? = nil,
        storyText: String? = nil,
        autoConfirm: Bool = false
    ) async throws -> SuccessStory {
        isLoading = true
        errorMessage = nil

        let request = CreateSuccessStoryRequest(
            petId: petId,
            alertId: alertId,
            reunionLatitude: coordinate?.latitude,
            reunionLongitude: coordinate?.longitude,
            reunionCity: city,
            storyText: storyText,
            autoConfirm: autoConfirm
        )

        do {
            let newStory = try await apiService.createSuccessStory(request)
            stories.insert(newStory, at: 0)
            isLoading = false
            return newStory
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Update a success story
    func updateSuccessStory(
        id: String,
        storyText: String? = nil,
        isPublic: Bool? = nil,
        isConfirmed: Bool? = nil
    ) async throws {
        isLoading = true
        errorMessage = nil

        let updates = UpdateSuccessStoryRequest(
            storyText: storyText,
            isPublic: isPublic,
            isConfirmed: isConfirmed
        )

        do {
            let updatedStory = try await apiService.updateSuccessStory(id: id, updates: updates)

            // Update the story in the array
            if let index = stories.firstIndex(where: { $0.id == id }) {
                stories[index] = updatedStory
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Delete a success story
    func deleteSuccessStory(id: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            try await apiService.deleteSuccessStory(id: id)

            // Remove from local array
            stories.removeAll { $0.id == id }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Upload a photo for a success story
    func uploadPhoto(storyId: String, imageData: Data) async throws -> SuccessStoryPhoto {
        isLoading = true
        errorMessage = nil

        do {
            let photo = try await apiService.uploadSuccessStoryPhoto(storyId: storyId, imageData: imageData)
            isLoading = false
            return photo
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Confirm a success story (make it public)
    func confirmStory(id: String) async throws {
        try await updateSuccessStory(id: id, isPublic: true, isConfirmed: true)
    }
}
