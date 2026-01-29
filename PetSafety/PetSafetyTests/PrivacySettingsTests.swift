import XCTest
@testable import PetSafety

/// Comprehensive test suite for Privacy Settings functionality.
/// Tests the privacy-related operations including:
/// - Loading user privacy settings
/// - Updating individual privacy fields
/// - Error handling and state management
/// - UI state synchronization
final class PrivacySettingsTests: XCTestCase {

    var authViewModel: AuthViewModel!
    var mockAPIService: MockAPIService!

    // Test user with default privacy settings
    let testUser = User(
        id: "user-123",
        email: "test@example.com",
        role: "user",
        firstName: "John",
        lastName: "Doe",
        phone: "+1234567890",
        secondaryPhone: nil,
        secondaryEmail: nil,
        address: "123 Main St",
        addressLine2: nil,
        city: "Test City",
        postalCode: "12345",
        country: "Hungary",
        isServiceProvider: false,
        serviceProviderType: nil,
        organizationName: nil,
        vetLicenseNumber: nil,
        isVerified: true,
        createdAt: "2024-01-01T00:00:00Z",
        updatedAt: "2024-01-01T00:00:00Z",
        showPhonePublicly: true,
        showEmailPublicly: true,
        showAddressPublicly: false
    )

    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        authViewModel = AuthViewModel(apiService: mockAPIService)
    }

    override func tearDown() {
        authViewModel = nil
        mockAPIService = nil
        super.tearDown()
    }

    // MARK: - Loading Privacy Settings Tests

    func testLoadCurrentUserPopulatesPrivacySettings() async throws {
        // Given
        mockAPIService.mockUser = testUser

        // When
        try await authViewModel.loadCurrentUser()

        // Then
        XCTAssertNotNil(authViewModel.currentUser)
        XCTAssertEqual(authViewModel.currentUser?.showPhonePublicly, true)
        XCTAssertEqual(authViewModel.currentUser?.showEmailPublicly, true)
        XCTAssertEqual(authViewModel.currentUser?.showAddressPublicly, false)
    }

    func testPrivacySettingsDefaultToTrueWhenNil() async throws {
        // Given - user with nil privacy settings
        let userWithNilSettings = User(
            id: "user-123",
            email: "test@example.com",
            role: "user",
            firstName: "John",
            lastName: "Doe",
            phone: "+1234567890",
            secondaryPhone: nil,
            secondaryEmail: nil,
            address: nil,
            addressLine2: nil,
            city: nil,
            postalCode: nil,
            country: nil,
            isServiceProvider: nil,
            serviceProviderType: nil,
            organizationName: nil,
            vetLicenseNumber: nil,
            isVerified: nil,
            createdAt: nil,
            updatedAt: nil,
            showPhonePublicly: nil,
            showEmailPublicly: nil,
            showAddressPublicly: nil
        )
        mockAPIService.mockUser = userWithNilSettings

        // When
        try await authViewModel.loadCurrentUser()

        // Then - nil values should be handled in UI with defaults
        XCTAssertNotNil(authViewModel.currentUser)
        XCTAssertNil(authViewModel.currentUser?.showPhonePublicly)
        XCTAssertNil(authViewModel.currentUser?.showEmailPublicly)
        XCTAssertNil(authViewModel.currentUser?.showAddressPublicly)
    }

    // MARK: - Update Privacy Settings Tests

    func testUpdateProfileUpdatesShowPhonePublicly() async throws {
        // Given
        mockAPIService.mockUser = testUser
        try await authViewModel.loadCurrentUser()

        let updatedUser = User(
            id: testUser.id,
            email: testUser.email,
            role: testUser.role,
            firstName: testUser.firstName,
            lastName: testUser.lastName,
            phone: testUser.phone,
            secondaryPhone: testUser.secondaryPhone,
            secondaryEmail: testUser.secondaryEmail,
            address: testUser.address,
            addressLine2: testUser.addressLine2,
            city: testUser.city,
            postalCode: testUser.postalCode,
            country: testUser.country,
            isServiceProvider: testUser.isServiceProvider,
            serviceProviderType: testUser.serviceProviderType,
            organizationName: testUser.organizationName,
            vetLicenseNumber: testUser.vetLicenseNumber,
            isVerified: testUser.isVerified,
            createdAt: testUser.createdAt,
            updatedAt: testUser.updatedAt,
            showPhonePublicly: false,
            showEmailPublicly: testUser.showEmailPublicly,
            showAddressPublicly: testUser.showAddressPublicly
        )
        mockAPIService.mockUser = updatedUser

        // When
        try await authViewModel.updateProfile(updates: ["show_phone_publicly": false])

        // Then
        XCTAssertEqual(authViewModel.currentUser?.showPhonePublicly, false)
        XCTAssertTrue(mockAPIService.updateUserCalled)
        XCTAssertEqual(mockAPIService.lastUpdatePayload?["show_phone_publicly"] as? Bool, false)
    }

    func testUpdateProfileUpdatesShowEmailPublicly() async throws {
        // Given
        mockAPIService.mockUser = testUser
        try await authViewModel.loadCurrentUser()

        let updatedUser = User(
            id: testUser.id,
            email: testUser.email,
            role: testUser.role,
            firstName: testUser.firstName,
            lastName: testUser.lastName,
            phone: testUser.phone,
            secondaryPhone: testUser.secondaryPhone,
            secondaryEmail: testUser.secondaryEmail,
            address: testUser.address,
            addressLine2: testUser.addressLine2,
            city: testUser.city,
            postalCode: testUser.postalCode,
            country: testUser.country,
            isServiceProvider: testUser.isServiceProvider,
            serviceProviderType: testUser.serviceProviderType,
            organizationName: testUser.organizationName,
            vetLicenseNumber: testUser.vetLicenseNumber,
            isVerified: testUser.isVerified,
            createdAt: testUser.createdAt,
            updatedAt: testUser.updatedAt,
            showPhonePublicly: testUser.showPhonePublicly,
            showEmailPublicly: false,
            showAddressPublicly: testUser.showAddressPublicly
        )
        mockAPIService.mockUser = updatedUser

        // When
        try await authViewModel.updateProfile(updates: ["show_email_publicly": false])

        // Then
        XCTAssertEqual(authViewModel.currentUser?.showEmailPublicly, false)
    }

    func testUpdateProfileUpdatesShowAddressPublicly() async throws {
        // Given
        mockAPIService.mockUser = testUser
        try await authViewModel.loadCurrentUser()

        let updatedUser = User(
            id: testUser.id,
            email: testUser.email,
            role: testUser.role,
            firstName: testUser.firstName,
            lastName: testUser.lastName,
            phone: testUser.phone,
            secondaryPhone: testUser.secondaryPhone,
            secondaryEmail: testUser.secondaryEmail,
            address: testUser.address,
            addressLine2: testUser.addressLine2,
            city: testUser.city,
            postalCode: testUser.postalCode,
            country: testUser.country,
            isServiceProvider: testUser.isServiceProvider,
            serviceProviderType: testUser.serviceProviderType,
            organizationName: testUser.organizationName,
            vetLicenseNumber: testUser.vetLicenseNumber,
            isVerified: testUser.isVerified,
            createdAt: testUser.createdAt,
            updatedAt: testUser.updatedAt,
            showPhonePublicly: testUser.showPhonePublicly,
            showEmailPublicly: testUser.showEmailPublicly,
            showAddressPublicly: true
        )
        mockAPIService.mockUser = updatedUser

        // When
        try await authViewModel.updateProfile(updates: ["show_address_publicly": true])

        // Then
        XCTAssertEqual(authViewModel.currentUser?.showAddressPublicly, true)
    }

    func testUpdateProfileUpdatesMultiplePrivacySettings() async throws {
        // Given
        mockAPIService.mockUser = testUser
        try await authViewModel.loadCurrentUser()

        let updatedUser = User(
            id: testUser.id,
            email: testUser.email,
            role: testUser.role,
            firstName: testUser.firstName,
            lastName: testUser.lastName,
            phone: testUser.phone,
            secondaryPhone: testUser.secondaryPhone,
            secondaryEmail: testUser.secondaryEmail,
            address: testUser.address,
            addressLine2: testUser.addressLine2,
            city: testUser.city,
            postalCode: testUser.postalCode,
            country: testUser.country,
            isServiceProvider: testUser.isServiceProvider,
            serviceProviderType: testUser.serviceProviderType,
            organizationName: testUser.organizationName,
            vetLicenseNumber: testUser.vetLicenseNumber,
            isVerified: testUser.isVerified,
            createdAt: testUser.createdAt,
            updatedAt: testUser.updatedAt,
            showPhonePublicly: false,
            showEmailPublicly: false,
            showAddressPublicly: true
        )
        mockAPIService.mockUser = updatedUser

        // When
        try await authViewModel.updateProfile(updates: [
            "show_phone_publicly": false,
            "show_email_publicly": false,
            "show_address_publicly": true
        ])

        // Then
        XCTAssertEqual(authViewModel.currentUser?.showPhonePublicly, false)
        XCTAssertEqual(authViewModel.currentUser?.showEmailPublicly, false)
        XCTAssertEqual(authViewModel.currentUser?.showAddressPublicly, true)
    }

    // MARK: - Error Handling Tests

    func testUpdateProfileThrowsOnNetworkError() async {
        // Given
        mockAPIService.mockUser = testUser
        try? await authViewModel.loadCurrentUser()
        mockAPIService.shouldThrowError = true
        mockAPIService.mockError = NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Network connection lost"])

        // When/Then
        do {
            try await authViewModel.updateProfile(updates: ["show_phone_publicly": false])
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testUpdateProfileThrowsOnServerError() async {
        // Given
        mockAPIService.mockUser = testUser
        try? await authViewModel.loadCurrentUser()
        mockAPIService.shouldThrowError = true
        mockAPIService.mockError = NSError(domain: "ServerError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Internal server error"])

        // When/Then
        do {
            try await authViewModel.updateProfile(updates: ["show_email_publicly": false])
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testCurrentUserNotModifiedOnFailure() async {
        // Given
        mockAPIService.mockUser = testUser
        try? await authViewModel.loadCurrentUser()

        let originalPhoneSetting = authViewModel.currentUser?.showPhonePublicly

        mockAPIService.shouldThrowError = true
        mockAPIService.mockError = NSError(domain: "UpdateError", code: 400, userInfo: nil)

        // When
        do {
            try await authViewModel.updateProfile(updates: ["show_phone_publicly": false])
        } catch {
            // Expected
        }

        // Then - original value should be preserved
        XCTAssertEqual(authViewModel.currentUser?.showPhonePublicly, originalPhoneSetting)
    }

    // MARK: - Loading State Tests

    func testIsLoadingDuringUpdateProfile() async throws {
        // Given
        mockAPIService.mockUser = testUser
        try await authViewModel.loadCurrentUser()
        mockAPIService.delay = 0.1

        // When
        let task = Task {
            try await authViewModel.updateProfile(updates: ["show_phone_publicly": false])
        }

        // Give it a moment to start
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Then - should be loading
        XCTAssertTrue(authViewModel.isLoading)

        // Wait for completion
        try await task.value

        // Then - should not be loading
        XCTAssertFalse(authViewModel.isLoading)
    }

    func testIsLoadingFalseAfterFailure() async {
        // Given
        mockAPIService.mockUser = testUser
        try? await authViewModel.loadCurrentUser()
        mockAPIService.shouldThrowError = true
        mockAPIService.mockError = NSError(domain: "Error", code: 500, userInfo: nil)

        // When
        do {
            try await authViewModel.updateProfile(updates: ["show_phone_publicly": false])
        } catch {
            // Expected
        }

        // Then
        XCTAssertFalse(authViewModel.isLoading)
    }

    // MARK: - Edge Cases Tests

    func testUpdateProfileWithEmptyUpdates() async throws {
        // Given
        mockAPIService.mockUser = testUser
        try await authViewModel.loadCurrentUser()

        // When
        try await authViewModel.updateProfile(updates: [:])

        // Then - should still call API
        XCTAssertTrue(mockAPIService.updateUserCalled)
    }

    func testPrivacySettingsPersistAcrossReload() async throws {
        // Given - user with specific settings
        let userWithSettings = User(
            id: testUser.id,
            email: testUser.email,
            role: testUser.role,
            firstName: testUser.firstName,
            lastName: testUser.lastName,
            phone: testUser.phone,
            secondaryPhone: testUser.secondaryPhone,
            secondaryEmail: testUser.secondaryEmail,
            address: testUser.address,
            addressLine2: testUser.addressLine2,
            city: testUser.city,
            postalCode: testUser.postalCode,
            country: testUser.country,
            isServiceProvider: testUser.isServiceProvider,
            serviceProviderType: testUser.serviceProviderType,
            organizationName: testUser.organizationName,
            vetLicenseNumber: testUser.vetLicenseNumber,
            isVerified: testUser.isVerified,
            createdAt: testUser.createdAt,
            updatedAt: testUser.updatedAt,
            showPhonePublicly: false,
            showEmailPublicly: true,
            showAddressPublicly: true
        )
        mockAPIService.mockUser = userWithSettings

        // When
        try await authViewModel.loadCurrentUser()

        // Then
        XCTAssertEqual(authViewModel.currentUser?.showPhonePublicly, false)
        XCTAssertEqual(authViewModel.currentUser?.showEmailPublicly, true)
        XCTAssertEqual(authViewModel.currentUser?.showAddressPublicly, true)
    }

    func testTogglePhonePrivacyOnAndOff() async throws {
        // Given
        mockAPIService.mockUser = testUser
        try await authViewModel.loadCurrentUser()

        // When - turn off
        var updatedUser = testUser
        updatedUser = User(
            id: testUser.id, email: testUser.email, role: testUser.role,
            firstName: testUser.firstName, lastName: testUser.lastName,
            phone: testUser.phone, secondaryPhone: testUser.secondaryPhone,
            secondaryEmail: testUser.secondaryEmail, address: testUser.address,
            addressLine2: testUser.addressLine2, city: testUser.city,
            postalCode: testUser.postalCode, country: testUser.country,
            isServiceProvider: testUser.isServiceProvider,
            serviceProviderType: testUser.serviceProviderType,
            organizationName: testUser.organizationName,
            vetLicenseNumber: testUser.vetLicenseNumber,
            isVerified: testUser.isVerified,
            createdAt: testUser.createdAt, updatedAt: testUser.updatedAt,
            showPhonePublicly: false,
            showEmailPublicly: testUser.showEmailPublicly,
            showAddressPublicly: testUser.showAddressPublicly
        )
        mockAPIService.mockUser = updatedUser
        try await authViewModel.updateProfile(updates: ["show_phone_publicly": false])

        XCTAssertEqual(authViewModel.currentUser?.showPhonePublicly, false)

        // When - turn back on
        updatedUser = User(
            id: testUser.id, email: testUser.email, role: testUser.role,
            firstName: testUser.firstName, lastName: testUser.lastName,
            phone: testUser.phone, secondaryPhone: testUser.secondaryPhone,
            secondaryEmail: testUser.secondaryEmail, address: testUser.address,
            addressLine2: testUser.addressLine2, city: testUser.city,
            postalCode: testUser.postalCode, country: testUser.country,
            isServiceProvider: testUser.isServiceProvider,
            serviceProviderType: testUser.serviceProviderType,
            organizationName: testUser.organizationName,
            vetLicenseNumber: testUser.vetLicenseNumber,
            isVerified: testUser.isVerified,
            createdAt: testUser.createdAt, updatedAt: testUser.updatedAt,
            showPhonePublicly: true,
            showEmailPublicly: testUser.showEmailPublicly,
            showAddressPublicly: testUser.showAddressPublicly
        )
        mockAPIService.mockUser = updatedUser
        try await authViewModel.updateProfile(updates: ["show_phone_publicly": true])

        // Then
        XCTAssertEqual(authViewModel.currentUser?.showPhonePublicly, true)
    }
}

// MARK: - Mock API Service

class MockAPIService: APIServiceProtocol {
    var mockUser: User?
    var shouldThrowError = false
    var mockError: Error?
    var updateUserCalled = false
    var lastUpdatePayload: [String: Any]?
    var delay: TimeInterval = 0

    func getCurrentUser() async throws -> User {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if shouldThrowError, let error = mockError {
            throw error
        }
        guard let user = mockUser else {
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user
    }

    func updateUser(_ updates: [String: Any]) async throws -> User {
        updateUserCalled = true
        lastUpdatePayload = updates

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if shouldThrowError, let error = mockError {
            throw error
        }
        guard let user = mockUser else {
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user
    }
}

// MARK: - Protocol for testability

protocol APIServiceProtocol {
    func getCurrentUser() async throws -> User
    func updateUser(_ updates: [String: Any]) async throws -> User
}
