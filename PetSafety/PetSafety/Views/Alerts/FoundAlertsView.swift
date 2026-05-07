import SwiftUI
import MapKit

struct FoundAlertsView: View {
    @ObservedObject var viewModel: AlertsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Content
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("alerts_loading")
                        .font(.appFont(size: 15))
                        .foregroundColor(.mutedText)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.foundAlerts.isEmpty {
                EmptyAlertsStateView(kind: .found)
            } else {
                FoundAlertsListView(alerts: viewModel.foundAlerts)
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
        .adaptiveList()
    }
}

struct FoundAlertRowView: View {
    let alert: MissingPetAlert

    var body: some View {
        HStack(spacing: 16) {
            // Pet Photo
            if let pet = alert.pet {
                CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.white)
                        .padding(20)
                }
                .frame(width: 80, height: 80)
                .background(Color.tealAccent.opacity(0.2))
                .cornerRadius(12)
                .clipped()
            }

            VStack(alignment: .leading, spacing: 6) {
                // Pet Name
                if let pet = alert.pet {
                    Text(pet.name)
                        .font(.appFont(.headline))
                        .foregroundColor(.primary)
                }

                // Status Badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.appFont(.caption))
                        .foregroundColor(.tealAccent)
                    Text("alert_status_found")
                        .font(.appFont(.caption))
                        .fontWeight(.semibold)
                        .foregroundColor(.tealAccent)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.tealAccent.opacity(0.1))
                .cornerRadius(6)

                // Found Date
                if let updatedAt = alert.updatedAt.toDate() {
                    Text("alert_found_on \(updatedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                }

                // Location
                if let location = alert.lastSeenLocation {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.appFont(.caption2))
                        Text(location)
                            .font(.appFont(.caption))
                    }
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.appFont(.caption))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Map View
struct FoundAlertsMapView: View {
    let alerts: [MissingPetAlert]
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var selectedAlert: MissingPetAlert?

    private var alertsWithCoordinates: [(alert: MissingPetAlert, coordinate: CLLocationCoordinate2D)] {
        alerts.compactMap { alert in
            guard let coordinate = alert.coordinate else { return nil }
            return (alert, coordinate)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition) {
                ForEach(alertsWithCoordinates, id: \.alert.id) { entry in
                    Annotation(String(localized: "map_found_alert"), coordinate: entry.coordinate) {
                        FoundPetMapMarker(alert: entry.alert, isSelected: selectedAlert?.id == entry.alert.id)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedAlert = entry.alert
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
                    FoundAlertMapCard(alert: alert)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Center on the first alert with coordinates; otherwise let SwiftUI
            // auto-frame to whatever annotations are present.
            if let firstCoord = alertsWithCoordinates.first?.coordinate {
                mapPosition = .region(MKCoordinateRegion(
                    center: firstCoord,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ))
            } else {
                mapPosition = .automatic
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
                CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.white)
                        .font(.appFont(size: 16))
                }
                .frame(width: isSelected ? 60 : 50, height: isSelected ? 60 : 50)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.tealAccent, lineWidth: isSelected ? 4 : 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            // Arrow pointing down
            Image(systemName: "arrowtriangle.down.fill")
                .font(.appFont(size: 12))
                .foregroundColor(.tealAccent)
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
                    CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.white)
                            .padding(15)
                    }
                    .frame(width: 70, height: 70)
                    .background(Color.tealAccent.opacity(0.2))
                    .cornerRadius(12)
                    .clipped()
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Pet Name
                    if let pet = alert.pet {
                        Text(pet.name)
                            .font(.appFont(.headline))
                            .foregroundColor(.primary)
                    }

                    // Found Status
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.appFont(.caption))
                        Text("alert_found_reunited")
                            .font(.appFont(.subheadline))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.tealAccent)

                    // Location
                    if let location = alert.lastSeenLocation {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.appFont(.caption2))
                            Text(location)
                                .font(.appFont(.caption))
                        }
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.appFont(.body))
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
