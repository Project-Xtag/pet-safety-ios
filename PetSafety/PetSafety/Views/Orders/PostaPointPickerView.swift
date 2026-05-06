import SwiftUI

struct PostaPointPickerView: View {
    let selected: PostaPointDetails?
    let onSelect: (PostaPointDetails) -> Void

    @State private var zipCode = ""
    @State private var deliveryPoints: [DeliveryPoint] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Selected point confirmation
            if let point = selected {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.tealAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(point.name)
                            .font(.appFont(.subheadline))
                            .fontWeight(.semibold)
                        if let address = point.address {
                            Text(address)
                                .font(.appFont(.caption))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tealAccent.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.tealAccent, lineWidth: 1.5)
                )
            }

            // Search bar
            HStack(spacing: 8) {
                TextField(String(localized: "postapoint_zip_placeholder"), text: $zipCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .onSubmit {
                        if zipCode.count >= 4 {
                            searchPoints()
                        }
                    }

                Button(action: searchPoints) {
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 20, height: 20)
                    } else {
                        Text("search")
                    }
                }
                .disabled(zipCode.count < 4 || isSearching)
                .buttonStyle(.bordered)
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.appFont(.caption))
                    .foregroundColor(.red)
            }

            // Results
            if hasSearched && deliveryPoints.isEmpty && !isSearching {
                Text("postapoint_no_results")
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }

            ForEach(deliveryPoints) { point in
                Button(action: {
                    onSelect(PostaPointDetails(
                        id: point.id,
                        name: point.name,
                        address: point.address
                    ))
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.brandOrange)
                            .font(.appFont(.title3))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(point.name)
                                .font(.appFont(.subheadline))
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            if let address = point.address {
                                Text(address)
                                    .font(.appFont(.caption))
                                    .foregroundColor(.secondary)
                            }
                            if let city = point.city, let postcode = point.postcode {
                                Text("\(postcode) \(city)")
                                    .font(.appFont(.caption))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if selected?.id == point.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.tealAccent)
                        }
                    }
                    .padding(12)
                    .background(
                        selected?.id == point.id
                            ? Color.tealAccent.opacity(0.08)
                            : Color(.systemGray6)
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                selected?.id == point.id ? Color.tealAccent : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func searchPoints() {
        guard zipCode.count >= 4 else { return }
        isSearching = true
        errorMessage = nil

        Task {
            do {
                let points = try await APIService.shared.getDeliveryPoints(zipCode: zipCode)
                await MainActor.run {
                    deliveryPoints = points
                    hasSearched = true
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = String(localized: "postapoint_search_failed")
                    hasSearched = true
                    isSearching = false
                }
            }
        }
    }
}
