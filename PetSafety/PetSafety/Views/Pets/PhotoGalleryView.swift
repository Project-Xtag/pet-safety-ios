import SwiftUI
import PhotosUI

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
                        Text("\(pet.name)'s Photos")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        if viewModel.hasPhotos {
                            Text("\(viewModel.photoCount) photo\(viewModel.photoCount == 1 ? "" : "s")")
                                .font(.system(size: 15))
                                .foregroundColor(.mutedText)
                        }
                    }
                    .padding(.top)

                    // Upload button
                    Button(action: { showingSourcePicker = true }) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text("Add Photos")
                        }
                    }
                    .buttonStyle(BrandButtonStyle(isDisabled: viewModel.isUploading))
                    .padding(.horizontal)
                    .disabled(viewModel.isUploading)

                    // Upload progress
                    if viewModel.isUploading {
                        VStack(spacing: 8) {
                            ProgressView(value: viewModel.uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle())

                            Text("Uploading photos...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    // Photo grid
                    if viewModel.isLoading {
                        ProgressView("Loading photos...")
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
                                                appState.showSuccess("Primary photo updated")
                                            } else {
                                                appState.showError("Failed to set primary photo")
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
                        Text("Tip: Long press a photo to set as primary or delete")
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

                            Text("No photos yet")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Add photos to create a gallery for \(pet.name)")
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

            // Camera view overlay
            if showingCamera {
                CameraView(isPresented: $showingCamera) { image in
                    processSelectedImage(image)
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
        .navigationTitle("Photo Gallery")
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
        .confirmationDialog("Choose Photo Source", isPresented: $showingSourcePicker) {
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Photo", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let photo = photoToDelete {
                    deletePhoto(photo)
                }
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
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
                    appState.showSuccess("\(succeeded) photo\(succeeded == 1 ? "" : "s") uploaded successfully")
                }

                if failed > 0 {
                    appState.showError("\(failed) photo\(failed == 1 ? "" : "s") failed to upload")
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
                    appState.showSuccess("Photo uploaded successfully")
                } else {
                    appState.showError(viewModel.errorMessage ?? "Failed to upload photo")
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
                appState.showSuccess("Photo deleted")
            } else {
                appState.showError(viewModel.errorMessage ?? "Failed to delete photo")
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
            AsyncImage(url: URL(string: photo.photoUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))

                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()

                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))

                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(12)
            .onTapGesture {
                showingFullScreen = true
            }
            .contextMenu {
                Button {
                    onSetPrimary()
                } label: {
                    Label("Set as Primary", systemImage: "star.fill")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            // Primary badge
            if photo.isPrimary {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text("Primary")
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

            AsyncImage(url: URL(string: photo.photoUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)

                case .empty:
                    ProgressView()

                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.white)

                @unknown default:
                    EmptyView()
                }
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
