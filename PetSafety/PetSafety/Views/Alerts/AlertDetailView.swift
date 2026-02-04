import SwiftUI
import MapKit

struct AlertDetailView: View {
    let alert: MissingPetAlert
    @StateObject private var viewModel = AlertsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingReportSighting = false
    @State private var isMarkingFound = false
    @State private var mapPosition: MapCameraPosition

    init(alert: MissingPetAlert) {
        self.alert = alert
        let region: MKCoordinateRegion
        if let coordinate = alert.coordinate {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        _mapPosition = State(initialValue: .region(region))
    }

    // Check if current user is the pet owner
    private var isOwner: Bool {
        guard let currentUserId = authViewModel.currentUser?.id else { return false }
        // Check if the alert belongs to the current user
        return alert.userId == currentUserId
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pet Info
                if let pet = alert.pet {
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .accessibilityLabel("Pet photo placeholder")
                        }
                        .frame(width: 150, height: 150)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.red, lineWidth: 4)
                        )

                        Text(pet.name)
                            .font(.system(size: 32, weight: .bold))

                        Text("\(pet.species) • \(pet.breed ?? String(localized: "unknown_breed"))")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                // Alert Status
                HStack {
                    Circle()
                        .fill(alert.status == "active" ? Color.red : Color.green)
                        .frame(width: 12, height: 12)

                    Text(alert.status.capitalized)
                        .font(.headline)

                    Spacer()

                    // Only show "Mark as Found" button to the pet owner
                    if alert.status == "active" && isOwner {
                        Button(action: { markAsFound() }) {
                            if isMarkingFound {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("mark_as_found")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(isMarkingFound)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // Last Seen Location
                if let coordinate = alert.coordinate {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("last_seen_location", systemImage: "location.fill")
                            .font(.headline)

                        Map(position: $mapPosition) {
                            Annotation(String(localized: "last_seen_label"), coordinate: coordinate) {
                                VStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.red)
                                        .accessibilityLabel(Text("last_seen_location"))

                                    Text("last_seen_label")
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .frame(height: 200)
                        .cornerRadius(12)

                        if let location = alert.lastSeenLocation {
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Additional Info
                if let info = alert.additionalInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("additional_information", systemImage: "info.circle.fill")
                            .font(.headline)

                        Text(info)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Sightings
                if let sightings = alert.sightings, !sightings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(String(format: NSLocalizedString("reported_sightings_count", comment: ""), sightings.count), systemImage: "eye.fill")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(sightings) { sighting in
                            SightingCard(sighting: sighting)
                        }
                    }
                }

                // Report Sighting Button
                Button(action: { showingReportSighting = true }) {
                    Label("report_a_sighting", systemImage: "plus.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReportSighting) {
            NavigationView {
                ReportSightingView(alertId: alert.id)
            }
        }
    }

    private func markAsFound() {
        Task {
            isMarkingFound = true

            do {
                try await viewModel.updateAlertStatus(id: alert.id, status: "found")

                await MainActor.run {
                    isMarkingFound = false
                    appState.showSuccess(String(format: NSLocalizedString("pet_marked_found", comment: ""), alert.pet?.name ?? "Pet"))
                    // Dismiss the detail view to return to the refreshed list
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isMarkingFound = false
                    appState.showError(String(format: NSLocalizedString("mark_found_failed_message", comment: ""), error.localizedDescription))
                }
            }
        }
    }
}

struct SightingCard: View {
    let sighting: Sighting

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    sighting.reporterName ?? String(localized: "anonymous"),
                    systemImage: "person.fill"
                )
                .font(.subheadline)
                .fontWeight(.medium)

                Spacer()

                Text(formatDate(sighting.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let location = sighting.sightingLocation {
                Label(location, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let notes = sighting.sightingNotes {
                Text(notes)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            if let contact = sighting.reporterPhone ?? sighting.reporterEmail {
                Text(String(format: NSLocalizedString("contact_label", comment: ""), contact))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .short
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        AlertDetailView(alert: MissingPetAlert(
            id: "1",
            petId: "1",
            userId: "1",
            status: "active",
            lastSeenLocation: "Central Park, NYC",
            lastSeenLatitude: 40.7829,
            lastSeenLongitude: -73.9654,
            additionalInfo: "Last seen near the fountain",
            createdAt: "",
            updatedAt: "",
            pet: nil,
            sightings: nil
        ))
    }
}
