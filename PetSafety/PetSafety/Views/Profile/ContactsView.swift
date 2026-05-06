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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Info banner
                VStack(alignment: .leading, spacing: 8) {
                    Label("contacts_settings", systemImage: "info.circle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandOrange)

                    Text("contacts_info_full")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.tealAccent.opacity(0.1))
                .cornerRadius(14)

                if isEditing {
                    editingView
                } else {
                    displayView
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("contacts_email_section")
                .font(.system(size: 17, weight: .semibold))

            VStack(spacing: 0) {
                if !primaryEmail.isEmpty || !secondaryEmail.isEmpty {
                    if !primaryEmail.isEmpty {
                        ContactRowView(
                            type: "Email",
                            value: primaryEmail,
                            isPrimary: primaryEmailContact == 1,
                            isVisible: showPrimaryEmail
                        )
                    }
                    if !primaryEmail.isEmpty && !secondaryEmail.isEmpty {
                        Divider()
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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }

        // Phone Section
        VStack(alignment: .leading, spacing: 12) {
            Text("contacts_phone_section")
                .font(.system(size: 17, weight: .semibold))

            VStack(spacing: 0) {
                if !primaryPhone.isEmpty || !secondaryPhone.isEmpty {
                    if !primaryPhone.isEmpty {
                        ContactRowView(
                            type: "Phone",
                            value: primaryPhone,
                            isPrimary: primaryPhoneContact == 1,
                            isVisible: showPrimaryPhone
                        )
                    }
                    if !primaryPhone.isEmpty && !secondaryPhone.isEmpty {
                        Divider()
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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }

        // Edit Button
        Button(action: { isEditing = true }) {
            HStack {
                Spacer()
                Text("contacts_edit_title")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Color.brandOrange)
            .cornerRadius(16)
        }
    }

    // MARK: - Editing View
    @ViewBuilder
    private var editingView: some View {
        editingFieldCard(
            header: "contacts_primary_email",
            footer: "contacts_primary_email_edit_footer",
            placeholderKey: "contacts_email_placeholder",
            text: $primaryEmail,
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            visibilityBinding: $showPrimaryEmail,
            showVisibilityToggle: true
        )
        editingFieldCard(
            header: "contacts_secondary_email",
            footer: "contacts_secondary_email_edit_footer",
            placeholderKey: "contacts_secondary_email_placeholder",
            text: $secondaryEmail,
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            visibilityBinding: $showSecondaryEmail,
            showVisibilityToggle: !secondaryEmail.isEmpty
        )
        editingFieldCard(
            header: "contacts_primary_phone",
            footer: "contacts_primary_phone_edit_footer",
            placeholderKey: "contacts_phone_placeholder",
            text: $primaryPhone,
            keyboardType: .phonePad,
            textContentType: .telephoneNumber,
            visibilityBinding: $showPrimaryPhone,
            showVisibilityToggle: true
        )
        editingFieldCard(
            header: "contacts_secondary_phone",
            footer: "contacts_secondary_phone_edit_footer",
            placeholderKey: "contacts_secondary_phone_placeholder",
            text: $secondaryPhone,
            keyboardType: .phonePad,
            textContentType: .telephoneNumber,
            visibilityBinding: $showSecondaryPhone,
            showVisibilityToggle: !secondaryPhone.isEmpty
        )

        // Save/Cancel buttons
        VStack(spacing: 12) {
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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(Color.brandOrange.opacity(isLoading || !isFormValid ? 0.5 : 1.0))
                .cornerRadius(16)
            }
            .disabled(isLoading || !isFormValid)

            Button(action: { cancelEditing() }) {
                HStack {
                    Spacer()
                    Text("cancel")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 14)
            }
            .disabled(isLoading)
        }
    }

    @ViewBuilder
    private func editingFieldCard(
        header: LocalizedStringKey,
        footer: LocalizedStringKey,
        placeholderKey: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType,
        textContentType: UITextContentType?,
        visibilityBinding: Binding<Bool>,
        showVisibilityToggle: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 12) {
                TextField(NSLocalizedString(placeholderKey, comment: ""), text: text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if showVisibilityToggle {
                    Toggle("contacts_show_on_tag", isOn: visibilityBinding)
                        .tint(.brandOrange)
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)

            Text(footer)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Computed Properties
    private var isFormValid: Bool {
        // At least one valid email must be provided
        return InputValidators.isValidEmail(primaryEmail)
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
        // Secondary contacts use independent visibility settings
        showSecondaryEmail = user.showSecondaryEmailPublicly ?? false
        showSecondaryPhone = user.showSecondaryPhonePublicly ?? false
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
                updates["show_secondary_phone_publicly"] = showSecondaryPhone
                updates["show_secondary_email_publicly"] = showSecondaryEmail

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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: type == "Email" ? "envelope.fill" : "phone.fill")
                .foregroundColor(.tealAccent)
                .frame(width: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

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
                    Text(isVisible ? "contacts_visible_on_tag" : "contacts_hidden_badge")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.vertical, 8)
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
