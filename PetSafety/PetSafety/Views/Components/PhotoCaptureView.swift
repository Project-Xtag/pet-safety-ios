import SwiftUI
import PhotosUI
import UIKit

/// A single-image capture control: tap the provided label → choose Photo Library
/// or Camera → emits the raw selection. Built for the vaccination
/// certificate-capture flow (the cert path needs camera, to photograph a paper
/// record); reuses the relocated `CameraView`.
///
/// **UI-only.** It emits the selection and does NO post-processing — the consumer
/// decides what to do with it. The cert path runs the result through
/// `VaccinationCertificateEncoder` (via `loadAsUploadable` / `certificateUploadable`)
/// to get upload-ready `(data, mime)`; a different consumer could handle it
/// differently. Keeping the encoder out of here is deliberate: this component
/// must not silently impose transcoding on any caller.
///
/// Scope note: the four existing library-only photo pickers (pet form, profile,
/// found-pet, setup wizard) are intentionally NOT routed through this — they
/// share only a thin PhotosPicker+decode seam and diverge on trigger UI and
/// post-pick handling, so folding them in would be churn/regression risk for no
/// real dedup. The genuinely shared asset was `CameraView`, now relocated.
struct PhotoCaptureView<Label: View>: View {
    @ViewBuilder var label: () -> Label
    /// Fired with the user's raw selection. Library picks arrive as a
    /// `PhotosPickerItem` (bytes loaded lazily by the consumer); camera captures
    /// arrive as a decoded `UIImage`.
    var onCapture: (CapturedImage) -> Void

    @State private var showingSourceDialog = false
    @State private var showingLibrary = false
    @State private var showingCamera = false
    @State private var pickerItem: PhotosPickerItem?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        Button {
            // No camera (simulator / camera-less device) → skip the one-option
            // dialog and go straight to the library.
            if cameraAvailable { showingSourceDialog = true } else { showingLibrary = true }
        } label: {
            label()
        }
        .confirmationDialog(Text("choose_photo_source"), isPresented: $showingSourceDialog) {
            Button("take_photo") { showingCamera = true }
            Button("choose_from_gallery") { showingLibrary = true }
            Button("cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingLibrary, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newValue in
            guard let newValue else { return }
            onCapture(.picker(newValue))
            pickerItem = nil   // reset so re-picking the same asset fires again
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(isPresented: $showingCamera) { image in
                onCapture(.camera(image))
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

/// The raw output of `PhotoCaptureView` — the consumer post-processes per its
/// own needs (the cert path → `VaccinationCertificateEncoder`).
enum CapturedImage {
    case picker(PhotosPickerItem)
    case camera(UIImage)
}
