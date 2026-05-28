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

    /// Activate a tag against an EXISTING pet (replacement tag, or
    /// legacy wizard path where the pet was auto-created at order).
    func activateTag(code: String, petId: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await apiService.activateTag(qrCode: code, petId: petId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Post-2026-05-24 first-tag flow: create the pet AND activate
    /// the tag atomically. The wizard calls this when the order's
    /// pending registration has no pre-existing petId.
    func activateTagWithNewPet(code: String, petData: CreatePetRequest) async throws -> QRTag {
        isLoading = true
        errorMessage = nil

        do {
            let tag = try await apiService.activateTag(qrCode: code, petData: petData)
            isLoading = false
            return tag
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
