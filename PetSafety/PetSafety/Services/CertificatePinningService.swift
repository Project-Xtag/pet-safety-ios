//
//  CertificatePinningService.swift
//  PetSafety
//
//  Created by Pet Safety Team on 2026-01-30.
//  TLS Certificate Pinning for secure API communication
//

import Foundation
import CommonCrypto

/**
 * CertificatePinningService - Implements TLS certificate pinning
 *
 * Pins the public key (SPKI) hash of the API server's certificate to prevent
 * man-in-the-middle attacks even if a malicious CA certificate is installed.
 *
 * Usage:
 *   let session = CertificatePinningService.shared.pinnedSession
 *   // Use this session for all API requests
 */
final class CertificatePinningService: NSObject {

    // MARK: - Singleton

    static let shared = CertificatePinningService()

    // MARK: - Configuration

    /// Pinned host - only apply pinning to this domain
    private let pinnedHost = "pet-er.app"

    /// SHA-256 hashes of the Subject Public Key Info (SPKI) of trusted certificates.
    /// These are Base64-encoded SHA-256 hashes of the public key.
    ///
    /// To generate a pin from a certificate:
    /// openssl s_client -connect pet-er.app:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
    ///
    /// Include multiple pins for certificate rotation (primary + backup).
    private let pinnedPublicKeyHashes: Set<String> = [
        // Primary certificate pin (pet-er.app current certificate)
        // TODO: Replace with actual hash from production certificate
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=",  // Placeholder - replace with actual pin

        // Backup pin (for certificate rotation)
        // This should be the pin of the next certificate or CA's intermediate
        "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=",  // Placeholder - replace with actual backup pin
    ]

    /// Whether to enforce pinning (disable for debugging only)
    /// In production, this should always be true
    private var enforcePinning: Bool {
        #if DEBUG
        // Allow disabling pinning in debug builds via environment variable
        return ProcessInfo.processInfo.environment["DISABLE_CERT_PINNING"] != "1"
        #else
        return true
        #endif
    }

    // MARK: - URLSession

    /// URLSession configured with certificate pinning
    lazy var pinnedSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }()

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Public Key Extraction

    /// Extract the SHA-256 hash of the public key from a certificate
    private func getPublicKeyHash(from certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }

        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as? Data else {
            return nil
        }

        // Create SPKI header for RSA keys (most common)
        // ASN.1 header for RSA 2048 public key
        let rsa2048SPKIHeader: [UInt8] = [
            0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
            0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
        ]

        var spkiData = Data(rsa2048SPKIHeader)
        spkiData.append(publicKeyData)

        // Calculate SHA-256 hash
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        spkiData.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(spkiData.count), &hash)
        }

        return Data(hash).base64EncodedString()
    }
}

// MARK: - URLSessionDelegate

extension CertificatePinningService: URLSessionDelegate {

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        // Only apply pinning to our API host
        guard host == pinnedHost || host.hasSuffix(".\(pinnedHost)") else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Skip pinning if disabled (debug only)
        guard enforcePinning else {
            #if DEBUG
            print("[CertificatePinning] Pinning disabled for debugging")
            #endif
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Evaluate the server trust
        var error: CFError?
        let trustResult = SecTrustEvaluateWithError(serverTrust, &error)

        guard trustResult else {
            #if DEBUG
            print("[CertificatePinning] Trust evaluation failed: \(error?.localizedDescription ?? "unknown")")
            #endif
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Check if any certificate in the chain matches our pinned hashes
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            #if DEBUG
            print("[CertificatePinning] Failed to get certificate chain")
            #endif
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        for (index, certificate) in certificateChain.enumerated() {
            if let hash = getPublicKeyHash(from: certificate) {
                #if DEBUG
                print("[CertificatePinning] Certificate \(index) hash: \(hash)")
                #endif

                if pinnedPublicKeyHashes.contains(hash) {
                    #if DEBUG
                    print("[CertificatePinning] Pin matched for \(host)")
                    #endif
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    return
                }
            }
        }

        // No pin matched - reject the connection
        #if DEBUG
        print("[CertificatePinning] No pin matched for \(host) - rejecting connection")
        #endif
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
