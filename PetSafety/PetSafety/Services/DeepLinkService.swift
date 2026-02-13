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
                handleTagActivation(code: code)
                return true
            }
            // If code is directly after the host (senra://tag/PS-XXXXXXXX)
            // Check if path is empty but there's a last path component
            if let lastComponent = url.lastPathComponent as String?, !lastComponent.isEmpty && lastComponent != "tag" {
                handleTagActivation(code: lastComponent)
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
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        // https://senra.pet/qr/{code}
        if pathComponents.count >= 2 && pathComponents[0] == "qr" {
            let code = pathComponents[1]
            handleTagActivation(code: code)
            return true
        }

        return false
    }

    /// Process a tag activation deep link
    private func handleTagActivation(code: String) {
        #if DEBUG
        print("🔗 DeepLinkService: Tag activation for code: \(code)")
        #endif

        // Store the code and trigger the activation flow
        pendingTagCode = code
        showTagActivation = true
    }

    /// Clear the pending deep link state
    func clearPendingLink() {
        pendingTagCode = nil
        showTagActivation = false
    }

    /// Extract tag code from a scanned QR code string
    /// The QR code might contain:
    /// - Just the code: PS-XXXXXXXX
    /// - Full URL: https://senra.pet/qr/PS-XXXXXXXX
    /// - Custom scheme: senra://tag/PS-XXXXXXXX
    static func extractTagCode(from scannedValue: String) -> String {
        let trimmed = scannedValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if it's a URL
        if let url = URL(string: trimmed) {
            // https://senra.pet/qr/{code}
            if url.scheme == "https" && (url.host == "senra.pet" || url.host == "www.senra.pet") {
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                if pathComponents.count >= 2 && pathComponents[0] == "qr" {
                    return pathComponents[1]
                }
            }

            // senra://tag/{code}
            if url.scheme == "senra" && url.host == "tag" {
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
