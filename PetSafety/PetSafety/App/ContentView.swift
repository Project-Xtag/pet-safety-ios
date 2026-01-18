import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .alert(appState.alertTitle, isPresented: $appState.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appState.alertMessage)
        }
        .overlay {
            if appState.isLoading {
                LoadingView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                PetsListView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("My Pets", systemImage: "pawprint.fill")
            }

            NavigationView {
                QRScannerView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Scan QR", systemImage: "qrcode.viewfinder")
            }

            AlertsTabView()
                .tabItem {
                    Label("Alerts", systemImage: "exclamationmark.triangle.fill")
                }

            NavigationView {
                ProfileView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .accentColor(Color("BrandColor"))
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ProgressView()
                .scaleEffect(1.5)
                .frame(width: 100, height: 100)
                .background(Color.white)
                .cornerRadius(10)
        }
    }
}

// MARK: - Adaptive Layout Helpers (iPad-friendly)
extension View {
    func adaptiveContainer(maxWidth: CGFloat = 700) -> some View {
        self
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 24)
    }

    func adaptiveList(maxWidth: CGFloat = 700) -> some View {
        self
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
