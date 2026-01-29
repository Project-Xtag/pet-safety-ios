import SwiftUI

/**
 * Map App Picker View
 *
 * Presents a sheet allowing users to choose which map app to open
 * for viewing a pet's location when their tag is scanned.
 *
 * Shows a warning when location is approximate (~500m accuracy).
 */

struct MapAppPickerView: View {
    let location: LocationData
    let petName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Warning for approximate location
                if location.isApproximate {
                    Section {
                        Label {
                            Text("This is an approximate location (~500m). Search the surrounding area.")
                                .font(.callout)
                                .foregroundStyle(.orange)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }

                // Coordinates display
                Section {
                    HStack {
                        Text("Coordinates")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatCoordinates())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Map app options
                Section("Open in") {
                    Button(action: openAppleMaps) {
                        Label("Apple Maps", systemImage: "map.fill")
                    }

                    Button(action: openGoogleMaps) {
                        Label("Google Maps", systemImage: "globe")
                    }

                    Button(action: openWaze) {
                        Label("Waze", systemImage: "car.fill")
                    }
                }
            }
            .navigationTitle("\(petName) Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func formatCoordinates() -> String {
        let precision = location.isApproximate ? 3 : 6
        return String(format: "%.\(precision)f, %.\(precision)f", location.latitude, location.longitude)
    }

    // MARK: - Map App Openers

    private func openAppleMaps() {
        let label = petName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Pet"
        let urlString = "https://maps.apple.com/?ll=\(location.latitude),\(location.longitude)&q=\(label)%20Location"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
        dismiss()
    }

    private func openGoogleMaps() {
        // Try Google Maps app first
        let appURL = "comgooglemaps://?q=\(location.latitude),\(location.longitude)"
        let webURL = "https://www.google.com/maps/search/?api=1&query=\(location.latitude),\(location.longitude)"

        if let url = URL(string: appURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: webURL) {
            UIApplication.shared.open(url)
        }
        dismiss()
    }

    private func openWaze() {
        let urlString = "https://waze.com/ul?ll=\(location.latitude),\(location.longitude)&navigate=yes"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    MapAppPickerView(
        location: LocationData(
            latitude: 47.497,
            longitude: 19.040,
            isApproximate: true
        ),
        petName: "Buddy"
    )
}
