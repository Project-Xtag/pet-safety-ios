import SwiftUI
import MapKit

struct AlertsListView: View {
    @StateObject private var viewModel = AlertsViewModel()
    @State private var showingCreateAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Offline indicator at the top
            OfflineIndicator()

            ZStack {
                if viewModel.isLoading && viewModel.alerts.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.errorMessage != nil && viewModel.alerts.isEmpty {
                    ErrorRetryView(message: viewModel.errorMessage ?? String(localized: "failed_load_alerts")) {
                        Task { await viewModel.fetchAlerts() }
                    }
                } else if viewModel.alerts.isEmpty {
                EmptyStateView(
                    icon: "exclamationmark.triangle.fill",
                    title: String(localized: "no_active_alerts"),
                    message: String(localized: "no_active_alerts_message"),
                    actionTitle: String(localized: "create_alert"),
                    action: { showingCreateAlert = true }
                )
            } else {
                List {
                    ForEach(viewModel.alerts) { alert in
                        NavigationLink(destination: AlertDetailView(alert: alert)) {
                            AlertRowView(alert: alert)
                        }
                    }
                }
                .listStyle(.inset)
            }
        } // end of ZStack
        } // end of VStack with OfflineIndicator
        .navigationTitle(Text("missing_pet_alerts_title"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateAlert = true }) {
                    Image(systemName: "plus")
                        .accessibilityLabel(Text("create_new_alert"))
                }
            }
        }
        .sheet(isPresented: $showingCreateAlert) {
            NavigationView {
                CreateAlertView()
            }
        }
        .task {
            await viewModel.fetchAlerts()
        }
        .refreshable {
            await viewModel.fetchAlerts()
        }
    }
}

struct AlertRowView: View {
    let alert: MissingPetAlert

    var statusColor: Color {
        switch alert.status {
        case "active": return .red
        case "found": return .tealAccent
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Pet Photo or Icon
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
                .frame(width: 70, height: 70)
                .background(statusColor.opacity(0.2))
                .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let pet = alert.pet {
                    Text(pet.name)
                        .font(.headline)
                }

                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    Text(alert.status.capitalized)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                }

                if let location = alert.lastSeenLocation {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let sightings = alert.sightings, !sightings.isEmpty {
                    Text(sightings.count == 1 ? String(localized: "sighting_count_singular") : String(format: NSLocalizedString("sighting_count_plural", comment: ""), sightings.count))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        AlertsListView()
    }
}
