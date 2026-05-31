import Foundation
import SwiftUI
import UIKit
import PhotosUI

/// Turns arbitrary picked image bytes into an upload-ready `(data, mime)` pair
/// for the vaccination certificate endpoint, which accepts **JPEG / PNG / WebP
/// only** (Stage B decision #1).
///
/// The three accepted formats pass through **untouched** — sniffed by magic
/// bytes, so a PNG screenshot or an already-JPEG photo is never needlessly
/// re-encoded. Anything else (HEIC/HEIF — the iPhone camera default; TIFF; …) is
/// transcoded to JPEG via `UIImage`'s decoder. iPhone shoots HEIC by default and
/// an un-transcoded HEIC is a silent backend 415, so this branch is the headline
/// risk of the cert path.
///
/// **Pure and side-effect-free**: `Data` in, `(data, mime)?` out, no
/// PhotosPicker and no network — so the HEIC→JPEG branch is unit-testable from
/// raw byte fixtures. NOTE: the transcode leans on `UIImage`'s HEIC decoder,
/// which is only present in the **iOS-sim test target** (not a plain logic-test
/// target) — run the encoder tests there.
enum VaccinationCertificateEncoder {

    /// JPEG quality for transcoded output. 0.85 keeps a 12 MP photo ~1–2 MB,
    /// comfortably under the backend's 10 MB cap.
    static let defaultJpegQuality: CGFloat = 0.85

    /// Returns upload-ready bytes + MIME, or `nil` if `data` is empty or isn't a
    /// decodable image (so the caller can surface a clean "couldn't read that
    /// image" rather than POSTing garbage).
    static func encode(_ data: Data, jpegQuality: CGFloat = defaultJpegQuality) -> (data: Data, mime: String)? {
        guard !data.isEmpty else { return nil }

        // Accepted formats pass through verbatim — no re-encode.
        if isJPEG(data) { return (data, "image/jpeg") }
        if isPNG(data)  { return (data, "image/png") }
        if isWebP(data) { return (data, "image/webp") }

        // HEIC/HEIF/TIFF/anything else → transcode to JPEG via UIImage's decoder.
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: jpegQuality) else {
            return nil
        }
        return (jpeg, "image/jpeg")
    }

    // MARK: - Magic-byte sniffing
    //
    // Indices normalized to 0-based via `[UInt8](prefix(...))` so a sliced `Data`
    // (non-zero `startIndex`) can't throw off the comparisons.

    private static func isJPEG(_ d: Data) -> Bool {
        let b = [UInt8](d.prefix(2))
        return b.count == 2 && b[0] == 0xFF && b[1] == 0xD8
    }

    private static func isPNG(_ d: Data) -> Bool {
        let b = [UInt8](d.prefix(8))
        return b.elementsEqual([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    }

    /// WebP = RIFF container with a "WEBP" form type: bytes 0–3 "RIFF", 8–11
    /// "WEBP" (4–7 are the chunk size, ignored). Sniff only — pass-through does
    /// not decode, so this never needs a WebP codec.
    private static func isWebP(_ d: Data) -> Bool {
        guard d.count >= 12 else { return false }
        let b = [UInt8](d.prefix(12))
        return Array(b[0...3]).elementsEqual(Array("RIFF".utf8))
            && Array(b[8...11]).elementsEqual(Array("WEBP".utf8))
    }
}

extension PhotosPickerItem {
    /// Upload-ready bytes + MIME for the certificate endpoint. A thin wrapper:
    /// loads the picked bytes and hands them to `VaccinationCertificateEncoder`
    /// (JPEG/PNG/WebP pass through; HEIC/HEIF and anything else → JPEG). Returns
    /// `nil` if the picker delivered no bytes or they aren't a decodable image.
    ///
    /// The transcode logic lives in the encoder (pure, unit-tested); this wrapper
    /// is just the PhotosPicker glue.
    func loadAsUploadable(
        jpegQuality: CGFloat = VaccinationCertificateEncoder.defaultJpegQuality
    ) async -> (data: Data, mime: String)? {
        guard let raw = try? await loadTransferable(type: Data.self) else { return nil }
        return VaccinationCertificateEncoder.encode(raw, jpegQuality: jpegQuality)
    }
}

extension UIImage {
    /// Upload-ready `(data, mime)` for a camera capture (which hands back a
    /// `UIImage`, not raw file bytes — so it's always JPEG-encoded here). Mirrors
    /// `PhotosPickerItem.loadAsUploadable` for the camera source.
    func certificateUploadable(
        jpegQuality: CGFloat = VaccinationCertificateEncoder.defaultJpegQuality
    ) -> (data: Data, mime: String)? {
        guard let jpeg = jpegData(compressionQuality: jpegQuality) else { return nil }
        return (jpeg, "image/jpeg")
    }
}
