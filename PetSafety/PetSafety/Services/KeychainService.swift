//
//  KeychainService.swift
//  PetSafety
//
//  Created by Pet Safety Team on 2026-01-12.
//  Secure storage service for sensitive data using iOS Keychain
//

import Foundation
import Security

/// Secure storage service for tokens and sensitive data
/// Uses iOS Keychain instead of UserDefaults for security
class KeychainService {

    static let shared = KeychainService()

    private init() {}

    // MARK: - Constants

    private let serviceName = "com.petsafety.app"

    enum KeychainKey: String {
        case authToken = "auth_token"
        case refreshToken = "refresh_token"
        case userId = "user_id"
        case userEmail = "user_email"
    }

    // MARK: - Public Methods

    /// Save a string value to Keychain
    func save(_ value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("❌ KeychainService: Failed to convert string to data")
            return false
        }

        return save(data, for: key)
    }

    /// Save data to Keychain
    func save(_ data: Data, for key: KeychainKey) -> Bool {
        // Delete any existing item first
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            #if DEBUG
            print("✅ KeychainService: Saved \(key.rawValue)")
            #endif
            return true
        } else {
            print("❌ KeychainService: Failed to save \(key.rawValue) - Status: \(status)")
            return false
        }
    }

    /// Retrieve a string value from Keychain
    func getString(for key: KeychainKey) -> String? {
        guard let data = getData(for: key) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// Retrieve data from Keychain
    func getData(for key: KeychainKey) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess {
            #if DEBUG
            print("✅ KeychainService: Retrieved \(key.rawValue)")
            #endif
            return result as? Data
        } else if status == errSecItemNotFound {
            #if DEBUG
            print("⚠️ KeychainService: Item not found for \(key.rawValue)")
            #endif
            return nil
        } else {
            print("❌ KeychainService: Failed to retrieve \(key.rawValue) - Status: \(status)")
            return nil
        }
    }

    /// Delete a value from Keychain
    @discardableResult
    func delete(_ key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            #if DEBUG
            print("✅ KeychainService: Deleted \(key.rawValue)")
            #endif
            return true
        } else {
            print("❌ KeychainService: Failed to delete \(key.rawValue) - Status: \(status)")
            return false
        }
    }

    /// Delete all items for this app
    func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            #if DEBUG
            print("✅ KeychainService: Deleted all items")
            #endif
            return true
        } else {
            print("❌ KeychainService: Failed to delete all items - Status: \(status)")
            return false
        }
    }

    /// Check if a key exists in Keychain
    func exists(_ key: KeychainKey) -> Bool {
        return getData(for: key) != nil
    }

    // MARK: - Convenience Methods for Auth Token

    /// Save authentication token
    func saveAuthToken(_ token: String) -> Bool {
        return save(token, for: .authToken)
    }

    /// Get authentication token
    func getAuthToken() -> String? {
        return getString(for: .authToken)
    }

    /// Delete authentication token
    func deleteAuthToken() -> Bool {
        return delete(.authToken)
    }

    /// Check if user is authenticated (has valid token)
    var isAuthenticated: Bool {
        return exists(.authToken)
    }

    // MARK: - Migration Helper

    /// Migrate token from UserDefaults to Keychain
    /// Call this once to migrate existing users
    func migrateFromUserDefaults() {
        let userDefaults = UserDefaults.standard

        // Migrate auth token
        if let oldToken = userDefaults.string(forKey: "auth_token") {
            if saveAuthToken(oldToken) {
                userDefaults.removeObject(forKey: "auth_token")
                print("✅ Migrated auth_token from UserDefaults to Keychain")
            }
        }

        // Migrate user ID if stored
        if let oldUserId = userDefaults.string(forKey: "user_id") {
            if save(oldUserId, for: .userId) {
                userDefaults.removeObject(forKey: "user_id")
                print("✅ Migrated user_id from UserDefaults to Keychain")
            }
        }

        userDefaults.synchronize()
    }
}

// MARK: - Error Handling

extension KeychainService {
    /// Human-readable error message from OSStatus
    func errorMessage(for status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Success"
        case errSecItemNotFound:
            return "Item not found"
        case errSecDuplicateItem:
            return "Duplicate item"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecUnimplemented:
            return "Function not implemented"
        case errSecParam:
            return "Invalid parameter"
        case errSecAllocate:
            return "Failed to allocate memory"
        case errSecNotAvailable:
            return "Not available"
        case errSecDecode:
            return "Failed to decode"
        case errSecInteractionNotAllowed:
            return "User interaction not allowed"
        default:
            return "Unknown error (\(status))"
        }
    }
}
