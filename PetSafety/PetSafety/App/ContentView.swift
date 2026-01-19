import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @StateObject private var deepLinkService = DeepLinkService.shared

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
        // Handle deep links for tag activation
        .sheet(isPresented: $deepLinkService.showTagActivation) {
            if let tagCode = deepLinkService.pendingTagCode {
                if authViewModel.isAuthenticated {
                    TagActivationView(tagCode: tagCode) {
                        deepLinkService.clearPendingLink()
                    }
                    .environmentObject(appState)
                } else {
                    // User not logged in - show message
                    DeepLinkLoginPromptView(tagCode: tagCode) {
                        deepLinkService.clearPendingLink()
                    }
                }
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        #if DEBUG
        print("🔗 ContentView: Received URL: \(url.absoluteString)")
        #endif

        // Let the DeepLinkService handle the URL
        deepLinkService.handleURL(url)
    }
}

// MARK: - Deep Link Login Prompt
struct DeepLinkLoginPromptView: View {
    let tagCode: String
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                Text("Login Required")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Please log in to activate this tag for your pet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                VStack(spacing: 8) {
                    Text("Tag Code")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(tagCode)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.vertical)

                Text("After logging in, scan the tag again or go to My Pets to activate it")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                Button(action: onDismiss) {
                    Text("OK")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("BrandColor"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationTitle("Activate Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                }
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
