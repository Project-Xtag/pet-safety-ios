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
    @State private var mapRegion: MKCoordinateRegion

    init(alert: MissingPetAlert) {
        self.alert = alert
        if let coordinate = alert.coordinate {
            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } else {
            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
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

                        Text("\(pet.species) • \(pet.breed ?? "Unknown Breed")")
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
                                Text("Mark as Found")
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
                        Label("Last Seen Location", systemImage: "location.fill")
                            .font(.headline)

                        Map(coordinateRegion: $mapRegion, annotationItems: [alert]) { item in
                            MapAnnotation(coordinate: coordinate) {
                                VStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.red)

                                    Text("Last Seen")
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
                        Label("Additional Information", systemImage: "info.circle.fill")
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
                        Label("Reported Sightings (\(sightings.count))", systemImage: "eye.fill")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(sightings) { sighting in
                            SightingCard(sighting: sighting)
                        }
                    }
                }

                // Report Sighting Button
                Button(action: { showingReportSighting = true }) {
                    Label("Report a Sighting", systemImage: "plus.circle.fill")
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
                    appState.showSuccess("\(alert.pet?.name ?? "Pet") has been marked as found! 🎉")
                    // Dismiss the detail view to return to the refreshed list
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isMarkingFound = false
                    appState.showError("Failed to mark as found: \(error.localizedDescription)")
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
                    sighting.reporterName ?? "Anonymous",
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
                Text("Contact: \(contact)")
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

struct ReportSightingView: View {
    let alertId: String
    @StateObject private var viewModel = AlertsViewModel()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var reporterName = ""
    @State private var reporterPhone = ""
    @State private var reporterEmail = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var useCurrentLocation = false

    var body: some View {
        Form {
            Section("Your Contact Information") {
                TextField("Name (optional)", text: $reporterName)
                TextField("Phone (optional)", text: $reporterPhone)
                    .keyboardType(.phonePad)
                TextField("Email (optional)", text: $reporterEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }

            Section("Sighting Location") {
                Toggle("Use Current Location", isOn: $useCurrentLocation)

                if !useCurrentLocation {
                    TextField("Enter location", text: $location)
                }
            }

            Section("Details") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle("Report Sighting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Submit") {
                    submitSighting()
                }
                .disabled(viewModel.isLoading)
            }
        }
        .onChange(of: useCurrentLocation) { _, isOn in
            if isOn {
                locationManager.requestLocation()
            }
        }
    }

    private func submitSighting() {
        Task {
            do {
                let coordinate = useCurrentLocation ? locationManager.location : nil
                let locationText = useCurrentLocation ? nil : (location.isEmpty ? nil : location)

                try await viewModel.reportSighting(
                    alertId: alertId,
                    reporterName: reporterName.isEmpty ? nil : reporterName,
                    reporterPhone: reporterPhone.isEmpty ? nil : reporterPhone,
                    reporterEmail: reporterEmail.isEmpty ? nil : reporterEmail,
                    location: locationText,
                    coordinate: coordinate,
                    notes: notes.isEmpty ? nil : notes
                )

                appState.showSuccess("Sighting reported successfully!")
                dismiss()
            } catch {
                appState.showError(error.localizedDescription)
            }
        }
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
