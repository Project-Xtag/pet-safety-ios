import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()

    var body: some View {
        List {
            Section(header: Text("notif_channels"), footer: Text("notif_channels_footer")) {
                Toggle(isOn: $viewModel.preferences.notifyByPush) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("notif_push")
                            Text("notif_push_desc")
                                .font(.appFont(.caption))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.brandOrange)
                    }
                }
                .disabled(viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByPush)

                Toggle(isOn: $viewModel.preferences.notifyByEmail) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("notif_email")
                            Text("notif_email_desc")
                                .font(.appFont(.caption))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                    }
                }
                .disabled(viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByEmail)

                Toggle(isOn: $viewModel.preferences.notifyBySms) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("notif_sms")
                            Text("notif_sms_desc")
                                .font(.appFont(.caption))
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "message.fill")
                            .foregroundColor(.green)
                    }
                }
                .disabled(viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyBySms)
            }

            Section(header: Text("notif_pet_alerts"), footer: Text("notif_pet_alerts_footer")) {
                Toggle(isOn: $viewModel.preferences.missingPetAlerts) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("notif_missing_pet_alerts")
                        Text("notif_missing_pet_alerts_subtitle")
                            .font(.appFont(.caption))
                            .foregroundColor(.secondary)
                    }
                }
            }

            if viewModel.hasChanges {
                Section {
                    Button(action: {
                        Task { await viewModel.savePreferences() }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("notif_save_changes")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color.brandOrange)
                    .disabled(viewModel.isSaving || !viewModel.preferences.isValid)
                }
            }

            Section(footer: Text("notif_critical_footer")) {
                EmptyView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            Spacer().frame(height: 20)
        }
        .navigationTitle("notif_title")
        .adaptiveList()
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPreferences()
        }
        .alert("error", isPresented: $viewModel.showError) {
            Button("ok", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? String(localized: "error"))
        }
        .alert("notif_saved", isPresented: $viewModel.showSuccess) {
            Button("ok", role: .cancel) {}
        } message: {
            Text("notif_saved_message")
        }
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
    }
}
