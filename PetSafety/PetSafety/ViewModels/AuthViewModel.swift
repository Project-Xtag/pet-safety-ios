import Foundation
import Sentry

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    init() {
        checkAuthStatus()
    }

    func checkAuthStatus() {
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
                } catch {
                    // Token might be invalid, log out
                    logout()
                }
            }
        }
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
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func logout() {
        apiService.logout()
        currentUser = nil
        isAuthenticated = false

        _ = KeychainService.shared.delete(.userId)
        _ = KeychainService.shared.delete(.userEmail)

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
}
