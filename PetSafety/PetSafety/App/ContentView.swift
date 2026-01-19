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
        print("Received URL: \(url.absoluteString)")
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

                ZStack {
                    Circle()
                        .fill(Color.brandOrange.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.brandOrange)
                }

                Text("Login Required")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text("Please log in to activate this tag for your pet")
                    .font(.system(size: 15))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                VStack(spacing: 8) {
                    Text("Tag Code")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.mutedText)

                    Text(tagCode)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.vertical)

                Text("After logging in, scan the tag again or go to My Pets to activate it")
                    .font(.system(size: 13))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                Button(action: onDismiss) {
                    Text("OK")
                }
                .buttonStyle(BrandButtonStyle())
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

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    NavigationView {
                        PetsListView()
                    }
                    .navigationViewStyle(.stack)
                case 1:
                    NavigationView {
                        QRScannerView()
                    }
                    .navigationViewStyle(.stack)
                case 2:
                    AlertsTabView()
                case 3:
                    NavigationView {
                        ProfileView()
                    }
                    .navigationViewStyle(.stack)
                default:
                    EmptyView()
                }
            }

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(
                icon: "pawprint.fill",
                title: "My Pets",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )

            TabBarItem(
                icon: "qrcode.viewfinder",
                title: "Scan QR",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )

            TabBarItem(
                icon: "exclamationmark.triangle.fill",
                title: "Alerts",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )

            TabBarItem(
                icon: "person.fill",
                title: "Account",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -5)
        )
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .brandOrange : .mutedText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                isSelected
                    ? Color.peachBackground.opacity(0.8)
                    : Color.clear
            )
            .cornerRadius(16)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.brandOrange)
            }
            .frame(width: 100, height: 100)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
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
