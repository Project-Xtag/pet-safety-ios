//
//  KeychainServiceTests.swift
//  PetSafetyTests
//
//  Created by Pet Safety Team on 2026-01-12.
//  Tests for KeychainService secure storage
//

import Testing
@testable import PetSafety

@MainActor
struct KeychainServiceTests {

    let keychainService = KeychainService.shared

    // Clean up after each test
    func cleanup() {
        _ = keychainService.deleteAll()
    }

    @Test func testSaveAndRetrieveAuthToken() async throws {
        cleanup()

        let testToken = "test_auth_token_12345"

        // Save token
        let saveSuccess = keychainService.saveAuthToken(testToken)
        #expect(saveSuccess == true, "Failed to save auth token")

        // Retrieve token
        let retrievedToken = keychainService.getAuthToken()
        #expect(retrievedToken == testToken, "Retrieved token doesn't match saved token")

        cleanup()
    }

    @Test func testAuthTokenExists() async throws {
        cleanup()

        // Initially should not exist
        #expect(keychainService.isAuthenticated == false, "Token should not exist initially")

        // Save token
        _ = keychainService.saveAuthToken("test_token")

        // Now should exist
        #expect(keychainService.isAuthenticated == true, "Token should exist after save")

        cleanup()
    }

    @Test func testDeleteAuthToken() async throws {
        cleanup()

        // Save token
        _ = keychainService.saveAuthToken("test_token")
        #expect(keychainService.isAuthenticated == true)

        // Delete token
        let deleteSuccess = keychainService.deleteAuthToken()
        #expect(deleteSuccess == true, "Failed to delete auth token")

        // Should not exist anymore
        #expect(keychainService.isAuthenticated == false, "Token should not exist after delete")

        cleanup()
    }

    @Test func testSaveAndRetrieveMultipleKeys() async throws {
        cleanup()

        let testToken = "auth_token_123"
        let testUserId = "user_id_456"
        let testEmail = "test@example.com"

        // Save multiple values
        #expect(keychainService.save(testToken, for: .authToken))
        #expect(keychainService.save(testUserId, for: .userId))
        #expect(keychainService.save(testEmail, for: .userEmail))

        // Retrieve and verify
        #expect(keychainService.getString(for: .authToken) == testToken)
        #expect(keychainService.getString(for: .userId) == testUserId)
        #expect(keychainService.getString(for: .userEmail) == testEmail)

        cleanup()
    }

    @Test func testUpdateExistingToken() async throws {
        cleanup()

        let originalToken = "original_token"
        let newToken = "new_token"

        // Save original
        _ = keychainService.saveAuthToken(originalToken)
        #expect(keychainService.getAuthToken() == originalToken)

        // Update with new token
        _ = keychainService.saveAuthToken(newToken)

        // Should return new token
        #expect(keychainService.getAuthToken() == newToken, "Token should be updated")

        cleanup()
    }

    @Test func testDeleteAllKeys() async throws {
        cleanup()

        // Save multiple values
        _ = keychainService.save("token", for: .authToken)
        _ = keychainService.save("user123", for: .userId)
        _ = keychainService.save("test@example.com", for: .userEmail)

        // Verify they exist
        #expect(keychainService.exists(.authToken))
        #expect(keychainService.exists(.userId))
        #expect(keychainService.exists(.userEmail))

        // Delete all
        let deleteSuccess = keychainService.deleteAll()
        #expect(deleteSuccess == true, "Failed to delete all items")

        // Verify all are gone
        #expect(keychainService.exists(.authToken) == false)
        #expect(keychainService.exists(.userId) == false)
        #expect(keychainService.exists(.userEmail) == false)

        cleanup()
    }

    @Test func testRetrieveNonExistentKey() async throws {
        cleanup()

        // Try to retrieve non-existent token
        let token = keychainService.getAuthToken()
        #expect(token == nil, "Non-existent token should return nil")

        cleanup()
    }

    @Test func testTokenPersistence() async throws {
        cleanup()

        let testToken = "persistent_token_xyz"

        // Save token
        _ = keychainService.saveAuthToken(testToken)

        // Create new instance (simulating app restart)
        let newKeychainService = KeychainService.shared

        // Should still retrieve the token
        let retrievedToken = newKeychainService.getAuthToken()
        #expect(retrievedToken == testToken, "Token should persist across instances")

        cleanup()
    }
}
