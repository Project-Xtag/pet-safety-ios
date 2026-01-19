import SwiftUI

struct ContactsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var isLoading = false

    // Primary contact fields (from user profile)
    @State private var primaryEmail = ""
    @State private var primaryPhone = ""
    @State private var showPrimaryEmail = true
    @State private var showPrimaryPhone = true

    // Secondary contact fields
    @State private var secondaryEmail = ""
    @State private var secondaryPhone = ""
    @State private var showSecondaryEmail = false
    @State private var showSecondaryPhone = false

    // Which contact is primary for each type
    @State private var primaryEmailContact = 1 // 1 = primary, 2 = secondary
    @State private var primaryPhoneContact = 1 // 1 = primary, 2 = secondary

    var body: some View {
        List {
            // Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Contact Settings", systemImage: "info.circle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandOrange)

                    Text("These contact details will be shown when someone scans your pet's QR tag. You can add up to two email addresses and phone numbers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            if isEditing {
                editingView
            } else {
                displayView
            }
        }
        .adaptiveList()
        .navigationTitle("Contact Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                    .foregroundColor(.brandOrange)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(.brandOrange)
                    .disabled(isLoading || !isFormValid)
                }
            }
        }
        .onAppear {
            loadContactData()
        }
    }

    // MARK: - Display View
    @ViewBuilder
    private var displayView: some View {
        // Email Section
        Section(header: Text("Email Addresses")) {
            if !primaryEmail.isEmpty || !secondaryEmail.isEmpty {
                if !primaryEmail.isEmpty {
                    ContactRowView(
                        type: "Email",
                        value: primaryEmail,
                        isPrimary: primaryEmailContact == 1,
                        isVisible: showPrimaryEmail
                    )
                }

                if !secondaryEmail.isEmpty {
                    ContactRowView(
                        type: "Email",
                        value: secondaryEmail,
                        isPrimary: primaryEmailContact == 2,
                        isVisible: showSecondaryEmail
                    )
                }
            } else {
                EmptyContactView(type: "email addresses")
            }
        }

        // Phone Section
        Section(header: Text("Phone Numbers")) {
            if !primaryPhone.isEmpty || !secondaryPhone.isEmpty {
                if !primaryPhone.isEmpty {
                    ContactRowView(
                        type: "Phone",
                        value: primaryPhone,
                        isPrimary: primaryPhoneContact == 1,
                        isVisible: showPrimaryPhone
                    )
                }

                if !secondaryPhone.isEmpty {
                    ContactRowView(
                        type: "Phone",
                        value: secondaryPhone,
                        isPrimary: primaryPhoneContact == 2,
                        isVisible: showSecondaryPhone
                    )
                }
            } else {
                EmptyContactView(type: "phone numbers")
            }
        }

        // Edit Button
        Section {
            Button(action: { isEditing = true }) {
                HStack {
                    Spacer()
                    Text("Edit Contact Details")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Editing View
    @ViewBuilder
    private var editingView: some View {
        // Primary Email
        Section(header: Text("Primary Email"), footer: Text("Your main account email address")) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Email address", text: $primaryEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Toggle("Show on pet tag", isOn: $showPrimaryEmail)
                    .tint(.brandOrange)
            }
            .padding(.vertical, 4)
        }

        // Secondary Email
        Section(header: Text("Secondary Email (Optional)"), footer: Text("Backup email for pet recovery notifications")) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Secondary email address", text: $secondaryEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !secondaryEmail.isEmpty {
                    Toggle("Show on pet tag", isOn: $showSecondaryEmail)
                        .tint(.brandOrange)
                }
            }
            .padding(.vertical, 4)
        }

        // Primary Phone
        Section(header: Text("Primary Phone"), footer: Text("Your main contact number")) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Phone number", text: $primaryPhone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Toggle("Show on pet tag", isOn: $showPrimaryPhone)
                    .tint(.brandOrange)
            }
            .padding(.vertical, 4)
        }

        // Secondary Phone
        Section(header: Text("Secondary Phone (Optional)"), footer: Text("Backup phone for emergencies")) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Secondary phone number", text: $secondaryPhone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !secondaryPhone.isEmpty {
                    Toggle("Show on pet tag", isOn: $showSecondaryPhone)
                        .tint(.brandOrange)
                }
            }
            .padding(.vertical, 4)
        }

        // Save/Cancel buttons
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
            .disabled(isLoading || !isFormValid)

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
    }

    // MARK: - Computed Properties
    private var isFormValid: Bool {
        // At least one valid email must be provided
        let hasValidEmail = !primaryEmail.trimmingCharacters(in: .whitespaces).isEmpty &&
                           primaryEmail.contains("@")
        return hasValidEmail
    }

    // MARK: - Data Management
    private func loadContactData() {
        guard let user = authViewModel.currentUser else { return }

        // Load from user profile
        primaryEmail = user.email
        primaryPhone = user.phone ?? ""
        showPrimaryEmail = user.showEmailPublicly ?? true
        showPrimaryPhone = user.showPhonePublicly ?? true

        // TODO: Load secondary contacts from backend when endpoint is available
        // For now, secondary contacts are stored locally
    }

    private func cancelEditing() {
        loadContactData()
        isEditing = false
    }

    private func saveChanges() {
        Task {
            isLoading = true

            do {
                // Update user profile with contact preferences
                let updates: [String: Any] = [
                    "phone": primaryPhone.trimmingCharacters(in: .whitespaces),
                    "show_email_publicly": showPrimaryEmail,
                    "show_phone_publicly": showPrimaryPhone
                ]

                try await authViewModel.updateProfile(updates: updates)

                // TODO: Save secondary contacts to backend when endpoint is available

                appState.showSuccess("Contact details updated successfully!")

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
struct ContactRowView: View {
    let type: String
    let value: String
    let isPrimary: Bool
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type == "Email" ? "envelope.fill" : "phone.fill")
                .foregroundColor(.tealAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.body)

                HStack(spacing: 8) {
                    if isPrimary {
                        Text("PRIMARY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.brandOrange)
                            .cornerRadius(4)
                    }

                    if isVisible {
                        Text("Visible on tag")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Hidden")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EmptyContactView: View {
    let type: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: type == "email addresses" ? "envelope" : "phone")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No \(type) added")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#Preview {
    NavigationView {
        ContactsView()
            .environmentObject(AuthViewModel())
            .environmentObject(AppState())
    }
}
