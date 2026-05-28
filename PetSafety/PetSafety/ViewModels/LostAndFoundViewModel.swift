import Foundation
import CoreLocation

/// Drives the redesigned Lost & Found board in `AlertsTabView`.
///
/// Pulls both missing-pet alerts and community-submitted found-pet
/// reports for the user's vicinity (web parity with CommunityBoard.tsx)
/// and exposes filterable, sortable feeds.
///
/// Kept separate from `AlertsViewModel` because that VM handles the
/// owner's own alerts (creating/marking found/etc.) — different concern.
@MainActor
class LostAndFoundViewModel: ObservableObject {
    // MARK: - Loaded data
    @Published private(set) var missingAlerts: [MissingPetAlert] = []
    @Published private(set) var foundReports: [CommunityFoundPet] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    /// Centre of the search; nil while we're still resolving user location.
    @Published private(set) var searchCenter: CLLocationCoordinate2D?

    // MARK: - UI state (filters / view mode)
    @Published var view: ViewMode = .list
    @Published var query: String = ""
    @Published var speciesFilter: SpeciesFilter = .all
    @Published var statusFilter: StatusFilter = .all

    /// Radius for the API queries. The web pulls a wider radius for the
    /// map ring (25 km) and overlays a 10 km notification radius circle —
    /// we'll do the same on iOS.
    let mapRadiusKm: Double = 25
    let notificationRadiusKm: Double = 10

    enum ViewMode { case list, map }

    enum SpeciesFilter: String, CaseIterable, Identifiable {
        case all, dog, cat
        var id: String { rawValue }
    }

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all, missing, community
        var id: String { rawValue }
    }

    // MARK: - Lifecycle

    /// Load both feeds in parallel for the given centre + radius. Failure
    /// of one branch doesn't blank the other — we mirror Promise.allSettled
    /// from the web instead of Promise.all.
    func fetchNearby(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        searchCenter = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        async let missingResult = loadMissing(latitude: latitude, longitude: longitude)
        async let foundResult = loadFound(latitude: latitude, longitude: longitude)
        let (missing, found) = await (missingResult, foundResult)

        var firstError: String?
        switch missing {
        case .success(let value): missingAlerts = value
        case .failure(let error):
            missingAlerts = []
            firstError = error.localizedDescription
        }
        switch found {
        case .success(let value): foundReports = value
        case .failure(let error):
            foundReports = []
            if firstError == nil { firstError = error.localizedDescription }
        }
        errorMessage = firstError
        isLoading = false
    }

    private func loadMissing(latitude: Double, longitude: Double) async -> Result<[MissingPetAlert], Error> {
        do {
            let alerts = try await APIService.shared.getNearbyAlerts(
                latitude: latitude,
                longitude: longitude,
                radiusKm: mapRadiusKm
            )
            // Filter to only active missing alerts — the web board hides
            // already-reunited / cancelled pets from the community view.
            return .success(alerts.filter { $0.status == "active" })
        } catch {
            return .failure(error)
        }
    }

    private func loadFound(latitude: Double, longitude: Double) async -> Result<[CommunityFoundPet], Error> {
        do {
            // Don't pass species — the picker filters client-side so
            // toggling species doesn't re-hit the network.
            let reports = try await APIService.shared.getNearbyFoundPets(
                latitude: latitude,
                longitude: longitude,
                radiusKm: mapRadiusKm,
                species: nil
            )
            return .success(reports.filter { $0.status == .active })
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Derived filtered feeds

    var filteredMissing: [MissingPetAlert] {
        guard statusFilter != .community else { return [] }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return missingAlerts.filter { alert in
            // The flat species/breed/name fields from /alerts/nearby get
            // decoded into the nested `pet` Pet model — see Alert.swift's
            // custom decoder. Read through `pet` here rather than the
            // top-level alert.
            if speciesFilter != .all {
                let species = alert.pet?.species.lowercased()
                switch speciesFilter {
                case .dog where species != "dog": return false
                case .cat where species != "cat": return false
                default: break
                }
            }
            if !q.isEmpty {
                let haystack = [alert.pet?.name, alert.pet?.breed, alert.lastSeenLocation]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .lowercased()
                if !haystack.contains(q) { return false }
            }
            return true
        }
    }

    var filteredFound: [CommunityFoundPet] {
        guard statusFilter != .missing else { return [] }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return foundReports.filter { report in
            switch speciesFilter {
            case .all: break
            case .dog: if report.species != .dog { return false }
            case .cat: if report.species != .cat { return false }
            }
            if !q.isEmpty {
                let haystack = [report.breed, report.color, report.foundAddress, report.description]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .lowercased()
                if !haystack.contains(q) { return false }
            }
            return true
        }
    }

    /// Insert a freshly-created report at the top of the local feed so
    /// the user sees their submission immediately, even before the
    /// admin-approval / next refresh cycle.
    func prependLocalFoundReport(_ report: CommunityFoundPet) {
        foundReports.insert(report, at: 0)
    }
}
