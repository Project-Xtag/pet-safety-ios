import SwiftUI
import CoreLocation

struct AlertsTabView: View {
    @StateObject private var viewModel = AlertsViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedTab = 0

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
                TabView(selection: $selectedTab) {
                    MissingAlertsView(viewModel: viewModel)
                        .tag(0)

                    FoundAlertsView(viewModel: viewModel)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Nearby Alerts")
            .navigationBarTitleDisplayMode(.large)
            .task {
                // Request location permission if not granted
                locationManager.requestLocation()

                // Wait a bit for location to be obtained
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                // Fetch nearby alerts using current location or default
                if let location = locationManager.location {
                    await viewModel.fetchNearbyAlerts(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        radiusKm: 10
                    )
                } else {
                    // Use default location if user location not available
                    // TODO: Get user's registered address from profile
                    await viewModel.fetchNearbyAlerts(
                        latitude: 51.5074,  // London default
                        longitude: -0.1278,
                        radiusKm: 10
                    )
                }
            }
            .refreshable {
                if let location = locationManager.location {
                    await viewModel.fetchNearbyAlerts(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        radiusKm: 10
                    )
                }
            }
        }
    }
}

#Preview {
    AlertsTabView()
}
