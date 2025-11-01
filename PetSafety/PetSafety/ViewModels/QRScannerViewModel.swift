import Foundation
import AVFoundation

@MainActor
class QRScannerViewModel: ObservableObject {
    @Published var scannedCode: String?
    @Published var scanResult: ScanResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var cameraPermissionGranted = false

    private let apiService = APIService.shared

    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                }
            }
        default:
            cameraPermissionGranted = false
        }
    }

    func scanQRCode(_ code: String) async {
        scannedCode = code
        isLoading = true
        errorMessage = nil

        do {
            scanResult = try await apiService.scanQRCode(code)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func activateTag(code: String, petId: Int) async throws {
        isLoading = true
        errorMessage = nil

        let request = ActivateTagRequest(tagCode: code, petId: petId)

        do {
            _ = try await apiService.activateTag(request)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func reset() {
        scannedCode = nil
        scanResult = nil
        errorMessage = nil
    }
}
