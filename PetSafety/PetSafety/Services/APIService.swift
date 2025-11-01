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
    private let baseURL = "https://your-backend-url.com/api" // TODO: Update with actual backend URL
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
            request.httpBody = try JSONEncoder().encode(body)
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
                    print("Decoding error: \(error)")
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
            endpoint: "/auth/login",
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
        let request = try buildRequest(endpoint: "/users/profile")
        return try await performRequest(request, responseType: User.self)
    }

    func updateUser(_ updates: [String: Any]) async throws -> User {
        let request = try buildRequest(
            endpoint: "/users/profile",
            method: "PUT",
            body: DynamicBody(updates)
        )
        return try await performRequest(request, responseType: User.self)
    }

    // MARK: - Pets
    func getPets() async throws -> [Pet] {
        let request = try buildRequest(endpoint: "/pets")
        return try await performRequest(request, responseType: [Pet].self)
    }

    func getPet(id: Int) async throws -> Pet {
        let request = try buildRequest(endpoint: "/pets/\(id)")
        return try await performRequest(request, responseType: Pet.self)
    }

    func createPet(_ petData: CreatePetRequest) async throws -> Pet {
        let request = try buildRequest(
            endpoint: "/pets",
            method: "POST",
            body: petData
        )
        return try await performRequest(request, responseType: Pet.self)
    }

    func updatePet(id: Int, _ updates: UpdatePetRequest) async throws -> Pet {
        let request = try buildRequest(
            endpoint: "/pets/\(id)",
            method: "PUT",
            body: updates
        )
        return try await performRequest(request, responseType: Pet.self)
    }

    func deletePet(id: Int) async throws {
        let request = try buildRequest(
            endpoint: "/pets/\(id)",
            method: "DELETE"
        )
        let _: EmptyResponse = try await performRequest(request, responseType: EmptyResponse.self)
    }

    func uploadPetPhoto(petId: Int, imageData: Data) async throws -> Pet {
        guard let url = URL(string: baseURL + "/pets/\(petId)/photo") else {
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

        return try await performRequest(request, responseType: Pet.self)
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

    func updateAlertStatus(id: Int, status: String) async throws -> MissingPetAlert {
        let request = try buildRequest(
            endpoint: "/alerts/\(id)/status",
            method: "PUT",
            body: ["status": status]
        )
        return try await performRequest(request, responseType: MissingPetAlert.self)
    }

    func reportSighting(alertId: Int, sighting: ReportSightingRequest) async throws -> Sighting {
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
}

// MARK: - Helper Types
struct ErrorResponse: Codable {
    let error: String
}

struct EmptyResponse: Codable {}

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
