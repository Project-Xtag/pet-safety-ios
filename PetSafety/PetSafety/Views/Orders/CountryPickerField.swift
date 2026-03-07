import SwiftUI

struct CountryPickerField: View {
    @Binding var selectedCode: String

    private var selectedCountry: SupportedCountry? {
        SupportedCountries.findByCode(selectedCode)
    }

    var body: some View {
        Menu {
            ForEach(SupportedCountries.all) { country in
                Button(action: { selectedCode = country.code }) {
                    if country.code == selectedCode {
                        Label(country.name, systemImage: "checkmark")
                    } else {
                        Text(country.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15))

                Text(selectedCountry?.name ?? String(localized: "select_country"))
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
