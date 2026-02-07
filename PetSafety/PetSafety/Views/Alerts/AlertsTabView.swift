import SwiftUI
import CoreLocation

struct AlertsTabView: View {
    @StateObject private var viewModel = AlertsViewModel()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedViewMode = 0
    @State private var showAddressRequiredMessage = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Content
                    VStack(spacing: 20) {
                        // View Mode Segmented Control (List / Map)
                        segmentedControl(
                            options: ["List", "Map"],
                            selection: $selectedViewMode
                        )
                        .padding(.horizontal, 24)

                        // Content Area
                        if showAddressRequiredMessage {
                            AddressRequiredView()
                        } else {
                            contentView
                        }
                    }
                    .padding(.top, 24)
                }
            }
            .navigationBarHidden(true)
            .task {
                await loadNearbyAlerts()
            }
            .refreshable {
                await loadNearbyAlerts()
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Missing Pets")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.peachBackground)
    }

    // MARK: - Segmented Control
    private func segmentedControl(options: [String], selection: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection.wrappedValue = index
                    }
                }) {
                    Text(options[index])
                        .font(.system(size: 14, weight: selection.wrappedValue == index ? .bold : .medium))
                        .foregroundColor(selection.wrappedValue == index ? .white : .mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selection.wrappedValue == index
                                ? Color.brandOrange
                                : Color.clear
                        )
                        .cornerRadius(14)
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.05))
        .cornerRadius(18)
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if selectedViewMode == 0 {
            // List View - Only show missing alerts
            MissingAlertsView(viewModel: viewModel)
        } else {
            // Map View - real MapKit map
            MissingAlertsMapView(
                alerts: viewModel.missingAlerts,
                userLocation: locationManager.location
            )
        }
    }

    // MARK: - Helper Methods
    private func loadNearbyAlerts() async {
        // Request location
        locationManager.requestLocation()

        // Wait for location with retries (up to 5 seconds total)
        var attempts = 0
        let maxAttempts = 10
        while locationManager.location == nil && attempts < maxAttempts {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            attempts += 1
        }

        if let location = locationManager.location {
            showAddressRequiredMessage = false
            await viewModel.fetchNearbyAlerts(
                latitude: location.latitude,
                longitude: location.longitude,
                radiusKm: 10
            )
        } else if let user = authViewModel.currentUser,
                  let addressCoordinate = await geocodeUserAddress(user: user) {
            showAddressRequiredMessage = false
            await viewModel.fetchNearbyAlerts(
                latitude: addressCoordinate.latitude,
                longitude: addressCoordinate.longitude,
                radiusKm: 10
            )
        } else {
            showAddressRequiredMessage = true
        }
    }

    private func geocodeUserAddress(user: User) async -> CLLocationCoordinate2D? {
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


// MARK: - Empty Alerts State
struct EmptyAlertsStateView: View {
    let alertType: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.tealAccent)
            }

            VStack(spacing: 8) {
                Text("No \(alertType) Pets Nearby")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text("There are no active \(alertType.lowercased()) pet alerts within 10km of your location")
                    .font(.system(size: 14))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Address Required View
struct AddressRequiredView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.brandOrange.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "location.slash.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.brandOrange)
            }

            VStack(spacing: 12) {
                Text("Location Required")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text("To view nearby alerts, we need to know your location")
                    .font(.system(size: 15))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.tealAccent.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Text("1")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.tealAccent)
                        }
                        Text("Enable location services in Settings")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }

                    Text("OR")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.mutedText)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.tealAccent.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Text("2")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.tealAccent)
                        }
                        Text("Add your registered address in Profile")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 32)

                NavigationLink(destination: AddressView()) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Add My Address")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(BrandButtonStyle())
                .padding(.horizontal, 48)
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AlertsTabView()
        .environmentObject(AuthViewModel())
}
