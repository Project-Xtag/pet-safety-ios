import SwiftUI

/// Owner submission form (M3) — mirrors `FoundPetFormView`'s `Form`/toolbar shape but
/// drives off `SubmitPetFriendlyPlaceViewModel` so the tested error-state logic (M2)
/// owns the field state and the typed-failure branching. The two typed failures reach
/// the UI as the review contract requires: 422 geocode → `addressError` shown INLINE
/// under the address field; 409 dedup → an alert whose copy branches on `existingName`
/// presence. Everything else → a form-level error section.
struct SubmitPetFriendlyPlaceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SubmitPetFriendlyPlaceViewModel()

    /// Called with the created pending place so the caller can react (e.g. refresh /mine).
    var onSubmitted: ((SubmittedPetFriendlyPlace) -> Void)?

    private let nameMax = 150, addressMax = 500, phoneMax = 32, websiteMax = 500
    private let cityMax = 120, postcodeMax = 20, introMax = 2000

    var body: some View {
        NavigationView {
            Form {
                categorySection
                nameSection
                addressSection
                contactSection
                introSection
                if let formError = vm.formError {
                    Section {
                        Text(formError).foregroundColor(.errorColor).font(.appFont(size: 13))
                    }
                }
            }
            .navigationTitle(String(localized: "pet_friendly_submit_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_cancel")) { dismiss() }
                        .disabled(vm.isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "pet_friendly_submit_submit")) {
                        Task {
                            if let created = await vm.submit() {
                                onSubmitted?(created)
                                dismiss()
                            }
                        }
                    }
                    .disabled(!vm.canSubmit || vm.isSubmitting)
                }
            }
            .alert(
                String(localized: "pet_friendly_submit_duplicate_title"),
                isPresented: Binding(
                    get: { vm.duplicate != nil },
                    set: { if !$0 { vm.acknowledgeDuplicate() } }
                ),
                presenting: vm.duplicate
            ) { _ in
                Button(String(localized: "common_ok"), role: .cancel) {}
            } message: { match in
                // Presence-branch: the M1/M2 two-shape reaching the UI.
                if let name = match.existingName {
                    Text(String(localized: "pet_friendly_submit_duplicate_named \(name)"))
                } else {
                    Text(String(localized: "pet_friendly_submit_duplicate_generic"))
                }
            }
        }
    }

    // MARK: - Sections

    private var categorySection: some View {
        Section(header: Text("pet_friendly_submit_category")) {
            Picker(String(localized: "pet_friendly_submit_category"), selection: $vm.category) {
                Text("pet_friendly_submit_category_choose").tag(Optional<PetFriendlyPlace.Category>.none)
                ForEach(PetFriendlyPlace.Category.allCases.filter { $0 != .unknown }, id: \.self) { cat in
                    Text(categoryLabel(cat)).tag(Optional(cat))
                }
            }
        }
    }

    private var nameSection: some View {
        Section(header: Text("pet_friendly_submit_name")) {
            TextField(String(localized: "pet_friendly_submit_name_placeholder"), text: $vm.name)
                .onChange(of: vm.name) { _, v in if v.count > nameMax { vm.name = String(v.prefix(nameMax)) } }
        }
    }

    private var addressSection: some View {
        Section(header: Text("pet_friendly_submit_address")) {
            TextField(String(localized: "pet_friendly_submit_address_placeholder"), text: $vm.address)
                .textInputAutocapitalization(.words)
                .onChange(of: vm.address) { _, v in if v.count > addressMax { vm.address = String(v.prefix(addressMax)) } }
            TextField(String(localized: "pet_friendly_submit_city_placeholder"), text: $vm.city)
                .onChange(of: vm.city) { _, v in if v.count > cityMax { vm.city = String(v.prefix(cityMax)) } }
            TextField(String(localized: "pet_friendly_submit_postcode_placeholder"), text: $vm.postcode)
                .onChange(of: vm.postcode) { _, v in if v.count > postcodeMax { vm.postcode = String(v.prefix(postcodeMax)) } }
            // 422 geocode failure is pinned to the address field (review item).
            if let addressError = vm.addressError {
                Text(addressError).foregroundColor(.errorColor).font(.appFont(size: 12))
            }
            Text("pet_friendly_submit_address_hint")
                .font(.appFont(size: 11))
                .foregroundColor(.mutedText)
        }
    }

    private var contactSection: some View {
        Section(header: Text("pet_friendly_submit_contact")) {
            TextField(String(localized: "pet_friendly_submit_phone_placeholder"), text: $vm.phone)
                .keyboardType(.phonePad)
                .onChange(of: vm.phone) { _, v in if v.count > phoneMax { vm.phone = String(v.prefix(phoneMax)) } }
            TextField(String(localized: "pet_friendly_submit_website_placeholder"), text: $vm.website)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: vm.website) { _, v in if v.count > websiteMax { vm.website = String(v.prefix(websiteMax)) } }
        }
    }

    private var introSection: some View {
        Section(header: Text("pet_friendly_submit_introduction")) {
            TextEditor(text: $vm.introduction)
                .frame(minHeight: 90)
                .onChange(of: vm.introduction) { _, v in if v.count > introMax { vm.introduction = String(v.prefix(introMax)) } }
        }
    }

    private func categoryLabel(_ c: PetFriendlyPlace.Category) -> String {
        switch c {
        case .cafeBar: return String(localized: "pet_friendly_category_cafe_bar")
        case .restaurant: return String(localized: "pet_friendly_category_restaurant")
        case .hotel: return String(localized: "pet_friendly_category_hotel")
        case .beach: return String(localized: "pet_friendly_category_beach")
        case .other: return String(localized: "pet_friendly_category_other")
        case .unknown: return ""
        }
    }
}
