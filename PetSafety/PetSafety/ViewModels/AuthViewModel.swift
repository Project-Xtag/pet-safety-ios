import Foundation

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
        if UserDefaults.standard.string(forKey: "auth_token") != nil {
            Task {
                do {
                    currentUser = try await apiService.getCurrentUser()
                    isAuthenticated = true
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
            let response = try await apiService.login(email: email)
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
