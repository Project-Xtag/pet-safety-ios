import Foundation

/**
 * FCM Service for Firebase Cloud Messaging
 *
 * Handles FCM token registration with the backend.
 * Tokens are sent to the server which uses them for push notifications.
 */

actor FCMService {
    static let shared = FCMService()

    private let baseURL = "https://pet-er.app/api"

    private init() {}

    /// Register FCM token with backend
    /// - Parameters:
    ///   - token: The FCM token from Firebase
    ///   - deviceName: Optional device name for identification
    func registerToken(_ token: String, deviceName: String? = nil) async {
        do {
            try await registerTokenWithBackend(token, deviceName: deviceName)
            #if DEBUG
            print("FCM token registered successfully")
            #endif
        } catch {
            #if DEBUG
            print("Failed to register FCM token: \(error)")
            #endif
        }
    }

    /// Remove FCM token from backend (e.g., on logout)
    /// - Parameter token: The FCM token to remove
    func removeToken(_ token: String) async {
        do {
            try await removeTokenFromBackend(token)
            #if DEBUG
            print("FCM token removed successfully")
            #endif
        } catch {
            #if DEBUG
            print("Failed to remove FCM token: \(error)")
            #endif
        }
    }

    // MARK: - Private API Methods

    private func registerTokenWithBackend(_ token: String, deviceName: String?) async throws {
        guard let url = URL(string: "https://pet-er.app/api/users/me/fcm-tokens") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let authToken = KeychainService.shared.getAuthToken() {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        var body: [String: Any] = [
            "token": token,
            "platform": "ios"
        ]

        if let deviceName = deviceName {
            body["deviceName"] = deviceName
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await CertificatePinningService.shared.pinnedSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func removeTokenFromBackend(_ token: String) async throws {
        let encodedToken = token.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? token
        guard let url = URL(string: "https://pet-er.app/api/users/me/fcm-tokens/\(encodedToken)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        // Add auth token if available
        if let authToken = KeychainService.shared.getAuthToken() {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await CertificatePinningService.shared.pinnedSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
