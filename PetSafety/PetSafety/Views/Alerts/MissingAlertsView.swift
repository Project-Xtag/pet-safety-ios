import SwiftUI
import MapKit
import UIKit

struct MissingAlertsView: View {
    @ObservedObject var viewModel: AlertsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Offline indicator at the top
            OfflineIndicator()

            // Content
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("alerts_loading")
                        .font(.system(size: 15))
                        .foregroundColor(.mutedText)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.missingAlerts.isEmpty {
                EmptyAlertsStateView(kind: .missing)
            } else {
                MissingAlertsListView(alerts: viewModel.missingAlerts)
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
                    Text("alert_status_missing")
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
                    Text("alert_missing_since \(createdAt.formatted(date: .abbreviated, time: .omitted))")
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
    var userLocation: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var navigationAlert: MissingPetAlert?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition) {
                // Show user location marker
                if let userLoc = userLocation {
                    Annotation(String(localized: "map_you"), coordinate: userLoc) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 14, height: 14)
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 14, height: 14)
                        }
                    }
                }

                ForEach(alerts.filter { $0.coordinate != nil }) { alert in
                    Annotation(String(localized: "map_missing_alert"), coordinate: alert.coordinate!) {
                        PetMapMarker(alert: alert, isSelected: false)
                            .onTapGesture {
                                navigationAlert = alert
                            }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            if alerts.filter({ $0.coordinate != nil }).isEmpty {
                VStack {
                    Spacer()
                    Text("alerts_no_missing_nearby")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationDestination(item: $navigationAlert) { alert in
            AlertDetailView(alert: alert)
        }
        .onAppear {
            centerMap()
        }
        .onChange(of: alerts.count) { _, _ in
            centerMap()
        }
    }

    private func centerMap() {
        if let firstCoord = alerts.first(where: { $0.coordinate != nil })?.coordinate {
            mapPosition = .region(MKCoordinateRegion(
                center: firstCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        } else if let userLoc = userLocation {
            mapPosition = .region(MKCoordinateRegion(
                center: userLoc,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
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
                CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
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

        if days == 1 {
            return String(localized: "time_duration_day")
        } else if days > 1 {
            return String(format: NSLocalizedString("time_duration_days %lld", comment: ""), days)
        } else if hours == 1 {
            return String(localized: "time_duration_hour")
        } else if hours > 0 {
            return String(format: NSLocalizedString("time_duration_hours %lld", comment: ""), hours)
        } else {
            return String(localized: "time_less_than_hour")
        }
    }
}

#Preview {
    NavigationView {
        MissingAlertsView(viewModel: AlertsViewModel())
    }
}
