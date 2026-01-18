import SwiftUI
import MapKit

struct MissingAlertsView: View {
    @ObservedObject var viewModel: AlertsViewModel
    @State private var viewMode: ViewMode = .list

    enum ViewMode {
        case list, map
    }

    var body: some View {
        VStack(spacing: 0) {
            // Offline indicator at the top
            OfflineIndicator()

            // Segmented Control
            Picker("View Mode", selection: $viewMode) {
                Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                Label("Map", systemImage: "map").tag(ViewMode.map)
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            if viewModel.isLoading {
                ProgressView("Loading alerts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.missingAlerts.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "No Missing Pets Nearby",
                    message: "There are no active missing pet alerts within 10km of your location",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                if viewMode == .list {
                    MissingAlertsListView(alerts: viewModel.missingAlerts)
                } else {
                    MissingAlertsMapView(alerts: viewModel.missingAlerts)
                }
            }
        }
    }
}

// MARK: - List View
struct MissingAlertsListView: View {
    let alerts: [MissingPetAlert]

    var body: some View {
        List(alerts) { alert in
            NavigationLink(destination: AlertDetailView(alert: alert)) {
                MissingAlertRowView(alert: alert)
            }
        }
        .listStyle(.plain)
        .adaptiveList()
    }
}

struct MissingAlertRowView: View {
    let alert: MissingPetAlert

    var body: some View {
        HStack(spacing: 16) {
            // Pet Photo
            if let pet = alert.pet {
                AsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.white)
                        .padding(20)
                }
                .frame(width: 80, height: 80)
                .background(Color.red.opacity(0.2))
                .cornerRadius(12)
                .clipped()
            }

            VStack(alignment: .leading, spacing: 6) {
                // Pet Name
                if let pet = alert.pet {
                    Text(pet.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                // Status Badge
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text("Missing")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)

                // Missing Since
                if let createdAt = alert.createdAt.toDate() {
                    Text("Missing since \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Location
                if let location = alert.lastSeenLocation {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Map View
struct MissingAlertsMapView: View {
    let alerts: [MissingPetAlert]
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var selectedAlert: MissingPetAlert?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition) {
                ForEach(alerts) { alert in
                    let coordinate = alert.coordinate ?? CLLocationCoordinate2D()
                    Annotation("Missing Alert", coordinate: coordinate) {
                        PetMapMarker(alert: alert, isSelected: selectedAlert?.id == alert.id)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedAlert = alert
                                }
                            }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // Selected Alert Card
            if let alert = selectedAlert {
                VStack {
                    Spacer()
                    MissingAlertMapCard(alert: alert)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Center map on first alert or use default location
            var region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            if let firstCoord = alerts.first?.coordinate {
                region.center = firstCoord
            }
            mapPosition = .region(region)
        }
    }
}

struct PetMapMarker: View {
    let alert: MissingPetAlert
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Pet Photo in Circle
            if let pet = alert.pet {
                AsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
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

struct MissingAlertMapCard: View {
    let alert: MissingPetAlert
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationLink(destination: AlertDetailView(alert: alert)) {
            HStack(spacing: 16) {
                // Pet Photo
                if let pet = alert.pet {
                    AsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
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
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Pet Name
                    if let pet = alert.pet {
                        Text(pet.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    // Duration Missing
                    if let createdAt = alert.createdAt.toDate() {
                        let duration = Date().timeIntervalSince(createdAt)
                        Text("Missing for \(duration.formatDuration())")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                    }

                    // Location
                    if let location = alert.lastSeenLocation {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Extensions
extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self) ?? ISO8601DateFormatter().date(from: self)
    }
}

extension TimeInterval {
    func formatDuration() -> String {
        let days = Int(self) / 86400
        let hours = Int(self) / 3600 % 24

        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "Less than an hour"
        }
    }
}

#Preview {
    NavigationView {
        MissingAlertsView(viewModel: AlertsViewModel())
    }
}
