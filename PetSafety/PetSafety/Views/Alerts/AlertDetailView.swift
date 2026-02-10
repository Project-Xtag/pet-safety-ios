import SwiftUI
import MapKit
import UIKit

struct AlertDetailView: View {
    let alert: MissingPetAlert
    @StateObject private var viewModel = AlertsViewModel()
    @StateObject private var petsViewModel = PetsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingReportSighting = false
    @State private var showingReportFound = false
    @State private var showingMarkFoundConfirmation = false
    @State private var showingSuccessStoryPrompt = false
    @State private var isMarkingFound = false
    @State private var mapPosition: MapCameraPosition
    @State private var reverseGeocodedAddress: String?

    // Check if current user is the pet owner
    private var isOwner: Bool {
        guard let currentUserId = authViewModel.currentUser?.id else { return false }
        return alert.userId == currentUserId
    }

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

    // Build pet details string with age and sex
    private func petDetailsString(_ pet: Pet) -> String {
        var details: [String] = []
        details.append(pet.species)
        if let breed = pet.breed, !breed.isEmpty {
            details.append(breed)
        }
        if let age = pet.age, !age.isEmpty {
            details.append(age)
        }
        if let sex = pet.sex, !sex.isEmpty {
            details.append(sex.capitalized)
        }
        return details.joined(separator: " • ")
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

                        Text(petDetailsString(pet))
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                // Alert Status
                HStack {
                    Circle()
                        .fill(alert.status == "active" ? Color.red : Color.tealAccent)
                        .frame(width: 12, height: 12)

                    Text(alert.status.capitalized)
                        .font(.headline)

                    Spacer()

                    // Missing since date
                    if let createdAt = alert.createdAt.toDate() {
                        Text("alert_missing_since \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // Additional Info (moved before Last Seen Location)
                if let info = alert.additionalInfo, !info.isEmpty {
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

                // Last Seen Location (moved after Additional Info)
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

                        if let address = reverseGeocodedAddress ?? alert.lastSeenLocation {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .task {
                        await reverseGeocodeCoordinate(coordinate)
                    }
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

                // Action Buttons (only for active alerts)
                if alert.status == "active" {
                    VStack(spacing: 12) {
                        if isOwner {
                            // Owner sees "Mark as Found" button
                            Button(action: { showingMarkFoundConfirmation = true }) {
                                HStack {
                                    if isMarkingFound {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    Text("mark_as_found")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isMarkingFound)
                        } else {
                            // Non-owners see "Report Sighting" and "Report Found" buttons
                            Button(action: { showingReportSighting = true }) {
                                Label("report_a_sighting", systemImage: "eye.fill")
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button(action: { showingReportFound = true }) {
                                Label("report_found", systemImage: "checkmark.circle.fill")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .padding(.bottom, 100) // Extra bottom padding to clear tab bar
        }
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showingReportSighting) {
            NavigationView {
                ReportSightingView(alertId: alert.id)
                    .environmentObject(appState)
                    .environmentObject(viewModel)
            }
        }
        .sheet(isPresented: $showingReportFound) {
            if let pet = alert.pet, let qrCode = pet.qrCode {
                ShareLocationView(qrCode: qrCode, petName: pet.name)
            }
        }
        .alert("alert_mark_found_title \(alert.pet?.name ?? String(localized: "pet_default"))", isPresented: $showingMarkFoundConfirmation) {
            Button("cancel", role: .cancel) { }
            Button("mark_as_found") {
                markAsFound()
            }
        } message: {
            Text("alert_mark_found_message \(alert.pet?.name ?? String(localized: "pet_default"))")
        }
        .fullScreenCover(isPresented: $showingSuccessStoryPrompt) {
            if let pet = alert.pet {
                SuccessStoryPromptView(
                    pet: Pet(
                        id: pet.id,
                        ownerId: alert.userId,
                        name: pet.name,
                        species: pet.species,
                        breed: pet.breed,
                        color: pet.color,
                        profileImage: pet.photoUrl,
                        isMissing: false,
                        createdAt: alert.createdAt,
                        updatedAt: alert.updatedAt
                    ),
                    onDismiss: {
                        showingSuccessStoryPrompt = false
                        appState.showSuccess(String(format: String(localized: "alert_marked_found_success"), pet.name))
                        dismiss()
                    },
                    onStorySubmitted: {
                        showingSuccessStoryPrompt = false
                        dismiss()
                    }
                )
                .environmentObject(appState)
            }
        }
    }

    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) async {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let components = [
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }
                if !components.isEmpty {
                    reverseGeocodedAddress = components.joined(separator: ", ")
                }
            }
        } catch {
            // Reverse geocoding failed, fall back to stored address
        }
    }

    private func markAsFound() {
        guard let petId = alert.pet?.id else { return }
        isMarkingFound = true

        Task {
            do {
                _ = try await petsViewModel.markPetFound(petId: petId)
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    isMarkingFound = false
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    showingSuccessStoryPrompt = true
                }
            } catch {
                await MainActor.run {
                    appState.showError(String(format: String(localized: "alert_mark_found_error"), error.localizedDescription))
                    isMarkingFound = false
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
