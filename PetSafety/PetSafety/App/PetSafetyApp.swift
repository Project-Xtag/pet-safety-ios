import SwiftUI
import UIKit
import Sentry
import os

extension Notification.Name {
    static let checkoutCompleted = Notification.Name("checkoutCompleted")
    static let tagOrderCompleted = Notification.Name("tagOrderCompleted")
    static let replacementCompleted = Notification.Name("replacementCompleted")
}

private let appLog = Logger(subsystem: "com.petsafety.PetSafety", category: "AppStartup")
private let startupTime = CFAbsoluteTimeGetCurrent()

@main
struct PetSafetyApp: App {
    // Use AppDelegate for Firebase and push notification setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @StateObject private var notificationHandler = NotificationHandler.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @State private var showSplash = true
    @State private var lastSubscriptionRefresh: Date = .distantPast

    init() {
        appLog.notice("⏱️ PetSafetyApp.init() started at +\(String(format: "%.0f", (CFAbsoluteTimeGetCurrent() - startupTime) * 1000))ms")

        // Initialize Sentry for error tracking
        initializeSentry()

        // Configure appearance
        setupAppearance()

        appLog.notice("⏱️ PetSafetyApp.init() completed at +\(String(format: "%.0f", (CFAbsoluteTimeGetCurrent() - startupTime) * 1000))ms")
    }

    private func initializeSentry() {
        // Fetch Sentry DSN from Firebase Remote Config in the background.
        // This runs with low priority so it doesn't block app startup.
        Task.detached(priority: .utility) {
            do {
                try await ConfigurationManager.shared.fetchConfiguration()
            } catch {
                #if DEBUG
                print("⚠️ Remote Config fetch failed: \(error)")
                print("   Continuing with default/cached values...")
                #endif
            }

            let dsn = ConfigurationManager.shared.sentryDSN

            guard !dsn.isEmpty else {
                #if DEBUG
                await MainActor.run { print("⚠️ Sentry DSN not configured in Remote Config - error tracking disabled") }
                #endif
                return
            }

            await MainActor.run {
                SentrySDK.start { options in
                    options.dsn = dsn
                    options.environment = {
                        #if DEBUG
                        return "development"
                        #else
                        return "production"
                        #endif
                    }()

                    options.tracesSampleRate = 0.1

                    #if DEBUG
                    options.attachScreenshot = true
                    options.attachViewHierarchy = true
                    #else
                    options.attachScreenshot = false
                    options.attachViewHierarchy = false
                    #endif

                    options.enableSwizzling = true
                    options.enableCaptureFailedRequests = true

                    options.beforeSend = { event in
                        if let exceptionValue = event.exceptions?.first?.value,
                           exceptionValue.contains("unauthorized") || exceptionValue.contains("401") ||
                           exceptionValue.contains("400") || exceptionValue.contains("404") ||
                           exceptionValue.contains("403") {
                            return nil
                        }
                        return event
                    }
                }

                #if DEBUG
                print("✅ Sentry initialized for error tracking")
                #endif
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            } else {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(appState)
                    .environmentObject(subscriptionViewModel)
                    .environmentObject(notificationHandler)
                    .preferredColorScheme(
                        appearanceMode == "light" ? .light :
                        appearanceMode == "dark" ? .dark : nil
                    )
                    .tint(Color(UIColor.darkGray)) // Dark gray for alert buttons
                    .transition(.opacity)
                    .sheet(isPresented: $notificationHandler.showMapPicker) {
                        if let notification = notificationHandler.pendingScanNotification,
                           let location = notification.location {
                            MapAppPickerView(
                                location: location,
                                petName: notification.petName ?? "Pet"
                            )
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .fcmTokenReceived)) { notification in
                        // FCM token received - could update UI or trigger additional actions
                        #if DEBUG
                        if let token = notification.userInfo?["token"] as? String {
                            print("App received FCM token: \(token.prefix(20))...")
                        }
                        #endif
                    }
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active && authViewModel.isAuthenticated {
                            // Refresh subscription when app comes to foreground (debounce 60s)
                            let now = Date()
                            if now.timeIntervalSince(lastSubscriptionRefresh) > 60 {
                                lastSubscriptionRefresh = now
                                Task {
                                    await subscriptionViewModel.loadCurrentSubscription()
                                }
                            }
                        }
                    }
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "senra" else { return }

        switch url.host {
        case "checkout":
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let type = components?.queryItems?.first(where: { $0.name == "type" })?.value

            if path == "success" {
                switch type {
                case "subscription":
                    appState.showSuccess(String(localized: "checkout_subscription_success"))
                    NotificationCenter.default.post(name: .checkoutCompleted, object: nil)
                case "qr_tag_order":
                    appState.showSuccess(String(localized: "checkout_tag_order_success"))
                    NotificationCenter.default.post(name: .tagOrderCompleted, object: nil)
                case "replacement_shipping":
                    appState.showSuccess(String(localized: "checkout_replacement_success"))
                    NotificationCenter.default.post(name: .replacementCompleted, object: nil)
                default:
                    appState.showSuccess(String(localized: "checkout_success"))
                    NotificationCenter.default.post(name: .checkoutCompleted, object: nil)
                }
            } else if path == "cancelled" {
                #if DEBUG
                print("Checkout cancelled deep link received")
                #endif
            }
        default:
            #if DEBUG
            print("ℹ️ Unhandled deep link: \(url)")
            #endif
        }
    }

    private func setupAppearance() {
        // Brand orange color: #FF914D
        let brandOrange = UIColor(red: 1.0, green: 0.569, blue: 0.302, alpha: 1.0)

        // Configure navigation bar appearance - clean light style
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        // Back button indicator
        appearance.setBackIndicatorImage(UIImage(systemName: "chevron.left"), transitionMaskImage: UIImage(systemName: "chevron.left"))

        // Configure button appearance with brand orange
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: brandOrange]
        appearance.buttonAppearance = buttonAppearance
        appearance.backButtonAppearance = buttonAppearance

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        // Make back button and bar buttons use brand orange
        UINavigationBar.appearance().tintColor = brandOrange
    }
}

// App-wide state management
class AppState: ObservableObject {
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var alertTitle = "Notice"
    @Published var isLoading = false

    // SSE Service for real-time notifications
    private let sseService = SSEService.shared

    init() {
        // Setup SSE event handlers (connection is managed by AuthViewModel)
        setupSSEHandlers()
    }

    func showError(_ message: String) {
        alertTitle = String(localized: "alert_error")
        alertMessage = message
        showAlert = true
    }

    func showSuccess(_ message: String) {
        alertTitle = String(localized: "alert_success")
        alertMessage = message
        showAlert = true
    }

    // MARK: - SSE Management

    func connectToSSE() {
        #if DEBUG
        print("🔌 AppState: Connecting to SSE...")
        #endif
        sseService.connect()
    }

    func disconnectFromSSE() {
        #if DEBUG
        print("🔌 AppState: Disconnecting from SSE...")
        #endif
        sseService.disconnect()
    }


    private func setupSSEHandlers() {
        // Handle tag scanned events
        sseService.onTagScanned = { [weak self] event in
            #if DEBUG
            print("📡 AppState: Tag scanned for \(event.petName)")
            #endif

            // Show in-app alert
            DispatchQueue.main.async {
                self?.showSuccess(String(format: NSLocalizedString("sse_tag_scanned_body", comment: ""), event.petName, event.address ?? ""))
            }

            // Note: Local notification is handled automatically by SSEService
        }

        // Handle sighting reported events
        sseService.onSightingReported = { [weak self] event in
            #if DEBUG
            print("📡 AppState: Sighting reported for \(event.petName)")
            #endif

            // Show in-app alert
            DispatchQueue.main.async {
                let locationSuffix = event.address != nil ? String(format: NSLocalizedString("sse_sighting_at", comment: ""), event.address!) : ""
                self?.showSuccess(String(format: NSLocalizedString("sse_sighting_body", comment: ""), event.petName, locationSuffix))
            }

            // Note: Local notification is handled automatically by SSEService
        }

        // Handle pet found events
        sseService.onPetFound = { [weak self] event in
            #if DEBUG
            print("📡 AppState: Pet found - \(event.petName)")
            #endif

            // Show in-app alert
            DispatchQueue.main.async {
                self?.showSuccess(String(format: NSLocalizedString("sse_pet_found_body", comment: ""), event.petName))
            }

            // Note: Local notification is handled automatically by SSEService
        }

        // Handle connection events
        sseService.onConnected = { event in
            #if DEBUG
            print("✅ AppState: SSE Connected for user \(event.userId)")
            #endif
        }
    }
}
