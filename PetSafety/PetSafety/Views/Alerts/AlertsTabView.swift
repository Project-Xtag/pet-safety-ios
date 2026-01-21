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
            // Map View
            AlertsMapView(alerts: viewModel.alerts)
        }
    }

    // MARK: - Helper Methods
    private func loadNearbyAlerts() async {
        locationManager.requestLocation()
        try? await Task.sleep(nanoseconds: 1_000_000_000)

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

// MARK: - Alerts Map View
struct AlertsMapView: View {
    let alerts: [MissingPetAlert]
    @State private var selectedAlert: MissingPetAlert?

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map placeholder with markers
            ZStack {
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()

                // Pet photo markers positioned on map
                ForEach(Array(alerts.prefix(10).enumerated()), id: \.element.id) { index, alert in
                    let positions: [(CGFloat, CGFloat)] = [
                        (0.20, 0.30), (0.35, 0.60), (0.50, 0.25),
                        (0.45, 0.70), (0.65, 0.45), (0.25, 0.80),
                        (0.70, 0.20), (0.55, 0.85), (0.30, 0.15),
                        (0.75, 0.65)
                    ]
                    let pos = positions[index % positions.count]

                    GeometryReader { geometry in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedAlert = alert
                            }
                        }) {
                            AlertMapMarker(alert: alert, isSelected: selectedAlert?.id == alert.id)
                        }
                        .position(
                            x: geometry.size.width * pos.1,
                            y: geometry.size.height * pos.0
                        )
                    }
                }
            }

            // Selected Alert Card
            if let alert = selectedAlert {
                AlertMapCard(alert: alert)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Alert Map Marker
struct AlertMapMarker: View {
    let alert: MissingPetAlert
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Pet Photo in Circle
            if let photoUrl = alert.pet?.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                .frame(width: isSelected ? 60 : 50, height: isSelected ? 60 : 50)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.red, lineWidth: isSelected ? 4 : 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: isSelected ? 60 : 50, height: isSelected ? 60 : 50)
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.red)
                        .font(.system(size: isSelected ? 24 : 20))
                }
                .overlay(
                    Circle()
                        .stroke(Color.red, lineWidth: isSelected ? 4 : 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            // Arrow pointing down
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 12))
                .foregroundColor(.red)
                .offset(y: -6)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Alert Map Card
struct AlertMapCard: View {
    let alert: MissingPetAlert

    var body: some View {
        HStack(spacing: 16) {
            // Pet Photo
            if let photoUrl = alert.pet?.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.white)
                        .padding(15)
                }
                .frame(width: 70, height: 70)
                .background(Color.red.opacity(0.2))
                .cornerRadius(12)
                .clipped()
            } else {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.red)
                    .padding(15)
                    .frame(width: 70, height: 70)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Pet Name
                Text(alert.pet?.name ?? "Unknown Pet")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Missing Status
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("MISSING")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.red)

                // Location
                if let location = alert.lastSeenLocation {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
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
