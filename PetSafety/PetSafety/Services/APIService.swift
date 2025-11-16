import Foundation

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

class APIService {
    static let shared = APIService()

    // MARK: - Configuration
    private let baseURL = "https://pet-er.app/api"
    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "auth_token") }
    }

    private init() {}

    // MARK: - Request Builder
    private func buildRequest(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            let encoder = JSONEncoder()
            let bodyData = try encoder.encode(body)
            request.httpBody = bodyData

            // Log the request body for debugging
            if let jsonString = String(data: bodyData, encoding: .utf8) {
                print("📤 API Request to \(endpoint):")
                print("Method: \(method)")
                print("Body: \(jsonString)")
            }
        }

        return request
    }

    // MARK: - Generic Request Method
    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type
    ) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    return try decoder.decode(T.self, from: data)
                } catch {
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
                    throw APIError.decodingError
                }

            case 401:
                authToken = nil
                throw APIError.unauthorized

            default:
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
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

    // MARK: - Authentication
    func login(email: String) async throws -> LoginResponse {
        let request = try buildRequest(
            endpoint: "/auth/send-otp",
            method: "POST",
            body: LoginRequest(email: email),
            requiresAuth: false
        )
        return try await performRequest(request, responseType: LoginResponse.self)
    }

    func verifyOTP(email: String, code: String) async throws -> VerifyOTPResponse {
        let request = try buildRequest(
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
        let request = try buildRequest(endpoint: "/users/me")
        let response = try await performRequest(request, responseType: UserResponse.self)
        return response.user
    }

    func updateUser(_ updates: [String: Any]) async throws -> User {
        let request = try buildRequest(
            endpoint: "/users/me",
            method: "PUT",
            body: DynamicBody(updates)
        )
        return try await performRequest(request, responseType: User.self)
    }

    // MARK: - Pets
    func getPets() async throws -> [Pet] {
        let request = try buildRequest(endpoint: "/pets")
        let response = try await performRequest(request, responseType: PetsResponse.self)
        return response.pets
    }

    func getPet(id: String) async throws -> Pet {
        let request = try buildRequest(endpoint: "/pets/\(id)")
        let response = try await performRequest(request, responseType: PetResponse.self)
        return response.pet
    }

    func createPet(_ petData: CreatePetRequest) async throws -> Pet {
        let request = try buildRequest(
            endpoint: "/pets",
            method: "POST",
            body: petData
        )
        let response = try await performRequest(request, responseType: PetResponse.self)
        return response.pet
    }

    func updatePet(id: String, _ updates: UpdatePetRequest) async throws -> Pet {
        let request = try buildRequest(
            endpoint: "/pets/\(id)",
            method: "PUT",
            body: updates
        )
        let response = try await performRequest(request, responseType: PetResponse.self)
        return response.pet
    }

    func deletePet(id: String) async throws {
        let request = try buildRequest(
            endpoint: "/pets/\(id)",
            method: "DELETE"
        )
        let _: EmptyResponse = try await performRequest(request, responseType: EmptyResponse.self)
    }

    func uploadPetPhoto(petId: String, imageData: Data) async throws -> Pet {
        // Backend expects /image not /photo
        let endpoint = "/pets/\(petId)/image"
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        print("📸 Uploading image to: \(url.absoluteString)")
        print("📸 Pet ID: \(petId)")
        print("📸 Image size: \(imageData.count) bytes")

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

        print("📸 Sending multipart request with field name 'image'...")
        let response = try await performRequest(request, responseType: ImageUploadResponse.self)
        print("✅ Image upload successful! URL: \(response.imageUrl)")

        // Need to fetch the full updated pet since backend only returns partial data
        print("📥 Fetching updated pet data...")
        return try await getPet(id: petId)
    }

    // MARK: - Alerts
    func getAlerts() async throws -> [MissingPetAlert] {
        let request = try buildRequest(endpoint: "/alerts")
        return try await performRequest(request, responseType: [MissingPetAlert].self)
    }

    func createAlert(_ alertData: CreateAlertRequest) async throws -> MissingPetAlert {
        let request = try buildRequest(
            endpoint: "/alerts",
            method: "POST",
            body: alertData
        )
        return try await performRequest(request, responseType: MissingPetAlert.self)
    }

    func updateAlertStatus(id: String, status: String) async throws -> MissingPetAlert {
        let request = try buildRequest(
            endpoint: "/alerts/\(id)/status",
            method: "PUT",
            body: ["status": status]
        )
        return try await performRequest(request, responseType: MissingPetAlert.self)
    }

    func reportSighting(alertId: String, sighting: ReportSightingRequest) async throws -> Sighting {
        let request = try buildRequest(
            endpoint: "/alerts/\(alertId)/sightings",
            method: "POST",
            body: sighting
        )
        return try await performRequest(request, responseType: Sighting.self)
    }

    // MARK: - QR Tags
    func scanQRCode(_ code: String) async throws -> ScanResponse {
        let request = try buildRequest(
            endpoint: "/qr-tags/scan/\(code)",
            requiresAuth: false
        )
        return try await performRequest(request, responseType: ScanResponse.self)
    }

    func activateTag(_ activation: ActivateTagRequest) async throws -> QRTag {
        let request = try buildRequest(
            endpoint: "/qr-tags/activate",
            method: "POST",
            body: activation
        )
        return try await performRequest(request, responseType: QRTag.self)
    }

    // MARK: - Orders
    func createOrder(_ orderData: CreateOrderRequest) async throws -> PaymentIntentResponse {
        let request = try buildRequest(
            endpoint: "/orders",
            method: "POST",
            body: orderData,
            requiresAuth: false
        )
        return try await performRequest(request, responseType: PaymentIntentResponse.self)
    }

    func getOrders() async throws -> [Order] {
        let request = try buildRequest(endpoint: "/orders")
        return try await performRequest(request, responseType: [Order].self)
    }

    func createReplacementOrder(petId: String, shippingAddress: ShippingAddress) async throws -> ReplacementOrderResponse {
        let request = try buildRequest(
            endpoint: "/orders/replacement/\(petId)",
            method: "POST",
            body: CreateReplacementOrderRequest(shippingAddress: shippingAddress),
            requiresAuth: true
        )
        return try await performRequest(request, responseType: ReplacementOrderResponse.self)
    }

    func createTagOrder(_ orderData: CreateTagOrderRequest) async throws -> CreateTagOrderResponse {
        let request = try buildRequest(
            endpoint: "/orders",
            method: "POST",
            body: orderData,
            requiresAuth: false
        )
        return try await performRequest(request, responseType: CreateTagOrderResponse.self)
    }
}

// MARK: - Helper Types
struct ErrorResponse: Codable {
    let error: String
}

struct EmptyResponse: Codable {}

struct UserResponse: Codable {
    let success: Bool
    let user: User
}

struct PetsResponse: Codable {
    let success: Bool
    let pets: [Pet]
}

struct PetResponse: Codable {
    let success: Bool
    let pet: Pet
}

struct ImageUploadResponse: Codable {
    let success: Bool
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

    enum CodingKeys: String, CodingKey {
        case street1, street2, city, province, country
        case postCode = "postCode"
    }
}

struct CreateReplacementOrderRequest: Codable {
    let shippingAddress: ShippingAddress
}

struct ReplacementOrderResponse: Codable {
    let success: Bool
    let order: Order
    let message: String?
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
}

struct CreateTagOrderResponse: Codable {
    let success: Bool
    let order: Order
    let userCreated: Bool?
    let userId: String?
    let message: String
}
