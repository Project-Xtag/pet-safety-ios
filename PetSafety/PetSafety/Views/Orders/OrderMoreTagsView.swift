import SwiftUI

struct OrderMoreTagsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoading = false
    @State private var orderComplete = false
    @State private var checkoutURL: URL?
    @State private var showCheckoutSheet = false

    // Pet names
    @State private var petNames: [String] = [""]

    // Owner information
    @State private var ownerName = ""
    @State private var email = ""
    @State private var phone = ""

    // Shipping address
    @State private var street1 = ""
    @State private var street2 = ""
    @State private var city = ""
    @State private var province = ""
    @State private var postCode = ""
    @State private var country = ""

    // Pricing - tags are free, only shipping cost
    private let shippingCost: Double = 3.90

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
        .navigationTitle(Text("order_more_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(String(localized: "cancel")) {
                    dismiss()
                }
                .foregroundColor(.brandOrange)
            }
        }
        .task {
            await loadUserInfo()
        }
        .sheet(isPresented: $showCheckoutSheet) {
            if let url = checkoutURL {
                SafariCheckoutView(url: url) { _ in
                    showCheckoutSheet = false
                    checkoutURL = nil
                    orderComplete = true
                }
            }
        }
    }

    private var orderCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.tealAccent)

            Text("order_more_complete")
                .font(.system(size: 32, weight: .bold))

            Text("order_more_confirmation")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("done")
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
            Section(header: Text("order_more_pet_names"), footer: Text("order_more_pet_names_footer")) {
                ForEach(petNames.indices, id: \.self) { index in
                    HStack {
                        TextField(String(localized: "order_more_pet_name_placeholder"), text: $petNames[index])

                        if petNames.count > 1 {
                            Button(action: { removePetName(at: index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }

                Button(action: addPetName) {
                    Label(String(localized: "order_more_add_another"), systemImage: "plus.circle")
                }
            }

            Section(header: Text("order_more_your_info")) {
                TextField(String(localized: "order_more_full_name"), text: $ownerName)
                TextField(String(localized: "order_more_email"), text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                TextField(String(localized: "order_more_phone"), text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            }

            Section(header: Text("order_more_shipping")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("order_more_street")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_more_street_placeholder"), text: $street1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_more_line2")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_more_line2_placeholder"), text: $street2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_more_city")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_more_city"), text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_more_province")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_more_province"), text: $province)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_more_postal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_more_postal"), text: $postCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_more_country")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_more_country"), text: $country)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)
            }

            Section(header: Text("order_more_summary")) {
                HStack {
                    Text("order_more_tags_count \(validPetCount)")
                    Spacer()
                    Text(String(localized: "free_price"))
                        .foregroundColor(.tealAccent)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("order_more_shipping_cost")
                    Spacer()
                    Text(String(format: "€%.2f", shippingCost))
                }

                HStack {
                    Text("order_more_total")
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
                            Text("order_more_redirecting")
                                .foregroundColor(.white)
                        } else {
                            Text("order_more_proceed_to_payment")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.tealAccent)
                .disabled(isLoading || !isFormValid)
            }
        }
        .adaptiveList()
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
            #if DEBUG
            print("⚠️ No user data available - user can fill form manually")
            #endif
            return
        }

        // Pre-fill user information
        await MainActor.run {
            email = user.email
            if let userPhone = user.phone {
                phone = userPhone
            }

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
                let quantity = validPetCount
                let userCountry = authViewModel.currentUser?.country

                let checkout = try await APIService.shared.createTagCheckout(
                    quantity: quantity,
                    countryCode: userCountry
                )

                if let url = URL(string: checkout.url) {
                    checkoutURL = url
                    showCheckoutSheet = true
                } else {
                    appState.showError("Invalid checkout URL")
                }
            } catch {
                appState.showError(error.localizedDescription)
            }

            isLoading = false
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
