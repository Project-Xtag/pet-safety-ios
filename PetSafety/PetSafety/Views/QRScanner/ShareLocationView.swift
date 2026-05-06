import SwiftUI
import CoreLocation

/// Share-Location sheet (post 2026-05-02 missing-pet flow overhaul).
///
/// The precision toggle is gone — finders can either share their precise
/// GPS fix (default path) or fall back to typing an address as free text
/// when GPS is denied / unavailable. The backend geocodes manual addresses
/// server-side; on geocoding failure the owner gets the typed text with a
/// "no map coordinates" note rather than nothing.
///
/// `Decline to share` is no longer offered. The whole reason this sheet
/// exists is for the finder to help the owner; opening it is consent.
struct ShareLocationView: View {
    let qrCode: String
    let petName: String

    @StateObject private var locationManager = LocationManager()
    @State private var manualAddress: String = ""
    @State private var showManualAddress = false
    @State private var isSharing = false
    @State private var shared = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    locationDisplay

                    if let error = errorMessage {
                        Text(error)
                            .font(.appFont(.caption))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if shared {
                        successState
                    } else {
                        primaryAction
                        if !showManualAddress {
                            Button(action: { showManualAddress = true }) {
                                Text(NSLocalizedString("share_address_instead", comment: ""))
                                    .font(.appFont(.subheadline))
                            }
                            .padding(.top, 4)
                        } else {
                            manualAddressBlock
                        }
                    }

                    Text(NSLocalizedString("share_privacy_note", comment: ""))
                        .font(.appFont(.caption2))
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
                    Button("done") { dismiss() }
                }
            }
            .onAppear { locationManager.requestLocation() }
        }
    }

    // MARK: - View pieces

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.circle.fill")
                .font(.appFont(size: 60))
                .foregroundColor(.blue)

            Text(String(format: NSLocalizedString("share_help_get_home %@", comment: ""), petName))
                .font(.appFont(.title2))
                .bold()

            Text(NSLocalizedString("share_location_subtitle", comment: ""))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var locationDisplay: some View {
        if let location = locationManager.location {
            VStack(spacing: 8) {
                Text(NSLocalizedString("share_your_location", comment: ""))
                    .font(.appFont(.headline))
                Text(String(
                    format: NSLocalizedString("coordinates_display", comment: ""),
                    String(format: "%.6f", location.latitude),
                    String(format: "%.6f", location.longitude)
                ))
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        } else if !showManualAddress {
            VStack(spacing: 8) {
                ProgressView()
                Text(NSLocalizedString("share_getting_location", comment: ""))
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    private var successState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.appFont(size: 50))
                .foregroundColor(.tealAccent)
            Text(NSLocalizedString("share_owner_notified", comment: ""))
                .font(.appFont(.headline))
            Text(NSLocalizedString("share_on_their_way", comment: ""))
        }
        .foregroundColor(.secondary)
        .padding()
    }

    private var primaryAction: some View {
        Button(action: submitGPSLocation) {
            if isSharing {
                HStack {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
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
        .background(gpsButtonDisabled ? Color.gray : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .disabled(gpsButtonDisabled)
        .padding(.horizontal)
    }

    private var manualAddressBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("share_manual_address_title", comment: ""))
                .font(.appFont(.headline))
            Text(NSLocalizedString("share_manual_address_desc", comment: ""))
                .font(.appFont(.caption))
                .foregroundColor(.secondary)

            // SwiftUI's TextEditor has no native placeholder, so overlay the
            // hint text behind the field and hide it once the user starts
            // typing. Allow taps through (allowsHitTesting false) so the
            // placeholder doesn't intercept the editor's tap target.
            ZStack(alignment: .topLeading) {
                if manualAddress.isEmpty {
                    Text(NSLocalizedString("share_manual_address_placeholder", comment: ""))
                        .font(.appFont(.body))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $manualAddress)
                    .frame(minHeight: 80)
                    .opacity(manualAddress.isEmpty ? 0.95 : 1)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            Button(action: submitManualAddress) {
                if isSharing {
                    HStack {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text(NSLocalizedString("share_notifying", comment: ""))
                            .foregroundColor(.white)
                    }
                } else {
                    Text(NSLocalizedString("share_notify_with_location", comment: ""))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(manualButtonDisabled ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(manualButtonDisabled)
        }
        .padding(.horizontal)
    }

    // MARK: - Computed Properties

    private var gpsButtonDisabled: Bool {
        if isSharing { return true }
        if locationManager.location == nil { return true }
        return false
    }

    private var manualButtonDisabled: Bool {
        if isSharing { return true }
        return manualAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    private func submitGPSLocation() {
        isSharing = true
        errorMessage = nil

        Task {
            do {
                guard let location = locationManager.location else {
                    await MainActor.run {
                        errorMessage = NSLocalizedString("share_location_unavailable", comment: "")
                        isSharing = false
                    }
                    return
                }

                let payload = LocationConsentData(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    accuracy_meters: locationManager.accuracy ?? 10
                )

                _ = try await APIService.shared.shareLocation(
                    qrCode: qrCode,
                    location: payload
                )

                await MainActor.run {
                    shared = true
                    isSharing = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { dismiss() }
                }
            } catch {
                await MainActor.run {
                    #if DEBUG
                    print("Error sharing GPS location: \(error)")
                    #endif
                    errorMessage = error.localizedDescription
                    isSharing = false
                }
            }
        }
    }

    private func submitManualAddress() {
        let trimmed = manualAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSharing = true
        errorMessage = nil

        Task {
            do {
                _ = try await APIService.shared.shareLocation(
                    qrCode: qrCode,
                    manualAddress: trimmed
                )

                await MainActor.run {
                    shared = true
                    isSharing = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { dismiss() }
                }
            } catch {
                await MainActor.run {
                    #if DEBUG
                    print("Error sharing manual address: \(error)")
                    #endif
                    errorMessage = error.localizedDescription
                    isSharing = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ShareLocationView(qrCode: "TEST123", petName: "Buddy")
}
