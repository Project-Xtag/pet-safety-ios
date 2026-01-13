import SwiftUI

@main
struct PetSafetyApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appState = AppState()

    init() {
        // Configure appearance
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(appState)
                .accentColor(.white)
        }
    }

    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        // Make back button visible and white
        appearance.setBackIndicatorImage(UIImage(systemName: "chevron.left"), transitionMaskImage: UIImage(systemName: "chevron.left"))

        // Configure button appearance (including back button)
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance = buttonAppearance
        appearance.backButtonAppearance = buttonAppearance

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        // Make back button tint color white
        UINavigationBar.appearance().tintColor = .white
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
