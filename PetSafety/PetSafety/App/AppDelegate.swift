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
                print("Push notification authorization error: \(error)")
                return
            }

            if granted {
                print("Push notification permission granted")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("Push notification permission denied")
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

        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs device token: \(tokenString)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
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

        // Log the notification
        print("Received notification in foreground: \(userInfo)")

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

        print("User tapped notification: \(userInfo)")

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
            print("FCM token is nil")
            return
        }

        print("FCM token received: \(token)")

        // Store token locally for reference
        UserDefaults.standard.set(token, forKey: "fcmToken")

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
