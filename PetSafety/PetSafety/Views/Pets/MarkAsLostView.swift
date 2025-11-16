import SwiftUI
import MapKit

struct MarkAsLostView: View {
    let pet: Pet
    @StateObject private var alertsViewModel = AlertsViewModel()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var location = ""
    @State private var additionalInfo = ""
    @State private var useCurrentLocation = false

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
                } else if let coordinate = locationManager.location {
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
        .navigationTitle("Report Missing Pet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Report Missing") {
                    reportMissing()
                }
                .foregroundColor(.white)
                .disabled(alertsViewModel.isLoading || (!useCurrentLocation && location.isEmpty))
            }
        }
        .task {
            if useCurrentLocation {
                locationManager.requestLocation()
            }
        }
        .onChange(of: useCurrentLocation) { _, isOn in
            if isOn {
                locationManager.requestLocation()
            }
        }
    }

    private func reportMissing() {
        Task {
            do {
                let coordinate = useCurrentLocation ? locationManager.location : nil
                let locationText = useCurrentLocation ? nil : (location.isEmpty ? nil : location)

                _ = try await alertsViewModel.createAlert(
                    petId: pet.id,
                    location: locationText,
                    coordinate: coordinate,
                    additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo
                )

                appState.showSuccess("\(pet.name) has been reported as missing. Alerts are being sent to nearby users, vets, and shelters.")
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
