import SwiftUI

struct OrderMoreTagsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false

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
    @State private var country = "ES"

    // Pricing
    private let pricePerTag: Double = 14.99
    private let shippingCost: Double = 3.99

    var totalCost: Double {
        let tagCount = petNames.filter { !$0.isEmpty }.count
        return Double(tagCount) * pricePerTag + shippingCost
    }

    var body: some View {
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
                TextField("Street Address Line 1", text: $street1)
                TextField("Street Address Line 2 (optional)", text: $street2)

                HStack {
                    TextField("City", text: $city)
                    TextField("Province/State", text: $province)
                }

                HStack {
                    TextField("Post Code", text: $postCode)
                    TextField("Country", text: $country)
                        .disabled(true)
                }
            }

            Section(header: Text("Order Summary")) {
                HStack {
                    Text("Tags (\(validPetCount))")
                    Spacer()
                    Text(String(format: "€%.2f", Double(validPetCount) * pricePerTag))
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
                Button(action: { proceedToPayment() }) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Processing...")
                                .foregroundColor(.white)
                        } else {
                            Text("Proceed to Payment")
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
        .navigationTitle("Order More Tags")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadUserInfo()
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
        !postCode.isEmpty
    }

    private func addPetName() {
        petNames.append("")
    }

    private func removePetName(at index: Int) {
        petNames.remove(at: index)
    }

    private func loadUserInfo() async {
        do {
            let user = try await APIService.shared.getCurrentUser()

            // Pre-fill user information
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
        } catch {
            print("Failed to load user profile: \(error)")
        }
    }

    private func proceedToPayment() {
        // Note: This is a simplified version. In a production app, you would:
        // 1. Create the order on the backend
        // 2. Get a payment intent
        // 3. Show Stripe payment sheet
        // 4. Confirm payment
        // 5. Show success

        appState.showError("Payment integration is not yet implemented. This feature will allow you to order tags through Stripe payment.")
    }
}

#Preview {
    NavigationView {
        OrderMoreTagsView()
            .environmentObject(AppState())
    }
}
