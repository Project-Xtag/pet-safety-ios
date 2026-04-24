import Foundation
import SwiftUI

/// Handles deep links and universal links for the Pet Safety app
/// Supports:
/// - Custom scheme: senra://tag/{code}
/// - Universal links: https://senra.pet/qr/{code}
@MainActor
class DeepLinkService: ObservableObject {
    static let shared = DeepLinkService()

    /// The pending tag code from a deep link
    @Published var pendingTagCode: String?

    /// Whether to show the tag activation view
    @Published var showTagActivation = false

    /// Whether a tag lookup is in progress
    @Published var isLookingUpTag = false

    /// Whether to show the scanned pet public profile (for active tags with a pet)
    @Published var showScannedPetProfile = false

    /// Whether to show the promo tag claim flow
    @Published var showPromoClaimFlow = false

    /// The tag code for the promo claim flow
    @Published var promoClaimTagCode: String?

    /// Promo info for the claim flow (shelter name, duration, etc.)
    @Published var promoClaimInfo: PromoTagInfo?

    /// The pet data from a scanned active tag (populated by lookup)
    @Published var scannedTagLookup: TagLookupResponse?

    /// The type of deep link received
    enum DeepLinkType {
        case tagActivation(code: String)
        case petView(petId: String)
        case qrScan(code: String)
    }

    private init() {}

    /// Handle an incoming URL
    /// - Parameter url: The URL to handle
    /// - Returns: True if the URL was handled, false otherwise
    @discardableResult
    func handleURL(_ url: URL) -> Bool {
        #if DEBUG
        print("🔗 DeepLinkService: Handling URL: \(url.absoluteString)")
        #endif

        // Handle custom scheme: senra://tag/{code}
        if url.scheme == "senra" {
            return handleCustomScheme(url)
        }

        // Handle universal link: https://senra.pet/qr/{code}
        if url.scheme == "https" && (url.host == "senra.pet" || url.host == "www.senra.pet") {
            return handleUniversalLink(url)
        }

        #if DEBUG
        print("🔗 DeepLinkService: Unhandled URL scheme: \(url.scheme ?? "nil")")
        #endif

        return false
    }

    /// Handle custom scheme URLs (senra://)
    private func handleCustomScheme(_ url: URL) -> Bool {
        guard let host = url.host else { return false }

        switch host {
        case "tag":
            // senra://tag/{code}
            // Path components: ["", "code"]
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let code = pathComponents.first {
                handleTagScanned(code: code)
                return true
            }
            // If code is directly after the host (senra://tag/PS-XXXXXXXX)
            // Check if path is empty but there's a last path component
            if let lastComponent = url.lastPathComponent as String?, !lastComponent.isEmpty && lastComponent != "tag" {
                handleTagScanned(code: lastComponent)
                return true
            }

        case "pet":
            // senra://pet/{petId}
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let petId = pathComponents.first {
                #if DEBUG
                print("🔗 DeepLinkService: Pet view requested for: \(petId)")
                #endif
                // Could be implemented in the future
                return true
            }

        default:
            break
        }

        return false
    }

    /// Handle universal link URLs (https://senra.pet/...)
    private func handleUniversalLink(_ url: URL) -> Bool {
        var pathComponents = url.pathComponents.filter { $0 != "/" }

        // Strip country prefix (e.g. /hu/qr/ABC -> /qr/ABC)
        if let first = pathComponents.first, WebURLHelper.validCountryCodes.contains(first) {
            pathComponents.removeFirst()
        }

        // https://senra.pet/qr/{code}, https://senra.pet/t/{code}, or with country prefix
        let firstLower = pathComponents.first?.lowercased() ?? ""
        if pathComponents.count >= 2 && (firstLower == "qr" || firstLower == "t") {
            let code = pathComponents[1]
            handleTagScanned(code: code)
            return true
        }

        return false
    }

    /// Public entry point for the in-app QR scanner.
    /// Routes through the same lookup flow as deep links.
    func handleScannedCode(_ code: String) {
        handleTagScanned(code: code)
    }

    /// Process a scanned/deep-linked QR tag code.
    /// Performs a lookup first to determine the tag's status, then routes accordingly:
    /// - Active tag with pet → show public pet profile
    /// - Inactive tag + authenticated owner → show tag activation
    /// - Inactive tag + not logged in → show login prompt
    /// - Network error → fall back to activation flow (safe default)
    private func handleTagScanned(code: String) {
        #if DEBUG
        print("🔗 DeepLinkService: Tag scanned, looking up code: \(code)")
        #endif

        pendingTagCode = code
        isLookingUpTag = true

        Task {
            do {
                let lookup = try await APIService.shared.lookupTag(code: code)

                #if DEBUG
                print("🔗 DeepLinkService: Lookup result - exists: \(lookup.exists), status: \(lookup.status ?? "nil"), hasPet: \(lookup.hasPet ?? false), isOwner: \(lookup.isOwner ?? false)")
                #endif

                if lookup.canClaimPromo == true, let promo = lookup.promo, !promo.batchExpired {
                    // Promo-batch tag — show the promo claim flow
                    #if DEBUG
                    print("🔗 DeepLinkService: Promo tag detected from \(promo.shelterName)")
                    #endif
                    promoClaimTagCode = code
                    promoClaimInfo = promo
                    isLookingUpTag = false
                    showPromoClaimFlow = true
                } else if lookup.exists && lookup.status == "active" && lookup.hasPet == true && lookup.pet != nil {
                    // Active tag with a pet linked — show the public pet profile
                    scannedTagLookup = lookup
                    isLookingUpTag = false
                    showScannedPetProfile = true

                    // Log scan and notify owner (fire-and-forget)
                    Task {
                        _ = try? await APIService.shared.scanQRCode(code)
                    }
                } else {
                    // Tag exists but is not active/has no pet — show activation flow
                    isLookingUpTag = false
                    showTagActivation = true
                }
            } catch {
                #if DEBUG
                print("🔗 DeepLinkService: Lookup failed with error: \(error.localizedDescription). Falling back to activation flow.")
                #endif
                // Network error or unexpected response — fall back to activation flow
                isLookingUpTag = false
                showTagActivation = true
            }
        }
    }

    /// Clear the pending deep link state
    func clearPendingLink() {
        pendingTagCode = nil
        showTagActivation = false
        showScannedPetProfile = false
        showPromoClaimFlow = false
        promoClaimTagCode = nil
        promoClaimInfo = nil
        scannedTagLookup = nil
        isLookingUpTag = false
    }

    /// Extract tag code from a scanned QR code string
    /// The QR code might contain:
    /// - Just the code: PS-XXXXXXXX
    /// - Full URL: https://senra.pet/qr/PS-XXXXXXXX
    /// - Custom scheme: senra://tag/PS-XXXXXXXX
    static func extractTagCode(from scannedValue: String) -> String {
        let trimmed = scannedValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if it's a URL. Scheme and host comparisons are
        // case-insensitive because some handheld scanners and legacy
        // imports produce uppercase URL scaffolding (e.g.
        // "HTTPS://SENRA.PET/T/<CODE>"). The code itself is CASE-SENSITIVE
        // (nanoid alphabet includes both cases) so we never fold it.
        if let url = URL(string: trimmed) {
            let scheme = url.scheme?.lowercased()
            let host = url.host?.lowercased()

            // https://senra.pet/qr/{code}, https://senra.pet/t/{code}, or with country prefix
            if (scheme == "https" || scheme == "http") && (host == "senra.pet" || host == "www.senra.pet") {
                var pathComponents = url.pathComponents.filter { $0 != "/" }
                // Strip country prefix
                if let first = pathComponents.first, WebURLHelper.validCountryCodes.contains(first.lowercased()) {
                    pathComponents.removeFirst()
                }
                let firstLower = pathComponents.first?.lowercased() ?? ""
                if pathComponents.count >= 2 && (firstLower == "qr" || firstLower == "t") {
                    return pathComponents[1]
                }
            }

            // senra://tag/{code}
            if scheme == "senra" && host == "tag" {
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                if let code = pathComponents.first {
                    return code
                }
            }
        }

        // Assume it's just the code itself
        return trimmed
    }
}
