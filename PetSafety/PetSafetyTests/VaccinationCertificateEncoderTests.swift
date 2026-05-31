import Testing
import Foundation
import UIKit
@testable import PetSafety

/**
 * Pins the vaccination-certificate encoder's HEIC→JPEG seam (Stage B decision
 * #1). iPhone shoots HEIC by default and an un-transcoded HEIC is a silent
 * backend 415, so this is the headline risk of the cert path — locked here
 * against the picker UI, the PhotoCaptureView refactor, and the network.
 *
 * The HEIC branch transcodes via `UIImage`, whose HEIC decoder is only present
 * in the iOS-sim test target — these run there, not in a plain logic target.
 */
@Suite("Vaccination certificate encoder (HEIC→JPEG seam)")
struct VaccinationCertificateEncoderTests {

    /// A genuine 8×8 HEIC (`ftypheic` / HEVC), produced via
    /// `sips -z 8 8 <png> -s format heic`. Embedded (not a bundle resource) so the
    /// transcode branch runs against real HEIC bytes with zero resource wiring.
    private static let heicBase64 = "AAAAJGZ0eXBoZWljAAAAAG1pZjFNaVBybWlhZk1pSEJoZWljAAABw21ldGEAAAAAAAAAIWhkbHIAAAAAAAAAAHBpY3QAAAAAAAAAAAAAAAAAAAAAJGRpbmYAAAAcZHJlZgAAAAAAAAABAAAADHVybCAAAAABAAAADnBpdG0AAAAAAAEAAAA4aWluZgAAAAAAAgAAABVpbmZlAgAAAAABAABodmMxAAAAABVpbmZlAgAAAQACAABFeGlmAAAAABppcmVmAAAAAAAAAA5jZHNjAAIAAQABAAAA5mlwcnAAAADFaXBjbwAAABNjb2xybmNseAACAAIABoAAAAAMY2xsaQDLAEAAAAAUaXNwZQAAAAAAAAAIAAAACAAAAAlpcm90AAAAABBwaXhpAAAAAAMICAgAAABxaHZjQwEDcAAAALAAAAAAAB7wAPz9+PgAAAsDoAABABdAAQwB//8DcAAAAwCwAAADAAADAB5wJKEAAQAjQgEBA3AAAAMAsAAAAwAAAwAeoBQgQcCbDuIe5FlU3AgIGAKiAAEACUQBwGFyyERTZAAAABlpcG1hAAAAAAAAAAEAAQaBAgMFhoQAAAAsaWxvYwAAAABEAAACAAEAAAABAAACRQAAAGIAAgAAAAEAAAH3AAAATgAAAAFtZGF0AAAAAAAAAMAAAAAGRXhpZgAATU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAtKADAAQAAAABAAAAtAAAAAAAAABeKAGvo8eAD8pAfAApft2rv1oPTd1EHQd79rQ3jN8bxRX4LOQIPGz1u3Nm9BRuEiYfEWLdTg6KGdhdG/JjLq6X2sAZw3//w0v8QlK/oySgHDTff+nuOzVDhcKWXuT52A=="

    private func heicData() throws -> Data {
        try #require(Data(base64Encoded: Self.heicBase64))
    }

    /// A small solid-colour image, used to produce real JPEG/PNG bytes in-test.
    private func solidImage() -> UIImage {
        let r = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        return r.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    @Test("HEIC transcodes to JPEG (the headline branch)")
    func heicTranscodesToJpeg() throws {
        let heic = try heicData()
        let out = try #require(VaccinationCertificateEncoder.encode(heic))
        #expect(out.mime == "image/jpeg")
        #expect(out.data != heic)                       // transcoded, not passed through
        #expect([UInt8](out.data.prefix(2)) == [0xFF, 0xD8])  // genuinely JPEG
        #expect(UIImage(data: out.data) != nil)         // and decodable
    }

    @Test("JPEG passes through untouched")
    func jpegPassThrough() throws {
        let jpeg = try #require(solidImage().jpegData(compressionQuality: 0.9))
        let out = try #require(VaccinationCertificateEncoder.encode(jpeg))
        #expect(out.mime == "image/jpeg")
        #expect(out.data == jpeg)                        // identical bytes — no re-encode
    }

    @Test("PNG passes through untouched")
    func pngPassThrough() throws {
        let png = try #require(solidImage().pngData())
        let out = try #require(VaccinationCertificateEncoder.encode(png))
        #expect(out.mime == "image/png")
        #expect(out.data == png)
    }

    @Test("WebP passes through untouched (magic-byte sniff, no decode)")
    func webpPassThrough() throws {
        var webp = Data("RIFF".utf8)
        webp.append(contentsOf: [0x10, 0x00, 0x00, 0x00]) // chunk size (ignored by sniff)
        webp.append(Data("WEBP".utf8))
        webp.append(Data("VP8 ".utf8))                    // form payload start
        let out = try #require(VaccinationCertificateEncoder.encode(webp))
        #expect(out.mime == "image/webp")
        #expect(out.data == webp)                         // not decoded, passed straight through
    }

    @Test("Empty data returns nil")
    func emptyReturnsNil() {
        #expect(VaccinationCertificateEncoder.encode(Data()) == nil)
    }

    @Test("Undecodable non-image bytes return nil")
    func garbageReturnsNil() {
        let junk = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C])
        #expect(VaccinationCertificateEncoder.encode(junk) == nil)
    }
}
