import Foundation
import Sentry

/**
 * FCM Service for Firebase Cloud Messaging
 *
 * Handles FCM token registration with the backend. Delegates the actual HTTP
 * call to APIService so the request participates in 401 auto-refresh, App
 * Check, and Sentry breadcrumbs. Failures are reported to Sentry so silent
 * auth hiccups are observable in production — the register path runs again
 * on every app foreground / login restore, so transient failures recover.
 */

actor FCMService {
    static let shared = FCMService()

    private init() {}

    /// Register FCM token with backend
    /// - Parameters:
    ///   - token: The FCM token from Firebase
    ///   - deviceName: Optional device name for identification
    func registerToken(_ token: String, deviceName: String? = nil) async {
        do {
            try await APIService.shared.registerFCMToken(token: token, deviceName: deviceName)
            #if DEBUG
            print("FCM token registered successfully")
            #endif
        } catch {
            #if DEBUG
            print("Failed to register FCM token: \(error)")
            #endif
            if SentrySDK.isEnabled {
                SentrySDK.capture(error: error) { scope in
                    scope.setTag(value: "fcm_register_failed", key: "operation")
                    scope.setContext(value: ["token_prefix": String(token.prefix(20))], key: "fcm")
                }
            }
        }
    }

    /// Remove FCM token from backend (e.g., on logout)
    /// - Parameter token: The FCM token to remove
    func removeToken(_ token: String) async {
        do {
            try await APIService.shared.unregisterFCMToken(token: token)
            #if DEBUG
            print("FCM token removed successfully")
            #endif
        } catch {
            #if DEBUG
            print("Failed to remove FCM token: \(error)")
            #endif
            if SentrySDK.isEnabled {
                SentrySDK.capture(error: error) { scope in
                    scope.setTag(value: "fcm_unregister_failed", key: "operation")
                }
            }
        }
    }
}
