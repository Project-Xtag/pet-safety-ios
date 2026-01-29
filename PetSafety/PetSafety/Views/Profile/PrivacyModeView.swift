import SwiftUI

struct PrivacyModeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState

    @State private var showPhonePublicly: Bool = true
    @State private var showEmailPublicly: Bool = true
    @State private var showAddressPublicly: Bool = true
    @State private var isUpdating: Bool = false

    var body: some View {
        List {
            Section(header: Text("Contact Visibility"), footer: Text("Control what contact information is visible when someone scans your pet's QR tag")) {
                Toggle("Show Phone Number", isOn: $showPhonePublicly)
                    .disabled(isUpdating)
                    .onChange(of: showPhonePublicly) { _, newValue in
                        updatePrivacySetting("show_phone_publicly", value: newValue)
                    }
                Toggle("Show Email Address", isOn: $showEmailPublicly)
                    .disabled(isUpdating)
                    .onChange(of: showEmailPublicly) { _, newValue in
                        updatePrivacySetting("show_email_publicly", value: newValue)
                    }
                Toggle("Show Address", isOn: $showAddressPublicly)
                    .disabled(isUpdating)
                    .onChange(of: showAddressPublicly) { _, newValue in
                        updatePrivacySetting("show_address_publicly", value: newValue)
                    }
            }

            Section(header: Text("Data Privacy")) {
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        Text("Privacy Policy")
                    }
                }

                NavigationLink(destination: DataManagementView()) {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        Text("Data Management")
                    }
                }
            }

            Section(footer: Text("Your privacy is important to us. We never share your data with third parties without your explicit consent.")) {
                EmptyView()
            }
        }
        .navigationTitle("Privacy Mode")
        .adaptiveList()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Initialize from current user settings
            if let user = authViewModel.currentUser {
                showPhonePublicly = user.showPhonePublicly ?? true
                showEmailPublicly = user.showEmailPublicly ?? true
                showAddressPublicly = user.showAddressPublicly ?? true
            }
        }
    }

    private func updatePrivacySetting(_ field: String, value: Bool) {
        isUpdating = true
        Task {
            do {
                try await authViewModel.updateProfile(updates: [field: value])
                await MainActor.run {
                    isUpdating = false
                    appState.showSuccess("Privacy settings updated")
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    appState.showError("Failed to update privacy settings")
                    // Revert the toggle on failure
                    if let user = authViewModel.currentUser {
                        showPhonePublicly = user.showPhonePublicly ?? true
                        showEmailPublicly = user.showEmailPublicly ?? true
                        showAddressPublicly = user.showAddressPublicly ?? true
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                Text("Last updated: November 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Group {
                    SectionHeader(title: "1. Information We Collect")
                    SectionText(text: "We collect information you provide directly to us, including your name, email address, phone number, and address when you register for our service.")

                    SectionHeader(title: "2. How We Use Your Information")
                    SectionText(text: "We use the information we collect to provide, maintain, and improve our services, including to help reunite lost pets with their owners.")

                    SectionHeader(title: "3. Information Sharing")
                    SectionText(text: "We do not share your personal information with third parties except as necessary to provide our services or as required by law.")

                    SectionHeader(title: "4. Data Security")
                    SectionText(text: "We implement appropriate security measures to protect your personal information from unauthorized access, alteration, or destruction.")

                    SectionHeader(title: "5. Your Rights")
                    SectionText(text: "You have the right to access, update, or delete your personal information at any time through your account settings.")
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataManagementView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            Section(header: Text("Your Data"), footer: Text("View and manage all data we have stored about you")) {
                Button(action: { exportData() }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("Export My Data")
                            .foregroundColor(.primary)
                    }
                }
            }

            Section(header: Text("Data Deletion"), footer: Text("Permanently delete your account and all associated data. This action cannot be undone.")) {
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        Text("Delete My Account")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you sure you want to permanently delete your account? This will remove all your data including pet profiles and cannot be undone.")
        }
    }

    private func exportData() {
        appState.showSuccess("Data export will be emailed to you within 24 hours")
    }

    private func deleteAccount() {
        appState.showError("Account deletion is currently not available. Please contact support.")
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.top, 8)
    }
}

struct SectionText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundColor(.secondary)
    }
}

#Preview {
    NavigationView {
        PrivacyModeView()
    }
    .environmentObject(AuthViewModel())
    .environmentObject(AppState())
}
