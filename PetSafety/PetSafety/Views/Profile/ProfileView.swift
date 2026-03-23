import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @State private var showingLogoutAlert = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isUploadingPhoto = false

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
                        .padding(.bottom, 120)
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
    }

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title + dark mode toggle
            HStack {
                Spacer()
                Text("profile_title")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Button {
                    // Toggle: if system or light → dark, if dark → light
                    appearanceMode = (appearanceMode == "dark") ? "light" : "dark"
                } label: {
                    Image(systemName: appearanceMode == "dark" || (appearanceMode == "system" && colorScheme == .dark) ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.brandOrange)
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 60)

            // Avatar and Info
            VStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.tealAccent)
                            .frame(width: 96, height: 96)
                        if let profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel(String(localized: "accessibility_profile_avatar"))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)

                    // Photo Picker Button
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Image(systemName: isUploadingPhoto ? "arrow.triangle.2.circlepath" : "pencil")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.brandOrange)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .disabled(isUploadingPhoto)
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                profileImage = image
                                isUploadingPhoto = true
                                do {
                                    try await APIService.shared.uploadProfileImage(imageData: image.jpegData(compressionQuality: 0.8) ?? Data())
                                } catch {
                                    #if DEBUG
                                    print("Profile image upload failed: \(error)")
                                    #endif
                                }
                                isUploadingPhoto = false
                            }
                        }
                    }
                    .accessibilityLabel(String(localized: "accessibility_edit_profile_photo"))
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

            NavigationLink(destination: ContactsView()) {
                ProfileMenuRow(icon: "person.2", title: NSLocalizedString("profile_contacts", comment: ""))
            }

            NavigationLink(destination: NotificationSettingsView()) {
                ProfileMenuRow(icon: "bell", title: NSLocalizedString("profile_notification_settings", comment: ""))
            }

            NavigationLink(destination: OrdersView()) {
                ProfileMenuRow(icon: "bag", title: NSLocalizedString("profile_orders_invoices", comment: ""))
            }

            NavigationLink(destination: ShelterCodeView()) {
                ProfileMenuRow(icon: "building.2", title: NSLocalizedString("profile_shelter_code", comment: ""))
            }

            NavigationLink(destination: ContactSupportView()) {
                ProfileMenuRow(icon: "envelope", title: NSLocalizedString("profile_contact_us", comment: ""))
            }

            NavigationLink(destination: PrivacyModeView()) {
                ProfileMenuRow(icon: "lock.shield", title: NSLocalizedString("profile_privacy_mode", comment: ""))
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
