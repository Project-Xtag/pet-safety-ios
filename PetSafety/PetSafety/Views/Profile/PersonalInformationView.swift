import SwiftUI

struct PersonalInformationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isLoading = false

    // Form fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""

    var body: some View {
        List {
            if isEditing {
                // Edit Mode
                Section(header: Text("personal_details")) {
                    HStack {
                        Text("personal_first_name")
                            .frame(width: 100, alignment: .leading)
                        TextField(NSLocalizedString("personal_first_name_placeholder", comment: ""), text: $firstName)
                    }

                    HStack {
                        Text("personal_last_name")
                            .frame(width: 100, alignment: .leading)
                        TextField(NSLocalizedString("personal_last_name_placeholder", comment: ""), text: $lastName)
                    }

                    HStack {
                        Text("personal_email")
                            .frame(width: 100, alignment: .leading)
                        TextField(NSLocalizedString("personal_email_placeholder", comment: ""), text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(true) // Email usually can't be changed
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("personal_phone")
                            .frame(width: 100, alignment: .leading)
                        TextField(NSLocalizedString("personal_phone_placeholder", comment: ""), text: $phone)
                            .keyboardType(.phonePad)
                    }
                }

                Section {
                    Button(action: { saveChanges() }) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("saving")
                                    .foregroundColor(.white)
                            } else {
                                Text("save_changes")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(BrandButtonStyle(isDisabled: isLoading || !hasChanges))
                    .disabled(isLoading || !hasChanges)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Button(action: { cancelEditing() }) {
                        HStack {
                            Spacer()
                            Text("cancel")
                            Spacer()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(isLoading)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            } else {
                // View Mode
                Section(header: Text("personal_details")) {
                    InfoRow(label: NSLocalizedString("personal_first_name", comment: ""), value: firstName.isEmpty ? NSLocalizedString("not_set", comment: "") : firstName)
                    InfoRow(label: NSLocalizedString("personal_last_name", comment: ""), value: lastName.isEmpty ? NSLocalizedString("not_set", comment: "") : lastName)
                    InfoRow(label: NSLocalizedString("personal_email", comment: ""), value: email)
                    InfoRow(label: NSLocalizedString("personal_phone", comment: ""), value: phone.isEmpty ? NSLocalizedString("not_set", comment: "") : phone)
                }

                Section {
                    Button(action: { startEditing() }) {
                        Text("edit_information")
                    }
                    .buttonStyle(BrandButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("personal_title")
        .adaptiveList()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        cancelEditing()
                    }
                    .foregroundColor(.brandOrange)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save") {
                        saveChanges()
                    }
                    .foregroundColor(.brandOrange)
                    .disabled(isLoading || !hasChanges)
                }
            }
        }
        .onAppear {
            loadUserData()
        }
    }

    private var hasChanges: Bool {
        guard let user = authViewModel.currentUser else { return false }
        return firstName != (user.firstName ?? "") ||
               lastName != (user.lastName ?? "") ||
               phone != (user.phone ?? "")
    }

    private func loadUserData() {
        guard let user = authViewModel.currentUser else { return }
        firstName = user.firstName ?? ""
        lastName = user.lastName ?? ""
        email = user.email
        phone = user.phone ?? ""
    }

    private func startEditing() {
        isEditing = true
    }

    private func cancelEditing() {
        loadUserData() // Reset to original values
        isEditing = false
    }

    private func saveChanges() {
        Task {
            isLoading = true

            do {
                let updates: [String: Any] = [
                    "first_name": firstName,
                    "last_name": lastName,
                    "phone": phone
                ]

                try await authViewModel.updateProfile(updates: updates)
                appState.showSuccess(NSLocalizedString("updated", comment: ""))

                await MainActor.run {
                    isLoading = false
                    isEditing = false
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

// MARK: - Supporting Views
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(value == NSLocalizedString("not_set", comment: "") ? .secondary : .primary)
        }
    }
}

#Preview {
    NavigationView {
        PersonalInformationView()
            .environmentObject(AuthViewModel())
            .environmentObject(AppState())
    }
}
