import Foundation
import CoreLocation

@MainActor
class AlertsViewModel: ObservableObject {
    @Published var alerts: [MissingPetAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchAlerts() async {
        isLoading = true
        errorMessage = nil

        do {
            alerts = try await apiService.getAlerts()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func createAlert(
        petId: Int,
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

    func updateAlertStatus(id: Int, status: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let updatedAlert = try await apiService.updateAlertStatus(id: id, status: status)
            if let index = alerts.firstIndex(where: { $0.id == id }) {
                alerts[index] = updatedAlert
            }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func reportSighting(
        alertId: Int,
        reporterName: String?,
        reporterPhone: String?,
        reporterEmail: String?,
        location: String?,
        coordinate: CLLocationCoordinate2D?,
        notes: String?
    ) async throws {
        isLoading = true
        errorMessage = nil

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
