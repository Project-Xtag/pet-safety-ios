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
                    Label("contacts_settings", systemImage: "info.circle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandOrange)

                    Text("contacts_info_full")
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
        .navigationTitle("contact_details")
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
        Section(header: Text("contacts_email_section")) {
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
                EmptyContactView(type: NSLocalizedString("email_addresses", comment: "").lowercased())
            }
        }

        // Phone Section
        Section(header: Text("contacts_phone_section")) {
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
                EmptyContactView(type: NSLocalizedString("phone_numbers", comment: "").lowercased())
            }
        }

        // Edit Button
        Section {
            Button(action: { isEditing = true }) {
                HStack {
                    Spacer()
                    Text("contacts_edit_title")
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
        Section(header: Text("contacts_primary_email"), footer: Text("contacts_primary_email_edit_footer")) {
            VStack(alignment: .leading, spacing: 8) {
                TextField(NSLocalizedString("contacts_email_placeholder", comment: ""), text: $primaryEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Toggle("contacts_show_on_tag", isOn: $showPrimaryEmail)
                    .tint(.brandOrange)
            }
            .padding(.vertical, 4)
        }

        // Secondary Email
        Section(header: Text("contacts_secondary_email"), footer: Text("contacts_secondary_email_edit_footer")) {
            VStack(alignment: .leading, spacing: 8) {
                TextField(NSLocalizedString("contacts_secondary_email_placeholder", comment: ""), text: $secondaryEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !secondaryEmail.isEmpty {
                    Toggle("contacts_show_on_tag", isOn: $showSecondaryEmail)
                        .tint(.brandOrange)
                }
            }
            .padding(.vertical, 4)
        }

        // Primary Phone
        Section(header: Text("contacts_primary_phone"), footer: Text("contacts_primary_phone_edit_footer")) {
            VStack(alignment: .leading, spacing: 8) {
                TextField(NSLocalizedString("contacts_phone_placeholder", comment: ""), text: $primaryPhone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Toggle("contacts_show_on_tag", isOn: $showPrimaryPhone)
                    .tint(.brandOrange)
            }
            .padding(.vertical, 4)
        }

        // Secondary Phone
        Section(header: Text("contacts_secondary_phone"), footer: Text("contacts_secondary_phone_edit_footer")) {
            VStack(alignment: .leading, spacing: 8) {
                TextField(NSLocalizedString("contacts_secondary_phone_placeholder", comment: ""), text: $secondaryPhone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !secondaryPhone.isEmpty {
                    Toggle("contacts_show_on_tag", isOn: $showSecondaryPhone)
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
                        Text("saving")
                    } else {
                        Text("save_changes")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(isLoading || !isFormValid)

            Button(action: { cancelEditing() }) {
                HStack {
                    Spacer()
                    Text("cancel")
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

        // Load primary contacts from user profile
        primaryEmail = user.email
        primaryPhone = user.phone ?? ""
        showPrimaryEmail = user.showEmailPublicly ?? true
        showPrimaryPhone = user.showPhonePublicly ?? true

        // Load secondary contacts from user profile
        secondaryEmail = user.secondaryEmail ?? ""
        secondaryPhone = user.secondaryPhone ?? ""
        // Secondary contacts default to hidden if not explicitly set
        showSecondaryEmail = !secondaryEmail.isEmpty
        showSecondaryPhone = !secondaryPhone.isEmpty
    }

    private func cancelEditing() {
        loadContactData()
        isEditing = false
    }

    private func saveChanges() {
        Task {
            isLoading = true

            do {
                // Update user profile with all contact information
                var updates: [String: Any] = [
                    "phone": primaryPhone.trimmingCharacters(in: .whitespaces),
                    "show_email_publicly": showPrimaryEmail,
                    "show_phone_publicly": showPrimaryPhone
                ]

                // Add secondary contacts (trim whitespace, empty strings become nil on backend)
                let trimmedSecondaryPhone = secondaryPhone.trimmingCharacters(in: .whitespaces)
                let trimmedSecondaryEmail = secondaryEmail.trimmingCharacters(in: .whitespaces)

                // Send secondary_phone and secondary_email to backend
                updates["secondary_phone"] = trimmedSecondaryPhone.isEmpty ? "" : trimmedSecondaryPhone
                updates["secondary_email"] = trimmedSecondaryEmail.isEmpty ? "" : trimmedSecondaryEmail

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
                        Text("contacts_primary_badge")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.brandOrange)
                            .cornerRadius(4)
                    }

                    if isVisible {
                        Text("contacts_visible_on_tag")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("contacts_hidden_badge")
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
            Image(systemName: type.contains(NSLocalizedString("email", comment: "").lowercased()) ? "envelope" : "phone")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text(String(format: NSLocalizedString("contacts_no_type_added", comment: ""), type))
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
