import SwiftUI
import MapKit

struct SuccessStoriesView: View {
    @StateObject private var viewModel = SuccessStoriesViewModel()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showShareSheet = false
    @State private var selectedStoryForShare: SuccessStory?
    @State private var userLocation: CLLocationCoordinate2D?

    var body: some View {
        VStack(spacing: 0) {
            // Content
            if viewModel.isLoading && viewModel.stories.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("loading_success_stories")
                        .font(.system(size: 15))
                        .foregroundColor(.mutedText)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.stories.isEmpty {
                EmptySuccessStoriesView()
            } else {
                SuccessStoriesListView(
                    viewModel: viewModel
                )
            }
        }
        .task {
            await loadSuccessStories()
        }
        .refreshable {
            await loadSuccessStories()
        }
        .sheet(isPresented: $showShareSheet) {
            if let story = selectedStoryForShare {
                ShareSheet(activityItems: [createShareText(for: story)])
            }
        }
    }

    // MARK: - Helper Methods

    private func loadSuccessStories() async {
        locationManager.requestLocation()

        // Start geocoding user's address in parallel as fallback
        let currentUser = authViewModel.currentUser
        async let geocodedFallback = geocodeUserAddressFallback(currentUser)

        // Wait for device location (up to 3s, polling every 200ms)
        var attempts = 0
        while locationManager.location == nil && attempts < 15 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            attempts += 1
        }

        var latitude = 51.5074 // Default: London
        var longitude = -0.1278

        if let location = locationManager.location {
            latitude = location.latitude
            longitude = location.longitude
            userLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else if let addressCoordinate = await geocodedFallback {
            latitude = addressCoordinate.latitude
            longitude = addressCoordinate.longitude
            userLocation = addressCoordinate
        }

        await viewModel.fetchSuccessStories(
            latitude: latitude,
            longitude: longitude,
            radiusKm: 50,
            page: 1
        )
    }

    private func geocodeUserAddressFallback(_ user: User?) async -> CLLocationCoordinate2D? {
        guard let user = user else { return nil }
        return await geocodeUserAddress(user: user)
    }

    private func geocodeUserAddress(user: User) async -> CLLocationCoordinate2D? {
        let addressComponents = [
            user.address,
            user.city,
            user.postalCode,
            user.country
        ].compactMap { $0 }.filter { !$0.isEmpty }

        guard !addressComponents.isEmpty else { return nil }

        let addressString = addressComponents.joined(separator: ", ")
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(addressString)
            if let location = placemarks.first?.location {
                return location.coordinate
            }
        } catch {
            print("Geocoding failed: \(error.localizedDescription)")
        }

        return nil
    }

    private func createShareText(for story: SuccessStory) -> String {
        var text = ""
        if let petName = story.petName {
            let timeMissing = story.timeMissingText ?? String(localized: "some_time")
            if story.missingSinceDate != nil {
                text += String(format: NSLocalizedString("reunion_template", comment: ""), petName, timeMissing, petName, petName) + "\n\n"
            } else {
                text += String(format: NSLocalizedString("reunion_template_no_time", comment: ""), petName, petName) + "\n\n"
            }
        }
        if let storyText = story.storyText {
            text += "\(storyText)\n\n"
        }
        text += String(localized: "shared_via_pet_safety")
        return text
    }
}

// MARK: - List View
struct SuccessStoriesListView: View {
    @ObservedObject var viewModel: SuccessStoriesViewModel

    var body: some View {
        List {
            ForEach(viewModel.stories) { story in
                SuccessStoryRowView(story: story)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // Load More Button
            if viewModel.hasMore {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button("load_more") {
                            Task {
                                if let userLoc = viewModel.stories.first?.coordinate {
                                    await viewModel.loadMore(
                                        latitude: userLoc.latitude,
                                        longitude: userLoc.longitude,
                                        radiusKm: 50
                                    )
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .adaptiveList()
    }
}

struct SuccessStoryRowView: View {
    let story: SuccessStory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Pet Photo
                if let photoUrl = story.petPhotoUrl {
                    AsyncImage(url: URL(string: photoUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.white)
                            .padding(20)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.tealAccent.opacity(0.2))
                    .cornerRadius(12)
                    .clipped()
                } else {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                        .padding(20)
                        .frame(width: 80, height: 80)
                        .background(Color.tealAccent.opacity(0.2))
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Pet Name
                    if let petName = story.petName {
                        Text(petName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    // Found Badge
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.tealAccent)
                        Text("found_and_reunited")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.tealAccent)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.tealAccent.opacity(0.1))
                    .cornerRadius(6)

                    // Location
                    if let city = story.reunionCity {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(city)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    // Distance
                    if let distance = story.distanceKm {
                        Text(String(format: NSLocalizedString("distance_km", comment: ""), distance))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Reunion Template
            let petName = story.petName ?? ""
            let timeMissing = story.timeMissingText ?? String(localized: "some_time")
            if story.missingSinceDate != nil {
                Text(String(format: NSLocalizedString("reunion_template", comment: ""), petName, timeMissing, petName, petName))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            } else {
                Text(String(format: NSLocalizedString("reunion_template_no_time", comment: ""), petName, petName))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            // Owner's Story (optional)
            if let storyText = story.storyText {
                VStack(alignment: .leading, spacing: 2) {
                    Text("owners_story")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(storyText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(2)
                }
            }

            // Time Info
            HStack(spacing: 12) {
                if let timeMissing = story.timeMissingText {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(String(format: NSLocalizedString("missing_for", comment: ""), timeMissing))
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }

                if let foundDate = story.foundAtDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(String(format: NSLocalizedString("found_on", comment: ""), foundDate.timeAgoDisplay()))
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Map View
struct SuccessStoriesMapView: View {
    let stories: [SuccessStory]
    let userLocation: CLLocationCoordinate2D?

    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var selectedStory: SuccessStory?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition) {
                ForEach(stories) { story in
                    if let coordinate = story.coordinate {
                        Annotation(String(localized: "success_story_marker"), coordinate: coordinate) {
                            SuccessStoryMapMarker(
                                story: story,
                                isSelected: selectedStory?.id == story.id
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedStory = story
                                }
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // Selected Story Card
            if let story = selectedStory {
                VStack {
                    Spacer()
                    SuccessStoryMapCard(story: story)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Center map on user location or first story
            var region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            if let userLoc = userLocation {
                region.center = userLoc
            } else if let firstStory = stories.first, let coord = firstStory.coordinate {
                region.center = coord
            }
            mapPosition = .region(region)
        }
    }
}

struct SuccessStoryMapMarker: View {
    let story: SuccessStory
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Pet Photo in Circle
            if let photoUrl = story.petPhotoUrl {
                AsyncImage(url: URL(string: photoUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
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
                .font(.system(size: 12))
                .foregroundColor(.tealAccent)
                .offset(y: -6)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct SuccessStoryMapCard: View {
    let story: SuccessStory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Pet Photo
                if let photoUrl = story.petPhotoUrl {
                    AsyncImage(url: URL(string: photoUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.white)
                            .padding(20)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.tealAccent.opacity(0.2))
                    .cornerRadius(12)
                    .clipped()
                } else {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                        .padding(20)
                        .frame(width: 80, height: 80)
                        .background(Color.tealAccent.opacity(0.2))
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Pet Name
                    if let petName = story.petName {
                        Text(petName)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    // Found Badge
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.tealAccent)
                        Text("found_and_reunited")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.tealAccent)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.tealAccent.opacity(0.1))
                    .cornerRadius(6)

                    // Location
                    if let city = story.reunionCity {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(city)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    // Distance
                    if let distance = story.distanceKm {
                        Text(String(format: NSLocalizedString("distance_km", comment: ""), distance))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Reunion Template
            let petName = story.petName ?? ""
            let timeMissing = story.timeMissingText ?? String(localized: "some_time")
            if story.missingSinceDate != nil {
                Text(String(format: NSLocalizedString("reunion_template", comment: ""), petName, timeMissing, petName, petName))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            } else {
                Text(String(format: NSLocalizedString("reunion_template_no_time", comment: ""), petName, petName))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            // Owner's Story (optional)
            if let storyText = story.storyText {
                VStack(alignment: .leading, spacing: 2) {
                    Text("owners_story")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(storyText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(2)
                }
            }

            // Time Info
            HStack(spacing: 12) {
                if let timeMissingText = story.timeMissingText {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(String(format: NSLocalizedString("missing_for", comment: ""), timeMissingText))
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }

                if let foundDate = story.foundAtDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(String(format: NSLocalizedString("found_on", comment: ""), foundDate.timeAgoDisplay()))
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
    }
}

// MARK: - Empty State
struct EmptySuccessStoriesView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 100, height: 100)
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.tealAccent)
            }

            VStack(spacing: 12) {
                Text("no_success_stories")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text("no_success_stories_message")
                    .font(.system(size: 15))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Date Extension
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: self, to: now)

        if let day = components.day, day > 0 {
            return day == 1 ? String(localized: "success_day_ago") : String(format: NSLocalizedString("success_days_ago %lld", comment: ""), day)
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? String(localized: "success_hour_ago") : String(format: NSLocalizedString("success_hours_ago %lld", comment: ""), hour)
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? String(localized: "success_minute_ago") : String(format: NSLocalizedString("success_minutes_ago %lld", comment: ""), minute)
        } else {
            return String(localized: "success_just_now")
        }
    }
}

#Preview {
    SuccessStoriesView()
        .environmentObject(AuthViewModel())
}
