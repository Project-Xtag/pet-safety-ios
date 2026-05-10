import SwiftUI

struct OrderMoreTagsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoading = false
    @State private var showingCountryPicker = false
    @State private var orderComplete = false
    @State private var checkoutURL: URL?
    @State private var showCheckoutSheet = false

    // Gift order
    @State private var isGift = false
    @State private var giftQuantity = 1
    @State private var giftRecipientName = ""
    @State private var giftMessage = ""

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
    @State private var selectedCountryCode: String = {
        // Pre-select device country synchronously so HU/NO users see correct
        // prices and delivery options from the first render.
        if let region = Locale.current.region?.identifier,
           SupportedCountries.findByCode(region) != nil {
            return region
        }
        return ""
    }()

    // Delivery method (Hungary only)
    @State private var deliveryMethod = "home_delivery"
    @State private var selectedPostaPoint: PostaPointDetails?
    // Welcome promo (free shipping at tag order). Backend matches
    // against env.WELCOME_PROMO_CODE (live: "Budapesti Kutyasok") and
    // swaps the shipping rate to a 0-amount inline rate when valid.
    // `promoApplied` is set after a successful validate-promo
    // round-trip so the user sees the discount BEFORE the Stripe
    // redirect; the Apply button locks the input + the order summary
    // strikes the original shipping price.
    @State private var promoCode = ""
    @State private var promoApplied = false
    @State private var promoValidating = false
    @State private var promoError: String?

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
                .font(.appFont(size: 28, weight: .bold))

            Text("order_more_confirmation")
                .font(.appFont(.body))
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
                        // Gift Toggle
                        giftToggleCard

                        // Pet Names (hidden when gift order)
                        if !isGift {
                            petNamesCard
                        }

                        // Contact Details
                        contactDetailsCard

                        // Shipping Address
                        shippingAddressCard

                        // Delivery Method (Hungary only)
                        if isHungary {
                            deliveryMethodCard
                        }

                        // Promo Code (free shipping when valid)
                        promoCodeCard

                        // Order Summary
                        orderSummaryCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }

            // Floating CTA Button — gated on TAGS_AVAILABLE so we don't take
            // orders we can't fulfil. Loading and fetch errors fail-closed
            // (tagsAvailable becomes false), matching the backend gate.
            VStack(spacing: 0) {
                Divider()
                if appState.tagsAvailable {
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
                } else {
                    tagsComingSoonBanner
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
            }
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Tags Coming Soon

    /// Replaces the "Proceed to Payment" CTA when TAGS_AVAILABLE is off
    /// (or the config fetch hasn't returned). Same vertical footprint as
    /// the button so the bottom bar doesn't jump when the gate flips.
    private var tagsComingSoonBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "pawprint.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("tags_coming_soon_title")
                    .font(.appFont(.subheadline))
                    .fontWeight(.semibold)
                Text("tags_coming_soon_body")
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.tealAccent.opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: "shippingbox.fill")
                    .font(.appFont(size: 28))
                    .foregroundColor(.tealAccent)
            }

            Text("order_more_title")
                .font(.appFont(size: 24, weight: .bold))

            Text("order_more_subtitle")
                .font(.appFont(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(Color.peachBackground)
    }

    // MARK: - Section Cards

    private var giftToggleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $isGift) {
                HStack(spacing: 10) {
                    Image(systemName: "gift.fill")
                        .font(.appFont(size: 18))
                        .foregroundColor(.brandOrange)
                    Text("order_gift_toggle")
                        .font(.appFont(size: 16, weight: .medium))
                }
            }
            .tint(.brandOrange)

            if isGift {
                Text("order_gift_description")
                    .font(.appFont(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)

                Stepper(value: $giftQuantity, in: 1...20) {
                    HStack {
                        Text("order_gift_quantity")
                            .font(.appFont(size: 15))
                        Spacer()
                        Text("\(giftQuantity)")
                            .font(.appFont(size: 15, weight: .semibold))
                            .foregroundColor(.tealAccent)
                    }
                }

                TextField(String(localized: "order_gift_recipient_name"), text: $giftRecipientName)
                    .textFieldStyle(BrandTextFieldStyle(icon: "person"))
                    .textContentType(.name)

                VStack(alignment: .leading, spacing: 4) {
                    TextField(String(localized: "order_gift_message_placeholder"), text: $giftMessage, axis: .vertical)
                        .textFieldStyle(BrandTextFieldStyle(icon: "text.quote"))
                        .lineLimit(3...5)
                        .onChange(of: giftMessage) { _, newValue in
                            if newValue.count > 500 {
                                giftMessage = String(newValue.prefix(500))
                            }
                        }
                    if !giftMessage.isEmpty {
                        Text("\(giftMessage.count)/500")
                            .font(.appFont(size: 11))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private var petNamesCard: some View {
        SectionCard(title: String(localized: "order_more_pet_names"), icon: "pawprint.fill") {
            ForEach(petNames.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    TextField(String(localized: "order_more_pet_name_placeholder"), text: $petNames[index])
                        .textFieldStyle(BrandTextFieldStyle(icon: "pawprint"))
                    if petNames.count > 1 {
                        Button(action: { removePetName(at: index) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.appFont(.title3))
                                .foregroundColor(.errorColor.opacity(0.7))
                        }
                    }
                }
            }

            Button(action: addPetName) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.appFont(size: 16))
                    Text("order_more_add_another")
                        .font(.appFont(size: 15, weight: .medium))
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

            // Country picker — opens sheet with user's country at top
            Button(action: { showingCountryPicker = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                        .font(.appFont(size: 15))
                    Text(SupportedCountries.findByCode(selectedCountryCode)?.localizedName ?? String(localized: "address_select_country"))
                        .foregroundColor(selectedCountryCode.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(.secondary)
                        .font(.appFont(size: 12))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            .sheet(isPresented: $showingCountryPicker) {
                NavigationView {
                    List {
                        ForEach(SupportedCountries.sorted(priority: Locale.current.region?.identifier)) { country in
                            Button {
                                selectedCountryCode = country.code
                                showingCountryPicker = false
                            } label: {
                                HStack {
                                    Text(country.localizedName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if country.code == selectedCountryCode {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.brandOrange)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("address_select_country_title")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("cancel") { showingCountryPicker = false }
                                .foregroundColor(.brandOrange)
                        }
                    }
                }
            }
        }
    }

    private var promoCodeCard: some View {
        SectionCard(title: String(localized: "order_promo_code_title"), icon: "tag.fill") {
            VStack(alignment: .leading, spacing: 8) {
                Text("order_promo_code_label")
                    .font(.appFont(.subheadline))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    TextField(
                        String(localized: "order_promo_code_placeholder"),
                        text: $promoCode
                    )
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .disabled(promoApplied || promoValidating)
                    .onChange(of: promoCode) { _ in
                        if promoError != nil { promoError = nil }
                    }

                    if promoApplied {
                        Button(action: removePromo) {
                            Text("order_promo_code_remove")
                                .font(.appFont(.subheadline))
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button(action: applyPromo) {
                            if promoValidating {
                                Text("order_promo_code_validating")
                                    .font(.appFont(.subheadline))
                            } else {
                                Text("order_promo_code_apply")
                                    .font(.appFont(.subheadline))
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(promoCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || promoValidating)
                    }
                }

                if promoApplied {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("order_promo_code_applied_free_shipping")
                            .font(.appFont(.caption))
                            .foregroundColor(.green)
                    }
                } else if let promoError {
                    Text(promoError)
                        .font(.appFont(.caption))
                        .foregroundColor(.red)
                } else {
                    Text("order_promo_code_hint")
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func applyPromo() {
        let trimmed = promoCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !promoValidating else { return }
        promoValidating = true
        promoError = nil
        Task {
            do {
                let response = try await APIService.shared.validateTagPromo(code: trimmed)
                await MainActor.run {
                    if response.data?.valid == true {
                        promoApplied = true
                        promoError = nil
                    } else {
                        promoApplied = false
                        promoError = String(localized: "order_promo_code_invalid")
                    }
                    promoValidating = false
                }
            } catch {
                await MainActor.run {
                    promoApplied = false
                    promoError = String(localized: "order_promo_code_invalid")
                    promoValidating = false
                }
            }
        }
    }

    private func removePromo() {
        promoApplied = false
        promoCode = ""
        promoError = nil
    }

    private var deliveryMethodCard: some View {
        SectionCard(title: String(localized: "delivery_method_title"), icon: "truck.box.fill") {
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

    private var orderSummaryCard: some View {
        VStack(spacing: 0) {
            if isGift {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.appFont(size: 12))
                        .foregroundColor(.brandOrange)
                    Text("order_gift_badge")
                        .font(.appFont(size: 13, weight: .semibold))
                        .foregroundColor(.brandOrange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.brandOrange.opacity(0.12))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }

            HStack {
                Text("order_more_tags_count \(isGift ? giftQuantity : validPetCount)")
                    .font(.appFont(size: 15))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(localized: "free_price"))
                    .font(.appFont(size: 15, weight: .semibold))
                    .foregroundColor(.tealAccent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 16)

            HStack {
                Text("order_more_shipping_cost")
                    .font(.appFont(size: 15))
                    .foregroundColor(.secondary)
                Spacer()
                if isLoadingPrices {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if promoApplied {
                    // Original price struck through, "free" in green
                    // next to it. Mirrors the web /get-your-tag summary
                    // so the discount is visible before redirecting
                    // the user out to Stripe.
                    HStack(spacing: 6) {
                        Text(currentShippingPriceLabel)
                            .font(.appFont(size: 14))
                            .foregroundColor(.secondary)
                            .strikethrough()
                        Text("free_price")
                            .font(.appFont(size: 15, weight: .semibold))
                            .foregroundColor(.green)
                    }
                } else {
                    Text(currentShippingPriceLabel)
                        .font(.appFont(size: 15, weight: .semibold))
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
        selectedCountryCode.uppercased() == "HU"
    }

    private var validPetCount: Int {
        petNames.filter { !$0.isEmpty }.count
    }

    private var isFormValid: Bool {
        let hasPetNames = isGift ? true : validPetCount > 0
        return hasPetNames &&
            !ownerName.isEmpty &&
            InputValidators.isValidEmail(email) &&
            !street1.isEmpty &&
            !city.isEmpty &&
            !postCode.isEmpty &&
            !selectedCountryCode.isEmpty &&
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
            if let detected = detectedCountry, SupportedCountries.findByCode(detected) != nil {
                await MainActor.run { selectedCountryCode = detected }
            }
            return
        }

        await MainActor.run {
            email = user.email
            if let userPhone = user.phone {
                phone = userPhone
            }
            let formattedName = InputValidators.formatDisplayName(firstName: user.firstName, lastName: user.lastName)
            if !formattedName.isEmpty {
                ownerName = formattedName
            }
            if let address = user.address { street1 = address }
            if let userCity = user.city { city = userCity }
            if let postal = user.postalCode { postCode = postal }
            // Resolve country: user profile value → locale detection
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
                let quantity = isGift ? giftQuantity : validPetCount
                let validNames = petNames.filter { !$0.isEmpty }

                // Step 1: Create order record (matches Android flow)
                let shippingAddr = AddressDetails(
                    street1: street1,
                    street2: street2.isEmpty ? nil : street2,
                    city: city,
                    province: nil,
                    postCode: postCode,
                    country: selectedCountryCode.uppercased(),
                    phone: phone.isEmpty ? nil : phone
                )

                var orderRequest = CreateOrderRequest(
                    petNames: isGift ? nil : validNames,
                    ownerName: ownerName,
                    email: email,
                    shippingAddress: shippingAddr,
                    billingAddress: nil,
                    paymentMethod: "card",
                    shippingCost: nil
                )
                orderRequest.isGift = isGift ? true : nil
                orderRequest.giftRecipientName = isGift ? (giftRecipientName.isEmpty ? nil : giftRecipientName) : nil
                orderRequest.giftMessage = isGift ? (giftMessage.isEmpty ? nil : giftMessage) : nil
                orderRequest.quantity = isGift ? giftQuantity : nil
                orderRequest.deliveryMethod = isHungary ? deliveryMethod : nil
                orderRequest.postapointDetails = selectedPostaPoint
                orderRequest.locale = Locale.current.language.languageCode?.identifier

                _ = try await APIService.shared.createOrder(orderRequest)

                // Step 2: Create Stripe checkout session.
                // Forward the typed code only when the user has clicked
                // Apply and the backend confirmed validity. The same
                // server-side check runs again at /create-checkout, so
                // this is a UX-sync gate, not a trust boundary.
                let trimmedPromo = promoCode.trimmingCharacters(in: .whitespacesAndNewlines)
                let checkout = try await APIService.shared.createTagCheckout(
                    quantity: quantity,
                    countryCode: selectedCountryCode.uppercased(),
                    deliveryMethod: isHungary ? deliveryMethod : nil,
                    postapointDetails: selectedPostaPoint,
                    promoCode: (promoApplied && !trimmedPromo.isEmpty) ? trimmedPromo : nil
                )

                if checkout.url.hasPrefix("senra://") {
                    // Welcome-promo bypass — backend completed the
                    // order server-side (0-total), no Stripe redirect
                    // needed. Mirror the same notification that fires
                    // when the SafariCheckoutView intercepts a Stripe
                    // success URL so the rest of the app updates.
                    appState.showSuccess(String(localized: "checkout_tag_order_success"))
                    NotificationCenter.default.post(name: .tagOrderCompleted, object: nil)
                    isLoading = false
                    return
                }
                if let url = URL(string: checkout.url) {
                    checkoutURL = url
                    showCheckoutSheet = true
                } else {
                    appState.showError(String(localized: "error_invalid_checkout_url"))
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
                    .font(.appFont(size: 16))
                    .foregroundColor(.tealAccent)
                Text(title)
                    .font(.appFont(size: 17, weight: .semibold))
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

// MARK: - Delivery Option Card
struct DeliveryOptionCard: View {
    let title: String
    let price: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.appFont(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                Text(price)
                    .font(.appFont(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.brandOrange.opacity(0.12) : Color(UIColor.systemGray6))
            .foregroundColor(isSelected ? .brandOrange : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.brandOrange : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        OrderMoreTagsView()
            .environmentObject(AppState())
            .environmentObject(AuthViewModel())
    }
}
