import SwiftUI
import CoreLocation

/**
 * Share Location View with 2-Tier Location Toggle
 *
 * Simplified from the 3-card GDPR layout to a single toggle:
 * - Toggle ON (default): Share exact GPS location (precise)
 * - Toggle OFF: Share approximate ~500m area (coordinates rounded)
 *
 * Location is always shared when the user taps "Share Location".
 * The "Decline" option has been removed.
 */

struct ShareLocationView: View {
    let qrCode: String
    let petName: String

    @StateObject private var locationManager = LocationManager()
    @State private var shareExactLocation = true
    @State private var isSharing = false
    @State private var shared = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text(String(format: NSLocalizedString("share_help_get_home %@", comment: ""), petName))
                            .font(.title2)
                            .bold()

                        Text(NSLocalizedString("share_location_subtitle", comment: "Your location helps the owner find their pet faster."))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    // Location toggle
                    VStack(spacing: 12) {
                        Toggle(isOn: $shareExactLocation) {
                            HStack(spacing: 12) {
                                Image(systemName: shareExactLocation ? "location.fill" : "location.circle")
                                    .font(.title3)
                                    .foregroundColor(shareExactLocation ? .blue : .orange)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString("share_exact_location_toggle", comment: "Share exact location"))
                                        .font(.headline)
                                    Text(shareExactLocation
                                         ? NSLocalizedString("share_exact_desc", comment: "")
                                         : NSLocalizedString("share_approximate_desc", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .tint(.blue)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Current location display
                    if let location = locationManager.location {
                        VStack(spacing: 8) {
                            Text(NSLocalizedString("share_your_location", comment: ""))
                                .font(.headline)

                            if shareExactLocation {
                                Text("Lat: \(location.latitude, specifier: "%.6f"), Lng: \(location.longitude, specifier: "%.6f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                let rounded = roundToApproximate(lat: location.latitude, lng: location.longitude)
                                Text("Lat: \(rounded.lat, specifier: "%.3f"), Lng: \(rounded.lng, specifier: "%.3f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(NSLocalizedString("share_accuracy", comment: ""))
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text(NSLocalizedString("share_getting_location", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Success state
                    if shared {
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.tealAccent)
                            Text(NSLocalizedString("share_owner_notified", comment: ""))
                                .font(.headline)
                            Text(NSLocalizedString("share_on_their_way", comment: ""))
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    } else {
                        // Share button
                        Button(action: submitLocation) {
                            if isSharing {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text(NSLocalizedString("share_notifying", comment: ""))
                                        .foregroundColor(.white)
                                }
                            } else {
                                Label(
                                    NSLocalizedString("share_notify_with_location", comment: ""),
                                    systemImage: "location.fill"
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonDisabled ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(buttonDisabled)
                        .padding(.horizontal)
                    }

                    // Privacy note
                    Text(NSLocalizedString("share_privacy_note", comment: ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle(Text(String(format: NSLocalizedString("share_found_pet %@", comment: ""), petName)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                locationManager.requestLocation()
            }
        }
    }

    // MARK: - Computed Properties

    private var buttonDisabled: Bool {
        if isSharing { return true }
        if locationManager.location == nil { return true }
        return false
    }

    // MARK: - Actions

    private func submitLocation() {
        isSharing = true
        errorMessage = nil

        Task {
            do {
                guard let location = locationManager.location else {
                    await MainActor.run {
                        errorMessage = NSLocalizedString("share_location_unavailable", comment: "Location not available. Please ensure location services are enabled.")
                        isSharing = false
                    }
                    return
                }

                let locationData: LocationConsentData

                if shareExactLocation {
                    locationData = LocationConsentData(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        accuracy_meters: locationManager.accuracy ?? 10,
                        is_approximate: false,
                        consent_type: .precise,
                        share_exact_location: true
                    )
                } else {
                    let rounded = roundToApproximate(lat: location.latitude, lng: location.longitude)
                    locationData = LocationConsentData(
                        latitude: rounded.lat,
                        longitude: rounded.lng,
                        accuracy_meters: locationManager.accuracy ?? 500,
                        is_approximate: true,
                        consent_type: .approximate,
                        share_exact_location: false
                    )
                }

                _ = try await APIService.shared.shareLocation(
                    qrCode: qrCode,
                    location: locationData,
                    address: nil
                )

                await MainActor.run {
                    shared = true
                    isSharing = false
                    // Auto-dismiss after 2.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    #if DEBUG
                    print("Error sharing location: \(error)")
                    #endif
                    errorMessage = error.localizedDescription
                    isSharing = false
                }
            }
        }
    }

    // MARK: - Helpers

    private func roundToApproximate(lat: Double, lng: Double) -> (lat: Double, lng: Double) {
        // Round to 3 decimal places (~111m precision at equator)
        return (
            lat: (lat * 1000).rounded() / 1000,
            lng: (lng * 1000).rounded() / 1000
        )
    }
}

// MARK: - Preview

#Preview {
    ShareLocationView(qrCode: "TEST123", petName: "Buddy")
}
