import SwiftUI

struct CountryPickerField: View {
    @Binding var selectedCode: String

    /// Device region used to place the user's country at the top.
    private var deviceCountry: String? {
        Locale.current.region?.identifier
    }

    private var countries: [SupportedCountry] {
        SupportedCountries.sorted(priority: deviceCountry)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "globe")
                .foregroundColor(.secondary)
                .font(.system(size: 15))

            Picker(selection: $selectedCode) {
                Text(String(localized: "address_select_country"))
                    .tag("")
                ForEach(countries) { country in
                    Text(country.localizedName)
                        .tag(country.code)
                }
            } label: {
                EmptyView()
            }
            .labelsHidden()
            .tint(selectedCode.isEmpty ? .secondary : .primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}
