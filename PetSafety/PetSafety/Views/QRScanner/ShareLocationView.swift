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
            case .decline: return "Don't Share"
            case .approximate: return "Approximate Area"
            case .precise: return "Exact Location"
            }
        }

        var description: String {
            switch self {
            case .decline: return "The owner will only know their tag was scanned"
            case .approximate: return "Share your area (~500m accuracy)"
            case .precise: return "Share your exact GPS coordinates"
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

                        Text("Help \(petName) Get Home")
                            .font(.title2)
                            .bold()

                        Text("Choose how much location info to share with the owner")
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
                                Text("Your Location")
                                    .font(.headline)

                                if selectedConsent == .approximate {
                                    let rounded = roundToApproximate(lat: location.latitude, lng: location.longitude)
                                    Text("Lat: \(rounded.lat, specifier: "%.3f"), Lng: \(rounded.lng, specifier: "%.3f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("(~500m accuracy)")
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
                                Text("Getting your location...")
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
                            Text("Owner Notified!")
                                .font(.headline)
                            if selectedConsent == .decline {
                                Text("They know their pet's tag was scanned")
                            } else {
                                Text("They're on their way!")
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
                                    Text("Notifying Owner...")
                                        .foregroundColor(.white)
                                }
                            } else {
                                Label(
                                    selectedConsent == .decline ? "Notify Owner (No Location)" : "Share & Notify Owner",
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
                    Text("Your location data is only shared with the pet owner and is not stored permanently.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Found \(petName)!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
