import SwiftUI

struct OrderReplacementTagView: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoading = false
    @State private var isCheckingEligibility = true
    @State private var orderComplete = false
    @State private var showCheckoutSheet = false
    @State private var checkoutURL: URL?

    // Replacement eligibility
    @State private var isFreeReplacement = false
    @State private var shippingCost: Double = 0.0
    @State private var planName: String = "starter"

    // Shipping address fields
    @State private var street1 = ""
    @State private var street2 = ""
    @State private var city = ""
    @State private var postCode = ""
    @State private var selectedCountryCode: String = {
        if let region = Locale.current.region?.identifier,
           SupportedCountries.findByCode(region) != nil {
            return region
        }
        return ""
    }()
    @State private var phone = ""

    // Delivery method (Hungary only)
    @State private var deliveryMethod = "home_delivery"
    @State private var selectedPostaPoint: PostaPointDetails?

    // Shipping prices (fetched from API)
    @State private var shippingPrices: ShippingPricesResponse?
    @State private var isLoadingPrices = true

    private var isHungary: Bool {
        selectedCountryCode.uppercased() == "HU"
    }

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
        .sheet(isPresented: $showCheckoutSheet) {
            if let url = checkoutURL {
                SafariCheckoutView(url: url) { _ in
                    showCheckoutSheet = false
                    checkoutURL = nil
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .replacementCompleted)) { _ in
            orderComplete = true
        }
        .task {
            await checkEligibility()
            await loadUserAddress()
            await loadShippingPrices()
        }
    }

    // MARK: - Order Complete

    private var orderCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.tealAccent.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.tealAccent)
            }

            Text("order_replace_complete")
                .font(.system(size: 28, weight: .bold))

            Text("order_replace_confirmation")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: { dismiss() }) {
                Text("done")
            }
            .buttonStyle(BrandButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Order Form

    private var orderFormView: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    VStack(spacing: 16) {
                        // Pet Info
                        petInfoCard

                        // Eligibility Info
                        eligibilityCard

                        // Shipping Address
                        shippingAddressCard

                        // Delivery Method (Hungary only)
                        if isHungary {
                            deliveryMethodCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }

            // Floating CTA Button
            VStack(spacing: 0) {
                Divider()
                Button(action: { submitOrder() }) {
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("order_replace_creating")
                        }
                    } else if isFreeReplacement {
                        Text("order_replace_free_button")
                    } else {
                        Text(String(format: String(localized: "order_replace_paid_button %@"), formattedShippingCost))
                    }
                }
                .buttonStyle(BrandButtonStyle(isDisabled: !isFormValid || isCheckingEligibility))
                .disabled(isLoading || !isFormValid || isCheckingEligibility)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandOrange.opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 28))
                    .foregroundColor(.brandOrange)
            }

            Text("order_replace_title")
                .font(.system(size: 24, weight: .bold))

            Text("order_replace_subtitle")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(Color.peachBackground)
    }

    // MARK: - Section Cards

    private var petInfoCard: some View {
        ReplacementSectionCard(title: String(localized: "order_replace_pet_info"), icon: "pawprint.fill") {
            HStack(spacing: 14) {
                if let imageUrl = pet.profileImage {
                    CachedAsyncImage(url: URL(string: imageUrl)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemGray6))
                            .frame(width: 56, height: 56)
                        Image(systemName: pet.species.lowercased() == "dog" ? "dog.fill" : "cat.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.mutedText)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.system(size: 17, weight: .semibold))
                    Text(pet.species.capitalized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    if let breed = pet.breed, !breed.isEmpty {
                        Text(breed)
                            .font(.system(size: 13))
                            .foregroundColor(.mutedText)
                    }
                }

                Spacer()
            }
        }
    }

    private var eligibilityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isCheckingEligibility {
                HStack {
                    ProgressView()
                    Text("order_replace_checking")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
            } else {
                if isFreeReplacement {
                    Label(String(localized: "order_replace_eligible_free"), systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.tealAccent)
                } else {
                    Label(String(format: String(localized: "order_replace_additional_fee %@"), formattedShippingCost), systemImage: "eurosign.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.brandOrange)
                    Label(String(localized: "order_replace_upgrade_hint"), systemImage: "star.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Label(String(localized: "order_replace_old_deactivated"), systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Label(String(localized: "order_replace_delivery_time"), systemImage: "shippingbox.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Label(String(localized: "order_replace_scan_activate"), systemImage: "qrcode")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isFreeReplacement && !isCheckingEligibility
                ? Color.tealAccent.opacity(0.08)
                : Color.brandOrange.opacity(0.08)
        )
        .cornerRadius(14)
    }

    private var shippingAddressCard: some View {
        ReplacementSectionCard(title: String(localized: "order_replace_shipping"), icon: "house.fill") {
            TextField(String(localized: "order_replace_street"), text: $street1)
                .textFieldStyle(BrandTextFieldStyle())
                .textContentType(.streetAddressLine1)

            TextField(String(localized: "order_replace_line2"), text: $street2)
                .textFieldStyle(BrandTextFieldStyle())
                .textContentType(.streetAddressLine2)

            HStack(spacing: 12) {
                TextField(String(localized: "order_replace_city"), text: $city)
                    .textFieldStyle(BrandTextFieldStyle())
                    .textContentType(.addressCity)

                TextField(String(localized: "order_replace_postal"), text: $postCode)
                    .textFieldStyle(BrandTextFieldStyle())
                    .textContentType(.postalCode)
                    .autocapitalization(.allCharacters)
            }

            CountryPickerField(selectedCode: $selectedCountryCode)

            TextField(String(localized: "order_replace_phone"), text: $phone)
                .textFieldStyle(BrandTextFieldStyle(icon: "phone"))
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
        }
    }

    private var deliveryMethodCard: some View {
        ReplacementSectionCard(title: String(localized: "delivery_method_title"), icon: "truck.box.fill") {
            HStack(spacing: 10) {
                DeliveryOptionCard(
                    title: String(localized: "home_delivery_option"),
                    price: shippingPriceLabel(for: "home_delivery"),
                    isSelected: deliveryMethod == "home_delivery"
                ) {
                    deliveryMethod = "home_delivery"
                    selectedPostaPoint = nil
                }

                DeliveryOptionCard(
                    title: String(localized: "postapoint_delivery_option"),
                    price: shippingPriceLabel(for: "postapoint"),
                    isSelected: deliveryMethod == "postapoint"
                ) {
                    deliveryMethod = "postapoint"
                }
            }

            if deliveryMethod == "postapoint" {
                PostaPointPickerView(
                    selected: selectedPostaPoint,
                    onSelect: { point in
                        selectedPostaPoint = point
                    }
                )
            }
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        !street1.isEmpty && !city.isEmpty && !postCode.isEmpty && !selectedCountryCode.isEmpty &&
        (deliveryMethod != "postapoint" || selectedPostaPoint != nil)
    }

    private var formattedShippingCost: String {
        if isHungary, let hu = shippingPrices?.HU {
            if let info = hu.home_delivery {
                let priceInfo = ShippingPriceInfo(amount: shippingCost, currency: info.currency, label: "")
                return priceInfo.formattedPrice
            }
        }
        if let defaultInfo = shippingPrices?.defaultShipping {
            let priceInfo = ShippingPriceInfo(amount: shippingCost, currency: defaultInfo.currency, label: "")
            return priceInfo.formattedPrice
        }
        return String(format: "€%.2f", shippingCost)
    }

    private func deliveryOptionLabel(for method: String) -> String {
        let price = shippingPriceLabel(for: method)
        if method == "postapoint" {
            return "\(String(localized: "postapoint_delivery_option")) (\(price))"
        }
        return "\(String(localized: "home_delivery_option")) (\(price))"
    }

    private func shippingPriceLabel(for method: String) -> String {
        guard let hu = shippingPrices?.HU else { return "..." }
        if method == "postapoint" {
            return hu.postapoint?.formattedPrice ?? "..."
        } else {
            return hu.home_delivery?.formattedPrice ?? "..."
        }
    }

    // MARK: - Data Loading

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
            await MainActor.run {
                isFreeReplacement = false
                isCheckingEligibility = false
            }
        }
    }

    private func loadUserAddress() async {
        let detectedCountry = Locale.current.region?.identifier

        guard let user = authViewModel.currentUser else {
            if let detected = detectedCountry, SupportedCountries.findByCode(detected) != nil {
                await MainActor.run { selectedCountryCode = detected }
            }
            return
        }

        await MainActor.run {
            if let address = user.address { street1 = address }
            if let userPhone = user.phone { phone = userPhone }
            if let userCity = user.city { city = userCity }
            if let postal = user.postalCode { postCode = postal }
            let rawCountry = user.country ?? detectedCountry ?? ""
            if let match = SupportedCountries.find(rawCountry) {
                selectedCountryCode = match.code
            } else if let detected = detectedCountry, SupportedCountries.findByCode(detected) != nil {
                selectedCountryCode = detected
            }
        }
    }

    private func loadShippingPrices() async {
        do {
            let prices = try await APIService.shared.getShippingPrices()
            await MainActor.run {
                shippingPrices = prices
                isLoadingPrices = false
            }
        } catch {
            await MainActor.run { isLoadingPrices = false }
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
                    province: nil,
                    postCode: postCode,
                    country: selectedCountryCode,
                    phone: phone.isEmpty ? nil : phone
                )

                let response = try await APIService.shared.createReplacementOrder(
                    petId: pet.id,
                    shippingAddress: shippingAddress,
                    deliveryMethod: isHungary ? deliveryMethod : nil,
                    postapointDetails: selectedPostaPoint
                )

                isLoading = false

                if let urlString = response.checkoutUrl,
                   urlString.hasPrefix("https://checkout.stripe.com/"),
                   let url = URL(string: urlString) {
                    checkoutURL = url
                    showCheckoutSheet = true
                } else {
                    orderComplete = true
                }
            } catch {
                isLoading = false
                appState.showError(error.localizedDescription)
            }
        }
    }
}

// MARK: - Section Card Component

private struct ReplacementSectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.tealAccent)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
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
