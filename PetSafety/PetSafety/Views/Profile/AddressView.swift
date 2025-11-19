import SwiftUI

struct AddressView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isLoading = false

    // Form fields
    @State private var address = ""
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
                        TextField("123 Main Street", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("City")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("London", text: $city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Postal Code")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("SW1A 1AA", text: $postalCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Country")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("United Kingdom", text: $country)
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
                Section(header: Text("Current Address")) {
                    if !address.isEmpty || !city.isEmpty || !postalCode.isEmpty || !country.isEmpty {
                        if !address.isEmpty {
                            DetailRow(label: "Street Address", value: address)
                        }

                        if !city.isEmpty {
                            DetailRow(label: "City", value: city)
                        }

                        if !postalCode.isEmpty {
                            DetailRow(label: "Postal Code", value: postalCode)
                        }

                        if !country.isEmpty {
                            DetailRow(label: "Country", value: country)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "house.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)

                            Text("No address set")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Add your address to enable shipping and delivery")
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
                            Text(address.isEmpty && city.isEmpty ? "Add Address" : "Edit Address")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Address")
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
            loadAddressData()
        }
    }

    private var hasChanges: Bool {
        guard let user = authViewModel.currentUser else { return false }
        return address != (user.address ?? "") ||
               city != (user.city ?? "") ||
               postalCode != (user.postalCode ?? "") ||
               country != (user.country ?? "")
    }

    private func loadAddressData() {
        guard let user = authViewModel.currentUser else { return }
        address = user.address ?? ""
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
                    "address": address,
                    "city": city,
                    "postal_code": postalCode,
                    "country": country
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
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationView {
        AddressView()
            .environmentObject(AuthViewModel())
            .environmentObject(AppState())
    }
}
