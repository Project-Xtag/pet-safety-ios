import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var missingPetNames: [String] = []
    @State private var isCheckingDelete = false
    @State private var isDeleting = false

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

                    // Delete Account Section
                    deleteAccountSection
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("log_out", isPresented: $showingLogoutAlert) {
            Button("cancel", role: .cancel) { }
            Button("log_out", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("logout_confirm")
        }
        .alert("profile_delete_account", isPresented: $showingDeleteConfirmation) {
            Button("cancel", role: .cancel) { }
            Button("delete_account", role: .destructive) {
                performDeleteAccount()
            }
        } message: {
            Text("delete_account_full_warning")
        }
        .alert("profile_cannot_delete", isPresented: $showingDeleteError) {
            Button("ok", role: .cancel) { }
        } message: {
            if missingPetNames.isEmpty {
                Text(deleteErrorMessage)
            } else {
                Text(String(format: NSLocalizedString("missing_pets_label", comment: ""), missingPetNames.joined(separator: ", ")))
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title
            Text("profile_title")
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
                            .accessibilityLabel("Profile avatar")
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
                    .accessibilityLabel("Edit profile photo")
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
                ProfileMenuRow(icon: "person", title: NSLocalizedString("profile_personal_info", comment: ""))
            }

            NavigationLink(destination: AddressView()) {
                ProfileMenuRow(icon: "house", title: NSLocalizedString("profile_address", comment: ""))
            }

            NavigationLink(destination: ContactsView()) {
                ProfileMenuRow(icon: "person.2", title: NSLocalizedString("profile_contacts", comment: ""))
            }

            NavigationLink(destination: PrivacyModeView()) {
                ProfileMenuRow(icon: "lock.shield", title: NSLocalizedString("profile_privacy_mode", comment: ""))
            }

            NavigationLink(destination: NotificationSettingsView()) {
                ProfileMenuRow(icon: "bell", title: NSLocalizedString("profile_notifications", comment: ""))
            }

            NavigationLink(destination: HelpAndSupportView()) {
                ProfileMenuRow(icon: "questionmark.circle", title: NSLocalizedString("profile_help_support", comment: ""))
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
                Text("profile_log_out")
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

    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        VStack(spacing: 12) {
            Text("profile_danger_zone")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red.opacity(0.7))
                .tracking(1)

            Button(action: { checkAndDeleteAccount() }) {
                HStack(spacing: 12) {
                    if isCheckingDelete || isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                    }
                    Text(isDeleting ? NSLocalizedString("profile_deleting", comment: "") : NSLocalizedString("profile_delete_account", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .cornerRadius(16)
                .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isCheckingDelete || isDeleting)

            Text("profile_delete_permanent")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Delete Account Helpers
    private func checkAndDeleteAccount() {
        isCheckingDelete = true

        Task {
            do {
                let response = try await APIService.shared.canDeleteAccount()

                await MainActor.run {
                    isCheckingDelete = false

                    if response.canDelete {
                        showingDeleteConfirmation = true
                    } else {
                        deleteErrorMessage = response.message ?? NSLocalizedString("profile_cannot_delete_message", comment: "")
                        missingPetNames = response.missingPets?.map { $0.name } ?? []
                        showingDeleteError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingDelete = false
                    deleteErrorMessage = error.localizedDescription
                    missingPetNames = []
                    showingDeleteError = true
                }
            }
        }
    }

    private func performDeleteAccount() {
        isDeleting = true

        Task {
            do {
                _ = try await APIService.shared.deleteAccount()
                await MainActor.run {
                    authViewModel.logout()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    deleteErrorMessage = error.localizedDescription
                    missingPetNames = []
                    showingDeleteError = true
                }
            }
        }
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
                .accessibilityHidden(true)
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
                .accessibilityLabel(title)

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
