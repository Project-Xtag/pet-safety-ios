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
                        options: [String(localized: "list"), String(localized: "map")],
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
                Button("done") {
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
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("success_stories_title")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tealAccent.opacity(0.1))
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
                                ? Color.tealAccent
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
                Text("success_stories_loading")
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
                    viewModel: viewModel
                )
            } else {
                // Map View - real MapKit map
                SuccessStoriesMapView(
                    stories: viewModel.stories,
                    userLocation: userLocation
                )
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
            showAddressRequiredMessage = false
        } else if let addressCoordinate = await geocodedFallback {
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
            #if DEBUG
            print("Geocoding failed: \(error.localizedDescription)")
            #endif
        }

        return nil
    }

}

// MARK: - Success Stories List Content
struct SuccessStoriesListContent: View {
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


#Preview {
    NavigationView {
        SuccessStoriesTabView()
            .environmentObject(AuthViewModel())
    }
}
