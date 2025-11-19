import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false

    var body: some View {
        List {
            if let user = authViewModel.currentUser {
                // Profile Header with Subscription Badge
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color("BrandColor"))

                        VStack(spacing: 4) {
                            if !user.fullName.isEmpty {
                                Text(user.fullName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }

                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Subscription Badge (placeholder)
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("Premium Member")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // Menu Items
                Section {
                    NavigationLink(destination: PersonalInformationView()) {
                        MenuItemRow(
                            icon: "person.fill",
                            title: "Personal Information",
                            iconColor: .blue
                        )
                    }

                    NavigationLink(destination: AddressView()) {
                        MenuItemRow(
                            icon: "house.fill",
                            title: "Address",
                            iconColor: .green
                        )
                    }

                    NavigationLink(destination: ContactsView()) {
                        MenuItemRow(
                            icon: "person.2.fill",
                            title: "Contacts",
                            iconColor: .purple
                        )
                    }

                    NavigationLink(destination: PrivacyModeView()) {
                        MenuItemRow(
                            icon: "lock.shield.fill",
                            title: "Privacy Mode",
                            iconColor: .indigo
                        )
                    }

                    NavigationLink(destination: NotificationSettingsView()) {
                        MenuItemRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            iconColor: .orange
                        )
                    }

                    NavigationLink(destination: HelpAndSupportView()) {
                        MenuItemRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            iconColor: .cyan
                        )
                    }
                }

                // Logout
                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("Log Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

// MARK: - Menu Item Row Component
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
