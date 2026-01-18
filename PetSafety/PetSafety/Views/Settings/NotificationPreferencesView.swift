import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var viewModel = NotificationPreferencesViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Form {
                Section {
                    Text("Choose how you want to be notified when your pet's tag is scanned or a sighting is reported.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }

                Section(header: Text("Notification Methods")) {
                    Toggle(isOn: $viewModel.preferences.notifyByEmail) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email Notifications")
                                    .font(.body)
                                Text("Receive detailed email alerts")
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SMS Notifications")
                                    .font(.body)
                                Text("Receive text message alerts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "message.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .disabled(viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyBySms)

                    Toggle(isOn: $viewModel.preferences.notifyByPush) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Push Notifications")
                                    .font(.body)
                                Text("Receive real-time in-app alerts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .disabled(viewModel.preferences.enabledCount == 1 && viewModel.preferences.notifyByPush)
                }

                Section {
                    Text("⚠️ At least one notification method must remain enabled to ensure you don't miss important alerts about your pets.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }

                if viewModel.hasChanges {
                    Section {
                        Button(action: {
                            Task {
                                await viewModel.savePreferences()
                            }
                        }) {
                            HStack {
                                Spacer()
                                if viewModel.isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save Changes")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .foregroundColor(.white)
                        .listRowBackground(Color.blue)
                        .disabled(viewModel.isSaving || !viewModel.preferences.isValid)
                    }
                }
            }
            .adaptiveList()
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadPreferences()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Notification preferences saved successfully")
            }

            // Loading overlay
            if viewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading preferences...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }
        }
    }
}

@MainActor
class NotificationPreferencesViewModel: ObservableObject {
    @Published var preferences = NotificationPreferences.default
    @Published var originalPreferences = NotificationPreferences.default
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var showError = false
    @Published var showSuccess = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    var hasChanges: Bool {
        preferences.notifyByEmail != originalPreferences.notifyByEmail ||
        preferences.notifyBySms != originalPreferences.notifyBySms ||
        preferences.notifyByPush != originalPreferences.notifyByPush
    }

    func loadPreferences() async {
        isLoading = true
        errorMessage = nil

        do {
            let loadedPreferences = try await apiService.getNotificationPreferences()
            preferences = loadedPreferences
            originalPreferences = loadedPreferences

            #if DEBUG
            print("✅ Preferences loaded: Email=\(preferences.notifyByEmail), SMS=\(preferences.notifyBySms), Push=\(preferences.notifyByPush)")
            #endif
        } catch {
            errorMessage = error.localizedDescription
            showError = true

            #if DEBUG
            print("❌ Failed to load preferences: \(error)")
            #endif
        }

        isLoading = false
    }

    func savePreferences() async {
        guard preferences.isValid else {
            errorMessage = "At least one notification method must be enabled"
            showError = true
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let updatedPreferences = try await apiService.updateNotificationPreferences(preferences)
            originalPreferences = updatedPreferences
            preferences = updatedPreferences
            showSuccess = true

            #if DEBUG
            print("✅ Preferences saved: Email=\(preferences.notifyByEmail), SMS=\(preferences.notifyBySms), Push=\(preferences.notifyByPush)")
            #endif
        } catch {
            errorMessage = error.localizedDescription
            showError = true

            #if DEBUG
            print("❌ Failed to save preferences: \(error)")
            #endif
        }

        isSaving = false
    }
}

#Preview {
    NavigationView {
        NotificationPreferencesView()
    }
}
