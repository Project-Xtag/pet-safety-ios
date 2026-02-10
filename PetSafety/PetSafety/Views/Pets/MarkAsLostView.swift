import SwiftUI
import MapKit
import CoreLocation
import UIKit

enum LastSeenSource: String, CaseIterable {
    case currentLocation = "current_location"
    case registeredAddress = "registered_address"
    case customAddress = "custom_address"

    var displayName: String {
        switch self {
        case .currentLocation: return String(localized: "location_current")
        case .registeredAddress: return String(localized: "location_my_address")
        case .customAddress: return String(localized: "location_custom")
        }
    }
}

struct MarkAsLostView: View {
    let pet: Pet
    @StateObject private var petsViewModel = PetsViewModel()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var lastSeenSource: LastSeenSource = .registeredAddress
    @State private var customAddress = ""
    @State private var additionalInfo = ""
    @State private var isGeocoding = false

    /// Formatted registered address from user profile
    private var registeredAddress: String? {
        guard let user = authViewModel.currentUser else { return nil }
        let parts = [user.address, user.addressLine2, user.city, user.postalCode, user.country]
        let address = parts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        return address.isEmpty ? nil : address
    }

    var body: some View {
        Form {
            Section(header: Text("mark_lost_pet_info")) {
                HStack {
                    if let imageUrl = pet.profileImage {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    }

                    VStack(alignment: .leading) {
                        Text(pet.name)
                            .font(.headline)
                        Text(pet.species)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("mark_lost_last_seen"),
                    footer: Text("mark_lost_alerts_footer")) {
                Picker("Location", selection: $lastSeenSource) {
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
                            Text("Lat: \(String(format: "%.6f", loc.latitude)), Lng: \(String(format: "%.6f", loc.longitude))")
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
                }
            }

            Section(header: Text("mark_lost_additional_info")) {
                TextEditor(text: $additionalInfo)
                    .frame(minHeight: 100)
                    .overlay(alignment: .topLeading) {
                        if additionalInfo.isEmpty {
                            Text("mark_lost_additional_placeholder")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            }

            Section {
                Text("mark_lost_sends_to")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Label(String(localized: "mark_lost_nearby_owners"), systemImage: "person.3.fill")
                    Label(String(localized: "mark_lost_vet_clinics"), systemImage: "cross.case.fill")
                    Label(String(localized: "mark_lost_shelters"), systemImage: "house.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Section {
                Button(action: reportMissing) {
                    HStack {
                        Spacer()
                        if petsViewModel.isLoading || isGeocoding {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("mark_lost_report")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(isReportDisabled ? Color.gray.opacity(0.3) : Color.brandOrange)
                .foregroundColor(.white)
                .disabled(isReportDisabled)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .adaptiveList()
        .navigationTitle("mark_lost_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("cancel") {
                    dismiss()
                }
                .foregroundColor(.brandOrange)
            }
        }
        .task {
            locationManager.requestLocation()
        }
        .onChange(of: lastSeenSource) { _, source in
            if source == .currentLocation {
                locationManager.requestLocation()
            }
        }
    }

    private var isReportDisabled: Bool {
        if petsViewModel.isLoading || isGeocoding { return true }
        switch lastSeenSource {
        case .currentLocation:
            return locationManager.location == nil
        case .registeredAddress:
            return registeredAddress == nil
        case .customAddress:
            return customAddress.isEmpty
        }
    }

    private func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
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

    private func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
            if let placemark = placemarks.first {
                let parts = [placemark.name, placemark.locality, placemark.administrativeArea, placemark.country]
                return parts.compactMap { $0 }.joined(separator: ", ")
            }
            return nil
        } catch {
            #if DEBUG
            print("⚠️ Reverse geocoding failed: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    private func reportMissing() {
        Task {
            do {
                isGeocoding = true
                var coordinate: LocationCoordinate? = nil
                var addressText: String? = nil
                let notificationSource = lastSeenSource.rawValue
                var notificationLocation: LocationCoordinate? = nil
                var notificationAddress: String? = nil

                switch lastSeenSource {
                case .currentLocation:
                    if let loc = locationManager.location {
                        let coord = LocationCoordinate(lat: loc.latitude, lng: loc.longitude)
                        coordinate = coord
                        notificationLocation = coord
                        // Reverse-geocode to get address text for the backend
                        let clCoord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                        addressText = await reverseGeocodeLocation(clCoord) ?? "Current location"
                        notificationAddress = addressText
                    }
                case .registeredAddress:
                    addressText = registeredAddress
                    notificationAddress = registeredAddress
                    // Geocode address to get coordinates for alert creation
                    if let address = registeredAddress,
                       let geo = await geocodeAddress(address) {
                        let coord = LocationCoordinate(lat: geo.latitude, lng: geo.longitude)
                        coordinate = coord
                        notificationLocation = coord
                    }
                case .customAddress:
                    let addr = customAddress.isEmpty ? nil : customAddress
                    addressText = addr
                    notificationAddress = addr
                    // Geocode custom address to get coordinates for alert creation
                    if let address = addr,
                       let geo = await geocodeAddress(address) {
                        let coord = LocationCoordinate(lat: geo.latitude, lng: geo.longitude)
                        coordinate = coord
                        notificationLocation = coord
                    }
                }
                isGeocoding = false

                let response = try await petsViewModel.markPetMissing(
                    petId: pet.id,
                    location: coordinate,
                    address: addressText,
                    description: additionalInfo.isEmpty ? nil : additionalInfo,
                    notificationCenterSource: notificationSource,
                    notificationCenterLocation: notificationLocation,
                    notificationCenterAddress: notificationAddress
                )

                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                if response.alert != nil {
                    appState.showSuccess("\(pet.name) has been reported as missing. Alerts are being sent to nearby users, vets, and shelters.")
                } else {
                    appState.showSuccess("\(pet.name) has been marked as missing. Add location to send community alerts.")
                }

                dismiss()
            } catch {
                isGeocoding = false
                appState.showError(error.localizedDescription)
            }
        }
    }
}

#Preview {
    NavigationView {
        MarkAsLostView(pet: Pet(
            id: "1",
            ownerId: "1",
            name: "Max",
            species: "Dog",
            breed: "Golden Retriever",
            color: "Golden",
            weight: 30.0,
            microchipNumber: nil,
            medicalNotes: nil,
            notes: nil,
            profileImage: nil,
            isMissing: false,
            createdAt: "",
            updatedAt: ""
        ))
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
    }
}
