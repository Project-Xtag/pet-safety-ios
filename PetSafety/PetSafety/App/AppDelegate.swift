import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

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
        // Configure App Check BEFORE Firebase initialization
        // This protects Firebase APIs from abuse by verifying requests come from legitimate app instances
        ConfigurationManager.configureAppCheck()

        // Initialize Firebase
        FirebaseApp.configure()

        // Set up push notifications
        setupPushNotifications(application)

        // Set FCM messaging delegate
        Messaging.messaging().delegate = self

        return true
    }

    // MARK: - Push Notification Setup

    private func setupPushNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
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
                    application.registerForRemoteNotifications()
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
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("Failed to register for remote notifications: \(error)")
        #endif
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
        print("FCM token received: \(token)")
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
        return UIDevice.current.name
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let fcmTokenReceived = Notification.Name("fcmTokenReceived")
}
