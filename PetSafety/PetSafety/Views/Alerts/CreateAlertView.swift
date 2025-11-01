import SwiftUI
import MapKit

struct CreateAlertView: View {
    @StateObject private var viewModel = AlertsViewModel()
    @StateObject private var petsViewModel = PetsViewModel()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var selectedPet: Pet?
    @State private var location = ""
    @State private var additionalInfo = ""
    @State private var useCurrentLocation = false

    var body: some View {
        Form {
            Section("Select Pet") {
                if petsViewModel.pets.isEmpty {
                    Text("No pets available. Please add a pet first.")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Pet", selection: $selectedPet) {
                        Text("Select a pet").tag(nil as Pet?)
                        ForEach(petsViewModel.pets) { pet in
                            Text(pet.name).tag(pet as Pet?)
                        }
                    }
                }
            }

            Section("Last Seen Location") {
                Toggle("Use Current Location", isOn: $useCurrentLocation)

                if !useCurrentLocation {
                    TextField("Enter location", text: $location)
                } else if let coordinate = locationManager.location {
                    Text("Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Additional Information") {
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
        }
        .navigationTitle("Report Missing Pet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Create Alert") {
                    createAlert()
                }
                .disabled(selectedPet == nil || viewModel.isLoading)
            }
        }
        .task {
            await petsViewModel.fetchPets()
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

    private func createAlert() {
        guard let pet = selectedPet else { return }

        Task {
            do {
                let coordinate = useCurrentLocation ? locationManager.location : nil
                let locationText = useCurrentLocation ? nil : (location.isEmpty ? nil : location)

                try await viewModel.createAlert(
                    petId: pet.id,
                    location: locationText,
                    coordinate: coordinate,
                    additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo
                )

                appState.showSuccess("Missing pet alert created successfully!")
                dismiss()
            } catch {
                appState.showError(error.localizedDescription)
            }
        }
    }
}

// Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

#Preview {
    NavigationView {
        CreateAlertView()
            .environmentObject(AppState())
    }
}
