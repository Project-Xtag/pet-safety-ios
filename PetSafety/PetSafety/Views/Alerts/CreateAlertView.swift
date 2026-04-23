import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct CreateAlertView: View {
    @StateObject private var viewModel = AlertsViewModel()
    @StateObject private var petsViewModel = PetsViewModel()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var selectedPet: Pet?
    @State private var lastSeenSource: LastSeenSource = .registeredAddress
    @State private var customAddress = ""
    @State private var additionalInfo = ""
    @State private var rewardAmount: String = ""
    @State private var isGeocoding = false

    /// Formatted registered address from user profile
    private var registeredAddress: String? {
        guard let user = authViewModel.currentUser else { return nil }
        let parts = [user.address, user.addressLine2, user.city, user.postalCode, user.country]
        let address = parts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        return address.isEmpty ? nil : address
    }

    /// Whether the submit button should be disabled
    private var isSubmitDisabled: Bool {
        if selectedPet == nil || viewModel.isLoading || isGeocoding { return true }
        switch lastSeenSource {
        case .currentLocation:
            return locationManager.location == nil
        case .registeredAddress:
            return registeredAddress == nil
        case .customAddress:
            return customAddress.isEmpty
        }
    }

    var body: some View {
        Form {
            Section(header: Text("select_pet_header")) {
                if petsViewModel.pets.isEmpty {
                    Text("no_pets_available")
                        .foregroundColor(.secondary)
                } else {
                    Picker("pet_picker_label", selection: $selectedPet) {
                        Text("select_pet_to_report").tag(nil as Pet?)
                        ForEach(petsViewModel.pets) { pet in
                            Text(pet.name).tag(pet as Pet?)
                        }
                    }
                }
            }

            Section(header: Text("mark_lost_last_seen"),
                    footer: Text("mark_lost_alerts_footer")) {
                Picker(String(localized: "location_label"), selection: $lastSeenSource) {
                    ForEach(LastSeenSource.allCases, id: \.self) { source in
                        Text(source.displayName).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                switch lastSeenSource {
                case .currentLocation:
                    if let loc = locationManager.location {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text(String(format: NSLocalizedString("coordinates_display", comment: ""), String(format: "%.6f", loc.latitude), String(format: "%.6f", loc.longitude)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("mark_lost_getting_location")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                case .registeredAddress:
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.tealAccent)
                        if let address = registeredAddress {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("mark_lost_no_address")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }

                case .customAddress:
                    TextField(String(localized: "mark_lost_address_placeholder"), text: $customAddress)
                        .autocapitalization(.words)
                        .onChange(of: customAddress) { _, new in
                            if new.count > InputValidators.maxLocationText {
                                customAddress = String(new.prefix(InputValidators.maxLocationText))
                            }
                        }
                }
            }

            Section(header: Text("additional_information_header")) {
                TextEditor(text: $additionalInfo)
                    .frame(minHeight: 100)
                    .onChange(of: additionalInfo) { _, new in if new.count > InputValidators.maxAlertDescription { additionalInfo = String(new.prefix(InputValidators.maxAlertDescription)) } }
                    .overlay(alignment: .topLeading) {
                        if additionalInfo.isEmpty {
                            Text("additional_details_placeholder")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            }

            Section(header: Text("create_alert_reward")) {
                TextField(String(localized: "create_alert_reward_placeholder"), text: $rewardAmount)
                    .keyboardType(.decimalPad)
                    .onChange(of: rewardAmount) { _, new in if new.count > InputValidators.maxRewardAmount { rewardAmount = String(new.prefix(InputValidators.maxRewardAmount)) } }
            }
        }
        .adaptiveList()
        .navigationTitle(Text("report_missing_pet"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("cancel") {
                    dismiss()
                }
                .foregroundColor(.brandOrange)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("create_alert") {
                    createAlert()
                }
                .foregroundColor(.brandOrange)
                .disabled(isSubmitDisabled)
            }
        }
        .task {
            await petsViewModel.fetchPets()
        }
        .onChange(of: lastSeenSource) { _, source in
            if source == .currentLocation && locationManager.location == nil {
                locationManager.requestLocation()
            }
        }
        .onAppear {
            // Default to registered address, but if none, switch to current location
            if registeredAddress == nil {
                lastSeenSource = .currentLocation
                locationManager.requestLocation()
            }
        }
    }

    private func createAlert() {
        guard let pet = selectedPet else { return }

        Task {
            do {
                var coordinate: CLLocationCoordinate2D?
                var addressText: String?

                switch lastSeenSource {
                case .currentLocation:
                    coordinate = locationManager.location
                    // Reverse geocode to get address text
                    if let loc = coordinate {
                        isGeocoding = true
                        let geocoder = CLGeocoder()
                        if let placemark = try? await geocoder.reverseGeocodeLocation(CLLocation(latitude: loc.latitude, longitude: loc.longitude)).first {
                            addressText = [placemark.thoroughfare, placemark.subThoroughfare, placemark.locality, placemark.country]
                                .compactMap { $0 }
                                .joined(separator: ", ")
                        }
                        isGeocoding = false
                    }

                case .registeredAddress:
                    addressText = registeredAddress
                    // Forward geocode to get coordinates. try? used to
                    // silently swallow CLGeocoder failures, leaving
                    // `coordinate` nil — the alert was then created
                    // without a location and no user-visible error.
                    if let addr = addressText {
                        isGeocoding = true
                        do {
                            if let placemark = try await CLGeocoder().geocodeAddressString(addr).first,
                               let loc = placemark.location,
                               InputValidators.isValidCoordinate(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude) {
                                coordinate = loc.coordinate
                            }
                        } catch {
                            #if DEBUG
                            print("⚠️ Forward-geocode failed for registered address: \(error)")
                            #endif
                        }
                        isGeocoding = false
                    }

                case .customAddress:
                    addressText = customAddress
                    // Forward geocode to get coordinates
                    if !customAddress.isEmpty {
                        isGeocoding = true
                        do {
                            if let placemark = try await CLGeocoder().geocodeAddressString(customAddress).first,
                               let loc = placemark.location,
                               InputValidators.isValidCoordinate(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude) {
                                coordinate = loc.coordinate
                            }
                        } catch {
                            #if DEBUG
                            print("⚠️ Forward-geocode failed for custom address: \(error)")
                            #endif
                        }
                        isGeocoding = false
                    }
                }

                _ = try await viewModel.createAlert(
                    petId: pet.id,
                    location: addressText,
                    coordinate: coordinate,
                    additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo,
                    rewardAmount: rewardAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : rewardAmount.trimmingCharacters(in: .whitespacesAndNewlines),
                    notificationCenterSource: lastSeenSource.rawValue,
                    notificationCenterLocation: coordinate,
                    notificationCenterAddress: addressText
                )

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                appState.showSuccess(String(localized: "alert_created_success"))
                dismiss()
            } catch {
                let nsError = error as NSError
                if nsError.domain == "Offline" {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    appState.showSuccess(String(localized: "alert_queued_offline"))
                    dismiss()
                } else {
                    appState.showError(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CreateAlertView()
            .environmentObject(AppState())
            .environmentObject(AuthViewModel())
    }
}
