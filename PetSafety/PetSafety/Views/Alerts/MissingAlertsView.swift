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
                    Text("Loading alerts...")
                        .font(.system(size: 15))
                        .foregroundColor(.mutedText)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.missingAlerts.isEmpty {
                EmptyAlertsStateView(alertType: "Missing")
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
    var userLocation: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var selectedAlert: MissingPetAlert?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition) {
                // Show user location marker
                if let userLoc = userLocation {
                    Annotation("You", coordinate: userLoc) {
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
                    Annotation("Missing Alert", coordinate: alert.coordinate!) {
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

            if alerts.filter({ $0.coordinate != nil }).isEmpty {
                VStack {
                    Spacer()
                    Text("No missing pet alerts nearby")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.bottom, 20)
                }
            }

            // Selected Alert Card
            if let alert = selectedAlert {
                VStack {
                    Spacer()
                    MissingAlertMapCard(alert: alert)
                        .padding()
                        .padding(.bottom, 80) // Extra padding to avoid tab bar overlap
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
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
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PetsViewModel()
    @State private var showingReportSighting = false
    @State private var showingReportFound = false
    @State private var showingMarkFoundConfirmation = false
    @State private var showingSuccessStoryPrompt = false
    @State private var isMarkingFound = false

    // Check if current user is the pet owner
    private var isOwner: Bool {
        guard let currentUserId = authViewModel.currentUser?.id else { return false }
        return alert.userId == currentUserId
    }

    var body: some View {
        VStack(spacing: 12) {
            // Main card content - tappable to view details
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
            }
            .buttonStyle(PlainButtonStyle())

            // Action buttons
            HStack(spacing: 12) {
                Button(action: { showingReportSighting = true }) {
                    HStack {
                        Image(systemName: "eye.fill")
                        Text("Report Sighting")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.brandOrange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                if isOwner {
                    // Owner sees "Mark as Found" button
                    Button(action: { showingMarkFoundConfirmation = true }) {
                        HStack {
                            if isMarkingFound {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text("Mark as Found")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isMarkingFound)
                } else {
                    // Non-owners see "Report Found" button
                    Button(action: { showingReportFound = true }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Report Found")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
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
        .alert("Mark \(alert.pet?.name ?? "pet") as Found?", isPresented: $showingMarkFoundConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Mark as Found") {
                markAsFound()
            }
        } message: {
            Text("This will close the missing alert. Are you sure?")
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
                    },
                    onStorySubmitted: {
                        showingSuccessStoryPrompt = false
                    }
                )
                .environmentObject(appState)
            }
        }
    }

    private func markAsFound() {
        guard let petId = alert.pet?.id else { return }
        isMarkingFound = true

        Task {
            do {
                _ = try await viewModel.markPetFound(petId: petId)
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    appState.showSuccess("\(alert.pet?.name ?? "Pet") has been marked as found!")
                    showingSuccessStoryPrompt = true
                    isMarkingFound = false
                }
            } catch {
                await MainActor.run {
                    appState.showError("Failed to mark as found: \(error.localizedDescription)")
                    isMarkingFound = false
                }
            }
        }
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
