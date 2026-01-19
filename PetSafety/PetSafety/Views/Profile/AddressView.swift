import SwiftUI

struct AddressView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isLoading = false

    // Comprehensive form fields
    @State private var streetAddress = ""      // Main street address
    @State private var city = ""
    @State private var postalCode = ""
    @State private var country = ""

    var body: some View {
        List {
            if isEditing {
                // Edit Mode
                Section(header: Text("Address Details"), footer: Text("Enter your complete address for shipping and billing purposes")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Street Address")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("e.g., 123 Main Street, Apartment 4B", text: $streetAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("City / Town")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("e.g., London", text: $city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Postal Code / ZIP Code")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("e.g., SW1A 1AA", text: $postalCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Country")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("e.g., United Kingdom", text: $country)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)
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
                    .disabled(isLoading || !hasChanges || !isFormValid)

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
                Section(header: Text("Registered Address")) {
                    if !streetAddress.isEmpty || !city.isEmpty || !postalCode.isEmpty || !country.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            if !streetAddress.isEmpty {
                                AddressFieldView(label: "Street Address", value: streetAddress)
                            }

                            if !city.isEmpty {
                                AddressFieldView(label: "City / Town", value: city)
                            }

                            if !postalCode.isEmpty {
                                AddressFieldView(label: "Postal Code", value: postalCode)
                            }

                            if !country.isEmpty {
                                AddressFieldView(label: "Country", value: country)
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "house.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)

                            Text("No address registered")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Add your address to enable shipping and delivery of QR tags")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }

                Section {
                    Button(action: { startEditing() }) {
                        HStack {
                            Spacer()
                            Text(streetAddress.isEmpty && city.isEmpty ? "Add Address" : "Edit Address")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Address")
        .adaptiveList()
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
                    .disabled(isLoading || !hasChanges || !isFormValid)
                }
            }
        }
        .onAppear {
            loadAddressData()
        }
    }

    private var isFormValid: Bool {
        // At least street address and city should be filled
        !streetAddress.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var hasChanges: Bool {
        guard let user = authViewModel.currentUser else { return false }
        return streetAddress != (user.address ?? "") ||
               city != (user.city ?? "") ||
               postalCode != (user.postalCode ?? "") ||
               country != (user.country ?? "")
    }

    private func loadAddressData() {
        guard let user = authViewModel.currentUser else { return }
        streetAddress = user.address ?? ""
        city = user.city ?? ""
        postalCode = user.postalCode ?? ""
        country = user.country ?? ""
    }

    private func startEditing() {
        isEditing = true
    }

    private func cancelEditing() {
        loadAddressData() // Reset to original values
        isEditing = false
    }

    private func saveChanges() {
        Task {
            isLoading = true

            do {
                let updates: [String: Any] = [
                    "address": streetAddress.trimmingCharacters(in: .whitespaces),
                    "city": city.trimmingCharacters(in: .whitespaces),
                    "postal_code": postalCode.trimmingCharacters(in: .whitespaces),
                    "country": country.trimmingCharacters(in: .whitespaces)
                ]

                try await authViewModel.updateProfile(updates: updates)
                appState.showSuccess("Address updated successfully!")

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
struct AddressFieldView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.body)
        }
    }
}

#Preview {
    NavigationView {
        AddressView()
            .environmentObject(AuthViewModel())
            .environmentObject(AppState())
    }
}
