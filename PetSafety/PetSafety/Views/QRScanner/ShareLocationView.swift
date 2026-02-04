import SwiftUI
import CoreLocation

/**
 * Share Location View with 3-Tier GDPR Location Consent
 *
 * Allows finders to choose their privacy level when sharing location:
 * - Decline: Don't share location (owner just knows tag was scanned)
 * - Approximate: Share ~500m area (coordinates rounded)
 * - Precise: Share exact GPS location
 */

struct ShareLocationView: View {
    let qrCode: String
    let petName: String

    @StateObject private var locationManager = LocationManager()
    @State private var isSharing = false
    @State private var shared = false
    @State private var errorMessage: String?
    @State private var selectedConsent: LocationConsent = .precise
    @Environment(\.dismiss) var dismiss

    enum LocationConsent: String, CaseIterable {
        case decline = "decline"
        case approximate = "approximate"
        case precise = "precise"

        var title: String {
            switch self {
            case .decline: return NSLocalizedString("share_dont_share", comment: "")
            case .approximate: return NSLocalizedString("share_approximate", comment: "")
            case .precise: return NSLocalizedString("share_exact", comment: "")
            }
        }

        var description: String {
            switch self {
            case .decline: return NSLocalizedString("share_dont_share_desc", comment: "")
            case .approximate: return NSLocalizedString("share_approximate_desc", comment: "")
            case .precise: return NSLocalizedString("share_exact_desc", comment: "")
            }
        }

        var icon: String {
            switch self {
            case .decline: return "location.slash"
            case .approximate: return "location.circle"
            case .precise: return "location.fill"
            }
        }
    }

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

                        Text("share_choose_desc")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    // Location consent options
                    VStack(spacing: 12) {
                        ForEach(LocationConsent.allCases, id: \.self) { consent in
                            ConsentOptionCard(
                                consent: consent,
                                isSelected: selectedConsent == consent,
                                action: { selectedConsent = consent }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Current location display (when precise or approximate selected)
                    if selectedConsent != .decline {
                        if let location = locationManager.location {
                            VStack(spacing: 8) {
                                Text("share_your_location")
                                    .font(.headline)

                                if selectedConsent == .approximate {
                                    let rounded = roundToApproximate(lat: location.latitude, lng: location.longitude)
                                    Text("Lat: \(rounded.lat, specifier: "%.3f"), Lng: \(rounded.lng, specifier: "%.3f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("share_accuracy")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                } else {
                                    Text("Lat: \(location.latitude, specifier: "%.6f"), Lng: \(location.longitude, specifier: "%.6f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        } else {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("share_getting_location")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
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
                                .foregroundColor(.green)
                            Text("share_owner_notified")
                                .font(.headline)
                            if selectedConsent == .decline {
                                Text("share_owner_knows")
                            } else {
                                Text("share_on_their_way")
                            }
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    } else {
                        // Submit button
                        Button(action: submitLocation) {
                            if isSharing {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("share_notifying")
                                        .foregroundColor(.white)
                                }
                            } else {
                                Label(
                                    selectedConsent == .decline ? NSLocalizedString("share_notify_no_location", comment: "") : NSLocalizedString("share_notify_with_location", comment: ""),
                                    systemImage: selectedConsent == .decline ? "bell.fill" : "location.fill"
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
                    Text("share_privacy_note")
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
        if selectedConsent != .decline && locationManager.location == nil { return true }
        return false
    }

    // MARK: - Actions

    private func submitLocation() {
        isSharing = true
        errorMessage = nil

        Task {
            do {
                var locationData: LocationConsentData?

                if selectedConsent != .decline, let location = locationManager.location {
                    switch selectedConsent {
                    case .approximate:
                        let rounded = roundToApproximate(lat: location.latitude, lng: location.longitude)
                        locationData = LocationConsentData(
                            latitude: rounded.lat,
                            longitude: rounded.lng,
                            accuracy_meters: locationManager.accuracy ?? 500,
                            is_approximate: true,
                            consent_type: .approximate
                        )
                    case .precise:
                        locationData = LocationConsentData(
                            latitude: location.latitude,
                            longitude: location.longitude,
                            accuracy_meters: locationManager.accuracy ?? 10,
                            is_approximate: false,
                            consent_type: .precise
                        )
                    case .decline:
                        break
                    }
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
                    print("Error sharing location: \(error)")
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

// MARK: - Consent Option Card

struct ConsentOptionCard: View {
    let consent: ShareLocationView.LocationConsent
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: consent.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(consent.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(consent.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ShareLocationView(qrCode: "TEST123", petName: "Buddy")
}
