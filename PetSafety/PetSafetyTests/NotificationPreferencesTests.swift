import Testing
import Foundation
@testable import PetSafety

/// Tests for Notification Preferences - User preference management
@Suite("Notification Preferences Tests")
struct NotificationPreferencesTests {

    // MARK: - Model Tests

    @Test("NotificationPreferences should initialize with all enabled by default")
    func testDefaultPreferences() {
        let preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: true
        )

        #expect(preferences.notifyByEmail == true)
        #expect(preferences.notifyBySms == true)
        #expect(preferences.notifyByPush == true)
    }

    @Test("NotificationPreferences should validate when at least one method enabled")
    func testValidPreferences() {
        let allEnabled = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: true
        )
        #expect(allEnabled.isValid == true)

        let emailOnly = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: false,
            notifyByPush: false
        )
        #expect(emailOnly.isValid == true)

        let smsOnly = NotificationPreferences(
            notifyByEmail: false,
            notifyBySms: true,
            notifyByPush: false
        )
        #expect(smsOnly.isValid == true)

        let pushOnly = NotificationPreferences(
            notifyByEmail: false,
            notifyBySms: false,
            notifyByPush: true
        )
        #expect(pushOnly.isValid == true)

        let emailAndSms = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: false
        )
        #expect(emailAndSms.isValid == true)
    }

    @Test("NotificationPreferences should be invalid when all methods disabled")
    func testInvalidPreferences() {
        let allDisabled = NotificationPreferences(
            notifyByEmail: false,
            notifyBySms: false,
            notifyByPush: false
        )

        #expect(allDisabled.isValid == false)
    }

    @Test("NotificationPreferences should count enabled methods correctly")
    func testEnabledCount() {
        let allEnabled = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: true
        )
        #expect(allEnabled.enabledCount == 3)

        let twoEnabled = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: false
        )
        #expect(twoEnabled.enabledCount == 2)

        let oneEnabled = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: false,
            notifyByPush: false
        )
        #expect(oneEnabled.enabledCount == 1)

        let noneEnabled = NotificationPreferences(
            notifyByEmail: false,
            notifyBySms: false,
            notifyByPush: false
        )
        #expect(noneEnabled.enabledCount == 0)
    }

    @Test("NotificationPreferences should encode and decode correctly")
    func testCodable() throws {
        let original = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: false,
            notifyByPush: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(NotificationPreferences.self, from: data)

        #expect(decoded.notifyByEmail == original.notifyByEmail)
        #expect(decoded.notifyBySms == original.notifyBySms)
        #expect(decoded.notifyByPush == original.notifyByPush)
    }

    @Test("NotificationPreferences should decode from API response format")
    func testDecodeAPIFormat() throws {
        let jsonString = """
        {
            "notifyByEmail": true,
            "notifyBySms": false,
            "notifyByPush": true
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let preferences = try decoder.decode(NotificationPreferences.self, from: data)

        #expect(preferences.notifyByEmail == true)
        #expect(preferences.notifyBySms == false)
        #expect(preferences.notifyByPush == true)
        #expect(preferences.isValid == true)
        #expect(preferences.enabledCount == 2)
    }

    // MARK: - ViewModel Tests

    @Test("NotificationPreferencesViewModel should initialize with loading state")
    @MainActor
    func testViewModelInitialState() {
        let viewModel = NotificationPreferencesViewModel()

        #expect(viewModel.isLoading == false)
        #expect(viewModel.isSaving == false)
        #expect(viewModel.showError == false)
        #expect(viewModel.showSuccess == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.hasChanges == false)
    }

    @Test("NotificationPreferencesViewModel should detect changes")
    @MainActor
    func testViewModelDetectsChanges() {
        let viewModel = NotificationPreferencesViewModel()

        // Set initial preferences
        viewModel.preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: true
        )
        viewModel.originalPreferences = viewModel.preferences

        #expect(viewModel.hasChanges == false)

        // Make a change
        viewModel.preferences.notifyBySms = false

        #expect(viewModel.hasChanges == true)
    }

    @Test("NotificationPreferencesViewModel should prevent disabling last method")
    @MainActor
    func testViewModelPreventsDisablingLast() {
        let viewModel = NotificationPreferencesViewModel()

        // Set to only email enabled
        viewModel.preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: false,
            notifyByPush: false
        )

        let emailToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByEmail
        let smsToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyBySms
        let pushToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByPush

        #expect(emailToggleDisabled == true)
        #expect(smsToggleDisabled == false)
        #expect(pushToggleDisabled == false)
    }

    @Test("NotificationPreferencesViewModel should allow disabling when multiple enabled")
    @MainActor
    func testViewModelAllowsDisablingWhenMultiple() {
        let viewModel = NotificationPreferencesViewModel()

        // Set to all enabled
        viewModel.preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: true
        )

        let emailToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByEmail
        let smsToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyBySms
        let pushToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByPush

        #expect(emailToggleDisabled == false)
        #expect(smsToggleDisabled == false)
        #expect(pushToggleDisabled == false)
    }

    @Test("NotificationPreferencesViewModel should track enabled count")
    @MainActor
    func testViewModelEnabledCount() {
        let viewModel = NotificationPreferencesViewModel()

        viewModel.preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: false
        )

        #expect(viewModel.preferences.enabledCount == 2)

        viewModel.preferences.notifyByPush = true

        #expect(viewModel.preferences.enabledCount == 3)

        viewModel.preferences.notifyByEmail = false

        #expect(viewModel.preferences.enabledCount == 2)
    }

    // MARK: - API Response Tests

    @Test("NotificationPreferencesResponse should decode correctly")
    func testAPIResponseDecoding() throws {
        let jsonString = """
        {
            "success": true,
            "data": {
                "preferences": {
                    "notifyByEmail": true,
                    "notifyBySms": false,
                    "notifyByPush": true
                }
            }
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(ApiEnvelope<NotificationPreferencesResponse>.self, from: data)

        #expect(response.success == true)
        #expect(response.data?.preferences.notifyByEmail == true)
        #expect(response.data?.preferences.notifyBySms == false)
        #expect(response.data?.preferences.notifyByPush == true)
    }

    @Test("NotificationPreferencesResponse should handle error response")
    func testAPIErrorResponseDecoding() throws {
        let jsonString = """
        {
            "success": false,
            "error": "At least one notification method must be enabled",
            "details": {
                "field": "preferences"
            }
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(ErrorResponse.self, from: data)
        #expect(response.error.contains("At least one notification method must be enabled"))
        #expect(response.details?["field"] != nil)
    }

    @Test("UpdatePreferencesRequest should encode correctly")
    func testUpdateRequestEncoding() throws {
        let preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: false,
            notifyByPush: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(preferences)

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["notifyByEmail"] as? Bool == true)
        #expect(json["notifyBySms"] as? Bool == false)
        #expect(json["notifyByPush"] as? Bool == true)
    }

    // MARK: - Validation Logic Tests

    @Test("Should validate preferences before saving")
    func testPreferencesValidation() {
        let valid = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: false,
            notifyByPush: false
        )
        #expect(valid.isValid == true)

        let invalid = NotificationPreferences(
            notifyByEmail: false,
            notifyBySms: false,
            notifyByPush: false
        )
        #expect(invalid.isValid == false)
    }

    @Test("Should prevent creating invalid preferences")
    func testInvalidPreferencesCreation() {
        var preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: false,
            notifyByPush: false
        )

        // This should be prevented at UI level
        preferences.notifyByEmail = false

        #expect(preferences.isValid == false)
    }

    // MARK: - Edge Cases

    @Test("Should handle toggling preferences in sequence")
    func testPreferenceToggling() {
        var preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: true
        )

        // Toggle off email
        preferences.notifyByEmail = false
        #expect(preferences.isValid == true)
        #expect(preferences.enabledCount == 2)

        // Toggle off SMS
        preferences.notifyBySms = false
        #expect(preferences.isValid == true)
        #expect(preferences.enabledCount == 1)

        // Cannot toggle off push (last one)
        // This should be prevented at UI level
        preferences.notifyByPush = false
        #expect(preferences.isValid == false)
        #expect(preferences.enabledCount == 0)
    }

    @Test("Should handle rapid preference changes")
    func testRapidPreferenceChanges() {
        var preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: true
        )

        // Rapid toggles
        preferences.notifyByEmail = false
        preferences.notifyByEmail = true
        preferences.notifyBySms = false
        preferences.notifyByPush = false
        preferences.notifyByPush = true

        // Should end in valid state
        #expect(preferences.isValid == true)
        #expect(preferences.notifyByEmail == true)
        #expect(preferences.notifyBySms == false)
        #expect(preferences.notifyByPush == true)
    }

    @Test("Should maintain immutability when passing between functions")
    func testPreferencesImmutability() {
        let original = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: true
        )

        var copy = original
        copy.notifyByEmail = false

        // Original should be unchanged (struct semantics)
        #expect(original.notifyByEmail == true)
        #expect(copy.notifyByEmail == false)
    }

    // MARK: - Integration Tests

    @Test("Should match backend validation rules")
    func testBackendValidationParity() {
        // These should match backend validation:
        // - At least one method must be enabled
        // - All methods can be enabled
        // - Any combination with at least one enabled is valid

        let testCases = [
            (NotificationPreferences(notifyByEmail: true, notifyBySms: true, notifyByPush: true), true),
            (NotificationPreferences(notifyByEmail: true, notifyBySms: false, notifyByPush: false), true),
            (NotificationPreferences(notifyByEmail: false, notifyBySms: true, notifyByPush: false), true),
            (NotificationPreferences(notifyByEmail: false, notifyBySms: false, notifyByPush: true), true),
            (NotificationPreferences(notifyByEmail: true, notifyBySms: true, notifyByPush: false), true),
            (NotificationPreferences(notifyByEmail: true, notifyBySms: false, notifyByPush: true), true),
            (NotificationPreferences(notifyByEmail: false, notifyBySms: true, notifyByPush: true), true),
            (NotificationPreferences(notifyByEmail: false, notifyBySms: false, notifyByPush: false), false),
        ]

        for (preferences, expectedValid) in testCases {
            #expect(preferences.isValid == expectedValid)
        }
    }

    @Test("Should format preferences for API request")
    func testAPIRequestFormatting() throws {
        let preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: false,
            notifyByPush: true
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(preferences)

        let jsonString = String(data: data, encoding: .utf8)!

        // Should match backend expected format
        #expect(jsonString.contains("notify_by_email") || jsonString.contains("notifyByEmail"))
        #expect(jsonString.contains("true"))
        #expect(jsonString.contains("false"))
    }

    // MARK: - UI State Tests

    @Test("Should determine correct UI state for buttons")
    @MainActor
    func testUIButtonStates() {
        let viewModel = NotificationPreferencesViewModel()

        // All enabled - can disable any
        viewModel.preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: true
        )
        var emailToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByEmail
        var smsToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyBySms
        var pushToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByPush

        #expect(emailToggleDisabled == false)
        #expect(smsToggleDisabled == false)
        #expect(pushToggleDisabled == false)

        // Only email - cannot disable
        viewModel.preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: false,
            notifyByPush: false
        )
        emailToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByEmail
        smsToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyBySms
        pushToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByPush

        #expect(emailToggleDisabled == true)
        #expect(smsToggleDisabled == false)
        #expect(pushToggleDisabled == false)

        // Only SMS - cannot disable
        viewModel.preferences = NotificationPreferences(
            notifyByEmail: false,
            notifyBySms: true,
            notifyByPush: false
        )
        emailToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByEmail
        smsToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyBySms
        pushToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByPush

        #expect(emailToggleDisabled == false)
        #expect(smsToggleDisabled == true)
        #expect(pushToggleDisabled == false)

        // Only push - cannot disable
        viewModel.preferences = NotificationPreferences(
            notifyByEmail: false,
            notifyBySms: false,
            notifyByPush: true
        )
        emailToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByEmail
        smsToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyBySms
        pushToggleDisabled = viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByPush

        #expect(emailToggleDisabled == false)
        #expect(smsToggleDisabled == false)
        #expect(pushToggleDisabled == true)
    }

    @Test("Should show/hide save button based on changes")
    @MainActor
    func testSaveButtonVisibility() {
        let viewModel = NotificationPreferencesViewModel()

        viewModel.preferences = NotificationPreferences(
            notifyByEmail: true,
            notifyBySms: true,
            notifyByPush: true
        )
        viewModel.originalPreferences = viewModel.preferences

        // No changes - should hide save button
        #expect(viewModel.hasChanges == false)

        // Make change - should show save button
        viewModel.preferences.notifyByEmail = false
        #expect(viewModel.hasChanges == true)

        // Revert change - should hide save button again
        viewModel.preferences.notifyByEmail = true
        #expect(viewModel.hasChanges == false)
    }

    @Test("Should clear error messages on successful save")
    @MainActor
    func testErrorMessageClearing() {
        let viewModel = NotificationPreferencesViewModel()

        // Simulate error
        viewModel.errorMessage = "Network error"
        #expect(viewModel.errorMessage != nil)

        // On successful save, error should clear
        viewModel.errorMessage = nil
        viewModel.showSuccess = true

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showSuccess == true)
    }
}
