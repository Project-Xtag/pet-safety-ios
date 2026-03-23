import Testing
import Foundation
@testable import PetSafety

@Suite("AuthViewModel Tests")
@MainActor
struct AuthViewModelTests {

    // MARK: - Initial State

    @Test("Initial state — isAuthenticated is false")
    func testInitialIsAuthenticated() {
        let viewModel = AuthViewModel()
        // Without a stored keychain token, the VM should not be authenticated
        // Note: in CI/test environments there is no keychain token
        #expect(viewModel.isAuthenticated == false || KeychainService.shared.isAuthenticated,
                "isAuthenticated should be false when no token is stored")
    }

    @Test("Initial state — currentUser is nil")
    func testInitialCurrentUser() {
        let viewModel = AuthViewModel()
        #expect(viewModel.currentUser == nil, "currentUser should be nil on fresh init")
    }

    @Test("Initial state — isLoading is false")
    func testInitialIsLoading() {
        let viewModel = AuthViewModel()
        #expect(viewModel.isLoading == false, "isLoading should start as false")
    }

    @Test("Initial state — errorMessage is nil")
    func testInitialErrorMessage() {
        let viewModel = AuthViewModel()
        #expect(viewModel.errorMessage == nil, "errorMessage should be nil initially")
    }

    @Test("Initial state — isNewUser is false")
    func testInitialIsNewUser() {
        let viewModel = AuthViewModel()
        #expect(viewModel.isNewUser == false, "isNewUser should be false initially")
    }

    @Test("Initial state — showBiometricPrompt reflects biometric service state")
    func testInitialShowBiometricPrompt() {
        let viewModel = AuthViewModel()
        // showBiometricPrompt is set in checkAuthStatus based on biometricService
        // In test environment without stored credentials, should be false
        #expect(viewModel.showBiometricPrompt == false || BiometricService.shared.shouldShowBiometricLogin,
                "showBiometricPrompt should match biometric service state")
    }

    // MARK: - Biometric Properties

    @Test("biometricEnabled reflects BiometricService state")
    func testBiometricEnabledInit() {
        let viewModel = AuthViewModel()
        #expect(viewModel.biometricEnabled == BiometricService.shared.isBiometricEnabled,
                "biometricEnabled should match BiometricService.shared.isBiometricEnabled")
    }

    @Test("setBiometricEnabled updates biometricEnabled property")
    func testSetBiometricEnabled() {
        let viewModel = AuthViewModel()
        let originalValue = viewModel.biometricEnabled

        viewModel.setBiometricEnabled(!originalValue)
        #expect(viewModel.biometricEnabled == !originalValue)

        // Restore original
        viewModel.setBiometricEnabled(originalValue)
        #expect(viewModel.biometricEnabled == originalValue)
    }

    // MARK: - Dismiss Biometric Prompt

    @Test("dismissBiometricPrompt sets showBiometricPrompt to false")
    func testDismissBiometricPrompt() {
        let viewModel = AuthViewModel()
        viewModel.dismissBiometricPrompt()
        #expect(viewModel.showBiometricPrompt == false)
    }

    // MARK: - Logout

    @Test("logout clears currentUser and sets isAuthenticated to false")
    func testLogoutClearsState() {
        let viewModel = AuthViewModel()
        // Simulate some state (directly setting published properties for unit test)
        viewModel.logout()

        #expect(viewModel.currentUser == nil, "currentUser should be nil after logout")
        #expect(viewModel.isAuthenticated == false, "isAuthenticated should be false after logout")
        #expect(viewModel.biometricEnabled == false, "biometricEnabled should be false after logout")
    }

    @Test("shouldOfferBiometricEnrollment is false when biometric already enabled")
    func testShouldOfferBiometricEnrollmentWhenEnabled() {
        let viewModel = AuthViewModel()
        // If biometricEnabled is true, shouldOfferBiometricEnrollment should be false
        viewModel.setBiometricEnabled(true)
        #expect(viewModel.shouldOfferBiometricEnrollment == false,
                "Should not offer enrollment when already enabled")
        // Restore
        viewModel.setBiometricEnabled(false)
    }
}
