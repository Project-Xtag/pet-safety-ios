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
        }
    }

    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

// App-wide state management
class AppState: ObservableObject {
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var alertTitle = "Notice"
    @Published var isLoading = false

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
}
