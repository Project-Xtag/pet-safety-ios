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
            Section(header: Text("Select Pet")) {
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

            Section(header: Text("Last Seen Location")) {
                Toggle("Use Current Location", isOn: $useCurrentLocation)

                if !useCurrentLocation {
                    TextField("Enter location", text: $location)
                } else if let coordinate = locationManager.location {
                    Text("Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        }
        .adaptiveList()
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
                Button("Create Alert") {
                    createAlert()
                }
                .foregroundColor(.white)
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

                _ = try await viewModel.createAlert(
                    petId: pet.id,
                    location: locationText,
                    coordinate: coordinate,
                    additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo
                )

                appState.showSuccess("Missing pet alert created successfully!")
                dismiss()
            } catch {
                let nsError = error as NSError
                if nsError.domain == "Offline" {
                    appState.showSuccess("Alert queued. Will sync when online.")
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
    }
}
