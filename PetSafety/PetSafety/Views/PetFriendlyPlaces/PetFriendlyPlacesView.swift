import SwiftUI
import MapKit
import CoreLocation

// MARK: - Per-category theme (the native CATEGORY_THEME; frame colors match the web hexes)

private struct CategoryTheme {
    let color: Color
    let glyph: String
}

private func categoryTheme(_ category: PetFriendlyPlace.Category) -> CategoryTheme {
    switch category {
    case .cafeBar:    return .init(color: Color(red: 0.706, green: 0.333, blue: 0.122), glyph: "cup.and.saucer.fill")  // #B4551F
    case .restaurant: return .init(color: Color(red: 0.753, green: 0.224, blue: 0.169), glyph: "fork.knife")           // #C0392B
    case .hotel:      return .init(color: Color(red: 0.231, green: 0.357, blue: 0.647), glyph: "bed.double.fill")      // #3B5BA5
    case .beach:      return .init(color: Color(red: 0.122, green: 0.541, blue: 0.549), glyph: "beach.umbrella.fill")  // #1F8A8C
    case .other:      return .init(color: Color(red: 0.420, green: 0.447, blue: 0.502), glyph: "mappin.and.ellipse")   // #6B7280
    case .unknown:    return .init(color: Color(red: 0.420, green: 0.447, blue: 0.502), glyph: "mappin")               // grey fallback
    }
}

private func categoryLabel(_ c: PetFriendlyPlace.Category) -> String {
    switch c {
    case .cafeBar:    return String(localized: "pet_friendly_category_cafe_bar")
    case .restaurant: return String(localized: "pet_friendly_category_restaurant")
    case .hotel:      return String(localized: "pet_friendly_category_hotel")
    case .beach:      return String(localized: "pet_friendly_category_beach")
    case .other:      return String(localized: "pet_friendly_category_other")
    case .unknown:    return String(localized: "pet_friendly_category_other")
    }
}

/// Public discovery map + list for pet-friendly places (M3). Pushed from `AlertsTabView`
/// (the community area), so it does NOT wrap its own NavigationView. Market is derived
/// from the user's country; a 404 → `notInMarket` region state (distinct from empty).
/// Detail is a sheet off the LOADED row (no `getPetFriendlyPlace(id:)` — dormant until a
/// deep-link phase owns it), so it renders nil-safe.
struct PetFriendlyPlacesView: View {
    @StateObject private var viewModel = PetFriendlyPlacesViewModel()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var viewMode: ViewMode = .list
    @State private var selectedPlace: PetFriendlyPlace?
    @State private var showSubmit = false

    private enum ViewMode { case list, map }
    private static let budapest = CLLocationCoordinate2D(latitude: 47.4979, longitude: 19.0402)

    private var places: [PetFriendlyPlace] { viewModel.filteredPlaces }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.notInMarket {
                        notInMarketView
                    } else {
                        viewModeToggle
                        categoryChips
                        submitCTACard
                        content
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(String(localized: "pet_friendly_title"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $selectedPlace) { place in
            PetFriendlyPlaceDetailSheet(place: place)
        }
        .sheet(isPresented: $showSubmit) {
            SubmitPetFriendlyPlaceView { _ in
                // A new submission lands pending (invisible on the public read), so no
                // optimistic insert; just refresh so a later approval shows up.
                Task { await load() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.places.isEmpty {
            ProgressView().frame(maxWidth: .infinity, minHeight: 220)
        } else if let error = viewModel.errorMessage {
            infoState(systemImage: "exclamationmark.triangle", text: error)
        } else if viewMode == .list {
            listContent
        } else {
            mapContent
        }
    }

    // MARK: View toggle (Lista / Térkép)

    private var viewModeToggle: some View {
        HStack(spacing: 4) {
            toggleButton(active: viewMode == .list, systemImage: "square.grid.2x2",
                         label: String(localized: "pet_friendly_view_list")) { viewMode = .list }
            toggleButton(active: viewMode == .map, systemImage: "map",
                         label: String(localized: "pet_friendly_view_map")) { viewMode = .map }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 999)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggleButton(active: Bool, systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(label)
            }
            .font(.appFont(size: 14, weight: .semibold))
            .foregroundColor(active ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(active ? Color.brandOrange : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Category filter chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: String(localized: "pet_friendly_filter_all"), selected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(PetFriendlyPlace.Category.allCases.filter { $0 != .unknown }, id: \.self) { cat in
                    chip(label: categoryLabel(cat), color: categoryTheme(cat).color,
                         selected: viewModel.selectedCategory == cat) {
                        viewModel.selectedCategory = (viewModel.selectedCategory == cat) ? nil : cat
                    }
                }
            }
        }
    }

    private func chip(label: String, color: Color = .brandOrange, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.appFont(size: 13, weight: .semibold))
                .foregroundColor(selected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? color : Color(UIColor.systemBackground))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Submit CTA (entrance into M3c)

    private var submitCTACard: some View {
        Button { showSubmit = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.brandOrange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "pet_friendly_submit_cta_prompt"))
                        .font(.appFont(size: 14, weight: .semibold)).foregroundColor(.primary)
                    Text(String(localized: "pet_friendly_submit_cta"))
                        .font(.appFont(size: 12)).foregroundColor(.mutedText)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.mutedText)
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: List / Map

    @ViewBuilder
    private var listContent: some View {
        if places.isEmpty {
            infoState(systemImage: "mappin.slash", text: String(localized: "pet_friendly_empty"))
        } else {
            VStack(spacing: 12) {
                ForEach(places) { place in
                    Button { selectedPlace = place } label: { PlaceCard(place: place) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private var mapContent: some View {
        PetFriendlyMapView(
            places: places,
            center: locationManager.location ?? Self.budapest,
            onSelect: { selectedPlace = $0 }
        )
        .frame(height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var notInMarketView: some View {
        infoState(systemImage: "mappin.and.ellipse", text: String(localized: "pet_friendly_not_in_region"))
            .frame(minHeight: 320)
    }

    private func infoState(systemImage: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage).font(.system(size: 34)).foregroundColor(.brandOrange)
            Text(text).font(.appFont(size: 14)).foregroundColor(.mutedText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(24)
    }

    // MARK: Data loading

    private func load() async {
        locationManager.requestLocation()
        let user = authViewModel.currentUser
        let market = user?.country ?? Locale.current.region?.identifier ?? ""
        async let fallback = geocodeUserAddressFallback(user)
        var attempts = 0
        while locationManager.location == nil && attempts < 40 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            attempts += 1
        }
        let fallbackCoord = await fallback
        let coord = locationManager.location ?? fallbackCoord ?? Self.budapest
        await viewModel.loadNearby(latitude: coord.latitude, longitude: coord.longitude, market: market)
    }

    private func geocodeUserAddressFallback(_ user: User?) async -> CLLocationCoordinate2D? {
        guard let user else { return nil }
        let parts = [user.address, user.city, user.postalCode, user.country].compactMap { $0 }.filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        do {
            let placemarks = try await CLGeocoder().geocodeAddressString(parts.joined(separator: ", "))
            return placemarks.first?.location?.coordinate
        } catch {
            return nil
        }
    }
}

// MARK: - Place card (list row)

private struct PlaceCard: View {
    let place: PetFriendlyPlace

    var body: some View {
        let theme = categoryTheme(place.category)
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(theme.color.opacity(0.14)).frame(width: 48, height: 48)
                Image(systemName: theme.glyph).font(.system(size: 20, weight: .semibold)).foregroundColor(theme.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name).font(.appFont(size: 16, weight: .bold)).foregroundColor(.primary)
                    .lineLimit(1)
                Text(categoryLabel(place.category)).font(.appFont(size: 12, weight: .semibold)).foregroundColor(theme.color)
                Text([place.address, place.city].compactMap { $0 }.joined(separator: ", "))
                    .font(.appFont(size: 12)).foregroundColor(.mutedText).lineLimit(1)
            }
            Spacer()
            if let km = place.distanceKm {
                Text(String(format: "%.1f km", km)).font(.appFont(size: 12, weight: .semibold)).foregroundColor(.mutedText)
            }
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Map

private struct PetFriendlyMapView: View {
    let places: [PetFriendlyPlace]
    let center: CLLocationCoordinate2D
    let onSelect: (PetFriendlyPlace) -> Void

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(places) { place in
                Annotation(place.name, coordinate: place.coordinate) {
                    let theme = categoryTheme(place.category)
                    Button { onSelect(place) } label: {
                        ZStack {
                            Circle().fill(.white).frame(width: 36, height: 36)
                                .overlay(Circle().stroke(theme.color, lineWidth: 3))
                            Image(systemName: theme.glyph).font(.system(size: 14, weight: .bold)).foregroundColor(theme.color)
                        }
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear { recenter() }
        .onChange(of: "\(center.latitude),\(center.longitude)") { _, _ in recenter() }
    }

    private func recenter() {
        cameraPosition = .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        ))
    }
}

// MARK: - Detail sheet (off the loaded row; nil-safe; no getById)

private struct PetFriendlyPlaceDetailSheet: View {
    let place: PetFriendlyPlace
    @Environment(\.dismiss) private var dismiss
    @State private var showMapPicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                let theme = categoryTheme(place.category)
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(theme.color.opacity(0.14)).frame(width: 56, height: 56)
                            Image(systemName: theme.glyph).font(.system(size: 24, weight: .semibold)).foregroundColor(theme.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name).font(.appFont(size: 20, weight: .bold)).foregroundColor(.primary)
                            Text(categoryLabel(place.category)).font(.appFont(size: 13, weight: .semibold)).foregroundColor(theme.color)
                        }
                    }

                    detailRow(icon: "mappin.and.ellipse",
                              text: [place.address, place.city, place.postcode].compactMap { $0 }.joined(separator: ", "))
                    if let phone = place.phone, !phone.isEmpty {
                        detailLink(icon: "phone.fill", text: phone, url: URL(string: "tel:\(phone.filter { !$0.isWhitespace })"))
                    }
                    if let website = place.website, !website.isEmpty {
                        detailLink(icon: "globe", text: website, url: URL(string: website))
                    }
                    if let intro = place.introduction, !intro.isEmpty {
                        Text(intro).font(.appFont(size: 14)).foregroundColor(.primary).fixedSize(horizontal: false, vertical: true)
                    }

                    Button { showMapPicker = true } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            Text(String(localized: "pet_friendly_directions"))
                        }
                        .font(.appFont(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brandOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .navigationTitle(String(localized: "pet_friendly_detail_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common_done")) { dismiss() }
                }
            }
            .sheet(isPresented: $showMapPicker) {
                MapAppPickerView(
                    location: LocationData(latitude: place.latitude, longitude: place.longitude, isApproximate: false),
                    petName: place.name
                )
            }
        }
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundColor(.mutedText).frame(width: 20)
            Text(text).font(.appFont(size: 14)).foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private func detailLink(icon: String, text: String, url: URL?) -> some View {
        if let url {
            Link(destination: url) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: icon).foregroundColor(.brandOrange).frame(width: 20)
                    Text(text).font(.appFont(size: 14)).foregroundColor(.brandOrange).underline()
                }
            }
        } else {
            detailRow(icon: icon, text: text)
        }
    }
}

#if DEBUG
extension PetFriendlyPlace {
    /// One place per category so the map draws all five per-category pin colours/glyphs.
    static var previewSamples: [PetFriendlyPlace] {
        let cats: [Category] = [.cafeBar, .restaurant, .hotel, .beach, .other]
        return cats.enumerated().map { i, c in
            PetFriendlyPlace(
                id: "\(i)", category: c, name: categoryLabel(c), address: "Fő utca \(i)",
                latitude: 47.49 + Double(i) * 0.012, longitude: 19.04 + Double(i) * 0.012,
                introduction: nil, phone: nil, website: nil, city: "Budapest", postcode: nil,
                country: nil, distanceKm: Double(i), status: nil, createdAt: nil, updatedAt: nil
            )
        }
    }
}

#Preview("Per-category markers") {
    PetFriendlyMapView(
        places: PetFriendlyPlace.previewSamples,
        center: CLLocationCoordinate2D(latitude: 47.50, longitude: 19.06),
        onSelect: { _ in }
    )
    .frame(height: 480)
}
#endif
