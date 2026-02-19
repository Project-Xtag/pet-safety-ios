import SwiftUI

struct PrivacyModeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState

    @State private var showPhonePublicly: Bool = true
    @State private var showEmailPublicly: Bool = true
    @State private var showAddressPublicly: Bool = true
    @State private var isUpdating: Bool = false
    @State private var didInitialize: Bool = false

    var body: some View {
        List {
            Section(header: VStack(alignment: .leading, spacing: 6) {
                Text("privacy_contact_visibility")
                Text("privacy_contact_footer")
                    .textCase(nil)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }.padding(.bottom, 4)) {
                Toggle(isOn: $showPhonePublicly) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("privacy_show_phone")
                        Text("privacy_show_phone_subtitle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(isUpdating)
                .onChange(of: showPhonePublicly) { _, newValue in
                    guard didInitialize else { return }
                    updatePrivacySetting("show_phone_publicly", value: newValue)
                }
                Toggle(isOn: $showEmailPublicly) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("privacy_show_email")
                        Text("privacy_show_email_subtitle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(isUpdating)
                .onChange(of: showEmailPublicly) { _, newValue in
                    guard didInitialize else { return }
                    updatePrivacySetting("show_email_publicly", value: newValue)
                }
                Toggle(isOn: $showAddressPublicly) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("privacy_show_address")
                        Text("privacy_show_address_subtitle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(isUpdating)
                .onChange(of: showAddressPublicly) { _, newValue in
                    guard didInitialize else { return }
                    updatePrivacySetting("show_address_publicly", value: newValue)
                }
            }

            Section(header: Text("privacy_data_privacy")) {
                Button {
                    UIApplication.shared.open(WebURLHelper.privacyURL)
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        Text("privacy_privacy_policy")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
            // Defer so onChange handlers ignore the initial state setup
            DispatchQueue.main.async {
                didInitialize = true
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


#Preview {
    NavigationView {
        PrivacyModeView()
    }
    .environmentObject(AuthViewModel())
    .environmentObject(AppState())
}
