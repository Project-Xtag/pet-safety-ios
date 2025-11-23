import SwiftUI
import CoreLocation

struct AlertsTabView: View {
    @StateObject private var viewModel = AlertsViewModel()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showAddressRequiredMessage = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                Picker("Alerts Type", selection: $selectedTab) {
                    Text("Missing").tag(0)
                    Text("Found").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Tab Content
                if showAddressRequiredMessage {
                    AddressRequiredView()
                } else {
                    TabView(selection: $selectedTab) {
                        MissingAlertsView(viewModel: viewModel)
                            .tag(0)

                        FoundAlertsView(viewModel: viewModel)
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Nearby Alerts")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadNearbyAlerts()
            }
            .refreshable {
                await loadNearbyAlerts()
            }
        }
    }

    // MARK: - Helper Methods

    /// Load nearby alerts using device location or registered address
    private func loadNearbyAlerts() async {
        // First, try to get device location
        locationManager.requestLocation()

        // Wait a bit for location to be obtained
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        if let location = locationManager.location {
            // Use device location
            showAddressRequiredMessage = false
            await viewModel.fetchNearbyAlerts(
                latitude: location.latitude,
                longitude: location.longitude,
                radiusKm: 10
            )
        } else if let user = authViewModel.currentUser,
                  let addressCoordinate = await geocodeUserAddress(user: user) {
            // Use registered address
            showAddressRequiredMessage = false
            await viewModel.fetchNearbyAlerts(
                latitude: addressCoordinate.latitude,
                longitude: addressCoordinate.longitude,
                radiusKm: 10
            )
        } else {
            // No location available - show message to complete registration
            showAddressRequiredMessage = true
        }
    }

    /// Geocode user's registered address to coordinates
    private func geocodeUserAddress(user: User) async -> CLLocationCoordinate2D? {
        // Build address string from user's registered address
        let addressComponents = [
            user.address,
            user.city,
            user.postalCode,
            user.country
        ].compactMap { $0 }.filter { !$0.isEmpty }

        guard !addressComponents.isEmpty else {
            return nil
        }

        let addressString = addressComponents.joined(separator: ", ")

        // Use CLGeocoder to convert address to coordinates
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(addressString)

            if let location = placemarks.first?.location {
                return location.coordinate
            }
        } catch {
            print("Geocoding failed: \(error.localizedDescription)")
        }

        return nil
    }
}

// MARK: - Address Required View
struct AddressRequiredView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.slash.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            VStack(spacing: 12) {
                Text("Location Required")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("To view nearby alerts, we need to know your location")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                        Text("Enable location services in Settings")
                            .font(.subheadline)
                    }

                    Text("OR")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 12) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.blue)
                        Text("Add your registered address in Profile")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal, 32)

                NavigationLink(destination: AddressView()) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Add My Address")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    AlertsTabView()
        .environmentObject(AuthViewModel())
}
