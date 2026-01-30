import Foundation
import UIKit
import Sentry

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showBiometricPrompt = false
    @Published var biometricEnabled: Bool

    private let apiService = APIService.shared
    private let biometricService = BiometricService.shared

    init() {
        self.biometricEnabled = BiometricService.shared.isBiometricEnabled
        checkAuthStatus()
    }

    func checkAuthStatus() {
        // Check if we should show biometric prompt
        if biometricService.shouldShowBiometricLogin {
            showBiometricPrompt = true
            return
        }

        // Check if we have a valid token
        if KeychainService.shared.isAuthenticated {
            Task {
                do {
                    currentUser = try await apiService.getCurrentUser()
                    isAuthenticated = true
                    // Set Sentry user context for error tracking
                    if let user = currentUser {
                        let sentryUser = Sentry.User(userId: user.id)
                        SentrySDK.setUser(sentryUser)
                    }
                    // Connect to SSE for real-time notifications
                    SSEService.shared.connect()

                    // Register FCM token for push notifications
                    registerFCMToken()
                } catch {
                    // Token might be invalid, log out
                    logout()
                }
            }
        }
    }

    // MARK: - FCM Token Management

    private func registerFCMToken() {
        guard let token = KeychainService.shared.getFCMToken() else {
            #if DEBUG
            print("No FCM token available to register")
            #endif
            return
        }

        Task {
            await FCMService.shared.registerToken(token, deviceName: UIDevice.current.name)
        }
    }

    private func unregisterFCMToken() {
        guard let token = KeychainService.shared.getFCMToken() else {
            return
        }

        Task {
            await FCMService.shared.removeToken(token)
        }
    }

    // MARK: - Biometric Authentication

    /// Check if biometric login is available
    var canUseBiometric: Bool {
        biometricService.canUseBiometric
    }

    /// Get the biometric type name for display
    var biometricTypeName: String {
        biometricService.biometricType.displayName
    }

    /// Get the biometric icon name
    var biometricIconName: String {
        biometricService.biometricType.iconName
    }

    /// Check if biometric enrollment should be offered after login
    var shouldOfferBiometricEnrollment: Bool {
        canUseBiometric && !biometricEnabled
    }

    /// Enable or disable biometric login
    func setBiometricEnabled(_ enabled: Bool) {
        biometricService.isBiometricEnabled = enabled
        biometricEnabled = enabled
    }

    /// Authenticate using biometrics
    func authenticateWithBiometric() async {
        let result = await biometricService.authenticate()

        if result.success {
            // Biometric succeeded, load user data
            do {
                currentUser = try await apiService.getCurrentUser()
                isAuthenticated = true
                showBiometricPrompt = false

                // Set Sentry user context
                if let user = currentUser {
                    let sentryUser = Sentry.User(userId: user.id)
                    SentrySDK.setUser(sentryUser)
                }

                // Connect to SSE
                SSEService.shared.connect()

                // Register FCM token
                registerFCMToken()
            } catch {
                // Token might be invalid
                logout()
            }
        } else {
            // Biometric failed or cancelled
            showBiometricPrompt = false
            if let error = result.error {
                errorMessage = error
            }
        }
    }

    /// Dismiss biometric prompt and show regular login
    func dismissBiometricPrompt() {
        showBiometricPrompt = false
    }

    func login(email: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await apiService.login(email: email)
            isLoading = false
            // OTP sent successfully
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func verifyOTP(email: String, code: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.verifyOTP(email: email, code: code)
            currentUser = response.user
            isAuthenticated = true
            isLoading = false

            _ = KeychainService.shared.save(response.user.id, for: .userId)
            _ = KeychainService.shared.save(response.user.email, for: .userEmail)

            // Set Sentry user context for error tracking
            let sentryUser = Sentry.User(userId: response.user.id)
            SentrySDK.setUser(sentryUser)

            // Connect to SSE for real-time notifications
            SSEService.shared.connect()

            // Register FCM token for push notifications
            registerFCMToken()
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func logout() {
        // Unregister FCM token before logout
        unregisterFCMToken()
        apiService.logout()
        currentUser = nil
        isAuthenticated = false

        _ = KeychainService.shared.delete(.userId)
        _ = KeychainService.shared.delete(.userEmail)

        // Disable biometric login
        biometricService.disable()
        biometricEnabled = false

        // Clear Sentry user context
        SentrySDK.setUser(nil)

        // Disconnect from SSE
        SSEService.shared.disconnect()
    }

    func updateProfile(updates: [String: Any]) async throws {
        isLoading = true
        errorMessage = nil

        do {
            currentUser = try await apiService.updateUser(updates)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Check if user can delete their account
    func canDeleteAccount() async throws -> CanDeleteAccountResponse {
        return try await apiService.canDeleteAccount()
    }

    /// Delete user account and log out
    func deleteAccount() async throws {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await apiService.deleteAccount()
            isLoading = false
            // Log out after successful deletion
            logout()
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
