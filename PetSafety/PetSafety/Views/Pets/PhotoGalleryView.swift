import SwiftUI
import PhotosUI
import UIKit

/// Photo Gallery View for displaying and managing pet photos
struct PhotoGalleryView: View {
    let pet: Pet
    @StateObject private var viewModel = PetPhotosViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var showingSourcePicker = false
    @State private var showingCamera = false
    @State private var showingDeleteConfirmation = false
    @State private var photoToDelete: PetPhoto?
    @State private var isProcessingImages = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with pet info
                    VStack(spacing: 8) {
                        Text(String(format: NSLocalizedString("pet_photos_title", comment: ""), pet.name))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        if viewModel.hasPhotos {
                            Text("photo_count \(viewModel.photoCount)")
                                .font(.system(size: 15))
                                .foregroundColor(.mutedText)
                        }
                    }
                    .padding(.top)

                    // Upload button
                    Button(action: { showingSourcePicker = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                            Text("add_photos")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isUploading ? Color.tealAccent.opacity(0.5) : Color.tealAccent)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .disabled(viewModel.isUploading)

                    // Upload progress
                    if viewModel.isUploading {
                        VStack(spacing: 8) {
                            ProgressView(value: viewModel.uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .tint(.brandOrange)

                            if viewModel.totalUploadCount > 1 {
                                Text("photo_uploading_count \(viewModel.uploadedCount) \(viewModel.totalUploadCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("photo_uploading")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("\(Int(viewModel.uploadProgress * 100))%")
                                .font(.caption2.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    // Photo grid
                    if viewModel.isLoading {
                        ProgressView("loading_photos")
                            .padding(.top, 50)
                    } else if viewModel.hasPhotos {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.photos) { photo in
                                PhotoGridItem(
                                    photo: photo,
                                    onSetPrimary: {
                                        Task {
                                            let success = await viewModel.setPrimaryPhoto(
                                                petId: pet.id,
                                                photoId: photo.id
                                            )
                                            if success {
                                                appState.showSuccess(String(localized: "photo_primary_updated"))
                                            } else {
                                                appState.showError(String(localized: "photo_primary_failed"))
                                            }
                                        }
                                    },
                                    onDelete: {
                                        photoToDelete = photo
                                        showingDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Edit mode hint
                        Text("photo_tip")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 20) {
                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(Color(UIColor.systemGray6))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 44))
                                    .foregroundColor(.tealAccent)
                            }

                            Text("no_photos_yet")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)

                            Text(String(format: NSLocalizedString("add_photos_gallery_hint", comment: ""), pet.name))
                                .font(.system(size: 15))
                                .foregroundColor(.mutedText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)

                            Spacer()
                        }
                        .padding(.top, 50)
                    }

                    Spacer(minLength: 100)
                }
            }

        }
        .navigationTitle(Text("photo_gallery_title"))
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedItems,
            maxSelectionCount: 10,
            matching: .images
        )
        .onChange(of: selectedItems) { _ in
            processSelectedPhotos()
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(isPresented: $showingCamera) { image in
                processSelectedImage(image)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .confirmationDialog(Text("choose_photo_source"), isPresented: $showingSourcePicker) {
            Button("take_photo") {
                showingCamera = true
            }
            Button("choose_from_gallery") {
                showingImagePicker = true
            }
            Button("cancel", role: .cancel) {}
        }
        .alert(Text("delete_photo"), isPresented: $showingDeleteConfirmation) {
            Button("cancel", role: .cancel) {}
            Button("delete", role: .destructive) {
                if let photo = photoToDelete {
                    deletePhoto(photo)
                }
            }
        } message: {
            Text("delete_photo_confirm")
        }
        .task {
            await viewModel.loadPhotos(for: pet.id)
        }
        .refreshable {
            await viewModel.loadPhotos(for: pet.id)
        }
    }

    // MARK: - Helper Methods

    private func processSelectedPhotos() {
        guard !selectedItems.isEmpty else { return }

        isProcessingImages = true

        Task {
            var imagesToUpload: [Data] = []

            for item in selectedItems {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    // Compress image if needed
                    if let compressedData = compressImageIfNeeded(data) {
                        imagesToUpload.append(compressedData)
                    }
                }
            }

            if !imagesToUpload.isEmpty {
                let (succeeded, failed) = await viewModel.uploadPhotos(
                    for: pet.id,
                    imageDataArray: imagesToUpload
                )

                if succeeded > 0 {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    appState.showSuccess(String(format: String(localized: "photo_upload_success"), succeeded))
                }

                if failed > 0 {
                    appState.showError(String(format: String(localized: "photo_upload_failed"), failed))
                }
            }

            selectedItems = []
            isProcessingImages = false
        }
    }

    private func processSelectedImage(_ image: UIImage) {
        Task {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let compressedData = compressImageIfNeeded(imageData) ?? imageData

                let success = await viewModel.uploadPhoto(for: pet.id, imageData: compressedData)

                if success {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    appState.showSuccess(String(localized: "photo_uploaded"))
                } else {
                    appState.showError(viewModel.errorMessage ?? String(localized: "photo_upload_single_failed"))
                }
            }
        }
    }

    private func compressImageIfNeeded(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        // Max dimension: 1200px
        let maxDimension: CGFloat = 1200
        let size = image.size

        if size.width <= maxDimension && size.height <= maxDimension {
            return data
        }

        let ratio = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage?.jpegData(compressionQuality: 0.8)
    }

    private func deletePhoto(_ photo: PetPhoto) {
        Task {
            let success = await viewModel.deletePhoto(petId: pet.id, photoId: photo.id)

            if success {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                appState.showSuccess(String(localized: "photo_deleted"))
            } else {
                appState.showError(viewModel.errorMessage ?? String(localized: "photo_delete_failed"))
            }
        }
    }
}

// MARK: - Photo Grid Item

struct PhotoGridItem: View {
    let photo: PetPhoto
    let onSetPrimary: () -> Void
    let onDelete: () -> Void

    @State private var showingFullScreen = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo
            CachedAsyncImage(url: URL(string: photo.photoUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()
            } placeholder: {
                ProgressView()
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
            }
            .cornerRadius(12)
            .onTapGesture {
                showingFullScreen = true
            }
            .contextMenu {
                Button {
                    onSetPrimary()
                } label: {
                    Label("primary", systemImage: "star.fill")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("delete", systemImage: "trash")
                }
            }

            // Primary badge
            if photo.isPrimary {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text("primary")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.brandOrange)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(8)
            }
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            FullScreenPhotoView(photo: photo, isPresented: $showingFullScreen)
        }
    }
}

// MARK: - Full Screen Photo View

struct FullScreenPhotoView: View {
    let photo: PetPhoto
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            CachedAsyncImage(url: URL(string: photo.photoUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PhotoGalleryView(pet: Pet(
            id: "1",
            ownerId: "1",
            name: "Max",
            species: "Dog",
            breed: "Golden Retriever",
            color: "Golden",
            weight: 30.0,
            microchipNumber: "123456789",
            medicalNotes: "Allergic to chicken",
            notes: "Friendly with kids",
            profileImage: nil,
            isMissing: false,
            createdAt: "",
            updatedAt: ""
        ))
        .environmentObject(AppState())
    }
}
