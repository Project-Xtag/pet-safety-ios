import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()

    // Alert Types (local-only preferences)
    @AppStorage("notifyMissingPetAlerts") private var notifyMissingPetAlerts = true
    @AppStorage("notifyNearbyAlerts") private var notifyNearbyAlerts = true

    // Updates (local-only preferences)
    @AppStorage("notifyOrderUpdates") private var notifyOrderUpdates = true
    @AppStorage("notifyAccountActivity") private var notifyAccountActivity = true
    @AppStorage("notifyProductUpdates") private var notifyProductUpdates = false
    @AppStorage("notifyMarketingEmails") private var notifyMarketingEmails = false

    var body: some View {
        List {
            Section(header: Text("notif_channels"), footer: Text("notif_channels_footer")) {
                Toggle(isOn: $viewModel.preferences.notifyByPush) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("notif_push")
                            Text("notif_push_desc")
                                .font(.caption)
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
                                .font(.caption)
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
                                .font(.caption)
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
                Toggle("notif_missing_pet_alerts", isOn: $notifyMissingPetAlerts)
                Toggle("notif_nearby_alerts", isOn: $notifyNearbyAlerts)
            }

            Section(header: Text("notif_account_orders"), footer: Text("notif_account_orders_footer")) {
                Toggle("notif_order_updates", isOn: $notifyOrderUpdates)
                Toggle("notif_account_activity", isOn: $notifyAccountActivity)
            }

            Section(header: Text("notif_optional_updates"), footer: Text("notif_optional_footer")) {
                Toggle("notif_product_updates", isOn: $notifyProductUpdates)
                Toggle("notif_marketing_emails", isOn: $notifyMarketingEmails)
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
