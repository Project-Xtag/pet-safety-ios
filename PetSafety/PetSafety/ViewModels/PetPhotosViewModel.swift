import Foundation
import SwiftUI
import PhotosUI

/// ViewModel for managing pet photos
@MainActor
class PetPhotosViewModel: ObservableObject {
    @Published var photos: [PetPhoto] = []
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    // MARK: - Fetch Photos

    /// Load all photos for a pet
    func loadPhotos(for petId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.getPetPhotos(petId: petId)
            photos = response.photos.sorted { $0.displayOrder < $1.displayOrder }

            #if DEBUG
            print("✅ Loaded \(photos.count) photos for pet \(petId)")
            #endif
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load photos: \(error)")
            #endif
        }

        isLoading = false
    }

    // MARK: - Upload Photo

    /// Upload a single photo
    func uploadPhoto(for petId: String, imageData: Data, isPrimary: Bool = false) async -> Bool {
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        defer { isUploading = false }

        do {
            let response = try await apiService.uploadPetPhotoToGallery(
                petId: petId,
                imageData: imageData,
                isPrimary: isPrimary
            )

            // Add new photo to the list
            photos.append(response.photo)
            // Sort by display order
            photos.sort { $0.displayOrder < $1.displayOrder }

            uploadProgress = 1.0

            #if DEBUG
            print("✅ Photo uploaded successfully: \(response.photo.id)")
            #endif

            return true
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to upload photo: \(error)")
            #endif
            return false
        }

    }

    /// Upload multiple photos with progress tracking
    func uploadPhotos(for petId: String, imageDataArray: [Data]) async -> (succeeded: Int, failed: Int) {
        isUploading = true
        var succeeded = 0
        var failed = 0
        let total = imageDataArray.count

        for (index, imageData) in imageDataArray.enumerated() {
            let success = await uploadPhoto(for: petId, imageData: imageData)

            if success {
                succeeded += 1
            } else {
                failed += 1
            }

            // Update progress
            uploadProgress = Double(index + 1) / Double(total)
        }

        isUploading = false
        uploadProgress = 0.0

        return (succeeded, failed)
    }

    // MARK: - Set Primary Photo

    /// Set a photo as the primary photo
    func setPrimaryPhoto(petId: String, photoId: String) async -> Bool {
        errorMessage = nil

        do {
            let response = try await apiService.setPrimaryPhoto(petId: petId, photoId: photoId)

            // Update local photos array
            for index in photos.indices {
                photos[index] = PetPhoto(
                    id: photos[index].id,
                    petId: photos[index].petId,
                    photoUrl: photos[index].photoUrl,
                    isPrimary: photos[index].id == photoId,
                    displayOrder: photos[index].displayOrder,
                    uploadedAt: photos[index].uploadedAt
                )
            }

            #if DEBUG
            print("✅ Set photo \(photoId) as primary")
            #endif

            return true
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to set primary photo: \(error)")
            #endif
            return false
        }
    }

    // MARK: - Delete Photo

    /// Delete a photo
    func deletePhoto(petId: String, photoId: String) async -> Bool {
        errorMessage = nil

        do {
            let response = try await apiService.deletePetPhoto(petId: petId, photoId: photoId)

            // Remove from local array
            photos.removeAll { $0.id == photoId }

            #if DEBUG
            print("✅ Deleted photo \(photoId)")
            #endif

            return true
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to delete photo: \(error)")
            #endif
            return false
        }
    }

    // MARK: - Reorder Photos

    /// Reorder photos by dragging
    func reorderPhotos(petId: String) async -> Bool {
        errorMessage = nil

        // Get current photo IDs in display order
        let photoIds = photos.map { $0.id }

        do {
            let response = try await apiService.reorderPetPhotos(petId: petId, photoIds: photoIds)

            if let updatedPhotos = response.photos {
                photos = updatedPhotos.sorted { $0.displayOrder < $1.displayOrder }

                #if DEBUG
                print("✅ Photos reordered successfully")
                #endif

                return true
            }

            return false
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to reorder photos: \(error)")
            #endif
            return false
        }
    }

    /// Move photo in local array (for immediate UI feedback)
    func movePhoto(from source: IndexSet, to destination: Int) {
        photos.move(fromOffsets: source, toOffset: destination)

        // Update display order locally
        for (index, photo) in photos.enumerated() {
            photos[index] = PetPhoto(
                id: photo.id,
                petId: photo.petId,
                photoUrl: photo.photoUrl,
                isPrimary: photo.isPrimary,
                displayOrder: index,
                uploadedAt: photo.uploadedAt
            )
        }
    }

    // MARK: - Helper Methods

    /// Get the primary photo
    var primaryPhoto: PetPhoto? {
        photos.first { $0.isPrimary }
    }

    /// Check if there are any photos
    var hasPhotos: Bool {
        !photos.isEmpty
    }

    /// Get photo count
    var photoCount: Int {
        photos.count
    }
}
