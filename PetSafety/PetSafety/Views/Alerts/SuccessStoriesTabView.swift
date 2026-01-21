import SwiftUI
import CoreLocation
import MapKit

struct SuccessStoriesTabView: View {
    @StateObject private var viewModel = SuccessStoriesViewModel()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedViewMode = 0
    @State private var showAddressRequiredMessage = false
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var showShareSheet = false
    @State private var selectedStoryForShare: SuccessStory?

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Content
                VStack(spacing: 20) {
                    // View Mode Segmented Control (List / Map)
                    segmentedControl(
                        options: ["List", "Map"],
                        selection: $selectedViewMode
                    )
                    .padding(.horizontal, 24)

                    // Content Area
                    if showAddressRequiredMessage {
                        AddressRequiredView()
                    } else {
                        contentView
                    }
                }
                .padding(.top, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
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

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Success Stories")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
    }

    // MARK: - Segmented Control
    private func segmentedControl(options: [String], selection: Binding<Int>) -> some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection.wrappedValue = index
                    }
                }) {
                    Text(options[index])
                        .font(.system(size: 14, weight: selection.wrappedValue == index ? .bold : .medium))
                        .foregroundColor(selection.wrappedValue == index ? .white : .mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selection.wrappedValue == index
                                ? Color.green
                                : Color.clear
                        )
                        .cornerRadius(14)
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.05))
        .cornerRadius(18)
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.stories.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading success stories...")
                    .font(.system(size: 15))
                    .foregroundColor(.mutedText)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.stories.isEmpty {
            EmptySuccessStoriesView()
        } else {
            if selectedViewMode == 0 {
                // List View
                SuccessStoriesListContent(
                    viewModel: viewModel,
                    onShare: { story in
                        selectedStoryForShare = story
                        showShareSheet = true
                    }
                )
            } else {
                // Map View
                SuccessStoriesMapContent(
                    stories: viewModel.stories,
                    userLocation: userLocation,
                    onShare: { story in
                        selectedStoryForShare = story
                        showShareSheet = true
                    }
                )
            }
        }
    }

    // MARK: - Helper Methods
    private func loadSuccessStories() async {
        locationManager.requestLocation()
        try? await Task.sleep(nanoseconds: 500_000_000)

        var latitude = 51.5074 // Default: London
        var longitude = -0.1278

        if let location = locationManager.location {
            latitude = location.latitude
            longitude = location.longitude
            userLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            showAddressRequiredMessage = false
        } else if let user = authViewModel.currentUser,
                  let addressCoordinate = await geocodeUserAddress(user: user) {
            latitude = addressCoordinate.latitude
            longitude = addressCoordinate.longitude
            userLocation = addressCoordinate
            showAddressRequiredMessage = false
        } else {
            showAddressRequiredMessage = true
            return
        }

        await viewModel.fetchSuccessStories(
            latitude: latitude,
            longitude: longitude,
            radiusKm: 10,
            page: 1
        )
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
            text += "\(petName) Found! \n\n"
        }
        if let storyText = story.storyText {
            text += "\(storyText)\n\n"
        }
        if let city = story.reunionCity {
            text += "Reunited in \(city)\n"
        }
        text += "\nShared via Pet Safety App"
        return text
    }
}

// MARK: - Success Stories List Content
struct SuccessStoriesListContent: View {
    @ObservedObject var viewModel: SuccessStoriesViewModel
    let onShare: (SuccessStory) -> Void

    var body: some View {
        List {
            ForEach(viewModel.stories) { story in
                SuccessStoryRowView(story: story, onShare: onShare)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // Load More Button
            if viewModel.hasMore {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button("Load More") {
                            Task {
                                if let userLoc = viewModel.stories.first?.coordinate {
                                    await viewModel.loadMore(
                                        latitude: userLoc.latitude,
                                        longitude: userLoc.longitude,
                                        radiusKm: 10
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

// MARK: - Success Stories Map Content
struct SuccessStoriesMapContent: View {
    let stories: [SuccessStory]
    let userLocation: CLLocationCoordinate2D?
    let onShare: (SuccessStory) -> Void
    @State private var selectedStory: SuccessStory?

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map placeholder with markers
            ZStack {
                Color.green.opacity(0.05)
                    .ignoresSafeArea()

                // Pet photo markers positioned on map
                ForEach(Array(stories.prefix(10).enumerated()), id: \.element.id) { index, story in
                    let positions: [(CGFloat, CGFloat)] = [
                        (0.20, 0.30), (0.35, 0.60), (0.50, 0.25),
                        (0.45, 0.70), (0.65, 0.45), (0.25, 0.80),
                        (0.70, 0.20), (0.55, 0.85), (0.30, 0.15),
                        (0.75, 0.65)
                    ]
                    let pos = positions[index % positions.count]

                    GeometryReader { geometry in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedStory = story
                            }
                        }) {
                            SuccessStoryMapMarkerView(story: story, isSelected: selectedStory?.id == story.id)
                        }
                        .position(
                            x: geometry.size.width * pos.1,
                            y: geometry.size.height * pos.0
                        )
                    }
                }
            }

            // Selected Story Card
            if let story = selectedStory {
                SuccessStoryMapCardView(story: story, onShare: onShare)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Success Story Map Marker View
struct SuccessStoryMapMarkerView: View {
    let story: SuccessStory
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Pet Photo in Circle
            if let photoUrl = story.petPhotoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
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
                        .stroke(Color.green, lineWidth: isSelected ? 4 : 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: isSelected ? 60 : 50, height: isSelected ? 60 : 50)
                    Image(systemName: "heart.fill")
                        .foregroundColor(.green)
                        .font(.system(size: isSelected ? 24 : 20))
                }
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

            // Checkmark badge
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
                .background(Circle().fill(.white).frame(width: 12, height: 12))
                .offset(y: -70)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Success Story Map Card View
struct SuccessStoryMapCardView: View {
    let story: SuccessStory
    let onShare: (SuccessStory) -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Pet Photo
            if let photoUrl = story.petPhotoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                        .padding(15)
                }
                .frame(width: 70, height: 70)
                .background(Color.green.opacity(0.2))
                .cornerRadius(12)
                .clipped()
            } else {
                Image(systemName: "heart.fill")
                    .foregroundColor(.green)
                    .padding(15)
                    .frame(width: 70, height: 70)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Pet Name
                if let petName = story.petName {
                    Text(petName)
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
                if let city = story.reunionCity {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(city)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Share Button
            Button(action: {
                onShare(story)
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
    }
}

#Preview {
    NavigationView {
        SuccessStoriesTabView()
            .environmentObject(AuthViewModel())
    }
}
