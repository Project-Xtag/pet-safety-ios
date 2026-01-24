//
//  BiometricService.swift
//  PetSafety
//
//  Service for handling Face ID and Touch ID authentication
//

import Foundation
import LocalAuthentication

/// Service for handling biometric authentication (Face ID / Touch ID)
class BiometricService {

    static let shared = BiometricService()

    private init() {}

    // MARK: - UserDefaults Keys

    private let biometricEnabledKey = "biometric_enabled"

    // MARK: - Biometric Availability

    /// Check if biometric authentication is available on this device
    var canUseBiometric: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Get the type of biometric available (Face ID, Touch ID, or none)
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    enum BiometricType {
        case faceID
        case touchID
        case opticID
        case none

        var displayName: String {
            switch self {
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            case .opticID:
                return "Optic ID"
            case .none:
                return "Biometric"
            }
        }

        var iconName: String {
            switch self {
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            case .opticID:
                return "opticid"
            case .none:
                return "lock"
            }
        }
    }

    // MARK: - Biometric Preference

    /// Check if the user has enabled biometric login
    var isBiometricEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: biometricEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: biometricEnabledKey)
        }
    }

    /// Check if biometric login should be shown (available, enabled, and has stored token)
    var shouldShowBiometricLogin: Bool {
        return canUseBiometric && isBiometricEnabled && KeychainService.shared.isAuthenticated
    }

    // MARK: - Authentication

    /// Authenticate using biometrics
    /// - Parameters:
    ///   - reason: The reason shown to the user for why biometric is needed
    ///   - completion: Completion handler with success result and optional error message
    func authenticate(reason: String = "Log in to Pet Safety", completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Email"

        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error?.localizedDescription ?? "Biometric authentication not available")
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else {
                    let errorMessage: String?
                    if let laError = authError as? LAError {
                        switch laError.code {
                        case .userCancel, .userFallback, .systemCancel:
                            // User cancelled - not an error to display
                            errorMessage = nil
                        case .biometryLockout:
                            errorMessage = "Too many failed attempts. Please try again later."
                        case .biometryNotAvailable:
                            errorMessage = "Biometric authentication is not available."
                        case .biometryNotEnrolled:
                            errorMessage = "No biometric data enrolled. Please set up \(self.biometricType.displayName) in Settings."
                        default:
                            errorMessage = authError?.localizedDescription
                        }
                    } else {
                        errorMessage = authError?.localizedDescription
                    }
                    completion(false, errorMessage)
                }
            }
        }
    }

    /// Async version of authenticate
    func authenticate(reason: String = "Log in to Pet Safety") async -> (success: Bool, error: String?) {
        await withCheckedContinuation { continuation in
            authenticate(reason: reason) { success, error in
                continuation.resume(returning: (success, error))
            }
        }
    }

    // MARK: - Cleanup

    /// Disable biometric authentication (call on logout or account deletion)
    func disable() {
        isBiometricEnabled = false
    }
}
