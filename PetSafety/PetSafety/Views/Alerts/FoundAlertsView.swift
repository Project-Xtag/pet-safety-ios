import SwiftUI
import MapKit

struct FoundAlertsView: View {
    @ObservedObject var viewModel: AlertsViewModel
    @State private var viewMode: ViewMode = .list

    enum ViewMode {
        case list, map
    }

    var body: some View {
        VStack(spacing: 0) {
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
            } else if viewModel.foundAlerts.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "No Found Pets Nearby",
                    message: "There are no recently found pets within 10km of your location",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                if viewMode == .list {
                    FoundAlertsListView(alerts: viewModel.foundAlerts)
                } else {
                    FoundAlertsMapView(alerts: viewModel.foundAlerts)
                }
            }
        }
    }
}

// MARK: - List View
struct FoundAlertsListView: View {
    let alerts: [MissingPetAlert]

    var body: some View {
        List(alerts) { alert in
            NavigationLink(destination: AlertDetailView(alert: alert)) {
                FoundAlertRowView(alert: alert)
            }
        }
        .listStyle(.plain)
    }
}

struct FoundAlertRowView: View {
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
                .background(Color.green.opacity(0.2))
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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Found")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)

                // Found Date
                if let updatedAt = alert.updatedAt.toDate() {
                    Text("Found on \(updatedAt.formatted(date: .abbreviated, time: .omitted))")
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
struct FoundAlertsMapView: View {
    let alerts: [MissingPetAlert]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedAlert: MissingPetAlert?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: alerts) { alert in
                MapAnnotation(coordinate: alert.coordinate ?? CLLocationCoordinate2D()) {
                    FoundPetMapMarker(alert: alert, isSelected: selectedAlert?.id == alert.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedAlert = alert
                            }
                        }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // Selected Alert Card
            if let alert = selectedAlert {
                VStack {
                    Spacer()
                    FoundAlertMapCard(alert: alert)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Center map on first alert or use default location
            if let firstCoord = alerts.first?.coordinate {
                region.center = firstCoord
            }
        }
    }
}

struct FoundPetMapMarker: View {
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
                        .stroke(Color.green, lineWidth: isSelected ? 4 : 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            // Arrow pointing down
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
                .offset(y: -6)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct FoundAlertMapCard: View {
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
                    .background(Color.green.opacity(0.2))
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

                    // Found Status
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Found & Reunited")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.green)

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

#Preview {
    NavigationView {
        FoundAlertsView(viewModel: AlertsViewModel())
    }
}
