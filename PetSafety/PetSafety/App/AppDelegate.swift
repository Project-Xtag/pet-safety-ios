import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import Sentry
import os

private let delegateLog = Logger(subsystem: "com.petsafety.PetSafety", category: "AppDelegate")

/**
 * AppDelegate for Firebase Cloud Messaging and Push Notifications
 *
 * Handles:
 * - Firebase initialization
 * - Push notification permissions
 * - FCM token registration
 * - Incoming notification handling
 */

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let t0 = CFAbsoluteTimeGetCurrent()
        delegateLog.notice("⏱️ AppDelegate: didFinishLaunching START")

        // Configure App Check BEFORE Firebase initialization
        ConfigurationManager.configureAppCheck()
        delegateLog.notice("⏱️ AppDelegate: App Check configured +\(String(format: "%.0f", (CFAbsoluteTimeGetCurrent() - t0) * 1000))ms")

        // Initialize Firebase
        FirebaseApp.configure()
        delegateLog.notice("⏱️ AppDelegate: Firebase configured +\(String(format: "%.0f", (CFAbsoluteTimeGetCurrent() - t0) * 1000))ms")

        // Notify ConfigurationManager that Firebase is ready (unblocks Remote Config fetch)
        ConfigurationManager.shared.notifyFirebaseReady()

        // Set up push notifications
        setupPushNotifications(application)

        // Set FCM messaging delegate
        Messaging.messaging().delegate = self

        delegateLog.notice("⏱️ AppDelegate: didFinishLaunching END +\(String(format: "%.0f", (CFAbsoluteTimeGetCurrent() - t0) * 1000))ms")
        return true
    }

    // MARK: - Push Notification Setup

    private func setupPushNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self

        // Check if permission was already granted — if so, register immediately.
        // Otherwise, defer to PushNotificationPromptView which shows a custom
        // pre-permission dialog before triggering the system prompt.
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
            // If not yet determined, the custom prompt in the app will handle requesting permission
        }
    }

    /// Public method to request push notification permission.
    /// Called from PushNotificationPromptView when user taps "Enable Notifications".
    static func requestPushPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                #if DEBUG
                print("Push notification authorization error: \(error)")
                #endif
                return
            }

            if granted {
                #if DEBUG
                print("Push notification permission granted")
                #endif
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                #if DEBUG
                print("Push notification permission denied")
                #endif
            }
        }
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Pass device token to Firebase
        Messaging.messaging().apnsToken = deviceToken

        #if DEBUG
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs device token: \(tokenString)")
        #endif

        // Belt-and-braces: explicitly request the current FCM token instead
        // of waiting for the MessagingDelegate callback. We've seen prod
        // installs where Allow Notifications was ON but no FCM token ever
        // hit the backend — the delegate didn't fire on cold launch and
        // there was no fallback. With APNs now bound, Firebase has every-
        // thing it needs to mint an FCM token; if it errors, Sentry sees
        // the failure instead of it disappearing into a DEBUG-only print.
        AppDelegate.fetchAndRegisterFCMToken()
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("Failed to register for remote notifications: \(error)")
        #endif

        // APNs registration failure was previously DEBUG-only print; in
        // prod that meant a permission-on / token-never-arrives state was
        // completely invisible. Capture to Sentry so the silent path is
        // diagnosable. Common causes: missing aps-environment entitlement,
        // sandbox/prod env mismatch on TestFlight, network unreachable
        // during the APNs handshake.
        if SentrySDK.isEnabled {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "apns_register_failed", key: "operation")
            }
        }
    }

    // MARK: - FCM token: explicit fetch + register

    /// Fetch the current FCM token from Firebase and register it with the
    /// backend. Called from `didRegisterForRemoteNotificationsWithDevice-
    /// Token` after APNs is bound, and from `scenePhase == .active` on
    /// every authenticated foreground — defends against the cold-launch
    /// race where MessagingDelegate's `didReceiveRegistrationToken`
    /// doesn't fire and the user ends up with permission ON but no token
    /// ever sent to the backend.
    ///
    /// Idempotent: Firebase returns the same FCM token until it rotates;
    /// the backend dedupes by token string, so re-registering the same
    /// token on every foreground is cheap.
    static func fetchAndRegisterFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                #if DEBUG
                print("FCM token fetch failed: \(error)")
                #endif
                if SentrySDK.isEnabled {
                    SentrySDK.capture(error: error) { scope in
                        scope.setTag(value: "fcm_token_fetch_failed", key: "operation")
                    }
                }
                return
            }
            guard let token = token, !token.isEmpty else { return }

            _ = KeychainService.shared.saveFCMToken(token)

            if KeychainService.shared.isAuthenticated {
                Task {
                    await FCMService.shared.registerToken(token, deviceName: AppDelegate.staticDeviceName())
                }
            }
        }
    }

    /// Same shape as the instance `getDeviceName()` but callable from the
    /// static `fetchAndRegisterFCMToken` path.
    private static func staticDeviceName() -> String {
        let model = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        return "\(model) iOS \(systemVersion)"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        #if DEBUG
        // Log the notification
        print("Received notification in foreground: \(userInfo)")
        #endif

        // Show banner, sound, and badge even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        #if DEBUG
        print("User tapped notification: \(userInfo)")
        #endif

        // Handle the notification tap via NotificationHandler
        NotificationHandler.shared.handleNotificationTap(userInfo: userInfo)

        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {

    /// Called when FCM token is refreshed
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            #if DEBUG
            print("FCM token is nil")
            #endif
            return
        }

        #if DEBUG
        // Only log a prefix — FCM tokens are bearer-equivalent for push, so
        // anyone with the full token can send pushes to this device. Matches
        // the Android DebugTree policy (20-char prefix).
        print("FCM token received: \(token.prefix(20))…")
        #endif

        // Store token securely in Keychain (not UserDefaults)
        _ = KeychainService.shared.saveFCMToken(token)

        // Register token with backend if user is authenticated
        if KeychainService.shared.isAuthenticated {
            Task {
                await FCMService.shared.registerToken(token, deviceName: getDeviceName())
            }
        }

        // Post notification so other parts of the app can react
        NotificationCenter.default.post(
            name: .fcmTokenReceived,
            object: nil,
            userInfo: ["token": token]
        )
    }

    private func getDeviceName() -> String {
        // GDPR: UIDevice.current.name returns the user-assigned device name
        // (e.g. "Viktor's iPhone") on iOS 16+ unless the app requests the
        // userAssignedDeviceName entitlement. We don't — and even if we did,
        // sending a personal name to the backend-side push token DB is PII
        // we don't need. Use a generic model/system string instead; it's
        // enough to tell an iPhone from an iPad for UX (multi-device list).
        let model = UIDevice.current.model           // e.g. "iPhone", "iPad"
        let systemVersion = UIDevice.current.systemVersion
        return "\(model) iOS \(systemVersion)"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let fcmTokenReceived = Notification.Name("fcmTokenReceived")
}
