import SwiftUI

struct OrderMoreTagsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoading = false
    @State private var orderComplete = false
    @State private var paymentPending = false
    @State private var paymentIntentId: String?

    // Pet names
    @State private var petNames: [String] = [""]

    // Owner information
    @State private var ownerName = ""
    @State private var email = ""

    // Shipping address
    @State private var street1 = ""
    @State private var street2 = ""
    @State private var city = ""
    @State private var province = ""
    @State private var postCode = ""
    @State private var country = ""

    // Pricing - tags are free, only shipping cost
    private let shippingCost: Double = 3.99

    var totalCost: Double {
        return shippingCost
    }

    var body: some View {
        Group {
            if orderComplete {
                orderCompleteView
            } else {
                orderFormView
            }
        }
        .navigationTitle("Order More Tags")
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
            await loadUserInfo()
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

            if paymentPending {
                Text("Your order is placed and payment is pending. We'll guide you through payment soon.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("Your tags have been ordered! You'll receive a confirmation email shortly with tracking information.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

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
            Section(header: Text("Pet Names"), footer: Text("Enter the names of pets you want tags for")) {
                ForEach(petNames.indices, id: \.self) { index in
                    HStack {
                        TextField("Pet name", text: $petNames[index])

                        if petNames.count > 1 {
                            Button(action: { removePetName(at: index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Button(action: addPetName) {
                    Label("Add Another Pet", systemImage: "plus.circle")
                }
            }

            Section(header: Text("Your Information")) {
                TextField("Full Name", text: $ownerName)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            }

            Section(header: Text("Shipping Address")) {
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

            Section(header: Text("Order Summary")) {
                HStack {
                    Text("Tags (\(validPetCount))")
                    Spacer()
                    Text("FREE")
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Shipping")
                    Spacer()
                    Text(String(format: "€%.2f", shippingCost))
                }

                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text(String(format: "€%.2f", totalCost))
                        .fontWeight(.bold)
                }
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
                            Text("Place Order")
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
    }

    private var validPetCount: Int {
        petNames.filter { !$0.isEmpty }.count
    }

    private var isFormValid: Bool {
        validPetCount > 0 &&
        !ownerName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        !street1.isEmpty &&
        !city.isEmpty &&
        !postCode.isEmpty &&
        !country.isEmpty
    }

    private func addPetName() {
        petNames.append("")
    }

    private func removePetName(at index: Int) {
        petNames.remove(at: index)
    }

    private func loadUserInfo() async {
        // Use cached user data from AuthViewModel instead of making API call
        guard let user = authViewModel.currentUser else {
            print("⚠️ No user data available - user can fill form manually")
            return
        }

        // Pre-fill user information
        await MainActor.run {
            email = user.email

            if let firstName = user.firstName, let lastName = user.lastName {
                ownerName = "\(firstName) \(lastName)"
            } else if let firstName = user.firstName {
                ownerName = firstName
            }

            // Pre-fill address
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
                // Filter out empty pet names
                let validPetNames = petNames.filter { !$0.isEmpty }

                let shippingAddress = ShippingAddressDetails(
                    street1: street1,
                    street2: street2.isEmpty ? nil : street2,
                    city: city,
                    province: province.isEmpty ? nil : province,
                    postCode: postCode,
                    country: country
                )

                let orderRequest = CreateTagOrderRequest(
                    petNames: validPetNames,
                    ownerName: ownerName,
                    email: email,
                    shippingAddress: shippingAddress,
                    billingAddress: nil,
                    paymentMethod: "free",
                    shippingCost: shippingCost
                )

                let response = try await APIService.shared.createTagOrder(orderRequest)

                // Kick off payment intent creation for shipping
                let paymentResponse = try await APIService.shared.createPaymentIntent(
                    orderId: response.order.id,
                    amount: response.order.totalAmount,
                    email: email,
                    paymentMethod: "card",
                    currency: "gbp",
                    requiresAuth: authViewModel.isAuthenticated
                )

                paymentIntentId = paymentResponse.paymentIntent.id
                paymentPending = true

                isLoading = false

                orderComplete = true
            } catch {
                isLoading = false
                appState.showError(error.localizedDescription)
            }
        }
    }
}

#Preview {
    NavigationView {
        OrderMoreTagsView()
            .environmentObject(AppState())
            .environmentObject(AuthViewModel())
    }
}
