import SwiftUI

struct OrderReplacementTagView: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoading = false
    @State private var orderComplete = false

    // Shipping address fields
    @State private var street1 = ""
    @State private var street2 = ""
    @State private var city = ""
    @State private var province = ""
    @State private var postCode = ""
    @State private var country = ""

    var body: some View {
        Group {
            if orderComplete {
                orderCompleteView
            } else {
                orderFormView
            }
        }
        .navigationTitle("Order Replacement Tag")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
        .task {
            await loadUserAddress()
        }
    }

    private var orderCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)

            Text("Order Complete!")
                .font(.system(size: 32, weight: .bold))

            Text("Your replacement tag for \(pet.name) has been ordered. The old QR code has been deactivated. You'll receive a confirmation email shortly.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    private var orderFormView: some View {
        Form {
            Section(header: Text("Pet Information")) {
                HStack {
                    if let imageUrl = pet.profileImage {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    }

                    VStack(alignment: .leading) {
                        Text(pet.name)
                            .font(.headline)
                        Text(pet.species)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Important Information")) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("As a Premium member, replacement tags are completely free", systemImage: "checkmark.circle")
                        .font(.caption)
                    Label("Your old QR code will be deactivated when you place this order", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                    Label("You'll receive your new tag within 5-7 business days", systemImage: "shippingbox")
                        .font(.caption)
                    Label("Once you receive the new tag, you'll need to scan it to activate it", systemImage: "qrcode")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Section(header: Text("Shipping Address"), footer: Text("Confirm your shipping address for the replacement tag")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Street Address")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("e.g., 123 Main Street, Apartment 4B", text: $street1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Street Address Line 2 (Optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("e.g., Building, Floor, Suite", text: $street2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("City")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("e.g., London", text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Province / State (Optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("e.g., Greater London", text: $province)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Postal Code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("e.g., SW1A 1AA", text: $postCode)
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
                Button(action: { submitOrder() }) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Creating Order...")
                                .foregroundColor(.white)
                        } else {
                            Text("Confirm & Order Replacement Tag")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.blue)
                .disabled(isLoading || !isFormValid)
            }
        }
        .overlay {
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }

    private var isFormValid: Bool {
        !street1.isEmpty && !city.isEmpty && !postCode.isEmpty && !country.isEmpty
    }

    private func loadUserAddress() async {
        // Use cached user data from AuthViewModel instead of making API call
        guard let user = authViewModel.currentUser else {
            print("⚠️ No user data available - user can fill form manually")
            return
        }

        // Pre-fill address fields from user profile
        await MainActor.run {
            if let address = user.address {
                street1 = address
            }
            if let userCity = user.city {
                city = userCity
            }
            if let postal = user.postalCode {
                postCode = postal
            }
            if let userCountry = user.country {
                country = userCountry
            }
        }
    }

    private func submitOrder() {
        Task {
            isLoading = true

            do {
                let shippingAddress = ShippingAddress(
                    street1: street1,
                    street2: street2.isEmpty ? nil : street2,
                    city: city,
                    province: province.isEmpty ? nil : province,
                    postCode: postCode,
                    country: country
                )

                let response = try await APIService.shared.createReplacementOrder(
                    petId: pet.id,
                    shippingAddress: shippingAddress
                )

                isLoading = false

                if response.success {
                    orderComplete = true
                } else {
                    appState.showError(response.message ?? "Failed to create replacement order")
                }
            } catch {
                isLoading = false
                appState.showError(error.localizedDescription)
            }
        }
    }
}

#Preview {
    NavigationView {
        OrderReplacementTagView(pet: Pet(
            id: "1",
            ownerId: "1",
            name: "Max",
            species: "Dog",
            breed: "Golden Retriever",
            color: "Golden",
            weight: 30.0,
            microchipNumber: "123456789",
            medicalNotes: nil,
            notes: nil,
            profileImage: nil,
            isMissing: false,
            createdAt: "",
            updatedAt: ""
        ))
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
    }
}
