import SwiftUI

struct CountryPickerField: View {
    @Binding var selectedCode: String

    private var selectedCountry: SupportedCountry? {
        SupportedCountries.findByCode(selectedCode)
    }

    /// Device region used to place the user's country at the top.
    private var deviceCountry: String? {
        Locale.current.region?.identifier
    }

    var body: some View {
        let countries = SupportedCountries.sorted(priority: deviceCountry)

        Menu {
            // SwiftUI Menu renders buttons bottom-to-top, so reverse the list
            // to display the priority country at the visual top.
            ForEach(countries.reversed()) { country in
                Button(action: { selectedCode = country.code }) {
                    if country.code == selectedCode {
                        Label(country.localizedName, systemImage: "checkmark")
                    } else {
                        Text(country.localizedName)
                    }
                }
            }
        } label: {
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
    }
}
