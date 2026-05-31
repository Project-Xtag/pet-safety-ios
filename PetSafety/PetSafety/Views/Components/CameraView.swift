import SwiftUI
import UIKit

/// Camera capture wrapped as a SwiftUI view — presents `UIImagePickerController`
/// with the camera source and hands back the captured `UIImage`.
///
/// Relocated out of `PhotoGalleryView` so it's a shared primitive: the photo
/// gallery, and the vaccination certificate-capture flow (`PhotoCaptureView`),
/// both reuse it instead of duplicating the representable. Behavior is unchanged
/// from the original — `.originalImage`, dismiss on capture/cancel.
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
