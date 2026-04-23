import SwiftUI
import CoreLocation
import UIKit

struct ReportSightingView: View {
    let alertId: String

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var alertsViewModel: AlertsViewModel
    @StateObject private var locationManager = LocationManager()

    @Environment(\.dismiss) private var dismiss

    @State private var reporterName = ""
    @State private var reporterPhone = ""
    @State private var reporterEmail = ""
    @State private var locationText = ""
    @State private var notes = ""
    @State private var useCurrentLocation = false
    @State private var isSubmitting = false
    @State private var shareContactInfo = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.brandOrange.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "eye.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.brandOrange)
                    }

                    Text("report_sighting_header")
                        .font(.system(size: 22, weight: .bold))

                    Text("report_sighting_help")
                        .font(.system(size: 14))
                        .foregroundColor(.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 8)

                // Contact Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $shareContactInfo) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("share_contact_info")
                                .font(.system(size: 15, weight: .semibold))
                            Text("share_contact_info_desc")
                                .font(.system(size: 12))
                                .foregroundColor(.mutedText)
                        }
                    }
                    .tint(.brandOrange)

                    if shareContactInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Image(systemName: "person")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)
                                TextField(String(localized: "your_name"), text: $reporterName)
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("phone")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Image(systemName: "phone")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)
                                TextField(String(localized: "your_phone_number"), text: $reporterPhone)
                                    .textContentType(.telephoneNumber)
                                    .keyboardType(.phonePad)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("email")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)
                                TextField(String(localized: "your_email"), text: $reporterEmail)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Location Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("sighting_location")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Toggle(isOn: $useCurrentLocation) {
                        Label("use_current_location", systemImage: "location.fill")
                            .font(.system(size: 15))
                    }
                    .tint(.brandOrange)
                    .onChange(of: useCurrentLocation) { _, isOn in
                        if isOn {
                            locationManager.requestLocation()
                        }
                    }

                    if useCurrentLocation {
                        if locationManager.location != nil {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.tealAccent)
                                Text("location_captured")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("getting_location")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("address_or_description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Image(systemName: "mappin")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)
                                TextField(String(localized: "where_did_you_see"), text: $locationText)
                                    .autocapitalization(.sentences)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Notes Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("additional_details")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("sighting_notes_placeholder")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Submit Button
                Button(action: submitSighting) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("submit_sighting_report")
                    }
                }
                .buttonStyle(BrandButtonStyle(isDisabled: !canSubmit))
                .disabled(!canSubmit || isSubmitting)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationTitle(Text("report_sighting"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("cancel") {
                    dismiss()
                }
                .foregroundColor(.brandOrange)
            }
        }
    }

    private var canSubmit: Bool {
        // Need either GPS location or manual text location
        if useCurrentLocation {
            return locationManager.location != nil
        }
        return !locationText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submitSighting() {
        // Validate phone if provided (format, not just length). A pure
        // length gate used to accept "not-a-phone-14" because it's
        // 14 chars; the InputValidators regex rejects non-phone shapes
        // before they hit the backend normalizer.
        if shareContactInfo, !reporterPhone.isEmpty {
            let trimmedPhone = reporterPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            if !InputValidators.isValidPhone(trimmedPhone) {
                appState.showError(NSLocalizedString("sighting_phone_invalid", comment: ""))
                return
            }
        }

        isSubmitting = true

        let trimmedAddress = locationText.trimmingCharacters(in: .whitespaces)
        let initialCoordinate = useCurrentLocation ? locationManager.location : nil
        let initialAddress = useCurrentLocation ? nil : trimmedAddress

        Task {
            do {
                // Backend requires coordinates — geocode the typed address when GPS wasn't used
                var coordinate = initialCoordinate
                if coordinate == nil, let addr = initialAddress, !addr.isEmpty {
                    coordinate = await geocode(addr)
                    if coordinate == nil {
                        await MainActor.run {
                            appState.showError(String(localized: "sighting_address_not_found"))
                            isSubmitting = false
                        }
                        return
                    }
                }

                guard let finalCoord = coordinate else {
                    await MainActor.run {
                        appState.showError(String(localized: "sighting_location_required"))
                        isSubmitting = false
                    }
                    return
                }

                // Range + null-island guard on the resolved coordinate.
                // A geocoder that returns (0,0) or NaN would otherwise
                // post a Gulf-of-Guinea sighting that misroutes every
                // downstream proximity notification.
                guard InputValidators.isValidCoordinate(latitude: finalCoord.latitude, longitude: finalCoord.longitude) else {
                    await MainActor.run {
                        appState.showError(String(localized: "sighting_location_invalid"))
                        isSubmitting = false
                    }
                    return
                }

                try await alertsViewModel.reportSighting(
                    alertId: alertId,
                    reporterName: shareContactInfo && !reporterName.isEmpty ? reporterName : nil,
                    reporterPhone: shareContactInfo && !reporterPhone.isEmpty ? reporterPhone : nil,
                    reporterEmail: shareContactInfo && !reporterEmail.isEmpty ? reporterEmail : nil,
                    location: initialAddress,
                    coordinate: finalCoord,
                    notes: notes.isEmpty ? nil : notes
                )
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                appState.showSuccess(String(localized: "sighting_reported_owner_notified"))
                dismiss()
            } catch {
                let message = error.localizedDescription
                if message.contains("Queued for sync") {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    appState.showSuccess(String(localized: "sighting_queued_offline"))
                    dismiss()
                } else {
                    appState.showError(message)
                }
            }
            isSubmitting = false
        }
    }

    private func geocode(_ address: String) async -> CLLocationCoordinate2D? {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            return placemarks.first?.location?.coordinate
        } catch {
            #if DEBUG
            print("⚠️ Geocoding failed for '\(address)': \(error.localizedDescription)")
            #endif
            return nil
        }
    }
}
