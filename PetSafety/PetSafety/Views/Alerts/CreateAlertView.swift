import SwiftUI
import MapKit
import UIKit

struct CreateAlertView: View {
    @StateObject private var viewModel = AlertsViewModel()
    @StateObject private var petsViewModel = PetsViewModel()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var selectedPet: Pet?
    @State private var location = ""
    @State private var additionalInfo = ""
    @State private var rewardAmount: String = ""
    @State private var useCurrentLocation = false

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

            Section(header: Text("last_seen_location_header")) {
                Toggle("use_current_location", isOn: $useCurrentLocation)

                if !useCurrentLocation {
                    TextField(String(localized: "enter_location"), text: $location)
                } else if let coordinate = locationManager.location {
                    Text("Lat: \(String(format: "%.6f", coordinate.latitude)), Lon: \(String(format: "%.6f", coordinate.longitude))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("additional_information_header")) {
                TextEditor(text: $additionalInfo)
                    .frame(minHeight: 100)
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
                HStack {
                    Text("€")
                        .foregroundColor(.secondary)
                    TextField(String(localized: "create_alert_reward_placeholder"), text: $rewardAmount)
                        .keyboardType(.decimalPad)
                }
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
                    additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo,
                    rewardAmount: Double(rewardAmount)
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
    }
}
