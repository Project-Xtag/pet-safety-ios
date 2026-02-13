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
            Section(header: Text("privacy_contact_visibility"), footer: Text("privacy_contact_footer")) {
                Toggle("privacy_show_phone", isOn: $showPhonePublicly)
                    .disabled(isUpdating)
                    .onChange(of: showPhonePublicly) { _, newValue in
                        updatePrivacySetting("show_phone_publicly", value: newValue)
                    }
                Toggle("privacy_show_email", isOn: $showEmailPublicly)
                    .disabled(isUpdating)
                    .onChange(of: showEmailPublicly) { _, newValue in
                        updatePrivacySetting("show_email_publicly", value: newValue)
                    }
                Toggle("privacy_show_address", isOn: $showAddressPublicly)
                    .disabled(isUpdating)
                    .onChange(of: showAddressPublicly) { _, newValue in
                        updatePrivacySetting("show_address_publicly", value: newValue)
                    }
            }

            Section(header: Text("privacy_data_privacy")) {
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        Text("privacy_privacy_policy")
                    }
                }

                NavigationLink(destination: DataManagementView()) {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        Text("privacy_data_management")
                    }
                }
            }

            Section(footer: Text("privacy_mode_footer")) {
                EmptyView()
            }
        }
        .navigationTitle("privacy_title")
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
                    appState.showSuccess(String(localized: "privacy_settings_updated"))
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    appState.showError(String(localized: "privacy_settings_failed"))
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
                Text("privacy_privacy_policy")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                Text("privacy_policy_updated")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Group {
                    SectionHeader(title: String(localized: "privacy_policy_section1_title"))
                    SectionText(text: String(localized: "privacy_policy_section1_body"))

                    SectionHeader(title: String(localized: "privacy_policy_section2_title"))
                    SectionText(text: String(localized: "privacy_policy_section2_body"))

                    SectionHeader(title: String(localized: "privacy_policy_section3_title"))
                    SectionText(text: String(localized: "privacy_policy_section3_body"))

                    SectionHeader(title: String(localized: "privacy_policy_section4_title"))
                    SectionText(text: String(localized: "privacy_policy_section4_body"))

                    SectionHeader(title: String(localized: "privacy_policy_section5_title"))
                    SectionText(text: String(localized: "privacy_policy_section5_body"))
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("privacy_policy_title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataManagementView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            Section(header: Text("privacy_your_data"), footer: Text("privacy_your_data_footer")) {
                Button(action: { exportData() }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("privacy_export_data")
                            .foregroundColor(.primary)
                    }
                }
            }

            Section(header: Text("privacy_deletion_section"), footer: Text("privacy_deletion_footer")) {
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        Text("privacy_delete_account")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("privacy_data_management")
        .navigationBarTitleDisplayMode(.inline)
        .alert("delete_account", isPresented: $showingDeleteAlert) {
            Button("cancel", role: .cancel) { }
            Button("delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("privacy_delete_confirm")
        }
    }

    private func exportData() {
        appState.showSuccess(String(localized: "data_export_requested"))
    }

    private func deleteAccount() {
        appState.showError(String(localized: "account_deletion_unavailable"))
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
