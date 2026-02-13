import SwiftUI

struct OrderReplacementTagView: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoading = false
    @State private var isCheckingEligibility = true
    @State private var orderComplete = false

    // Replacement eligibility
    @State private var isFreeReplacement = false
    @State private var shippingCost: Double = 3.90
    @State private var planName: String = "starter"

    // Shipping address fields
    @State private var street1 = ""
    @State private var street2 = ""
    @State private var city = ""
    @State private var province = ""
    @State private var postCode = ""
    @State private var country = ""
    @State private var phone = ""

    var body: some View {
        Group {
            if orderComplete {
                orderCompleteView
            } else {
                orderFormView
            }
        }
        .navigationTitle(Text("order_replace_title"))
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
            await checkEligibility()
            await loadUserAddress()
        }
    }

    private func checkEligibility() async {
        do {
            let eligibility = try await APIService.shared.checkReplacementEligibility()
            await MainActor.run {
                isFreeReplacement = eligibility.isFreeReplacement
                shippingCost = eligibility.shippingCost
                planName = eligibility.planName
                isCheckingEligibility = false
            }
        } catch {
            // Default to paid replacement if check fails
            await MainActor.run {
                isFreeReplacement = false
                shippingCost = 3.90
                isCheckingEligibility = false
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

            Text("order_replace_complete")
                .font(.system(size: 32, weight: .bold))

            Text("order_replace_confirmation")
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
            Section(header: Text("order_replace_pet_info")) {
                HStack {
                    if let imageUrl = pet.profileImage {
                        CachedAsyncImage(url: URL(string: imageUrl)) { image in
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

            Section(header: Text("order_replace_important")) {
                VStack(alignment: .leading, spacing: 8) {
                    if isFreeReplacement {
                        Label(String(localized: "order_replace_eligible_free"), systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.tealAccent)
                    } else {
                        Label(String(format: String(localized: "order_replace_additional_fee %@"), String(format: "€%.2f", shippingCost)), systemImage: "eurosign.circle")
                            .font(.caption)
                            .foregroundColor(.brandOrange)
                        Label(String(localized: "order_replace_upgrade_hint"), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Label(String(localized: "order_replace_old_deactivated"), systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label(String(localized: "order_replace_delivery_time"), systemImage: "shippingbox")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label(String(localized: "order_replace_scan_activate"), systemImage: "qrcode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("order_replace_shipping"), footer: Text("order_replace_shipping_footer")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("order_replace_street")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_replace_street_placeholder"), text: $street1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_replace_line2")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_replace_line2_placeholder"), text: $street2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_replace_city")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_replace_city"), text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_replace_province")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_replace_province"), text: $province)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_replace_postal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_replace_postal"), text: $postCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_replace_country")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_replace_country"), text: $country)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("order_replace_phone")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "order_replace_phone_placeholder"), text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
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
                            Text("order_replace_creating")
                                .foregroundColor(.white)
                        } else {
                            if isFreeReplacement {
                                Text("order_replace_free_button")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            } else {
                                Text(String(format: String(localized: "order_replace_paid_button %@"), String(format: "€%.2f", shippingCost)))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.blue)
                .disabled(isLoading || !isFormValid || isCheckingEligibility)
            }
        }
        .adaptiveList()
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
            #if DEBUG
            print("⚠️ No user data available - user can fill form manually")
            #endif
            return
        }

        // Pre-fill address fields from user profile
        await MainActor.run {
            if let address = user.address {
                street1 = address
            }
            if let userPhone = user.phone {
                phone = userPhone
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
                    country: country,
                    phone: phone.isEmpty ? nil : phone
                )

                let response = try await APIService.shared.createReplacementOrder(
                    petId: pet.id,
                    shippingAddress: shippingAddress
                )

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
