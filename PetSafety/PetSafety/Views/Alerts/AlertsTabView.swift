import SwiftUI
import MapKit
import CoreLocation

/// Redesigned Lost & Found board — iOS counterpart of the web app's
/// CommunityBoard.tsx. Shows missing-pet alerts AND community-submitted
/// found-pet reports for the user's vicinity, with search + species +
/// status filters and a list/map toggle. The "Találtál egy gazdátlan
/// kisállatot?" CTA opens a sheet form (FoundPetFormView, chunk 4).
struct AlertsTabView: View {
    @StateObject private var viewModel = LostAndFoundViewModel()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddressRequiredMessage = false
    @State private var showFoundForm = false
    @State private var selectedFoundReport: CommunityFoundPet?

    // Status pill colors — match the web exactly (#FF2D2D / #F59E0B) so a
    // user switching between the web app and the mobile app sees the same
    // visual taxonomy. Defined inline rather than added to the asset
    // catalog to keep this chunk a single-file change.
    private static let missingRed = Color(red: 1.0, green: 0.176, blue: 0.176)
    private static let foundAmber = Color(red: 0.96, green: 0.62, blue: 0.04)
    private static let foundAmberTint = Color(red: 0.996, green: 0.953, blue: 0.78)

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        if showAddressRequiredMessage {
                            AddressRequiredView()
                                .frame(minHeight: 400)
                        } else {
                            viewModeToggle
                            searchBar
                            filterChipsRow(
                                title: String(localized: "lost_and_found_filter_species_label"),
                                items: LostAndFoundViewModel.SpeciesFilter.allCases,
                                labelFor: { speciesLabel($0) },
                                selected: $viewModel.speciesFilter
                            )
                            filterChipsRow(
                                title: String(localized: "lost_and_found_filter_status_label"),
                                items: LostAndFoundViewModel.StatusFilter.allCases,
                                labelFor: { statusLabel($0) },
                                dotFor: { statusDot($0) },
                                selected: $viewModel.statusFilter
                            )
                            foundCTACard
                            if viewModel.isLoading && viewModel.filteredMissing.isEmpty && viewModel.filteredFound.isEmpty {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 200)
                            } else if viewModel.view == .list {
                                listContent
                            } else {
                                mapContent
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .task { await loadNearby() }
            .refreshable { await loadNearby() }
            .sheet(isPresented: $showFoundForm) {
                // Placeholder until chunk 4 lands — see FoundPetFormView.
                NavigationView {
                    Text("found_pet_form_coming_soon")
                        .multilineTextAlignment(.center)
                        .padding(40)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(String(localized: "common_done")) { showFoundForm = false }
                            }
                        }
                }
            }
            .sheet(item: $selectedFoundReport) { report in
                // Placeholder until chunk 5 lands — see FoundPetDetailView.
                NavigationView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(report.breed ?? String(localized: "found_pet_unknown_breed"))
                            .font(.appFont(size: 22, weight: .bold))
                        if let desc = report.description { Text(desc) }
                        if let addr = report.foundAddress { Text(addr).foregroundColor(.mutedText) }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(String(localized: "common_done")) { selectedFoundReport = nil }
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("lost_and_found_eyebrow")
                .font(.appFont(size: 11, weight: .bold))
                .tracking(2.2)
                .foregroundColor(.brandOrange)
            Text("lost_and_found_title")
                .font(.appFont(size: 28, weight: .bold))
                .foregroundColor(.primary)
            Text("lost_and_found_description")
                .font(.appFont(size: 14))
                .foregroundColor(.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 60)
    }

    // MARK: - View toggle (Lista / Térkép)

    private var viewModeToggle: some View {
        HStack(spacing: 4) {
            toggleButton(
                isActive: viewModel.view == .list,
                systemImage: "square.grid.2x2",
                label: String(localized: "lost_and_found_view_list")
            ) { viewModel.view = .list }
            toggleButton(
                isActive: viewModel.view == .map,
                systemImage: "map",
                label: String(localized: "lost_and_found_view_map")
            ) { viewModel.view = .map }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 999)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggleButton(isActive: Bool, systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(label)
            }
            .font(.appFont(size: 14, weight: .semibold))
            .foregroundColor(isActive ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(isActive ? Color.brandOrange : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").foregroundColor(.mutedText)
            TextField(
                String(localized: "lost_and_found_search_placeholder"),
                text: $viewModel.query
            )
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Filter chips

    private func filterChipsRow<F: Identifiable & Hashable>(
        title: String,
        items: [F],
        labelFor: @escaping (F) -> String,
        dotFor: @escaping (F) -> Color? = { _ in nil },
        selected: Binding<F>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appFont(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundColor(.mutedText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        let isActive = item == selected.wrappedValue
                        Button {
                            selected.wrappedValue = item
                        } label: {
                            HStack(spacing: 6) {
                                if let dot = dotFor(item) {
                                    Circle()
                                        .fill(isActive ? .white : dot)
                                        .frame(width: 8, height: 8)
                                }
                                Text(labelFor(item))
                            }
                            .font(.appFont(size: 12, weight: .semibold))
                            .foregroundColor(isActive ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isActive ? Color.brandOrange : Color.clear)
                            .overlay(
                                Capsule()
                                    .stroke(isActive ? Color.brandOrange : Color.black.opacity(0.15), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func speciesLabel(_ filter: LostAndFoundViewModel.SpeciesFilter) -> String {
        switch filter {
        case .all: return String(localized: "lost_and_found_species_all")
        case .dog: return String(localized: "lost_and_found_species_dog")
        case .cat: return String(localized: "lost_and_found_species_cat")
        }
    }

    private func statusLabel(_ filter: LostAndFoundViewModel.StatusFilter) -> String {
        switch filter {
        case .all: return String(localized: "lost_and_found_status_all")
        case .missing: return String(localized: "lost_and_found_status_missing")
        case .community: return String(localized: "lost_and_found_status_community")
        }
    }

    private func statusDot(_ filter: LostAndFoundViewModel.StatusFilter) -> Color? {
        switch filter {
        case .all: return nil
        case .missing: return Self.missingRed
        case .community: return Self.foundAmber
        }
    }

    // MARK: - Found-pet CTA

    private var foundCTACard: some View {
        Button { showFoundForm = true } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Self.foundAmber)
                        .frame(width: 44, height: 44)
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("lost_and_found_cta_title")
                        .font(.appFont(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text("lost_and_found_cta_body")
                        .font(.appFont(size: 12))
                        .foregroundColor(.mutedText)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").foregroundColor(.mutedText)
            }
            .padding(16)
            .background(Self.foundAmberTint)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Self.foundAmber.opacity(0.44), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // MARK: - List mode

    private var listContent: some View {
        let missing = viewModel.filteredMissing
        let found = viewModel.filteredFound
        return Group {
            if missing.isEmpty && found.isEmpty {
                EmptyAlertsStateView(kind: .missing)
                    .frame(minHeight: 320)
            } else {
                VStack(spacing: 12) {
                    ForEach(missing) { alert in
                        NavigationLink(destination: AlertDetailView(alert: alert)) {
                            MissingPetAlertCard(alert: alert, missingColor: Self.missingRed)
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(found) { report in
                        Button { selectedFoundReport = report } label: {
                            CommunityFoundPetCard(report: report, amberColor: Self.foundAmber)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Map mode

    private var mapContent: some View {
        VStack(spacing: 12) {
            LostAndFoundMapView(
                missing: viewModel.filteredMissing,
                found: viewModel.filteredFound,
                searchCenter: viewModel.searchCenter,
                notificationRadiusKm: viewModel.notificationRadiusKm,
                missingColor: Self.missingRed,
                foundColor: Self.foundAmber,
                onSelectMissing: { _ in /* navigation handled via marker link */ },
                onSelectFound: { selectedFoundReport = $0 }
            )
            .frame(height: 420)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            MapLegend(
                missingColor: Self.missingRed,
                foundColor: Self.foundAmber,
                radiusKm: Int(viewModel.notificationRadiusKm)
            )
        }
    }

    // MARK: - Data loading (carried over from previous AlertsTabView)

    private func loadNearby() async {
        locationManager.requestLocation()
        let currentUser = authViewModel.currentUser
        async let geocodedFallback = geocodeUserAddressFallback(currentUser)
        var attempts = 0
        while locationManager.location == nil && attempts < 40 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            attempts += 1
        }
        if let location = locationManager.location {
            showAddressRequiredMessage = false
            await viewModel.fetchNearby(latitude: location.latitude, longitude: location.longitude)
        } else if let coordinate = await geocodedFallback {
            showAddressRequiredMessage = false
            await viewModel.fetchNearby(latitude: coordinate.latitude, longitude: coordinate.longitude)
        } else {
            showAddressRequiredMessage = true
        }
    }

    private func geocodeUserAddressFallback(_ user: User?) async -> CLLocationCoordinate2D? {
        guard let user = user else { return nil }
        let parts = [user.address, user.city, user.postalCode, user.country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(parts.joined(separator: ", "))
            return placemarks.first?.location?.coordinate
        } catch {
            return nil
        }
    }
}

// MARK: - Missing pet card

private struct MissingPetAlertCard: View {
    let alert: MissingPetAlert
    let missingColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let urlString = alert.pet?.profileImage, let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(missingColor.opacity(0.15))
                    }
                } else {
                    ZStack {
                        Rectangle().fill(missingColor.opacity(0.15))
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(missingColor)
                    }
                }
                statusBadge(text: String(localized: "lost_and_found_status_missing"), color: missingColor)
                    .padding(10)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4/3, contentMode: .fit)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(alert.pet?.name ?? String(localized: "lost_and_found_unknown_pet"))
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                if let breed = alert.pet?.breed, !breed.isEmpty {
                    Text(breed).font(.appFont(size: 13)).foregroundColor(.mutedText)
                }
                if let address = alert.lastSeenLocation, !address.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 11))
                            .foregroundColor(.mutedText)
                        Text(address).font(.appFont(size: 12)).foregroundColor(.mutedText).lineLimit(1)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Found pet card

private struct CommunityFoundPetCard: View {
    let report: CommunityFoundPet
    let amberColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let urlString = report.photoUrl, let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(amberColor.opacity(0.15))
                    }
                } else {
                    ZStack {
                        Rectangle().fill(amberColor.opacity(0.15))
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 36))
                            .foregroundColor(amberColor)
                    }
                }
                statusBadge(text: String(localized: "lost_and_found_status_community"), color: amberColor)
                    .padding(10)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4/3, contentMode: .fit)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(speciesLabel(report.species))
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                let subtitle = [report.breed, report.color].compactMap { $0 }.joined(separator: " · ")
                if !subtitle.isEmpty {
                    Text(subtitle).font(.appFont(size: 13)).foregroundColor(.mutedText)
                }
                if let address = report.foundAddress, !address.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 11))
                            .foregroundColor(.mutedText)
                        Text(address).font(.appFont(size: 12)).foregroundColor(.mutedText).lineLimit(1)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.06), lineWidth: 1))
    }

    private func speciesLabel(_ species: CommunityFoundPet.Species) -> String {
        switch species {
        case .dog: return String(localized: "lost_and_found_species_dog_singular")
        case .cat: return String(localized: "lost_and_found_species_cat_singular")
        case .other: return String(localized: "lost_and_found_species_other_singular")
        }
    }
}

// MARK: - Shared status badge

private func statusBadge(text: String, color: Color) -> some View {
    Text(text)
        .font(.appFont(size: 10, weight: .bold))
        .tracking(1.2)
        .textCase(.uppercase)
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color)
        .clipShape(Capsule())
}

// MARK: - Map view + legend

private struct LostAndFoundMapView: View {
    let missing: [MissingPetAlert]
    let found: [CommunityFoundPet]
    let searchCenter: CLLocationCoordinate2D?
    let notificationRadiusKm: Double
    let missingColor: Color
    let foundColor: Color
    let onSelectMissing: (MissingPetAlert) -> Void
    let onSelectFound: (CommunityFoundPet) -> Void

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition) {
            // Notification radius ring, centred on the search location.
            if let center = searchCenter {
                MapCircle(center: center, radius: notificationRadiusKm * 1000)
                    .foregroundStyle(Color(red: 0.22, green: 0.74, blue: 0.97).opacity(0.10))
                    .stroke(Color(red: 0.22, green: 0.74, blue: 0.97), lineWidth: 1)
            }
            ForEach(missing) { alert in
                if let coord = alert.coordinate {
                    Annotation(alert.pet?.name ?? "", coordinate: coord) {
                        Button { onSelectMissing(alert) } label: {
                            markerCircle(color: missingColor, systemImage: "exclamationmark.triangle.fill")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            ForEach(found) { report in
                let coord = CLLocationCoordinate2D(latitude: report.foundLatitude, longitude: report.foundLongitude)
                Annotation(report.breed ?? "", coordinate: coord) {
                    Button { onSelectFound(report) } label: {
                        markerCircle(color: foundColor, systemImage: "pawprint.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear { centerOnSearchCenterIfNeeded() }
        .onChange(of: searchCenter == nil ? "" : "\(searchCenter!.latitude),\(searchCenter!.longitude)") { _, _ in
            centerOnSearchCenterIfNeeded()
        }
    }

    private func centerOnSearchCenterIfNeeded() {
        guard let center = searchCenter else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18)
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    private func markerCircle(color: Color, systemImage: String) -> some View {
        ZStack {
            Circle().fill(.white).frame(width: 36, height: 36)
                .overlay(Circle().stroke(color, lineWidth: 3))
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

private struct MapLegend: View {
    let missingColor: Color
    let foundColor: Color
    let radiusKm: Int

    var body: some View {
        HStack(spacing: 16) {
            legendItem(color: missingColor, label: String(localized: "lost_and_found_status_missing"))
            legendItem(color: foundColor, label: String(localized: "lost_and_found_status_community"))
            legendItem(color: Color(red: 0.22, green: 0.74, blue: 0.97), label: String(localized: "lost_and_found_legend_radius \(radiusKm)"))
        }
        .font(.appFont(size: 11))
        .foregroundColor(.mutedText)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}

// MARK: - Address-required placeholder (preserved from previous AlertsTabView)

enum EmptyAlertsKind {
    case missing
    case found

    var titleKey: String.LocalizationValue {
        switch self {
        case .missing: return "alerts_no_nearby_missing_title"
        case .found: return "alerts_no_nearby_found_title"
        }
    }

    var messageKey: String.LocalizationValue {
        switch self {
        case .missing: return "alerts_no_nearby_missing_message"
        case .found: return "alerts_no_nearby_found_message"
        }
    }
}

struct EmptyAlertsStateView: View {
    let kind: EmptyAlertsKind

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Color(UIColor.systemGray6)).frame(width: 96, height: 96)
                Image(systemName: "checkmark.circle.fill")
                    .font(.appFont(size: 48))
                    .foregroundColor(.tealAccent)
            }
            VStack(spacing: 8) {
                Text(String(localized: kind.titleKey))
                    .font(.appFont(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text(String(localized: kind.messageKey))
                    .font(.appFont(size: 14))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AddressRequiredView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Color.brandOrange.opacity(0.1)).frame(width: 100, height: 100)
                Image(systemName: "location.slash.circle.fill")
                    .font(.appFont(size: 48))
                    .foregroundColor(.brandOrange)
            }
            VStack(spacing: 12) {
                Text("alerts_location_required")
                    .font(.appFont(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Text("alerts_location_required_message")
                    .font(.appFont(size: 15))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            NavigationLink(destination: AddressView()) {
                HStack {
                    Image(systemName: "house.fill")
                    Text("alerts_add_my_address").fontWeight(.semibold)
                }
            }
            .buttonStyle(BrandButtonStyle())
            .padding(.horizontal, 48)
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AlertsTabView()
        .environmentObject(AuthViewModel())
}
