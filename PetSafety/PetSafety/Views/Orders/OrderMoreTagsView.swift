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
    @State private var postCode = ""
    @State private var country = ""

    // Delivery method (Hungary only)
    @State private var deliveryMethod = "home_delivery"
    @State private var selectedPostaPoint: PostaPointDetails?

    // Shipping prices (fetched from API)
    @State private var shippingPrices: ShippingPricesResponse?
    @State private var isLoadingPrices = true

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
            await loadShippingPrices()
        }
        .sheet(isPresented: $showCheckoutSheet) {
            if let url = checkoutURL {
                SafariCheckoutView(url: url) { _ in
                    showCheckoutSheet = false
                    checkoutURL = nil
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagOrderCompleted)) { _ in
            orderComplete = true
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

            Text("order_more_complete")
                .font(.system(size: 28, weight: .bold))

            Text("order_more_confirmation")
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
                        // Pet Names
                        petNamesCard

                        // Contact Details
                        contactDetailsCard

                        // Shipping Address
                        shippingAddressCard

                        // Delivery Method (Hungary only)
                        if isHungary {
                            deliveryMethodCard
                        }

                        // Order Summary
                        orderSummaryCard
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
                            Text("order_more_redirecting")
                        }
                    } else {
                        Text("order_more_proceed_to_payment")
                    }
                }
                .buttonStyle(BrandButtonStyle(isDisabled: !isFormValid))
                .disabled(isLoading || !isFormValid)
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
                    .fill(Color.tealAccent.opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.tealAccent)
            }

            Text("order_more_title")
                .font(.system(size: 24, weight: .bold))

            Text("order_more_subtitle")
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

    private var petNamesCard: some View {
        SectionCard(title: String(localized: "order_more_pet_names"), icon: "pawprint.fill") {
            ForEach(petNames.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    TextField(String(localized: "order_more_pet_name_placeholder"), text: $petNames[index])
                        .textFieldStyle(BrandTextFieldStyle(icon: "pawprint"))
                    if petNames.count > 1 {
                        Button(action: { removePetName(at: index) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.errorColor.opacity(0.7))
                        }
                    }
                }
            }

            Button(action: addPetName) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("order_more_add_another")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.tealAccent)
            }
            .padding(.top, 4)
        }
    }

    private var contactDetailsCard: some View {
        SectionCard(title: String(localized: "order_more_your_info"), icon: "person.fill") {
            TextField(String(localized: "order_more_owner_name"), text: $ownerName)
                .textFieldStyle(BrandTextFieldStyle(icon: "person"))
                .textContentType(.name)

            TextField(String(localized: "order_more_email"), text: $email)
                .textFieldStyle(BrandTextFieldStyle(icon: "envelope"))
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)

            TextField(String(localized: "order_more_phone"), text: $phone)
                .textFieldStyle(BrandTextFieldStyle(icon: "phone"))
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
        }
    }

    private var shippingAddressCard: some View {
        SectionCard(title: String(localized: "order_more_shipping"), icon: "house.fill") {
            TextField(String(localized: "order_more_street"), text: $street1)
                .textFieldStyle(BrandTextFieldStyle())
                .textContentType(.streetAddressLine1)

            TextField(String(localized: "order_more_line2"), text: $street2)
                .textFieldStyle(BrandTextFieldStyle())
                .textContentType(.streetAddressLine2)

            HStack(spacing: 12) {
                TextField(String(localized: "order_more_city"), text: $city)
                    .textFieldStyle(BrandTextFieldStyle())
                    .textContentType(.addressCity)

                TextField(String(localized: "order_more_postal"), text: $postCode)
                    .textFieldStyle(BrandTextFieldStyle())
                    .textContentType(.postalCode)
                    .autocapitalization(.allCharacters)
            }

            TextField(String(localized: "order_more_country"), text: $country)
                .textFieldStyle(BrandTextFieldStyle(icon: "globe"))
                .textContentType(.countryName)
        }
    }

    private var deliveryMethodCard: some View {
        SectionCard(title: String(localized: "delivery_method_title"), icon: "truck.box.fill") {
            Picker("", selection: $deliveryMethod) {
                Text(deliveryOptionLabel(for: "home_delivery")).tag("home_delivery")
                Text(deliveryOptionLabel(for: "postapoint")).tag("postapoint")
            }
            .pickerStyle(.segmented)
            .onChange(of: deliveryMethod) { _, newValue in
                if newValue != "postapoint" {
                    selectedPostaPoint = nil
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

    private var orderSummaryCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("order_more_tags_count \(validPetCount)")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(localized: "free_price"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.tealAccent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 16)

            HStack {
                Text("order_more_shipping_cost")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                Spacer()
                if isLoadingPrices {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(currentShippingPriceLabel)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.tealAccent.opacity(0.08))
        .cornerRadius(14)
    }

    // MARK: - Helpers

    private var isHungary: Bool {
        let c = country.lowercased().trimmingCharacters(in: .whitespaces)
        return c == "hu" || c == "hungary" || c == "magyarország" || c == "magyarorszag"
    }

    private var validPetCount: Int {
        petNames.filter { !$0.isEmpty }.count
    }

    private var isFormValid: Bool {
        validPetCount > 0 &&
        !ownerName.isEmpty &&
        InputValidators.isValidEmail(email) &&
        !street1.isEmpty &&
        !city.isEmpty &&
        !postCode.isEmpty &&
        !country.isEmpty &&
        (deliveryMethod != "postapoint" || selectedPostaPoint != nil)
    }

    private var currentShippingPriceLabel: String {
        if isHungary {
            return shippingPriceLabel(for: deliveryMethod)
        }
        return shippingPrices?.defaultShipping?.formattedPrice ?? String(localized: "order_more_shipping_calculated")
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

    private func addPetName() {
        petNames.append("")
    }

    private func removePetName(at index: Int) {
        petNames.remove(at: index)
    }

    // MARK: - Data Loading

    private func loadUserInfo() async {
        // Auto-detect country from device locale as fallback
        let detectedCountry = Locale.current.region?.identifier

        guard let user = authViewModel.currentUser else {
            // No user data — at least set detected country
            if let detected = detectedCountry {
                await MainActor.run { country = detected }
            }
            return
        }

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
            if let address = user.address { street1 = address }
            if let userCity = user.city { city = userCity }
            if let postal = user.postalCode { postCode = postal }
            // Use user profile country, fallback to locale detection
            country = user.country ?? detectedCountry ?? ""
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
                let quantity = validPetCount
                let countryCode = country.count == 2 ? country.uppercased() : (authViewModel.currentUser?.country ?? Locale.current.region?.identifier)

                let checkout = try await APIService.shared.createTagCheckout(
                    quantity: quantity,
                    countryCode: countryCode,
                    deliveryMethod: isHungary ? deliveryMethod : nil,
                    postapointDetails: selectedPostaPoint
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

// MARK: - Section Card Component

private struct SectionCard<Content: View>: View {
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
        OrderMoreTagsView()
            .environmentObject(AppState())
            .environmentObject(AuthViewModel())
    }
}
