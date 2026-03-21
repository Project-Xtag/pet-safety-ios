import SwiftUI

struct CountryPickerField: View {
    @Binding var selectedCode: String
    @State private var showingPicker = false

    private var selectedCountry: SupportedCountry? {
        SupportedCountries.findByCode(selectedCode)
    }

    /// Device region used to place the user's country at the top.
    private var deviceCountry: String? {
        Locale.current.region?.identifier
    }

    var body: some View {
        Button(action: { showingPicker = true }) {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15))

                Text(selectedCountry?.localizedName ?? String(localized: "address_select_country"))
                    .foregroundColor(selectedCountry != nil ? .primary : .secondary)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
        }
        .sheet(isPresented: $showingPicker) {
            OrderCountryPickerSheet(
                selectedCode: $selectedCode,
                priorityCode: deviceCountry
            )
        }
    }
}

// MARK: - Country Picker Sheet
/// Full-screen sheet with the user's country at the top, followed by all others sorted alphabetically.
private struct OrderCountryPickerSheet: View {
    @Binding var selectedCode: String
    let priorityCode: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var countries: [SupportedCountry] {
        SupportedCountries.sorted(priority: priorityCode)
    }

    private var filteredCountries: [SupportedCountry] {
        if searchText.isEmpty { return countries }
        let query = searchText.lowercased()
        return countries.filter { $0.localizedName.lowercased().contains(query) || $0.code.lowercased().contains(query) }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCountries) { country in
                    Button {
                        selectedCode = country.code
                        dismiss()
                    } label: {
                        HStack {
                            Text(country.localizedName)
                                .foregroundColor(.primary)
                            Spacer()
                            if country.code == selectedCode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.brandOrange)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text("address_search_country"))
            .navigationTitle("address_select_country_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brandOrange)
                }
            }
        }
    }
}
