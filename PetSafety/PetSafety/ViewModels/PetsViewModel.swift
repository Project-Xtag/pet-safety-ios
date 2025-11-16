import Foundation
import UIKit

@MainActor
class PetsViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchPets() async {
        isLoading = true
        errorMessage = nil

        do {
            pets = try await apiService.getPets()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
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
}
