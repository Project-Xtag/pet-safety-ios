import SwiftUI

struct ShelterCodeView: View {
    @State private var shelterCode: String = ""
    @State private var isRedeeming: Bool = false
    @State private var successMessage: String? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        List {
            // Enter code section
            Section {
                if let successMessage {
                    Label(successMessage, systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    HStack {
                        TextField(String(localized: "shelter_code_enter_footer"), text: $shelterCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        Button(action: redeemCode) {
                            if isRedeeming {
                                ProgressView()
                            } else {
                                Text("shelter_code_redeem")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.brandOrange)
                        .disabled(shelterCode.isEmpty || isRedeeming)
                    }
                }
            } header: {
                Text("shelter_code_enter_header")
            } footer: {
                Text("shelter_code_enter_footer")
            }

            // How It Works
            Section("shelter_how_it_works") {
                Label(String(localized: "shelter_step_1"), systemImage: "1.circle.fill")
                Label(String(localized: "shelter_step_2"), systemImage: "2.circle.fill")
                Label(String(localized: "shelter_step_3"), systemImage: "3.circle.fill")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("shelter_code_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Actions

    private func redeemCode() {
        Task {
            isRedeeming = true
            errorMessage = nil
            do {
                let response = try await APIService.shared.redeemShelterCode(shelterCode.trimmingCharacters(in: .whitespacesAndNewlines))
                successMessage = response.message
            } catch {
                errorMessage = error.localizedDescription
            }
            isRedeeming = false
        }
    }
}
