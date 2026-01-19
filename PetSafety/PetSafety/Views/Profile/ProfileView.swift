import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    headerSection

                    // Menu Section
                    menuSection
                        .padding(.top, 24)

                    // Logout Button
                    logoutSection
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title
            Text("Account")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.top, 60)

            // Avatar and Info
            VStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.tealAccent)
                            .frame(width: 96, height: 96)
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)

                    // Edit Button
                    Button(action: {
                        // Edit profile photo
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.brandOrange)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                }

                // User Info
                if let user = authViewModel.currentUser {
                    VStack(spacing: 6) {
                        if !user.fullName.isEmpty {
                            Text(user.fullName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        }

                        Text(user.email)
                            .font(.system(size: 14))
                            .foregroundColor(.mutedText)
                    }

                    // Premium Badge
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.tealAccent)
                        Text("PREMIUM MEMBER")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.tealAccent)
                            .tracking(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.tealAccent.opacity(0.1))
                    .cornerRadius(20)
                }
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.peachBackground)
    }

    // MARK: - Menu Section
    private var menuSection: some View {
        VStack(spacing: 2) {
            NavigationLink(destination: PersonalInformationView()) {
                ProfileMenuRow(icon: "person", title: "Personal Information")
            }

            NavigationLink(destination: AddressView()) {
                ProfileMenuRow(icon: "house", title: "Address")
            }

            NavigationLink(destination: ContactsView()) {
                ProfileMenuRow(icon: "person.2", title: "Contacts")
            }

            NavigationLink(destination: PrivacyModeView()) {
                ProfileMenuRow(icon: "lock.shield", title: "Privacy Mode")
            }

            NavigationLink(destination: NotificationSettingsView()) {
                ProfileMenuRow(icon: "bell", title: "Notifications")
            }

            NavigationLink(destination: HelpAndSupportView()) {
                ProfileMenuRow(icon: "questionmark.circle", title: "Help & Support")
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }

    // MARK: - Logout Section
    private var logoutSection: some View {
        Button(action: { showingLogoutAlert = true }) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18))
                Text("Log Out")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.brandOrange)
            .cornerRadius(16)
            .shadow(color: Color.brandOrange.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Profile Menu Row
struct ProfileMenuRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.mutedText)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(UIColor.systemGray3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
    }
}

// Keep the original MenuItemRow for backward compatibility
struct MenuItemRow: View {
    let icon: String
    let title: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthViewModel())
            .environmentObject(AppState())
    }
}
