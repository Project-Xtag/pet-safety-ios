import SwiftUI

struct EditAlertView: View {
    let alert: MissingPetAlert
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var description: String
    @State private var lastSeenAddress: String
    @State private var rewardAmount: String
    @State private var isLoading = false

    init(alert: MissingPetAlert) {
        self.alert = alert
        _description = State(initialValue: alert.additionalInfo ?? "")
        _lastSeenAddress = State(initialValue: alert.lastSeenLocation ?? "")
        _rewardAmount = State(initialValue: alert.rewardAmount ?? "")
    }

    var body: some View {
        Form {
            Section(header: Text("edit_alert_location")) {
                TextField(String(localized: "mark_lost_address_placeholder"), text: $lastSeenAddress)
                    .autocapitalization(.words)
            }

            Section(header: Text("edit_alert_description")) {
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .overlay(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("mark_lost_additional_placeholder")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            }

            Section(header: Text("reward_amount_label")) {
                TextField(String(localized: "reward_amount_placeholder"), text: $rewardAmount)
                    .keyboardType(.default)
            }

            Section {
                Button(action: saveChanges) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("save_changes")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(isLoading ? Color.brandOrange.opacity(0.4) : Color.brandOrange)
                .foregroundColor(.white)
                .disabled(isLoading)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .adaptiveList()
        .navigationTitle("edit_alert_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("cancel") {
                    dismiss()
                }
                .foregroundColor(.brandOrange)
            }
        }
    }

    private func saveChanges() {
        isLoading = true
        Task {
            do {
                _ = try await APIService.shared.updateAlert(
                    id: alert.id,
                    description: description.isEmpty ? nil : description,
                    lastSeenAddress: lastSeenAddress.isEmpty ? nil : lastSeenAddress,
                    rewardAmount: rewardAmount.isEmpty ? nil : rewardAmount
                )
                await MainActor.run {
                    appState.showSuccess(String(localized: "edit_alert_success"))
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    appState.showError(error.localizedDescription)
                }
            }
        }
    }
}
