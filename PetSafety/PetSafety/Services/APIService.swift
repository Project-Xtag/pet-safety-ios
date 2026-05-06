import Foundation
import Sentry

// MARK: - Flexible ISO 8601 date decoding (handles with/without timezone and fractional seconds)
extension JSONDecoder.DateDecodingStrategy {
    static var flexibleISO8601: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            // Try standard ISO8601 with fractional seconds first (2026-01-01T20:15:53.292Z)
            let fmtFrac = ISO8601DateFormatter()
            fmtFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fmtFrac.date(from: string) { return date }

            // Try standard ISO8601 without fractional seconds (2026-01-01T20:15:53Z)
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime]
            if let date = fmt.date(from: string) { return date }

            // Try without timezone — append Z and retry (2026-01-01T20:15:53.292791)
            if let date = fmtFrac.date(from: string + "Z") { return date }
            if let date = fmt.date(from: string + "Z") { return date }

            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Unable to parse date: \(string)"
            ))
        }
    }
}

struct SubscriptionLimitInfo {
    let currentPlan: String
    let currentPetCount: Int
    let maxPets: Int
    let upgradeTo: String
    let upgradePrice: String
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case petLimitExceeded(SubscriptionLimitInfo)
    case decodingError
    case networkError(Error)
    /// App Check token unavailable while Remote Config has flipped enforcement
    /// on. Synthesised locally without ever hitting the network — mirrors
    /// the Android AppCheckInterceptor fail-closed behaviour (audit H47).
    case appCheckRequired

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "api_error_invalid_url")
        case .invalidResponse:
            return String(localized: "api_error_invalid_response")
        case .unauthorized:
            return String(localized: "api_error_unauthorized")
        case .serverError(let message):
            return message
        case .petLimitExceeded:
            return String(localized: "api_error_pet_limit")
        case .decodingError:
            return String(localized: "api_error_decoding")
        case .networkError(let error):
            return String(localized: "api_error_network \(error.localizedDescription)")
        case .appCheckRequired:
            return String(localized: "api_error_app_check_required")
        }
    }
}

protocol APIServiceProtocol: AnyObject {
    func createAlert(_ request: CreateAlertRequest) async throws -> MissingPetAlert
    func getPets() async throws -> [Pet]
    func getAlerts() async throws -> [MissingPetAlert]
    func getNearbyAlerts(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [MissingPetAlert]
    func updateAlertStatus(id: String, status: String) async throws -> MissingPetAlert
    func markPetFound(petId: String) async throws -> Pet
    func updatePet(id: String, _ request: UpdatePetRequest) async throws -> Pet
    func reportSighting(alertId: String, sighting: ReportSightingRequest) async throws -> Sighting
}

class APIService {
    static let shared = APIService()

    // MARK: - Configuration
    // Base URL is now fetched from ConfigurationManager (Firebase Remote Config)
    // Falls back to hardcoded default if Remote Config is unavailable
    private var baseURL: String {
        let configuredURL = ConfigurationManager.shared.apiBaseURL
        return configuredURL.isEmpty ? "https://api.senra.pet/api" : configuredURL
    }
    private var authToken: String? {
        get { KeychainService.shared.getAuthToken() }
        set {
            if let token = newValue {
                _ = KeychainService.shared.saveAuthToken(token)
            } else {
                _ = KeychainService.shared.deleteAuthToken()
            }
        }
    }

    // MARK: - Token Refresh State
    /// Actor to serialize concurrent token refresh attempts
    private let refreshCoordinator = TokenRefreshCoordinator()

    private init() {
        // Migrate existing tokens from UserDefaults to Keychain (one-time migration)
        KeychainService.shared.migrateFromUserDefaults()
    }

    // MARK: - Token Refresh

    /// Attempt to refresh the access token and persist the new tokens.
    /// Called by other services (e.g. SSEService) when they encounter a 401.
    /// Returns `true` if the refresh succeeded, `false` otherwise.
    func attemptTokenRefresh() async -> Bool {
        guard let storedRefreshToken = KeychainService.shared.getRefreshToken() else {
            return false
        }
        do {
            let newTokens = try await refreshCoordinator.refresh {
                try await self.refreshAccessToken(refreshToken: storedRefreshToken)
            }
            self.authToken = newTokens.accessToken
            _ = KeychainService.shared.saveRefreshToken(newTokens.refreshToken)
            return true
        } catch {
            #if DEBUG
            print("❌ APIService: Token refresh failed: \(error)")
            #endif
            return false
        }
    }

    /// Attempt to refresh the access token using the stored refresh token.
    /// Uses a raw URLSession call to avoid infinite loops through performRequest.
    private func refreshAccessToken(refreshToken: String) async throws -> (accessToken: String, refreshToken: String) {
        guard let url = URL(string: "\(baseURL)/auth/refresh") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["refreshToken": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await CertificatePinningService.shared.pinnedSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.unauthorized
        }

        struct RefreshResponse: Codable {
            let success: Bool
            let data: RefreshData?
            struct RefreshData: Codable {
                let token: String
                let refreshToken: String
            }
        }

        let result = try JSONDecoder().decode(RefreshResponse.self, from: data)
        guard let tokenData = result.data else {
            throw APIError.unauthorized
        }
        return (tokenData.token, tokenData.refreshToken)
    }

    // MARK: - Request Builder
    private func buildRequest(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Send device locale so backend returns locale-appropriate content (seed alerts, etc.)
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        request.setValue(languageCode, forHTTPHeaderField: "Accept-Language")

        // Add Firebase App Check token for API protection.
        // This verifies the request comes from a legitimate app instance.
        //
        // Behaviour matrix (mirrors Android AppCheckInterceptor):
        //
        //   DEBUG build              — getAppCheckToken returns nil to avoid
        //                              the latency / 403 of Firebase's debug
        //                              token exchange. We never enforce here.
        //
        //   Release, token available — attach the X-Firebase-AppCheck header.
        //
        //   Release, token missing,
        //     enforcement OFF        — proceed without the header (legacy
        //                              fail-open). Logged to Sentry as a
        //                              warning so config drift is visible.
        //
        //   Release, token missing,
        //     enforcement ON         — fail-closed locally with appCheckRequired
        //                              before the request ever leaves the device.
        //                              The Remote Config flag
        //                              `app_check_enforce_client_ios` ships at
        //                              false; flipping it on is a release-free
        //                              cutover once backend WS8.7 enforcement
        //                              ships. Audit H47.
        if let appCheckToken = await ConfigurationManager.shared.getAppCheckToken() {
            request.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
        } else {
            #if DEBUG
            print("⚠️ APIService: App Check token unavailable for \(endpoint)")
            #endif
            if SentrySDK.isEnabled {
                SentrySDK.capture(message: "App Check token unavailable")
            }
            #if !DEBUG
            if ConfigurationManager.shared.shouldEnforceAppCheckClient() {
                throw APIError.appCheckRequired
            }
            #endif
        }

        if let body = body {
            let encoder = JSONEncoder()
            let bodyData = try encoder.encode(body)
            request.httpBody = bodyData

            #if DEBUG
            // Log the request body for debugging
            if let jsonString = String(data: bodyData, encoding: .utf8) {
                print("📤 API Request to \(endpoint):")
                print("Method: \(method)")
                print("Body: \(jsonString)")
            }
            #endif
        }

        return request
    }

    // MARK: - Generic Request Method
    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type,
        isRetryAfterRefresh: Bool = false
    ) async throws -> T {
        // Add Sentry breadcrumb for API request tracking
        if SentrySDK.isEnabled {
            let crumb = Breadcrumb(level: .info, category: "http")
            crumb.message = "\(request.httpMethod ?? "GET") \(request.url?.path ?? "")"
            SentrySDK.addBreadcrumb(crumb)
        }

        do {
            let (data, response) = try await CertificatePinningService.shared.pinnedSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .flexibleISO8601

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let envelope = try decoder.decode(ApiEnvelope<T>.self, from: data)
                    if envelope.success {
                        if let payload = envelope.data {
                            return payload
                        }
                        if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T {
                            return empty
                        }
                        throw APIError.decodingError
                    }

                    let message = envelope.error ?? "Server error"
                    let detailsText = formatErrorDetails(envelope.details)
                    if let detailsText {
                        throw APIError.serverError("\(message) (\(detailsText))")
                    }
                    throw APIError.serverError(message)
                } catch let apiError as APIError {
                    throw apiError
                } catch {
                    #if DEBUG
                    print("❌ DECODING ERROR:")
                    print("Error: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
                            print("Coding path: \(context.codingPath)")
                        case .typeMismatch(let type, let context):
                            print("Type mismatch for type \(type): \(context.debugDescription)")
                            print("Coding path: \(context.codingPath)")
                        case .valueNotFound(let type, let context):
                            print("Value not found for type \(type): \(context.debugDescription)")
                            print("Coding path: \(context.codingPath)")
                        case .dataCorrupted(let context):
                            print("Data corrupted: \(context.debugDescription)")
                            print("Coding path: \(context.codingPath)")
                        @unknown default:
                            print("Unknown decoding error")
                        }
                    }
                    print("Response data as string: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                    #endif
                    throw APIError.decodingError
                }

            case 401:
                // If this is already a retry after refresh, give up
                if isRetryAfterRefresh {
                    authToken = nil
                    KeychainService.shared.clearAuthToken()
                    _ = KeychainService.shared.clearRefreshToken()
                    throw APIError.unauthorized
                }

                // Attempt token refresh
                guard let storedRefreshToken = KeychainService.shared.getRefreshToken() else {
                    authToken = nil
                    KeychainService.shared.clearAuthToken()
                    _ = KeychainService.shared.clearRefreshToken()
                    throw APIError.unauthorized
                }

                do {
                    let newTokens = try await refreshCoordinator.refresh {
                        try await self.refreshAccessToken(refreshToken: storedRefreshToken)
                    }
                    // Save new tokens
                    self.authToken = newTokens.accessToken
                    _ = KeychainService.shared.saveRefreshToken(newTokens.refreshToken)

                    // Rebuild the original request with the new token
                    var retryRequest = request
                    retryRequest.setValue("Bearer \(newTokens.accessToken)", forHTTPHeaderField: "Authorization")

                    // Retry the original request once
                    return try await performRequest(retryRequest, responseType: responseType, isRetryAfterRefresh: true)
                } catch {
                    // Refresh failed — clear all tokens and throw unauthorized
                    authToken = nil
                    KeychainService.shared.clearAuthToken()
                    _ = KeychainService.shared.clearRefreshToken()
                    throw APIError.unauthorized
                }

            case 403:
                // Check if this is a pet limit exceeded error
                if let limitResponse = try? decoder.decode(PetLimitErrorResponse.self, from: data),
                   let sub = limitResponse.subscription {
                    throw APIError.petLimitExceeded(SubscriptionLimitInfo(
                        currentPlan: sub.current_plan,
                        currentPetCount: sub.current_pet_count,
                        maxPets: sub.max_pets,
                        upgradeTo: sub.upgrade_to,
                        upgradePrice: sub.upgrade_price
                    ))
                }
                // Generic 403
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error)
                }
                throw APIError.serverError("Access denied")

            default:
                // Capture 5xx server errors to Sentry
                if httpResponse.statusCode >= 500 && SentrySDK.isEnabled {
                    SentrySDK.capture(message: "Server error \(httpResponse.statusCode): \(request.url?.path ?? "")")
                }

                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    let detailsText = formatErrorDetails(errorResponse.details)
                    if let detailsText {
                        throw APIError.serverError("\(errorResponse.error) (\(detailsText))")
                    }
                    throw APIError.serverError(errorResponse.error)
                }
                throw APIError.serverError("Server error: \(httpResponse.statusCode)")
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func formatErrorDetails(_ details: [String: JSONValue]?) -> String? {
        guard let details else { return nil }
        if let data = try? JSONEncoder().encode(details),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }

    // MARK: - Authentication
    func login(email: String) async throws -> LoginResponse {
        // Canonical lowercased email — matches backend lookup so iOS, web
        // and Android all resolve to the same user row.
        let normalizedEmail = EmailNormalizer.normalize(email)
        let locale = Locale.current.language.languageCode?.identifier
        let request = try await buildRequest(
            endpoint: "/auth/send-otp",
            method: "POST",
            body: LoginRequest(email: normalizedEmail, locale: locale),
            requiresAuth: false
        )
        let response = try await performRequest(request, responseType: LoginResponse.self)
        #if DEBUG
        print("✅ OTP send response: \(response.message)")
        #endif
        return response
    }

    func verifyOTP(email: String, code: String, firstName: String? = nil, lastName: String? = nil) async throws -> VerifyOTPResponse {
        let normalizedEmail = EmailNormalizer.normalize(email)
        let request = try await buildRequest(
            endpoint: "/auth/verify-otp",
            method: "POST",
            body: VerifyOTPRequest(email: normalizedEmail, code: code, firstName: firstName, lastName: lastName),
            requiresAuth: false
        )
        let response = try await performRequest(request, responseType: VerifyOTPResponse.self)
        authToken = response.token
        if let refreshToken = response.refreshToken {
            _ = KeychainService.shared.saveRefreshToken(refreshToken)
        }
        return response
    }

    func logout() {
        authToken = nil
        KeychainService.shared.clearAuthToken()
        _ = KeychainService.shared.clearRefreshToken()
    }

    // MARK: - User
    func getCurrentUser() async throws -> User {
        let request = try await buildRequest(endpoint: "/users/me")
        let response = try await performRequest(request, responseType: UserResponse.self)
        return response.user
    }

    func updateUser(_ updates: [String: Any]) async throws -> User {
        let request = try await buildRequest(
            endpoint: "/users/me",
            method: "PATCH",
            body: DynamicBody(updates)
        )
        let response = try await performRequest(request, responseType: UserResponse.self)
        return response.user
    }

    func uploadProfileImage(imageData: Data) async throws {
        var request = try await buildRequest(endpoint: "/users/me/profile-image", method: "POST")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        _ = try await performRequest(request, responseType: ProfileImageResponse.self)
    }

    func updateContactPreferences(
        showPhonePublicly: Bool?,
        showEmailPublicly: Bool?
    ) async throws -> User {
        var updates: [String: Any] = [:]
        if let showPhone = showPhonePublicly {
            updates["show_phone_publicly"] = showPhone
        }
        if let showEmail = showEmailPublicly {
            updates["show_email_publicly"] = showEmail
        }

        let request = try await buildRequest(
            endpoint: "/users/me",
            method: "PATCH",
            body: DynamicBody(updates)
        )
        let response = try await performRequest(request, responseType: UserResponse.self)
        return response.user
    }

    // MARK: - Pets
    func getPets() async throws -> [Pet] {
        let request = try await buildRequest(endpoint: "/pets")
        let response = try await performRequest(request, responseType: PetsResponse.self)
        return response.pets
    }

    func getPet(id: String) async throws -> Pet {
        let request = try await buildRequest(endpoint: "/pets/\(id)")
        let response = try await performRequest(request, responseType: PetResponse.self)
        return response.pet
    }

    func createPet(_ petData: CreatePetRequest) async throws -> Pet {
        let request = try await buildRequest(
            endpoint: "/pets",
            method: "POST",
            body: petData
        )
        let response = try await performRequest(request, responseType: PetResponse.self)
        return response.pet
    }

    func updatePet(id: String, _ updates: UpdatePetRequest) async throws -> Pet {
        let request = try await buildRequest(
            endpoint: "/pets/\(id)",
            method: "PUT",
            body: updates
        )
        let response = try await performRequest(request, responseType: PetResponse.self)
        return response.pet
    }

    func deletePet(id: String) async throws {
        let request = try await buildRequest(
            endpoint: "/pets/\(id)",
            method: "DELETE"
        )
        let _: EmptyResponse = try await performRequest(request, responseType: EmptyResponse.self)
    }

    /// Mark pet as missing and optionally create alert
    /// - Parameters:
    ///   - petId: Pet ID
    ///   - location: Optional last seen location coordinates
    ///   - address: Optional last seen address
    ///   - description: Optional additional details
    ///   - rewardAmount: Optional reward amount
    func markPetMissing(
        petId: String,
        location: LocationCoordinate? = nil,
        address: String? = nil,
        description: String? = nil,
        rewardAmount: String? = nil,
        notificationCenterSource: String? = nil,
        notificationCenterLocation: LocationCoordinate? = nil,
        notificationCenterAddress: String? = nil
    ) async throws -> MarkMissingResponse {
        struct MarkMissingRequest: Codable {
            let lastSeenLocation: LocationCoordinate?
            let lastSeenAddress: String?
            let description: String?
            let rewardAmount: String?
            let notificationCenterSource: String?
            let notificationCenterLocation: LocationCoordinate?
            let notificationCenterAddress: String?
        }

        let requestBody = MarkMissingRequest(
            lastSeenLocation: location,
            lastSeenAddress: address,
            description: description,
            rewardAmount: rewardAmount,
            notificationCenterSource: notificationCenterSource,
            notificationCenterLocation: notificationCenterLocation,
            notificationCenterAddress: notificationCenterAddress
        )

        let request = try await buildRequest(
            endpoint: "/pets/\(petId)/mark-missing",
            method: "POST",
            body: requestBody
        )
        let response = try await performRequest(request, responseType: MarkMissingResponse.self)
        return response
    }

    /// Mark pet as found (updates is_missing to false)
    func markPetFound(petId: String) async throws -> Pet {
        let updates = UpdatePetRequest(
            name: nil,
            species: nil,
            breed: nil,
            color: nil,
            weight: nil,
            microchipNumber: nil,
            medicalNotes: nil,
            allergies: nil,
            medications: nil,
            notes: nil,
            uniqueFeatures: nil,
            sex: nil,
            isNeutered: nil,
            isMissing: false,
            dateOfBirth: nil,
            dobIsApproximate: nil
        )

        let request = try await buildRequest(
            endpoint: "/pets/\(petId)",
            method: "PUT",
            body: updates
        )
        let response = try await performRequest(request, responseType: PetResponse.self)
        return response.pet
    }

    /// Get the server-generated social share card URL for an alert.
    /// Returns the same image that is auto-posted to official social accounts.
    func getShareCardUrl(alertId: String, locale: String = Locale.current.language.languageCode?.identifier ?? "en") async throws -> String {
        struct ShareCardResponse: Codable {
            let imageUrl: String
            let type: String
            let locale: String
        }
        let request = try await buildRequest(
            endpoint: "/alerts/\(alertId)/share-card?locale=\(locale)",
            method: "GET"
        )
        let response = try await performRequest(request, responseType: ShareCardResponse.self)
        return response.imageUrl
    }

    func uploadPetPhoto(petId: String, imageData: Data) async throws -> Pet {
        // Backend expects /image not /photo
        let endpoint = "/pets/\(petId)/image"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        #if DEBUG
        print("📸 Uploading image to: \(url.absoluteString)")
        print("📸 Pet ID: \(petId)")
        print("📸 Image size: \(imageData.count) bytes")
        #endif

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        // Backend expects field name 'image' not 'photo'
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        #if DEBUG
        print("📸 Sending multipart request with field name 'image'...")
        #endif

        let response = try await performRequest(request, responseType: ImageUploadResponse.self)

        #if DEBUG
        print("✅ Image upload successful! URL: \(response.imageUrl)")
        print("📥 Fetching updated pet data...")
        #endif

        // Need to fetch the full updated pet since backend only returns partial data
        return try await getPet(id: petId)
    }

    // MARK: - Pet Photos

    /// Get all photos for a pet
    func getPetPhotos(petId: String) async throws -> PetPhotosResponse {
        let request = try await buildRequest(endpoint: "/pets/\(petId)/photos")
        return try await performRequest(request, responseType: PetPhotosResponse.self)
    }

    /// Upload a new photo for a pet
    func uploadPetPhotoToGallery(petId: String, imageData: Data, isPrimary: Bool = false) async throws -> PhotoUploadResponse {
        let endpoint = "/pets/\(petId)/photos"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        #if DEBUG
        print("📸 Uploading photo to gallery: \(url.absoluteString)")
        print("📸 Pet ID: \(petId), Primary: \(isPrimary)")
        print("📸 Image size: \(imageData.count) bytes")
        #endif

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add photo file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add isPrimary field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"isPrimary\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(isPrimary)".data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        return try await performRequest(request, responseType: PhotoUploadResponse.self)
    }

    /// Set a photo as primary
    func setPrimaryPhoto(petId: String, photoId: String) async throws -> PhotoOperationResponse {
        let request = try await buildRequest(
            endpoint: "/pets/\(petId)/photos/\(photoId)/primary",
            method: "PUT",
            body: EmptyBody()
        )
        return try await performRequest(request, responseType: PhotoOperationResponse.self)
    }

    /// Delete a photo
    func deletePetPhoto(petId: String, photoId: String) async throws -> PhotoOperationResponse {
        let request = try await buildRequest(
            endpoint: "/pets/\(petId)/photos/\(photoId)",
            method: "DELETE"
        )
        return try await performRequest(request, responseType: PhotoOperationResponse.self)
    }

    /// Reorder photos
    func reorderPetPhotos(petId: String, photoIds: [String]) async throws -> PhotoReorderResponse {
        let request = try await buildRequest(
            endpoint: "/pets/\(petId)/photos/reorder",
            method: "PUT",
            body: PhotoReorderRequest(photoOrder: photoIds)
        )
        return try await performRequest(request, responseType: PhotoReorderResponse.self)
    }

    // MARK: - Alerts
    func getAlerts() async throws -> [MissingPetAlert] {
        let request = try await buildRequest(endpoint: "/alerts")
        let response = try await performRequest(request, responseType: AlertsResponse.self)
        return response.alerts
    }

    func getNearbyAlerts(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 10
    ) async throws -> [MissingPetAlert] {
        struct NearbyAlertsResponse: Codable {
            let alerts: [MissingPetAlert]
            let count: Int
        }

        let endpoint = "/alerts/nearby?lat=\(latitude)&lng=\(longitude)&radius=\(radiusKm)"
        let request = try await buildRequest(
            endpoint: endpoint,
            method: "GET",
            requiresAuth: false
        )
        let response = try await performRequest(request, responseType: NearbyAlertsResponse.self)
        return response.alerts
    }

    func createAlert(_ alertData: CreateAlertRequest) async throws -> MissingPetAlert {
        let request = try await buildRequest(
            endpoint: "/alerts/missing",
            method: "POST",
            body: alertData
        )
        let response = try await performRequest(request, responseType: AlertResponse.self)
        return response.alert
    }

    func updateAlertStatus(id: String, status: String) async throws -> MissingPetAlert {
        guard status == "found" else {
            throw APIError.serverError("Only 'found' status is supported")
        }
        let request = try await buildRequest(
            endpoint: "/alerts/\(id)/found",
            method: "POST",
            body: EmptyBody()
        )
        let response = try await performRequest(request, responseType: AlertResponse.self)
        return response.alert
    }

    func updateAlert(id: String, description: String?, lastSeenAddress: String?, rewardAmount: String?) async throws -> MissingPetAlert {
        struct UpdateAlertRequest: Codable {
            let description: String?
            let lastSeenAddress: String?
            let rewardAmount: String?
        }
        let request = try await buildRequest(
            endpoint: "/alerts/\(id)",
            method: "PUT",
            body: UpdateAlertRequest(
                description: description,
                lastSeenAddress: lastSeenAddress,
                rewardAmount: rewardAmount
            )
        )
        let response = try await performRequest(request, responseType: AlertResponse.self)
        return response.alert
    }

    func reportSighting(alertId: String, sighting: ReportSightingRequest) async throws -> Sighting {
        let request = try await buildRequest(
            endpoint: "/alerts/\(alertId)/sightings",
            method: "POST",
            body: sighting
        )
        let response = try await performRequest(request, responseType: SightingResponse.self)
        return response.sighting
    }

    // MARK: - QR Tags

    /// Look up a QR tag by code to determine its status before deciding what to show
    /// This is a public endpoint (no auth required) that returns tag status and pet info
    func lookupTag(code: String) async throws -> TagLookupResponse {
        let request = try await buildRequest(
            endpoint: "/qr-tags/lookup/\(code)",
            method: "GET",
            requiresAuth: false
        )
        return try await performRequest(request, responseType: TagLookupResponse.self)
    }

    func scanQRCode(_ code: String) async throws -> ScanResponse {
        let request = try await buildRequest(
            endpoint: "/qr-tags/scan/\(code)",
            method: "GET",
            requiresAuth: false
        )
        return try await performRequest(request, responseType: ScanResponse.self)
    }

    func activateTag(qrCode: String, petId: String) async throws -> QRTag {
        struct ActivateRequest: Codable {
            let qrCode: String
            let petId: String
        }

        struct ActivateResponse: Codable {
            let tag: QRTag
            let message: String?
        }

        let request = try await buildRequest(
            endpoint: "/qr-tags/activate",
            method: "POST",
            body: ActivateRequest(qrCode: qrCode, petId: petId),
            requiresAuth: true
        )
        let response = try await performRequest(request, responseType: ActivateResponse.self)
        return response.tag
    }

    /// Claim a promo-batch tag: register pet + activate tag + grant subscription
    func claimPromoTag(qrCode: String, pet: CreatePetRequest? = nil, petId: String? = nil) async throws -> ClaimPromoTagResponse {
        let body = ClaimPromoTagRequest(qrCode: qrCode, pet: pet, petId: petId)

        struct ClaimEnvelope: Codable {
            let data: ClaimPromoTagResponse
        }

        let request = try await buildRequest(
            endpoint: "/qr-tags/claim-promo",
            method: "POST",
            body: body,
            requiresAuth: true
        )
        let response = try await performRequest(request, responseType: ClaimEnvelope.self)
        return response.data
    }

    // Get active tag for a pet
    func getActiveTag(petId: String) async throws -> QRTag? {
        struct GetTagResponse: Codable {
            let tag: QRTag?
            let message: String?
        }

        let request = try await buildRequest(
            endpoint: "/qr-tags/pet/\(petId)",
            method: "GET",
            requiresAuth: true
        )
        let response = try await performRequest(request, responseType: GetTagResponse.self)
        return response.tag
    }

    /// Share finder's location with pet owner (no auth required).
    ///
    /// Either `location` (precise GPS) or `manualAddress` (free-text the
    /// server geocodes via Google Places → Nominatim) must be supplied —
    /// the backend rejects calls with neither. Both can coexist when the
    /// finder shares GPS plus a "near the playground" hint.
    func shareLocation(
        qrCode: String,
        location: LocationConsentData? = nil,
        manualAddress: String? = nil
    ) async throws -> ShareLocationResponse {
        struct ShareLocationRequest: Codable {
            let qrCode: String
            let location: LocationConsentData?
            let manual_address: String?
        }

        let request = try await buildRequest(
            endpoint: "/qr-tags/share-location",
            method: "POST",
            body: ShareLocationRequest(
                qrCode: qrCode,
                location: location,
                manual_address: manualAddress
            ),
            requiresAuth: false
        )
        return try await performRequest(request, responseType: ShareLocationResponse.self)
    }

    // MARK: - Orders
    func createOrder(_ orderData: CreateOrderRequest) async throws -> CreateTagOrderResponse {
        let request = try await buildRequest(
            endpoint: "/orders",
            method: "POST",
            body: orderData,
            requiresAuth: false
        )
        return try await performRequest(request, responseType: CreateTagOrderResponse.self)
    }

    func getOrders() async throws -> [Order] {
        let request = try await buildRequest(endpoint: "/orders")
        let response = try await performRequest(request, responseType: OrdersResponse.self)
        return response.orders
    }

    func getPendingRegistrations() async throws -> [PendingRegistration] {
        let request = try await buildRequest(endpoint: "/orders/pending-registrations")
        let response = try await performRequest(request, responseType: PendingRegistrationsResponse.self)
        return response.pending
    }

    func getUnactivatedTagsForQRCode(_ qrCode: String) async throws -> [UnactivatedOrderItem] {
        let request = try await buildRequest(endpoint: "/orders/unactivated-for-qr/\(qrCode)")
        let response = try await performRequest(request, responseType: UnactivatedTagsResponse.self)
        return response.unactivated
    }

    func checkReplacementEligibility() async throws -> ReplacementEligibilityResponse {
        let request = try await buildRequest(
            endpoint: "/orders/replacement/check-eligibility",
            method: "GET",
            requiresAuth: true
        )
        return try await performRequest(request, responseType: ReplacementEligibilityResponse.self)
    }

    func createReplacementOrder(petId: String, shippingAddress: ShippingAddress, deliveryMethod: String? = nil, postapointDetails: PostaPointDetails? = nil) async throws -> ReplacementOrderResponse {
        let request = try await buildRequest(
            endpoint: "/orders/replacement/\(petId)",
            method: "POST",
            body: CreateReplacementOrderRequest(shippingAddress: shippingAddress, deliveryMethod: deliveryMethod, postapointDetails: postapointDetails),
            requiresAuth: true
        )
        return try await performRequest(request, responseType: ReplacementOrderResponse.self)
    }

    func getDeliveryPoints(zipCode: String) async throws -> [DeliveryPoint] {
        let request = try await buildRequest(
            endpoint: "/orders/delivery-points?zipCode=\(zipCode)",
            method: "GET",
            requiresAuth: false
        )
        return try await performRequest(request, responseType: [DeliveryPoint].self)
    }

    func createTagOrder(_ orderData: CreateTagOrderRequest) async throws -> CreateTagOrderResponse {
        let request = try await buildRequest(
            endpoint: "/orders",
            method: "POST",
            body: orderData,
            requiresAuth: false
        )
        return try await performRequest(request, responseType: CreateTagOrderResponse.self)
    }

    func createTagCheckout(
        quantity: Int,
        countryCode: String? = nil,
        deliveryMethod: String? = nil,
        postapointDetails: PostaPointDetails? = nil
    ) async throws -> TagCheckoutData {
        #if DEBUG
        print("📡 API: Creating tag checkout for \(quantity) tags...")
        #endif

        let request = try await buildRequest(
            endpoint: "/orders/create-checkout",
            method: "POST",
            body: CreateTagCheckoutRequest(quantity: quantity, countryCode: countryCode, platform: "ios", deliveryMethod: deliveryMethod, postapointDetails: postapointDetails)
        )
        let response: TagCheckoutResponse = try await performRequest(request, responseType: TagCheckoutResponse.self)
        return response.checkout
    }

    // MARK: - App Config

    /// Public runtime config exposed by the backend. Fetched at app start to
    /// gate the proceed-to-payment buttons on `tagsAvailable`. No auth.
    func getAppConfig() async throws -> AppConfig {
        let request = try await buildRequest(endpoint: "/config", requiresAuth: false)
        return try await performRequest(request, responseType: AppConfig.self)
    }

    // MARK: - Notifications Inbox

    func getNotifications(page: Int = 1, limit: Int = 20) async throws -> NotificationsPageResponse {
        let request = try await buildRequest(endpoint: "/notifications?page=\(page)&limit=\(limit)")
        return try await performRequest(request, responseType: NotificationsPageResponse.self)
    }

    func getUnreadNotificationCount() async throws -> Int {
        let request = try await buildRequest(endpoint: "/notifications/unread-count")
        let response = try await performRequest(request, responseType: UnreadCountResponse.self)
        return response.count
    }

    func markNotificationAsRead(_ id: String) async throws {
        let request = try await buildRequest(endpoint: "/notifications/\(id)/read", method: "PATCH")
        _ = try await performRequest(request, responseType: EmptyResponse.self)
    }

    func markAllNotificationsAsRead() async throws {
        let request = try await buildRequest(endpoint: "/notifications/read-all", method: "PATCH")
        _ = try await performRequest(request, responseType: EmptyResponse.self)
    }

    func getShippingPrices() async throws -> ShippingPricesResponse {
        let request = try await buildRequest(
            endpoint: "/orders/shipping-prices",
            method: "GET",
            requiresAuth: false
        )
        return try await performRequest(request, responseType: ShippingPricesResponse.self)
    }

}

extension APIService: APIServiceProtocol {}

// MARK: - Helper Types
struct ErrorResponse: Codable {
    let error: String
    let code: String?
    let details: [String: JSONValue]?
}

struct SubscriptionLimitResponse: Codable {
    let current_plan: String
    let current_pet_count: Int
    let max_pets: Int
    let upgrade_to: String
    let upgrade_price: String
}

struct PetLimitErrorResponse: Codable {
    let success: Bool
    let error: String
    let subscription: SubscriptionLimitResponse?
}

struct ApiEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
    let code: String?
    let details: [String: JSONValue]?
}

enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(
                JSONValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

struct EmptyResponse: Codable {}

struct EmptyBody: Codable {}

struct UserResponse: Codable {
    let user: User
}

struct ProfileImageResponse: Decodable {
    let profileImage: String
}

struct PetsResponse: Codable {
    let pets: [Pet]
}

struct PetResponse: Codable {
    let pet: Pet
}

struct AlertsResponse: Codable {
    let alerts: [MissingPetAlert]
}

struct AlertResponse: Codable {
    let alert: MissingPetAlert
    let message: String?
}

struct SightingResponse: Codable {
    let sighting: Sighting
    let message: String?
}

struct OrdersResponse: Decodable {
    let orders: [Order]
}

struct ImageUploadResponse: Codable {
    let imageUrl: String
    let pet: PartialPet

    struct PartialPet: Codable {
        let profileImage: String?

        enum CodingKeys: String, CodingKey {
            case profileImage = "profile_image"
        }
    }
}

struct DynamicBody: Encodable {
    let dictionary: [String: Any]

    init(_ dictionary: [String: Any]) {
        self.dictionary = dictionary
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        for (key, value) in dictionary {
            let codingKey = DynamicCodingKey(stringValue: key)!
            if let stringValue = value as? String {
                try container.encode(stringValue, forKey: codingKey)
            } else if let intValue = value as? Int {
                try container.encode(intValue, forKey: codingKey)
            } else if let doubleValue = value as? Double {
                try container.encode(doubleValue, forKey: codingKey)
            } else if let boolValue = value as? Bool {
                try container.encode(boolValue, forKey: codingKey)
            }
        }
    }
}

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

// MARK: - Shipping Address Types
struct ShippingAddress: Codable {
    let street1: String
    let street2: String?
    let city: String
    let province: String?
    let postCode: String
    let country: String
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case street1, street2, city, province, country, phone
        case postCode = "postCode"
    }
}

struct CreateReplacementOrderRequest: Codable {
    let shippingAddress: ShippingAddress
    var platform: String = "ios"
    let deliveryMethod: String?
    let postapointDetails: PostaPointDetails?
}

struct ReplacementOrderResponse: Decodable {
    let order: Order
    let requiresPayment: Bool?
    let shippingCost: Double?
    let checkoutUrl: String?
    let message: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        order = try container.decode(Order.self, forKey: .order)
        requiresPayment = try container.decodeIfPresent(Bool.self, forKey: .requiresPayment)
        if let d = try? container.decodeIfPresent(Double.self, forKey: .shippingCost) {
            shippingCost = d
        } else if let s = try? container.decodeIfPresent(String.self, forKey: .shippingCost), let d = Double(s) {
            shippingCost = d
        } else {
            shippingCost = nil
        }
        checkoutUrl = try container.decodeIfPresent(String.self, forKey: .checkoutUrl)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }

    enum CodingKeys: String, CodingKey {
        case order, requiresPayment, shippingCost, checkoutUrl, message
    }
}

struct ReplacementEligibilityResponse: Decodable {
    let isFreeReplacement: Bool
    let planName: String
    let shippingCost: Double
    /// Backend-resolved currency (HUF for HU, NOK for NO, EUR otherwise).
    /// Optional because older builds of the backend didn't return it.
    let currency: String?
    let message: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isFreeReplacement = try container.decode(Bool.self, forKey: .isFreeReplacement)
        planName = try container.decode(String.self, forKey: .planName)
        if let d = try? container.decode(Double.self, forKey: .shippingCost) {
            shippingCost = d
        } else if let s = try? container.decode(String.self, forKey: .shippingCost), let d = Double(s) {
            shippingCost = d
        } else {
            shippingCost = 0
        }
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        message = try container.decode(String.self, forKey: .message)
    }

    enum CodingKeys: String, CodingKey {
        case isFreeReplacement, planName, shippingCost, currency, message
    }
}

// MARK: - Shipping Prices Types
struct ShippingPriceInfo: Decodable {
    let amount: Double
    let currency: String
    let label: String

    init(amount: Double, currency: String, label: String) {
        self.amount = amount
        self.currency = currency
        self.label = label
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let d = try? container.decode(Double.self, forKey: .amount) {
            amount = d
        } else if let s = try? container.decode(String.self, forKey: .amount), let d = Double(s) {
            amount = d
        } else {
            amount = 0
        }
        currency = try container.decode(String.self, forKey: .currency)
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case amount, currency, label
    }

    /// Format the price in a locale-aware way: HUF → "1 490 Ft", EUR → "€4.99"
    var formattedPrice: String {
        if currency == "HUF" {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.groupingSeparator = "\u{00A0}" // non-breaking space
            let formatted = formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
            return "\(formatted) Ft"
        } else {
            return String(format: "€%.2f", amount)
        }
    }
}

struct ShippingPricesCountry: Decodable {
    let home_delivery: ShippingPriceInfo?
    let postapoint: ShippingPriceInfo?
}

struct ShippingPricesResponse: Decodable {
    let HU: ShippingPricesCountry?

    // `default` is a Swift keyword, so we use a CodingKey
    let defaultShipping: ShippingPriceInfo?

    enum CodingKeys: String, CodingKey {
        case HU
        case defaultShipping = "default"
    }
}

// MARK: - Order More Tags Types
struct CreateTagOrderRequest: Codable {
    let petNames: [String]
    let ownerName: String
    let email: String
    let shippingAddress: ShippingAddressDetails
    let billingAddress: ShippingAddressDetails?
    let paymentMethod: String?
    let shippingCost: Double?
    let deliveryMethod: String?
    let postapointDetails: PostaPointDetails?
}

struct ShippingAddressDetails: Codable {
    let street1: String
    let street2: String?
    let city: String
    let province: String?
    let postCode: String
    let country: String
    let phone: String?
}

struct CreateTagOrderResponse: Decodable {
    let order: Order
    let userCreated: Bool?
    let userId: String?
    let message: String
}

// MARK: - Location Sharing Types

/// Precise GPS coordinates supplied with the share-location request.
/// 2026-05-02 missing-pet flow overhaul removed the precise/approximate
/// toggle — the backend rejects any payload that includes the legacy
/// `is_approximate`, `consent_type`, or `share_exact_location` fields.
struct LocationConsentData: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy_meters: Double
}

/// Response for /qr-tags/share-location.
struct ShareLocationResponse: Codable {
    let scan_id: String?
    let pet: PetSummary?
    let is_missing: Bool?
    let owner_notified: Bool?
    let location_shared: Bool?
    /// 'not_attempted' (GPS path), 'success' (manual address geocoded), or
    /// 'failed' (manual address kept as text only). Clients usually don't
    /// branch on this — the success toast wording is identical — but it's
    /// surfaced so future analytics / UI hints can use it.
    let geocoding_status: String?
    let manual_address_recorded: Bool?

    struct PetSummary: Codable {
        let name: String
        let species: String?
        let image_url: String?
    }
}

// MARK: - Mark Missing/Found Types
struct LocationCoordinate: Codable {
    let lat: Double
    let lng: Double
}

struct MarkMissingResponse: Codable {
    let pet: Pet
    let alert: AlertInfo?
    let message: String
}

struct AlertInfo: Codable {
    let id: String
}

// MARK: - Notification Preferences Extension
extension APIService {
    /// Get user's notification preferences
    func getNotificationPreferences() async throws -> NotificationPreferences {
        #if DEBUG
        print("📡 API: Getting notification preferences...")
        #endif

        let request = try await buildRequest(
            endpoint: "/users/me/notification-preferences",
            method: "GET"
        )

        let (data, response) = try await CertificatePinningService.shared.pinnedSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        print("📡 API: Response status: \(httpResponse.statusCode)")
        #endif

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .flexibleISO8601

        if (200...299).contains(httpResponse.statusCode) {
            let envelope = try decoder.decode(ApiEnvelope<NotificationPreferencesResponse>.self, from: data)
            if let preferences = envelope.data?.preferences {
                #if DEBUG
                print("✅ API: Notification preferences retrieved")
                #endif
                return preferences
            }
            throw APIError.decodingError
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
            let detailsText = formatErrorDetails(errorResponse.details)
            if let detailsText {
                throw APIError.serverError("\(errorResponse.error) (\(detailsText))")
            }
            throw APIError.serverError(errorResponse.error)
        }
        throw APIError.serverError("Failed to get notification preferences")
    }

    /// Update user's notification preferences.
    ///
    /// 2026-05-05 fix: optionally takes a `previous` snapshot. When
    /// supplied, only the channels whose values DIFFER from the snapshot
    /// are sent in the body. The pre-fix code always sent all three
    /// fields, so a stale local copy could clobber a change made from
    /// another device (Android, web) — last-write-wins on full state.
    /// Backend already supports partial PUT (each `if (notifyByX !==
    /// undefined)` branch independently), so the fix is client-side.
    /// Pass nil for `previous` to keep the legacy "send everything"
    /// behaviour (one remaining caller does that intentionally).
    func updateNotificationPreferences(
        _ preferences: NotificationPreferences,
        previous: NotificationPreferences? = nil
    ) async throws -> NotificationPreferences {
        #if DEBUG
        print("📡 API: Updating notification preferences...")
        #endif

        // Validate preferences before sending
        guard preferences.isValid else {
            throw APIError.serverError("At least one notification method must be enabled")
        }

        var body: [String: Bool] = [:]
        if let previous {
            if preferences.notifyByEmail != previous.notifyByEmail {
                body["notifyByEmail"] = preferences.notifyByEmail
            }
            if preferences.notifyBySms != previous.notifyBySms {
                body["notifyBySms"] = preferences.notifyBySms
            }
            if preferences.notifyByPush != previous.notifyByPush {
                body["notifyByPush"] = preferences.notifyByPush
            }
            // No fields actually changed — short-circuit and return the
            // preferences as-is so the caller's "saved!" toast still fires.
            if body.isEmpty {
                return preferences
            }
        } else {
            body = [
                "notifyByEmail": preferences.notifyByEmail,
                "notifyBySms": preferences.notifyBySms,
                "notifyByPush": preferences.notifyByPush,
            ]
        }

        let request = try await buildRequest(
            endpoint: "/users/me/notification-preferences",
            method: "PUT",
            body: body
        )

        let (data, response) = try await CertificatePinningService.shared.pinnedSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        print("📡 API: Response status: \(httpResponse.statusCode)")
        #endif

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .flexibleISO8601

        if (200...299).contains(httpResponse.statusCode) {
            let envelope = try decoder.decode(ApiEnvelope<NotificationPreferencesResponse>.self, from: data)
            if let preferences = envelope.data?.preferences {
                #if DEBUG
                print("✅ API: Notification preferences updated")
                #endif
                return preferences
            }
            throw APIError.decodingError
        }

        if httpResponse.statusCode == 400 {
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                let detailsText = formatErrorDetails(errorResponse.details)
                if let detailsText {
                    throw APIError.serverError("\(errorResponse.error) (\(detailsText))")
                }
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.serverError("Invalid preferences: At least one notification method must be enabled")
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
            let detailsText = formatErrorDetails(errorResponse.details)
            if let detailsText {
                throw APIError.serverError("\(errorResponse.error) (\(detailsText))")
            }
            throw APIError.serverError(errorResponse.error)
        }
        throw APIError.serverError("Failed to update notification preferences")
    }

    // MARK: - Success Stories

    /// Get public success stories near a location
    func getPublicSuccessStories(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 10,
        page: Int = 1,
        limit: Int = 10
    ) async throws -> SuccessStoriesResponse {
        #if DEBUG
        print("📡 API: Fetching public success stories...")
        #endif

        let endpoint = "/success-stories?lat=\(latitude)&lng=\(longitude)&radius=\(radiusKm)&page=\(page)&limit=\(limit)"
        let request = try await buildRequest(endpoint: endpoint, requiresAuth: false)

        return try await performRequest(request, responseType: SuccessStoriesResponse.self)
    }

    /// Get success stories for a specific pet
    func getSuccessStoriesForPet(petId: String) async throws -> [SuccessStory] {
        #if DEBUG
        print("📡 API: Fetching success stories for pet \(petId)...")
        #endif

        let request = try await buildRequest(endpoint: "/success-stories/pet/\(petId)")
        return try await performRequest(request, responseType: [SuccessStory].self)
    }

    /// Create a new success story
    func createSuccessStory(_ story: CreateSuccessStoryRequest) async throws -> SuccessStory {
        #if DEBUG
        print("📡 API: Creating success story...")
        #endif

        let request = try await buildRequest(endpoint: "/success-stories", method: "POST", body: story)
        return try await performRequest(request, responseType: SuccessStory.self)
    }

    /// Create a success story with simple parameters (for SuccessStoryPromptView)
    func createSuccessStorySimple(
        petId: String,
        alertId: String? = nil,
        storyText: String?,
        reunionCity: String?,
        reunionLatitude: Double?,
        reunionLongitude: Double?,
        isPublic: Bool
    ) async throws -> SuccessStory {
        #if DEBUG
        print("📡 API: Creating success story for pet \(petId)...")
        #endif

        var requestBody: [String: Any] = [
            "petId": petId,
            "isPublic": isPublic,
            "autoConfirm": true
        ]

        if let alertId = alertId {
            requestBody["alertId"] = alertId
        }
        if let storyText = storyText {
            requestBody["storyText"] = storyText
        }
        if let reunionCity = reunionCity {
            requestBody["reunionCity"] = reunionCity
        }
        if let lat = reunionLatitude {
            requestBody["reunionLatitude"] = lat
        }
        if let lng = reunionLongitude {
            requestBody["reunionLongitude"] = lng
        }

        let request = try await buildRequest(
            endpoint: "/success-stories",
            method: "POST",
            body: DynamicBody(requestBody)
        )
        return try await performRequest(request, responseType: SuccessStory.self)
    }

    /// Update a success story
    func updateSuccessStory(id: String, updates: UpdateSuccessStoryRequest) async throws -> SuccessStory {
        #if DEBUG
        print("📡 API: Updating success story \(id)...")
        #endif

        let request = try await buildRequest(endpoint: "/success-stories/\(id)", method: "PATCH", body: updates)
        return try await performRequest(request, responseType: SuccessStory.self)
    }

    /// Delete a success story
    func deleteSuccessStory(id: String) async throws {
        #if DEBUG
        print("📡 API: Deleting success story \(id)...")
        #endif

        let request = try await buildRequest(endpoint: "/success-stories/\(id)", method: "DELETE")
        _ = try await performRequest(request, responseType: EmptyResponse.self)

        #if DEBUG
        print("✅ API: Success story deleted")
        #endif
    }

    /// Upload a photo for a success story
    func uploadSuccessStoryPhoto(storyId: String, imageData: Data) async throws -> SuccessStoryPhoto {
        #if DEBUG
        print("📡 API: Uploading success story photo...")
        #endif

        guard let url = URL(string: baseURL + "/success-stories/\(storyId)/photos") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        return try await performRequest(request, responseType: SuccessStoryPhoto.self)
    }

    // MARK: - Subscriptions

    /// Get user's current subscription (read-only; purchase/cancel happens on senra.pet)
    func getMySubscription() async throws -> UserSubscription? {
        #if DEBUG
        print("📡 API: Fetching user subscription...")
        #endif

        let request = try await buildRequest(endpoint: "/subscriptions/my-subscription")
        let response = try await performRequest(request, responseType: MySubscriptionResponse.self)
        return response.subscription
    }

    /// Fetch the user's Stripe-billed invoices.
    /// Backend caps `limit` at 100; the default of 24 covers two years
    /// of monthly billing comfortably.
    func getInvoices(limit: Int = 24) async throws -> [Invoice] {
        #if DEBUG
        print("📡 API: Fetching invoices…")
        #endif

        let request = try await buildRequest(endpoint: "/billing/invoices?limit=\(limit)")
        let response = try await performRequest(request, responseType: InvoicesResponse.self)
        return response.invoices
    }

    /// Apply a referral code
    func applyReferralCode(_ code: String) async throws -> ReferralApplyResponse {
        #if DEBUG
        print("📡 API: Applying referral code \(code)...")
        #endif

        let request = try await buildRequest(
            endpoint: "/referrals/apply",
            method: "POST",
            body: ReferralApplyRequest(code: code)
        )
        return try await performRequest(request, responseType: ReferralApplyResponse.self)
    }

    /// Get subscription features for current plan (read-only feature flags)
    func getSubscriptionFeatures() async throws -> SubscriptionFeatures {
        #if DEBUG
        print("📡 API: Fetching subscription features...")
        #endif

        let request = try await buildRequest(endpoint: "/subscriptions/features")
        return try await performRequest(request, responseType: SubscriptionFeatures.self)
    }

    // MARK: - Referral Program

    /// Generate a referral code for the current user
    func generateReferralCode() async throws -> ReferralCodeResponse {
        #if DEBUG
        print("📡 API: Generating referral code...")
        #endif

        let request = try await buildRequest(
            endpoint: "/referrals/generate-code",
            method: "POST",
            body: EmptyBody()
        )
        return try await performRequest(request, responseType: ReferralCodeResponse.self)
    }

    /// Get referral status (code + history)
    func getReferralStatus() async throws -> ReferralStatusResponse {
        #if DEBUG
        print("📡 API: Fetching referral status...")
        #endif

        let request = try await buildRequest(endpoint: "/referrals/status")
        return try await performRequest(request, responseType: ReferralStatusResponse.self)
    }

    // MARK: - Account Deletion

    /// Check if user can delete their account (no missing pets)
    func canDeleteAccount() async throws -> CanDeleteAccountResponse {
        #if DEBUG
        print("📡 API: Checking if account can be deleted...")
        #endif

        let request = try await buildRequest(endpoint: "/users/me/can-delete")
        return try await performRequest(request, responseType: CanDeleteAccountResponse.self)
    }

    /// Delete user account (GDPR-compliant)
    /// - Anonymizes personal data
    /// - Cancels active subscriptions
    /// - Soft-deletes pets
    func deleteAccount() async throws -> DeleteAccountResponse {
        #if DEBUG
        print("📡 API: Deleting user account...")
        #endif

        let request = try await buildRequest(
            endpoint: "/users/me/delete",
            method: "POST",
            body: DeleteAccountRequest(confirmDelete: true)
        )
        return try await performRequest(request, responseType: DeleteAccountResponse.self)
    }
}

// MARK: - Account Deletion Types
struct CanDeleteAccountResponse: Codable {
    let canDelete: Bool
    let reason: String?
    let message: String?
    let missingPets: [MissingPetInfo]?
}

struct MissingPetInfo: Codable {
    let id: String
    let name: String
}

struct DeleteAccountRequest: Codable {
    let confirmDelete: Bool
}

struct DeleteAccountResponse: Codable {
    let message: String
}

// MARK: - Support Contact Types
struct SupportRequest: Codable {
    let category: String
    let subject: String
    let message: String
}

struct SupportResponse: Codable {
    let ticketId: String
    let message: String
}

// MARK: - FCM Tokens Extension
extension APIService {
    /// Register an FCM token with the backend. Uses the standard request
    /// pipeline so the call gets 401 auto-refresh, App Check, and Sentry
    /// breadcrumbs — previously FCMService had its own URLSession which
    /// silently swallowed transient auth failures.
    func registerFCMToken(token: String, deviceName: String?) async throws {
        struct FCMRegisterRequest: Codable {
            let token: String
            let platform: String
            let device_name: String?
        }

        let request = try await buildRequest(
            endpoint: "/users/me/fcm-tokens",
            method: "POST",
            body: FCMRegisterRequest(token: token, platform: "ios", device_name: deviceName)
        )
        _ = try await performRequest(request, responseType: EmptyResponse.self)
    }

    /// Remove an FCM token from the backend (called on logout).
    func unregisterFCMToken(token: String) async throws {
        let encodedToken = token.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? token
        let request = try await buildRequest(
            endpoint: "/users/me/fcm-tokens/\(encodedToken)",
            method: "DELETE"
        )
        _ = try await performRequest(request, responseType: EmptyResponse.self)
    }
}

// MARK: - Support Contact Extension
extension APIService {
    /// Submit a support request
    func submitSupportRequest(category: String, subject: String, message: String) async throws -> SupportResponse {
        #if DEBUG
        print("📡 API: Submitting support request...")
        #endif

        let request = try await buildRequest(
            endpoint: "/contact/support",
            method: "POST",
            body: SupportRequest(category: category, subject: subject, message: message)
        )
        return try await performRequest(request, responseType: SupportResponse.self)
    }
}

// MARK: - Token Refresh Coordinator
/// Actor that serializes concurrent token refresh attempts so only one
/// network call is made, and all waiting callers receive the same result.
/// `internal` (not `private`) so XCTest can pin behaviour parity with
/// the web TokenRefreshCoordinator and Android TokenAuthenticator
/// without going through the full APIService stack (audit H50).
internal actor TokenRefreshCoordinator {
    private var isRefreshing = false
    private var refreshTask: Task<(accessToken: String, refreshToken: String), Error>?

    /// Timeout for token refresh operations (15 seconds)
    private let refreshTimeoutNanoseconds: UInt64 = 15_000_000_000

    func refresh(
        using refreshClosure: @Sendable @escaping () async throws -> (accessToken: String, refreshToken: String)
    ) async throws -> (accessToken: String, refreshToken: String) {
        // If a refresh is already in flight, wait for it
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        let task = Task<(accessToken: String, refreshToken: String), Error> {
            try await refreshClosure()
        }
        refreshTask = task

        // Start a timeout task that cancels the refresh if it takes too long
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: refreshTimeoutNanoseconds)
            task.cancel()
        }

        do {
            let result = try await task.value
            timeoutTask.cancel()
            refreshTask = nil
            return result
        } catch {
            timeoutTask.cancel()
            refreshTask = nil
            throw error
        }
    }
}
