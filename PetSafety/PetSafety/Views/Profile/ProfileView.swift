import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false

    var body: some View {
        List {
            if let user = authViewModel.currentUser {
                // Profile Header
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color("BrandColor"))

                        VStack(spacing: 4) {
                            if !user.fullName.isEmpty {
                                Text(user.fullName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }

                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // Personal Information
                Section("Personal Information") {
                    if let firstName = user.firstName {
                        InfoRow(label: "First Name", value: firstName)
                    }

                    if let lastName = user.lastName {
                        InfoRow(label: "Last Name", value: lastName)
                    }

                    InfoRow(label: "Email", value: user.email)

                    if let phone = user.phone {
                        InfoRow(label: "Phone", value: phone)
                    }
                }

                // Address
                if user.address != nil || user.city != nil || user.country != nil {
                    Section("Address") {
                        if let address = user.address {
                            InfoRow(label: "Street", value: address)
                        }

                        if let city = user.city {
                            InfoRow(label: "City", value: city)
                        }

                        if let postalCode = user.postalCode {
                            InfoRow(label: "Postal Code", value: postalCode)
                        }

                        if let country = user.country {
                            InfoRow(label: "Country", value: country)
                        }
                    }
                }

                // Service Provider Info
                if user.isServiceProvider == true {
                    Section("Service Provider") {
                        if let type = user.serviceProviderType {
                            InfoRow(label: "Type", value: type.capitalized)
                        }

                        if let organization = user.organizationName {
                            InfoRow(label: "Organization", value: organization)
                        }

                        if let license = user.vetLicenseNumber {
                            InfoRow(label: "License Number", value: license)
                        }

                        HStack {
                            Text("Verified")
                            Spacer()
                            Image(systemName: (user.isVerified == true) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor((user.isVerified == true) ? .green : .red)
                        }
                    }
                }

                // Actions
                Section {
                    Button(action: { showingEditProfile = true }) {
                        Label("Edit Profile", systemImage: "pencil")
                    }

                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }

                    NavigationLink(destination: HelpView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive, action: { showingLogoutAlert = true }) {
                        Label("Logout", systemImage: "arrow.right.square")
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingEditProfile) {
            NavigationView {
                EditProfileView()
            }
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var postalCode = ""
    @State private var country = ""

    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
            }

            Section("Address") {
                TextField("Street Address", text: $address)
                TextField("City", text: $city)
                TextField("Postal Code", text: $postalCode)
                TextField("Country", text: $country)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(authViewModel.isLoading)
            }
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                firstName = user.firstName ?? ""
                lastName = user.lastName ?? ""
                phone = user.phone ?? ""
                address = user.address ?? ""
                city = user.city ?? ""
                postalCode = user.postalCode ?? ""
                country = user.country ?? ""
            }
        }
    }

    private func saveProfile() {
        Task {
            do {
                let updates: [String: Any] = [
                    "first_name": firstName,
                    "last_name": lastName,
                    "phone": phone,
                    "address": address,
                    "city": city,
                    "postal_code": postalCode,
                    "country": country
                ]

                try await authViewModel.updateProfile(updates: updates)
                appState.showSuccess("Profile updated successfully!")
                dismiss()
            } catch {
                appState.showError(error.localizedDescription)
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("locationEnabled") private var locationEnabled = true

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Push Notifications", isOn: $notificationsEnabled)
                Toggle("Location Services", isOn: $locationEnabled)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                Link("Privacy Policy", destination: URL(string: "https://petsafety.eu/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://petsafety.eu/terms")!)
            }
        }
        .navigationTitle("Settings")
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section("Contact") {
                Link("Email Support", destination: URL(string: "mailto:support@petsafety.eu")!)
                Link("FAQ", destination: URL(string: "https://petsafety.eu/faq")!)
            }

            Section("Resources") {
                NavigationLink("How to Use QR Tags") {
                    Text("Instructions coming soon")
                }

                NavigationLink("Report Missing Pet") {
                    Text("Instructions coming soon")
                }

                NavigationLink("Finding Lost Pets") {
                    Text("Instructions coming soon")
                }
            }
        }
        .navigationTitle("Help & Support")
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthViewModel())
            .environmentObject(AppState())
    }
}
