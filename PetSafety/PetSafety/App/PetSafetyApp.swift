import SwiftUI
import Sentry

@main
struct PetSafetyApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appState = AppState()

    init() {
        // Initialize Sentry for error tracking
        initializeSentry()

        // Configure appearance
        setupAppearance()
    }

    private func initializeSentry() {
        // Sentry DSN for error tracking
        let dsn = "https://59598f05268ea6c3d56f1af280001bf3@o4510743830724608.ingest.de.sentry.io/4510743841669200"

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = {
                #if DEBUG
                return "development"
                #else
                return "production"
                #endif
            }()

            // Performance monitoring - 10% of transactions
            options.tracesSampleRate = 0.1

            // Attach screenshots and view hierarchy for debugging
            options.attachScreenshot = true
            options.attachViewHierarchy = true

            // Enable automatic instrumentation
            options.enableSwizzling = true
            options.enableCaptureFailedRequests = true

            // Filter out expected errors (4xx client errors)
            options.beforeSend = { event in
                // Check if the error is a client error (4xx)
                if let exceptionValue = event.exceptions?.first?.value,
                   exceptionValue.contains("unauthorized") || exceptionValue.contains("401") ||
                   exceptionValue.contains("400") || exceptionValue.contains("404") ||
                   exceptionValue.contains("403") {
                    return nil // Don't send client errors
                }
                return event
            }
        }

        #if DEBUG
        print("✅ Sentry initialized for error tracking")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(appState)
                .tint(Color(red: 1.0, green: 0.569, blue: 0.302)) // Brand Orange #FF914D
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
        // Setup SSE event handlers
        setupSSEHandlers()

        // Connect to SSE if user is authenticated
        if KeychainService.shared.isAuthenticated {
            connectToSSE()
        }
    }

    func showError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showAlert = true
    }

    func showSuccess(_ message: String) {
        alertTitle = "Success"
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
                self?.showSuccess("\(event.petName)'s tag was scanned at \(event.address ?? "an unknown location")!")
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
                self?.showSuccess("\(event.petName) has been sighted\(event.address != nil ? " at \(event.address!)" : "")!")
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
                self?.showSuccess("Great news! \(event.petName) has been found!")
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
