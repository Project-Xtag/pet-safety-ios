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

    private let apiService = APIService.shared
    private let offlineManager = OfflineDataManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private let syncService = SyncService.shared

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
            foundAlerts = allAlerts.filter { $0.status == "resolved" }

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

        let request = CreateAlertRequest(
            petId: petId,
            lastSeenLocation: location,
            lastSeenLatitude: coordinate?.latitude,
            lastSeenLongitude: coordinate?.longitude,
            additionalInfo: additionalInfo
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
            if status == "resolved" {
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
                actionData["sightingLocation"] = location
            }
            if let coordinate = coordinate {
                actionData["sightingLatitude"] = coordinate.latitude
                actionData["sightingLongitude"] = coordinate.longitude
            }
            if let notes = notes {
                actionData["sightingNotes"] = notes
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
            sightingLocation: location,
            sightingLatitude: coordinate?.latitude,
            sightingLongitude: coordinate?.longitude,
            sightingNotes: notes
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
