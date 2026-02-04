import SwiftUI
import MapKit
import CoreLocation
import UIKit

enum NotificationCenterSource: String, CaseIterable {
    case currentLocation = "current_location"
    case registeredAddress = "registered_address"
    case customAddress = "custom_address"

    var displayName: String {
        switch self {
        case .currentLocation: return "Current Location"
        case .registeredAddress: return "My Address"
        case .customAddress: return "Custom"
        }
    }
}

struct MarkAsLostView: View {
    let pet: Pet
    @StateObject private var petsViewModel = PetsViewModel()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var location = ""
    @State private var additionalInfo = ""
    @State private var useCurrentLocation = false

    // Notification center fields
    @State private var notificationCenterSource: NotificationCenterSource = .registeredAddress
    @State private var customNotificationAddress = ""
    @State private var isGeocodingAddress = false

    var body: some View {
        Form {
            Section(header: Text("Pet Information")) {
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

            Section(header: Text("Last Seen Location"), footer: Text("Enter a street address, neighborhood, or landmark (e.g., 'Central Park, NYC' or '123 Main St, London')")) {
                Toggle("Use Current Location", isOn: $useCurrentLocation)

                if !useCurrentLocation {
                    TextField("e.g., Central Park or 123 Main St", text: $location)
                        .autocapitalization(.words)
                } else if locationManager.location != nil {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text("Using current location")
                            .font(.subheadline)
                    }
                }
            }

            Section(header: Text("Additional Information")) {
                TextEditor(text: $additionalInfo)
                    .frame(minHeight: 100)
                    .overlay(alignment: .topLeading) {
                        if additionalInfo.isEmpty {
                            Text("Provide any additional details about when and where your pet was last seen...")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            }

            Section(header: Text("Notification Center"),
                    footer: Text("Alerts will be sent to users, vets, and shelters within 10km of this location.")) {
                Picker("Send alerts near", selection: $notificationCenterSource) {
                    ForEach(NotificationCenterSource.allCases, id: \.self) { source in
                        Text(source.displayName).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                switch notificationCenterSource {
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
                            Text("Getting location...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                case .registeredAddress:
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.green)
                        Text("Using your registered address")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                case .customAddress:
                    TextField("Enter address for notifications", text: $customNotificationAddress)
                        .autocapitalization(.words)
                    if isGeocodingAddress {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Validating address...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section {
                Text("This will send alerts to:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Nearby pet owners (within 10km)", systemImage: "person.3.fill")
                    Label("Local veterinary clinics", systemImage: "cross.case.fill")
                    Label("Animal shelters", systemImage: "house.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .adaptiveList()
        .navigationTitle("Report Missing Pet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.brandOrange)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Report Missing") {
                    reportMissing()
                }
                .foregroundColor(.brandOrange)
                .disabled(petsViewModel.isLoading || (!useCurrentLocation && location.isEmpty))
            }
        }
        .task {
            // Request location on load for notification center default
            locationManager.requestLocation()
        }
        .onChange(of: useCurrentLocation) { _, isOn in
            if isOn {
                locationManager.requestLocation()
            }
        }
        .onChange(of: notificationCenterSource) { _, source in
            if source == .currentLocation {
                locationManager.requestLocation()
            }
        }
    }

    private func reportMissing() {
        Task {
            do {
                // Build location coordinate from current location
                let coordinate: LocationCoordinate? = if let loc = locationManager.location {
                    LocationCoordinate(lat: loc.latitude, lng: loc.longitude)
                } else {
                    nil
                }

                // Use address text if not using current location
                let addressText = useCurrentLocation ? nil : (location.isEmpty ? nil : location)

                // Build notification center location if using current location
                let notificationCenterLocation: LocationCoordinate? = if notificationCenterSource == .currentLocation,
                   let loc = locationManager.location {
                    LocationCoordinate(lat: loc.latitude, lng: loc.longitude)
                } else {
                    nil
                }

                // Build notification center address if using custom address
                let notificationCenterAddress: String? = if notificationCenterSource == .customAddress {
                    customNotificationAddress.isEmpty ? nil : customNotificationAddress
                } else {
                    nil
                }

                let response = try await petsViewModel.markPetMissing(
                    petId: pet.id,
                    location: coordinate,
                    address: addressText,
                    description: additionalInfo.isEmpty ? nil : additionalInfo,
                    notificationCenterSource: notificationCenterSource.rawValue,
                    notificationCenterLocation: notificationCenterLocation,
                    notificationCenterAddress: notificationCenterAddress
                )

                // Show appropriate success message based on whether alert was created
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                if response.alert != nil {
                    appState.showSuccess("\(pet.name) has been reported as missing. Alerts are being sent to nearby users, vets, and shelters.")
                } else {
                    appState.showSuccess("\(pet.name) has been marked as missing. Add location to send community alerts.")
                }

                dismiss()
            } catch {
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
    }
}
