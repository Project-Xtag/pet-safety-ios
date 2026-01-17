import Foundation
import CoreLocation

@MainActor
class AlertsViewModel: ObservableObject {
    @Published var alerts: [MissingPetAlert] = []
    @Published var missingAlerts: [MissingPetAlert] = []
    @Published var foundAlerts: [MissingPetAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOfflineMode = false

    private let apiService: APIServiceProtocol
    private let offlineManager: OfflineDataManager
    private let networkMonitor: NetworkMonitoring
    private let syncService: SyncService

    init(
        apiService: APIServiceProtocol = APIService.shared,
        offlineManager: OfflineDataManager = OfflineDataManager.shared,
        networkMonitor: NetworkMonitoring = NetworkMonitor.shared,
        syncService: SyncService = SyncService.shared
    ) {
        self.apiService = apiService
        self.offlineManager = offlineManager
        self.networkMonitor = networkMonitor
        self.syncService = syncService
    }

    func fetchAlerts() async {
        isLoading = true
        errorMessage = nil
        isOfflineMode = !networkMonitor.isConnected

        do {
            if networkMonitor.isConnected {
                // Fetch from API when online
                alerts = try await apiService.getAlerts()
                // Cache the data locally
                for alert in alerts {
                    try? offlineManager.saveAlert(alert)
                }
            } else {
                // Load from local cache when offline
                alerts = try offlineManager.fetchAlerts()
                errorMessage = "Showing cached data (offline)"
            }
            isLoading = false
        } catch {
            isLoading = false
            // Try to load from cache if API fails
            do {
                alerts = try offlineManager.fetchAlerts()
                errorMessage = "Showing cached data (failed to connect)"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func fetchNearbyAlerts(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 10
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let allAlerts = try await apiService.getNearbyAlerts(
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm
            )

            // Separate missing and found alerts
        missingAlerts = allAlerts.filter { $0.status == "active" }
        foundAlerts = allAlerts.filter { $0.status == "found" }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func createAlert(
        petId: String,
        location: String?,
        coordinate: CLLocationCoordinate2D?,
        additionalInfo: String?
    ) async throws -> MissingPetAlert {
        isLoading = true
        errorMessage = nil
        isOfflineMode = !networkMonitor.isConnected

        if !networkMonitor.isConnected {
            var actionData: [String: Any] = ["petId": petId]
            if let coordinate = coordinate {
                actionData["latitude"] = coordinate.latitude
                actionData["longitude"] = coordinate.longitude
            }
            if let location = location {
                actionData["lastSeenAddress"] = location
            }
            if let additionalInfo = additionalInfo {
                actionData["description"] = additionalInfo
            }

            let localAlertId = "offline-\(UUID().uuidString)"
            actionData["localAlertId"] = localAlertId

            _ = try await syncService.queueAction(type: .createAlert, data: actionData)

            let now = ISO8601DateFormatter().string(from: Date())
            let userId = KeychainService.shared.getString(for: .userId) ?? "unknown"
            let localAlert = MissingPetAlert(
                id: localAlertId,
                petId: petId,
                userId: userId,
                status: "pending-sync",
                lastSeenLocation: location,
                lastSeenLatitude: coordinate?.latitude,
                lastSeenLongitude: coordinate?.longitude,
                additionalInfo: additionalInfo,
                createdAt: now,
                updatedAt: now
            )

            alerts.insert(localAlert, at: 0)
            if !missingAlerts.contains(where: { $0.id == localAlertId }) {
                missingAlerts.insert(localAlert, at: 0)
            }
            try? offlineManager.saveAlert(localAlert)

            isLoading = false
            errorMessage = "Alert queued. Will sync when online."
            throw NSError(domain: "Offline", code: 0, userInfo: [NSLocalizedDescriptionKey: "Queued for sync"])
        }

        let request = CreateAlertRequest(
            petId: petId,
            lastSeenLocation: coordinate.map { LocationCoordinate(lat: $0.latitude, lng: $0.longitude) },
            lastSeenAddress: location,
            description: additionalInfo,
            rewardAmount: nil,
            alertRadiusKm: nil
        )

        do {
            let newAlert = try await apiService.createAlert(request)
            alerts.insert(newAlert, at: 0)
            isLoading = false
            return newAlert
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func updateAlertStatus(id: String, status: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let updatedAlert = try await apiService.updateAlertStatus(id: id, status: status)

            // Update the main alerts array
            if let index = alerts.firstIndex(where: { $0.id == id }) {
                alerts[index] = updatedAlert
            }

            // Move alert between missing and found arrays based on new status
        if status == "found" {
                // Remove from missing alerts
                missingAlerts.removeAll { $0.id == id }
                // Add to found alerts if not already there
                if !foundAlerts.contains(where: { $0.id == id }) {
                    foundAlerts.insert(updatedAlert, at: 0)
                }
        } else if status == "active" {
                // Remove from found alerts
                foundAlerts.removeAll { $0.id == id }
                // Add to missing alerts if not already there
                if !missingAlerts.contains(where: { $0.id == id }) {
                    missingAlerts.insert(updatedAlert, at: 0)
                }
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func reportSighting(
        alertId: String,
        reporterName: String?,
        reporterPhone: String?,
        reporterEmail: String?,
        location: String?,
        coordinate: CLLocationCoordinate2D?,
        notes: String?
    ) async throws {
        isLoading = true
        errorMessage = nil

        // If offline, queue the action
        if !networkMonitor.isConnected {
            var actionData: [String: Any] = ["alertId": alertId]
            if let reporterName = reporterName {
                actionData["reporterName"] = reporterName
            }
            if let reporterPhone = reporterPhone {
                actionData["reporterPhone"] = reporterPhone
            }
            if let reporterEmail = reporterEmail {
                actionData["reporterEmail"] = reporterEmail
            }
            if let location = location {
                actionData["address"] = location
            }
            if let coordinate = coordinate {
                actionData["latitude"] = coordinate.latitude
                actionData["longitude"] = coordinate.longitude
            }
            if let notes = notes {
                actionData["description"] = notes
            }

            _ = try await syncService.queueAction(type: .reportSighting, data: actionData)

            isLoading = false
            errorMessage = "Sighting report queued. Will sync when online."
            throw NSError(domain: "Offline", code: 0, userInfo: [NSLocalizedDescriptionKey: "Queued for sync"])
        }

        let request = ReportSightingRequest(
            reporterName: reporterName,
            reporterPhone: reporterPhone,
            reporterEmail: reporterEmail,
            location: coordinate.map { LocationCoordinate(lat: $0.latitude, lng: $0.longitude) },
            address: location,
            description: notes,
            photoUrl: nil,
            sightedAt: nil
        )

        do {
            _ = try await apiService.reportSighting(alertId: alertId, sighting: request)
            // Refresh alerts to get updated sightings
            await fetchAlerts()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
