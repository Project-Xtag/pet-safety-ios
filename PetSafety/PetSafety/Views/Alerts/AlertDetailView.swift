import SwiftUI
import MapKit

struct AlertDetailView: View {
    let alert: MissingPetAlert
    @StateObject private var viewModel = AlertsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingReportSighting = false
    @State private var showingReportFound = false
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
                        .fill(alert.status == "active" ? Color.red : Color.green)
                        .frame(width: 12, height: 12)

                    Text(alert.status.capitalized)
                        .font(.headline)

                    Spacer()

                    // Missing since date
                    if let createdAt = alert.createdAt.toDate() {
                        Text("Missing since \(createdAt.formatted(date: .abbreviated, time: .omitted))")
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
                        // Report as Found Button (like QR scan flow - anyone can report)
                        Button(action: { showingReportFound = true }) {
                            Label("Report as Found", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        // Report a Sighting Button
                        Button(action: { showingReportSighting = true }) {
                            Label("report_a_sighting", systemImage: "eye.fill")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .padding(.bottom, 20) // Extra bottom padding for scrollability
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReportSighting) {
            NavigationView {
                ReportSightingView(alertId: alert.id)
            }
        }
        .sheet(isPresented: $showingReportFound) {
            NavigationView {
                ReportFoundView(alert: alert)
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Report Found View (similar to QR scan found flow)
struct ReportFoundView: View {
    let alert: MissingPetAlert
    @EnvironmentObject var appState: AppState
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss

    @State private var reporterName = ""
    @State private var reporterPhone = ""
    @State private var reporterEmail = ""
    @State private var locationText = ""
    @State private var notes = ""
    @State private var useCurrentLocation = false
    @State private var isSubmitting = false
    @State private var shareContactInfo = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                    }

                    Text("Report Pet Found")
                        .font(.system(size: 22, weight: .bold))

                    if let pet = alert.pet {
                        Text("Help reunite \(pet.name) with their owner")
                            .font(.system(size: 14))
                            .foregroundColor(.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)

                // Contact Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $shareContactInfo) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("share_contact_info")
                                .font(.system(size: 15, weight: .semibold))
                            Text("The owner will be notified and can contact you")
                                .font(.system(size: 12))
                                .foregroundColor(.mutedText)
                        }
                    }
                    .tint(.green)

                    if shareContactInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Image(systemName: "person")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)
                                TextField(String(localized: "your_name"), text: $reporterName)
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("phone")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Image(systemName: "phone")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)
                                TextField(String(localized: "your_phone_number"), text: $reporterPhone)
                                    .textContentType(.telephoneNumber)
                                    .keyboardType(.phonePad)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("email")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)
                                TextField(String(localized: "your_email"), text: $reporterEmail)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Location Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Where did you find this pet?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Toggle(isOn: $useCurrentLocation) {
                        Label("use_current_location", systemImage: "location.fill")
                            .font(.system(size: 15))
                    }
                    .tint(.green)
                    .onChange(of: useCurrentLocation) { _, isOn in
                        if isOn {
                            locationManager.requestLocation()
                        }
                    }

                    if useCurrentLocation {
                        if locationManager.location != nil {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("location_captured")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("getting_location")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("address_or_description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Image(systemName: "mappin")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)
                                TextField("Where did you find the pet?", text: $locationText)
                                    .autocapitalization(.sentences)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Notes Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("additional_details")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Describe the pet's condition, behavior, etc.")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Submit Button
                Button(action: submitReport) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Submit Found Report")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSubmit ? Color.green : Color.green.opacity(0.5))
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
                    .cornerRadius(16)
                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(!canSubmit || isSubmitting)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .navigationTitle(Text("Report Found"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("cancel") {
                    dismiss()
                }
                .foregroundColor(.brandOrange)
            }
        }
    }

    private var canSubmit: Bool {
        // Need either GPS location or manual text location
        // And at least one contact method if sharing contact info
        let hasLocation = useCurrentLocation ? locationManager.location != nil : !locationText.trimmingCharacters(in: .whitespaces).isEmpty
        let hasContact = !shareContactInfo || !reporterPhone.isEmpty || !reporterEmail.isEmpty
        return hasLocation && hasContact
    }

    private func submitReport() {
        isSubmitting = true

        // This submits as a sighting with "found" indication in notes
        let coordinate = useCurrentLocation ? locationManager.location : nil
        let address = useCurrentLocation ? nil : locationText.trimmingCharacters(in: .whitespaces)
        let fullNotes = "🎉 PET FOUND REPORT\n\n\(notes.isEmpty ? "No additional notes" : notes)"

        Task {
            do {
                // Use AlertsViewModel to report sighting
                let alertsVM = AlertsViewModel()
                try await alertsVM.reportSighting(
                    alertId: alert.id,
                    reporterName: shareContactInfo && !reporterName.isEmpty ? reporterName : nil,
                    reporterPhone: shareContactInfo && !reporterPhone.isEmpty ? reporterPhone : nil,
                    reporterEmail: shareContactInfo && !reporterEmail.isEmpty ? reporterEmail : nil,
                    location: address,
                    coordinate: coordinate,
                    notes: fullNotes
                )
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                appState.showSuccess("Found report submitted! The owner has been notified.")
                dismiss()
            } catch {
                appState.showError(error.localizedDescription)
            }
            isSubmitting = false
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
