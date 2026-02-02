import Foundation
import UIKit

@MainActor
class PetsViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOfflineMode = false

    private let apiService = APIService.shared
    private let offlineManager = OfflineDataManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private let syncService = SyncService.shared

    func fetchPets() async {
        isLoading = true
        errorMessage = nil
        isOfflineMode = !networkMonitor.isConnected

        do {
            if networkMonitor.isConnected {
                // Fetch from API when online
                pets = try await apiService.getPets()
                // Sync cache: remove pets not in API response, then save current pets
                let cachedPets = (try? offlineManager.fetchPets()) ?? []
                let apiPetIds = Set(pets.map { $0.id })
                for cachedPet in cachedPets {
                    if !apiPetIds.contains(cachedPet.id) {
                        try? offlineManager.deletePet(withId: cachedPet.id)
                    }
                }
                try offlineManager.savePets(pets)
            } else {
                // Load from local cache when offline
                pets = try offlineManager.fetchPets()
                errorMessage = "Showing cached data (offline)"
            }
            isLoading = false
        } catch {
            isLoading = false
            // Try to load from cache if API fails
            do {
                pets = try offlineManager.fetchPets()
                errorMessage = "Showing cached data (failed to connect)"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func createPet(_ petData: CreatePetRequest) async throws -> Pet {
        isLoading = true
        errorMessage = nil

        do {
            let newPet = try await apiService.createPet(petData)
            pets.append(newPet)
            isLoading = false
            return newPet
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func updatePet(id: String, updates: UpdatePetRequest) async throws -> Pet {
        isLoading = true
        errorMessage = nil

        do {
            let updatedPet = try await apiService.updatePet(id: id, updates)
            if let index = pets.firstIndex(where: { $0.id == id }) {
                pets[index] = updatedPet
            }
            isLoading = false
            return updatedPet
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func deletePet(id: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            try await apiService.deletePet(id: id)
            pets.removeAll { $0.id == id }
            // Also remove from offline cache
            try? offlineManager.deletePet(withId: id)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func uploadPhoto(for petId: String, image: UIImage) async throws -> Pet {
        isLoading = true
        errorMessage = nil

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            isLoading = false
            throw NSError(domain: "PetsViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }

        do {
            let updatedPet = try await apiService.uploadPetPhoto(petId: petId, imageData: imageData)
            if let index = pets.firstIndex(where: { $0.id == petId }) {
                pets[index] = updatedPet
            }
            isLoading = false
            return updatedPet
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Mark pet as missing and optionally create alert
    /// Queues action if offline
    func markPetMissing(
        petId: String,
        location: LocationCoordinate? = nil,
        address: String? = nil,
        description: String? = nil,
        rewardAmount: Double? = nil,
        notificationCenterSource: String? = nil,
        notificationCenterLocation: LocationCoordinate? = nil,
        notificationCenterAddress: String? = nil
    ) async throws -> MarkMissingResponse {
        isLoading = true
        errorMessage = nil

        // If offline, queue the action
        if !networkMonitor.isConnected {
            var actionData: [String: Any] = ["petId": petId]
            if let location = location {
                actionData["latitude"] = location.lat
                actionData["longitude"] = location.lng
            }
            if let address = address {
                actionData["lastSeenAddress"] = address
            }
            if let description = description {
                actionData["description"] = description
            }
            if let notificationCenterSource = notificationCenterSource {
                actionData["notificationCenterSource"] = notificationCenterSource
            }
            if let notificationCenterLocation = notificationCenterLocation {
                actionData["notificationCenterLatitude"] = notificationCenterLocation.lat
                actionData["notificationCenterLongitude"] = notificationCenterLocation.lng
            }
            if let notificationCenterAddress = notificationCenterAddress {
                actionData["notificationCenterAddress"] = notificationCenterAddress
            }

            _ = try await syncService.queueAction(type: .markPetLost, data: actionData)

            // Update local pet status
            if let index = pets.firstIndex(where: { $0.id == petId }) {
                let updatedPet = pets[index]
                // Create a new Pet instance with updated isMissing status
                let newPet = Pet(
                    id: updatedPet.id,
                    ownerId: updatedPet.ownerId,
                    name: updatedPet.name,
                    species: updatedPet.species,
                    breed: updatedPet.breed,
                    color: updatedPet.color,
                    weight: updatedPet.weight,
                    microchipNumber: updatedPet.microchipNumber,
                    medicalNotes: updatedPet.medicalNotes,
                    notes: updatedPet.notes,
                    profileImage: updatedPet.profileImage,
                    isMissing: true,
                    createdAt: updatedPet.createdAt,
                    updatedAt: updatedPet.updatedAt,
                    ageYears: updatedPet.ageYears,
                    ageMonths: updatedPet.ageMonths,
                    ageText: updatedPet.ageText,
                    ageIsApproximate: updatedPet.ageIsApproximate,
                    allergies: updatedPet.allergies,
                    medications: updatedPet.medications,
                    uniqueFeatures: updatedPet.uniqueFeatures,
                    sex: updatedPet.sex,
                    isNeutered: updatedPet.isNeutered,
                    qrCode: updatedPet.qrCode,
                    dateOfBirth: updatedPet.dateOfBirth,
                    ownerName: updatedPet.ownerName,
                    ownerPhone: updatedPet.ownerPhone,
                    ownerEmail: updatedPet.ownerEmail
                )
                pets[index] = newPet
                try offlineManager.savePet(newPet)
            }

            isLoading = false
            errorMessage = "Action queued. Will sync when online."
            // Return a mock response for offline mode
            throw NSError(domain: "Offline", code: 0, userInfo: [NSLocalizedDescriptionKey: "Queued for sync"])
        }

        do {
            let response = try await apiService.markPetMissing(
                petId: petId,
                location: location,
                address: address,
                description: description,
                rewardAmount: rewardAmount,
                notificationCenterSource: notificationCenterSource,
                notificationCenterLocation: notificationCenterLocation,
                notificationCenterAddress: notificationCenterAddress
            )

            // Update local pet list and cache
            if let index = pets.firstIndex(where: { $0.id == petId }) {
                pets[index] = response.pet
                try? offlineManager.savePet(response.pet)
            }

            isLoading = false
            return response
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Mark pet as found
    /// Queues action if offline
    func markPetFound(petId: String) async throws -> Pet {
        isLoading = true
        errorMessage = nil

        // If offline, queue the action
        if !networkMonitor.isConnected {
            let actionData: [String: Any] = [
                "petId": petId,
                "alertId": "" // Will need to lookup alert ID during sync
            ]

            _ = try await syncService.queueAction(type: .markPetFound, data: actionData)

            // Update local pet status
            if let index = pets.firstIndex(where: { $0.id == petId }) {
                let updatedPet = pets[index]
                let newPet = Pet(
                    id: updatedPet.id,
                    ownerId: updatedPet.ownerId,
                    name: updatedPet.name,
                    species: updatedPet.species,
                    breed: updatedPet.breed,
                    color: updatedPet.color,
                    weight: updatedPet.weight,
                    microchipNumber: updatedPet.microchipNumber,
                    medicalNotes: updatedPet.medicalNotes,
                    notes: updatedPet.notes,
                    profileImage: updatedPet.profileImage,
                    isMissing: false,
                    createdAt: updatedPet.createdAt,
                    updatedAt: updatedPet.updatedAt,
                    ageYears: updatedPet.ageYears,
                    ageMonths: updatedPet.ageMonths,
                    ageText: updatedPet.ageText,
                    ageIsApproximate: updatedPet.ageIsApproximate,
                    allergies: updatedPet.allergies,
                    medications: updatedPet.medications,
                    uniqueFeatures: updatedPet.uniqueFeatures,
                    sex: updatedPet.sex,
                    isNeutered: updatedPet.isNeutered,
                    qrCode: updatedPet.qrCode,
                    dateOfBirth: updatedPet.dateOfBirth,
                    ownerName: updatedPet.ownerName,
                    ownerPhone: updatedPet.ownerPhone,
                    ownerEmail: updatedPet.ownerEmail
                )
                pets[index] = newPet
                try offlineManager.savePet(newPet)
            }

            isLoading = false
            errorMessage = "Action queued. Will sync when online."
            throw NSError(domain: "Offline", code: 0, userInfo: [NSLocalizedDescriptionKey: "Queued for sync"])
        }

        do {
            let updatedPet = try await apiService.markPetFound(petId: petId)

            // Update local pet list and cache
            if let index = pets.firstIndex(where: { $0.id == petId }) {
                pets[index] = updatedPet
                try? offlineManager.savePet(updatedPet)
            }

            isLoading = false
            return updatedPet
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
