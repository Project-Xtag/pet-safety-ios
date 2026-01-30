import Foundation
import Sentry

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode server response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
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
        return configuredURL.isEmpty ? "https://pet-er.app/api" : configuredURL
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

    private init() {
        // Migrate existing tokens from UserDefaults to Keychain (one-time migration)
        KeychainService.shared.migrateFromUserDefaults()
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

        // Add Firebase App Check token for API protection
        // This verifies the request comes from a legitimate app instance
        if let appCheckToken = await ConfigurationManager.shared.getAppCheckToken() {
            request.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
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
        responseType: T.Type
    ) async throws -> T {
        // Add Sentry breadcrumb for API request tracking
        let crumb = Breadcrumb(level: .info, category: "http")
        crumb.message = "\(request.httpMethod ?? "GET") \(request.url?.path ?? "")"
        SentrySDK.addBreadcrumb(crumb)

        do {
            let (data, response) = try await CertificatePinningService.shared.pinnedSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

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
                authToken = nil
                throw APIError.unauthorized

            default:
                // Capture 5xx server errors to Sentry
                if httpResponse.statusCode >= 500 {
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
        let request = try await buildRequest(
            endpoint: "/auth/send-otp",
            method: "POST",
            body: LoginRequest(email: email),
            requiresAuth: false
        )
        return try await performRequest(request, responseType: LoginResponse.self)
    }

    func verifyOTP(email: String, code: String) async throws -> VerifyOTPResponse {
        let request = try await buildRequest(
            endpoint: "/auth/verify-otp",
            method: "POST",
            body: VerifyOTPRequest(email: email, code: code),
            requiresAuth: false
        )
        let response = try await performRequest(request, responseType: VerifyOTPResponse.self)
        authToken = response.token
        return response
    }

    func logout() {
        authToken = nil
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
        rewardAmount: Double? = nil
    ) async throws -> MarkMissingResponse {
        struct MarkMissingRequest: Codable {
            let lastSeenLocation: LocationCoordinate?
            let lastSeenAddress: String?
            let description: String?
            let rewardAmount: Double?
        }

        let requestBody = MarkMissingRequest(
            lastSeenLocation: location,
            lastSeenAddress: address,
            description: description,
            rewardAmount: rewardAmount
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
            age: nil,
            weight: nil,
            microchipNumber: nil,
            medicalNotes: nil,
            allergies: nil,
            medications: nil,
            notes: nil,
            uniqueFeatures: nil,
            sex: nil,
            isNeutered: nil,
            isMissing: false
        )

        let request = try await buildRequest(
            endpoint: "/pets/\(petId)",
            method: "PUT",
            body: updates
        )
        let response = try await performRequest(request, responseType: PetResponse.self)
        return response.pet
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

    // Share finder's location with pet owner (no auth required)
    // Supports 3-tier GDPR-compliant location consent: none, approximate, precise
    func shareLocation(
        qrCode: String,
        location: LocationConsentData? = nil,
        address: String? = nil
    ) async throws -> ShareLocationResponse {
        struct ShareLocationRequest: Codable {
            let qrCode: String
            let location: LocationConsentData?
            let address: String?
        }

        let request = try await buildRequest(
            endpoint: "/qr-tags/share-location",
            method: "POST",
            body: ShareLocationRequest(
                qrCode: qrCode,
                location: location,
                address: address
            ),
            requiresAuth: false
        )
        return try await performRequest(request, responseType: ShareLocationResponse.self)
    }

    /// Legacy share location method for backwards compatibility
    func shareLocationLegacy(
        qrCode: String,
        latitude: Double,
        longitude: Double,
        address: String? = nil
    ) async throws -> ShareLocationResponse {
        // Convert to 3-tier format with precise location
        let location = LocationConsentData(
            latitude: latitude,
            longitude: longitude,
            accuracy_meters: 10,
            is_approximate: false,
            consent_type: .precise
        )
        return try await shareLocation(qrCode: qrCode, location: location, address: address)
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

    func checkReplacementEligibility() async throws -> ReplacementEligibilityResponse {
        let request = try await buildRequest(
            endpoint: "/orders/replacement/check-eligibility",
            method: "GET",
            requiresAuth: true
        )
        return try await performRequest(request, responseType: ReplacementEligibilityResponse.self)
    }

    func createReplacementOrder(petId: String, shippingAddress: ShippingAddress) async throws -> ReplacementOrderResponse {
        let request = try await buildRequest(
            endpoint: "/orders/replacement/\(petId)",
            method: "POST",
            body: CreateReplacementOrderRequest(shippingAddress: shippingAddress),
            requiresAuth: true
        )
        return try await performRequest(request, responseType: ReplacementOrderResponse.self)
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

    func createPaymentIntent(
        orderId: String,
        amount: Double,
        email: String?,
        paymentMethod: String? = nil,
        currency: String? = nil,
        requiresAuth: Bool = true
    ) async throws -> PaymentIntentResponse {
        let request = try await buildRequest(
            endpoint: "/payments/intent",
            method: "POST",
            body: CreatePaymentIntentRequest(
                orderId: orderId,
                amount: amount,
                paymentMethod: paymentMethod,
                currency: currency,
                email: email
            ),
            requiresAuth: requiresAuth
        )
        return try await performRequest(request, responseType: PaymentIntentResponse.self)
    }

    func getPaymentIntent(paymentIntentId: String) async throws -> PaymentIntentStatusResponse {
        let request = try await buildRequest(
            endpoint: "/payments/intent/\(paymentIntentId)",
            method: "GET",
            requiresAuth: true
        )
        return try await performRequest(request, responseType: PaymentIntentStatusResponse.self)
    }
}

extension APIService: APIServiceProtocol {}

// MARK: - Helper Types
struct ErrorResponse: Codable {
    let error: String
    let code: String?
    let details: [String: JSONValue]?
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

struct OrdersResponse: Codable {
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
}

struct ReplacementOrderResponse: Codable {
    let order: Order
    let requiresPayment: Bool?
    let shippingCost: Double?
    let message: String?
}

struct ReplacementEligibilityResponse: Codable {
    let isFreeReplacement: Bool
    let planName: String
    let shippingCost: Double
    let message: String
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

struct CreateTagOrderResponse: Codable {
    let order: Order
    let userCreated: Bool?
    let userId: String?
    let message: String
}

// MARK: - Location Sharing Types (3-Tier GDPR Consent)

/// Location consent type for GDPR compliance
enum LocationConsentType: String, Codable {
    case approximate = "approximate"
    case precise = "precise"
}

/// Location data with consent type for GDPR compliance
struct LocationConsentData: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy_meters: Double
    let is_approximate: Bool
    let consent_type: LocationConsentType
}

/// Updated response for share-location endpoint
struct ShareLocationResponse: Codable {
    // New format fields
    let scan_id: String?
    let pet: PetSummary?
    let is_missing: Bool?
    let owner_notified: Bool?
    let location_shared: Bool?
    let location_type: String?

    // Legacy format fields (for backwards compatibility)
    let message: String?
    let sightingId: String?
    let sentSMS: Bool?
    let sentEmail: Bool?
    let sentPush: Bool?

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
        decoder.dateDecodingStrategy = .iso8601

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

    /// Update user's notification preferences
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async throws -> NotificationPreferences {
        #if DEBUG
        print("📡 API: Updating notification preferences...")
        #endif

        // Validate preferences before sending
        guard preferences.isValid else {
            throw APIError.serverError("At least one notification method must be enabled")
        }

        let body = [
            "notifyByEmail": preferences.notifyByEmail,
            "notifyBySms": preferences.notifyBySms,
            "notifyByPush": preferences.notifyByPush
        ]

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
        decoder.dateDecodingStrategy = .iso8601

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
        isPublic: Bool
    ) async throws -> SuccessStory {
        #if DEBUG
        print("📡 API: Creating success story for pet \(petId)...")
        #endif

        var requestBody: [String: Any] = [
            "pet_id": petId,
            "is_public": isPublic
        ]

        if let alertId = alertId {
            requestBody["alert_id"] = alertId
        }
        if let storyText = storyText {
            requestBody["story_text"] = storyText
        }
        if let reunionCity = reunionCity {
            requestBody["reunion_city"] = reunionCity
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

    /// Get available subscription plans
    func getSubscriptionPlans() async throws -> [SubscriptionPlan] {
        #if DEBUG
        print("📡 API: Fetching subscription plans...")
        #endif

        let request = try await buildRequest(endpoint: "/subscriptions/plans", requiresAuth: false)
        let response = try await performRequest(request, responseType: SubscriptionPlansResponse.self)
        return response.plans
    }

    /// Get user's current subscription
    func getMySubscription() async throws -> UserSubscription? {
        #if DEBUG
        print("📡 API: Fetching user subscription...")
        #endif

        let request = try await buildRequest(endpoint: "/subscriptions/my-subscription")
        let response = try await performRequest(request, responseType: MySubscriptionResponse.self)
        return response.subscription
    }

    /// Create Stripe checkout session for subscription
    func createSubscriptionCheckout(
        planName: String,
        billingPeriod: String = "monthly"
    ) async throws -> SubscriptionCheckoutResponse {
        #if DEBUG
        print("📡 API: Creating subscription checkout for \(planName) (\(billingPeriod))...")
        #endif

        let request = try await buildRequest(
            endpoint: "/subscriptions/checkout",
            method: "POST",
            body: CreateCheckoutRequest(planName: planName, billingPeriod: billingPeriod)
        )
        return try await performRequest(request, responseType: SubscriptionCheckoutResponse.self)
    }

    /// Upgrade to Starter plan (free, no payment required)
    func upgradeToStarter() async throws -> UserSubscription {
        #if DEBUG
        print("📡 API: Upgrading to Starter plan...")
        #endif

        let request = try await buildRequest(
            endpoint: "/subscriptions/upgrade",
            method: "POST",
            body: UpgradeRequest(planName: "starter")
        )
        let response = try await performRequest(request, responseType: UpgradeResponse.self)
        return response.subscription
    }

    /// Get subscription features for current plan
    func getSubscriptionFeatures() async throws -> SubscriptionFeatures {
        #if DEBUG
        print("📡 API: Fetching subscription features...")
        #endif

        let request = try await buildRequest(endpoint: "/subscriptions/features")
        return try await performRequest(request, responseType: SubscriptionFeatures.self)
    }

    /// Cancel subscription
    func cancelSubscription() async throws -> UserSubscription {
        #if DEBUG
        print("📡 API: Cancelling subscription...")
        #endif

        let request = try await buildRequest(
            endpoint: "/subscriptions/cancel",
            method: "POST",
            body: EmptyBody()
        )
        let response = try await performRequest(request, responseType: CancelSubscriptionResponse.self)
        return response.subscription
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
