import SwiftUI

struct PersonalInformationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isLoading = false

    // Personal details fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""

    // Address fields
    @State private var streetAddress = ""
    @State private var addressLine2 = ""
    @State private var city = ""
    @State private var postalCode = ""
    @State private var country = ""
    @State private var showCountryPicker = false

    private var countries: [String] {
        SupportedCountries.sorted(priority: Locale.current.region?.identifier)
            .map { $0.localizedName }
    }

    var body: some View {
        List {
            if isEditing {
                // Edit Mode — Personal Details
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
                            .disabled(true)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("personal_phone")
                            .frame(width: 100, alignment: .leading)
                        TextField(NSLocalizedString("personal_phone_placeholder", comment: ""), text: $phone)
                            .keyboardType(.phonePad)
                    }
                }

                // Edit Mode — Address
                Section(header: Text("profile_address"), footer: Text("address_shipping_footer")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("address_street")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField(NSLocalizedString("address_street_placeholder", comment: ""), text: $streetAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("address_line2")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField(NSLocalizedString("address_line2_placeholder", comment: ""), text: $addressLine2)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("address_city")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField(NSLocalizedString("address_city_placeholder", comment: ""), text: $city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("address_postal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField(NSLocalizedString("address_postal_placeholder", comment: ""), text: $postalCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("address_country")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button(action: { showCountryPicker = true }) {
                            HStack {
                                Text(country.isEmpty ? NSLocalizedString("address_select_country", comment: "") : country)
                                    .foregroundColor(country.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
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
                // View Mode — Personal Details
                Section(header: Text("personal_details")) {
                    InfoRow(label: NSLocalizedString("personal_first_name", comment: ""), value: firstName.isEmpty ? NSLocalizedString("not_set", comment: "") : firstName)
                    InfoRow(label: NSLocalizedString("personal_last_name", comment: ""), value: lastName.isEmpty ? NSLocalizedString("not_set", comment: "") : lastName)
                    InfoRow(label: NSLocalizedString("personal_email", comment: ""), value: email)
                    InfoRow(label: NSLocalizedString("personal_phone", comment: ""), value: phone.isEmpty ? NSLocalizedString("not_set", comment: "") : phone)
                }

                // View Mode — Address
                Section(header: Text("profile_address")) {
                    if !streetAddress.isEmpty || !city.isEmpty {
                        if !streetAddress.isEmpty {
                            AddressFieldView(label: NSLocalizedString("address_street", comment: ""), value: streetAddress)
                        }
                        if !addressLine2.isEmpty {
                            AddressFieldView(label: NSLocalizedString("address_line2_label", comment: ""), value: addressLine2)
                        }
                        if !city.isEmpty {
                            AddressFieldView(label: NSLocalizedString("address_city", comment: ""), value: city)
                        }
                        if !postalCode.isEmpty {
                            AddressFieldView(label: NSLocalizedString("address_postal_label", comment: ""), value: postalCode)
                        }
                        if !country.isEmpty {
                            AddressFieldView(label: NSLocalizedString("address_country", comment: ""), value: country)
                        }
                    } else {
                        HStack {
                            Image(systemName: "house.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            Text("address_no_address")
                                .foregroundColor(.secondary)
                        }
                    }
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
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $country, countries: countries)
        }
    }

    private var hasChanges: Bool {
        guard let user = authViewModel.currentUser else { return false }
        return firstName != (user.firstName ?? "") ||
               lastName != (user.lastName ?? "") ||
               phone != (user.phone ?? "") ||
               streetAddress != (user.address ?? "") ||
               addressLine2 != (user.addressLine2 ?? "") ||
               city != (user.city ?? "") ||
               postalCode != (user.postalCode ?? "") ||
               country != (user.country ?? "")
    }

    private func loadUserData() {
        guard let user = authViewModel.currentUser else { return }
        firstName = user.firstName ?? ""
        lastName = user.lastName ?? ""
        email = user.email
        phone = user.phone ?? ""
        streetAddress = user.address ?? ""
        addressLine2 = user.addressLine2 ?? ""
        city = user.city ?? ""
        postalCode = user.postalCode ?? ""
        country = user.country ?? ""
    }

    private func startEditing() {
        isEditing = true
    }

    private func cancelEditing() {
        loadUserData()
        isEditing = false
    }

    private func saveChanges() {
        Task {
            isLoading = true

            do {
                let updates: [String: Any] = [
                    "first_name": firstName,
                    "last_name": lastName,
                    "phone": phone,
                    "address": streetAddress.trimmingCharacters(in: .whitespaces),
                    "address_line_2": addressLine2.trimmingCharacters(in: .whitespaces),
                    "city": city.trimmingCharacters(in: .whitespaces),
                    "postal_code": postalCode.trimmingCharacters(in: .whitespaces),
                    "country": country.trimmingCharacters(in: .whitespaces)
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
