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
                Section(header: Text("Personal Details")) {
                    HStack {
                        Text("First Name")
                            .frame(width: 100, alignment: .leading)
                        TextField("Enter first name", text: $firstName)
                    }

                    HStack {
                        Text("Last Name")
                            .frame(width: 100, alignment: .leading)
                        TextField("Enter last name", text: $lastName)
                    }

                    HStack {
                        Text("Email")
                            .frame(width: 100, alignment: .leading)
                        TextField("Enter email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(true) // Email usually can't be changed
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Phone")
                            .frame(width: 100, alignment: .leading)
                        TextField("Enter phone number", text: $phone)
                            .keyboardType(.phonePad)
                    }
                }

                Section {
                    Button(action: { saveChanges() }) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Saving...")
                            } else {
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoading || !hasChanges)

                    Button(action: { cancelEditing() }) {
                        HStack {
                            Spacer()
                            Text("Cancel")
                            Spacer()
                        }
                    }
                    .foregroundColor(.secondary)
                    .disabled(isLoading)
                }
            } else {
                // View Mode
                Section(header: Text("Personal Details")) {
                    InfoRow(label: "First Name", value: firstName.isEmpty ? "Not set" : firstName)
                    InfoRow(label: "Last Name", value: lastName.isEmpty ? "Not set" : lastName)
                    InfoRow(label: "Email", value: email)
                    InfoRow(label: "Phone", value: phone.isEmpty ? "Not set" : phone)
                }

                Section {
                    Button(action: { startEditing() }) {
                        HStack {
                            Spacer()
                            Text("Edit Information")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Personal Information")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(.white)
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
                appState.showSuccess("Personal information updated successfully!")

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
                .foregroundColor(value == "Not set" ? .secondary : .primary)
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
