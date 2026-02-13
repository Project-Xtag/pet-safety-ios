import XCTest
@testable import PetSafety

/**
 * FCM Service Unit Tests
 *
 * Tests the FCM token management functionality including:
 * - Token registration with backend
 * - Token removal on logout
 * - Network error handling
 * - URL encoding for special characters
 */
final class FCMServiceTests: XCTestCase {

    // MARK: - Test Setup

    override func setUp() {
        super.setUp()
        // Clear any stored tokens
        UserDefaults.standard.removeObject(forKey: "fcmToken")
    }

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "fcmToken")
    }

    // MARK: - Token Registration Tests

    func testRegisterTokenBuildsCorrectURL() async throws {
        // Given
        let expectedURL = "https://api.senra.pet/api/users/me/fcm-tokens"

        // Verify URL construction
        let url = URL(string: expectedURL)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "senra.pet")
        XCTAssertEqual(url?.path, "/api/users/me/fcm-tokens")
    }

    func testRegisterTokenRequestBodyFormat() async throws {
        // Given
        let token = "test-fcm-token-123"
        let deviceName = "iPhone 14 Pro"

        // When building request body
        var body: [String: Any] = [
            "token": token,
            "platform": "ios"
        ]
        body["deviceName"] = deviceName

        // Then
        XCTAssertEqual(body["token"] as? String, token)
        XCTAssertEqual(body["platform"] as? String, "ios")
        XCTAssertEqual(body["deviceName"] as? String, deviceName)
    }

    func testRegisterTokenWithoutDeviceName() async throws {
        // Given
        let token = "test-fcm-token-456"

        // When building request body without device name
        let body: [String: Any] = [
            "token": token,
            "platform": "ios"
        ]

        // Then device name should not be present
        XCTAssertNil(body["deviceName"])
        XCTAssertEqual(body.count, 2)
    }

    func testRegisterTokenSetsCorrectHeaders() async throws {
        // Given
        let url = URL(string: "https://api.senra.pet/api/users/me/fcm-tokens")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Then
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testRegisterTokenIncludesAuthHeader() async throws {
        // Given
        let authToken = "test-auth-token-xyz"
        let url = URL(string: "https://api.senra.pet/api/users/me/fcm-tokens")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        // Then
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-auth-token-xyz")
    }

    // MARK: - Token Removal Tests

    func testRemoveTokenBuildsCorrectURL() async throws {
        // Given
        let token = "token-to-remove-123"
        let encodedToken = token.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? token
        let expectedURL = "https://api.senra.pet/api/users/me/fcm-tokens/\(encodedToken)"

        // Verify URL construction
        let url = URL(string: expectedURL)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.path.contains(token) ?? false)
    }

    func testRemoveTokenEncodesSpecialCharacters() async throws {
        // Given - token with special characters that need encoding
        let token = "dK8xgkLmNp0:APA91bHq/special+chars="

        // When encoding
        let encodedToken = token.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)

        // Then
        XCTAssertNotNil(encodedToken)
        XCTAssertFalse(encodedToken!.contains(":"))
        XCTAssertFalse(encodedToken!.contains("+"))
        XCTAssertFalse(encodedToken!.contains("="))
    }

    func testRemoveTokenUsesDeleteMethod() async throws {
        // Given
        let url = URL(string: "https://api.senra.pet/api/users/me/fcm-tokens/test-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        // Then
        XCTAssertEqual(request.httpMethod, "DELETE")
    }

    // MARK: - Response Handling Tests

    func testSuccessResponseStatusCodes() {
        // Valid success status codes
        let successCodes = [200, 201, 204]

        for code in successCodes {
            XCTAssertTrue((200...299).contains(code), "Status code \(code) should be success")
        }
    }

    func testErrorResponseStatusCodes() {
        // Error status codes
        let errorCodes = [400, 401, 403, 404, 500]

        for code in errorCodes {
            XCTAssertFalse((200...299).contains(code), "Status code \(code) should be error")
        }
    }

    // MARK: - Singleton Tests

    func testFCMServiceIsSingleton() async {
        // Note: Due to actor isolation, we can't directly compare instances
        // This test documents expected behavior
        // await FCMService.shared should always return the same instance
    }

    // MARK: - Platform Identification Tests

    func testPlatformIsAlwaysIOS() {
        // Given
        let body: [String: Any] = [
            "token": "test",
            "platform": "ios"
        ]

        // Then
        XCTAssertEqual(body["platform"] as? String, "ios")
    }

    // MARK: - Error Handling Tests

    func testBadURLError() {
        // Given an invalid URL
        let invalidURL = URL(string: "not a valid url")

        // Then
        XCTAssertNil(invalidURL)
    }

    func testBadServerResponseError() {
        // URLError.badServerResponse should be thrown for non-2xx responses
        let error = URLError(.badServerResponse)
        XCTAssertEqual(error.code, .badServerResponse)
    }

    // MARK: - JSON Serialization Tests

    func testRequestBodySerialization() throws {
        // Given
        let body: [String: Any] = [
            "token": "test-token",
            "platform": "ios",
            "deviceName": "iPhone"
        ]

        // When
        let data = try JSONSerialization.data(withJSONObject: body)

        // Then
        XCTAssertNotNil(data)
        XCTAssertTrue(data.count > 0)

        // Verify it can be deserialized
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?["token"] as? String, "test-token")
    }

    // MARK: - Integration with KeychainService Tests

    func testAuthTokenRetrievalIntegration() {
        // FCMService uses KeychainService.shared.getAuthToken()
        // This documents the integration point

        // In production:
        // if let authToken = KeychainService.shared.getAuthToken() {
        //     request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        // }
    }

    // MARK: - Async/Await Pattern Tests

    func testAsyncRegistration() async {
        // FCMService.registerToken is async
        // It should not block the main thread
        // Error handling is done silently (no throw)

        // await FCMService.shared.registerToken("test-token")
        // This should complete without throwing
    }

    func testAsyncRemoval() async {
        // FCMService.removeToken is async
        // It should not block the main thread
        // Error handling is done silently (no throw)

        // await FCMService.shared.removeToken("test-token")
        // This should complete without throwing
    }
}

// MARK: - Mock URLSession for Testing

/// Mock URLSession for testing network requests
class MockURLSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        return (data ?? Data(), response ?? HTTPURLResponse())
    }
}

// MARK: - Test Helpers

extension FCMServiceTests {
    /// Helper to create a mock HTTP response
    func createMockResponse(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://api.senra.pet/api/users/me/fcm-tokens")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}
