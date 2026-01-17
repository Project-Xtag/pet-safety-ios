import Testing
import Foundation
import Combine
import CoreLocation
import CoreData
@testable import PetSafety

@Suite("Offline Sync Queue E2E Tests")
struct OfflineSyncQueueE2ETests {
    @Test("Offline alert is queued and synced")
    @MainActor
    func testOfflineAlertQueuedAndSynced() async throws {
        let offlineManager = OfflineDataManager(storeType: NSInMemoryStoreType)
        let networkMonitor = TestNetworkMonitor(isConnected: false)
        let apiService = MockAPIService()
        let syncService = SyncService(
            offlineManager: offlineManager,
            networkMonitor: networkMonitor,
            apiService: apiService,
            autoSync: false
        )
        let viewModel = AlertsViewModel(
            apiService: apiService,
            offlineManager: offlineManager,
            networkMonitor: networkMonitor,
            syncService: syncService
        )

        do {
            _ = try await viewModel.createAlert(
                petId: "pet_1",
                location: "123 Test Street",
                coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
                additionalInfo: "Test alert"
            )
            #expect(Bool(false), "Expected offline error to be thrown")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == "Offline")
        }

        let queuedActions = try offlineManager.fetchPendingActions()
        #expect(queuedActions.count == 1)

        let localAlerts = try offlineManager.fetchAlerts()
        #expect(localAlerts.count == 1)
        let localAlertId = localAlerts[0].id

        networkMonitor.isConnected = true
        await syncService.performFullSync()

        let remainingActions = try offlineManager.fetchPendingActions()
        #expect(remainingActions.isEmpty)

        let syncedAlerts = try offlineManager.fetchAlerts()
        let containsCreated = syncedAlerts.contains { $0.id == apiService.createdAlertId }
        let containsLocal = syncedAlerts.contains { $0.id == localAlertId }
        #expect(containsCreated)
        #expect(containsLocal == false)
    }
}

@MainActor
final class TestNetworkMonitor: NetworkMonitoring {
    @Published var isConnected: Bool

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }

    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        $isConnected.eraseToAnyPublisher()
    }
}

final class MockAPIService: APIServiceProtocol {
    private(set) var createdAlertId: String = ""

    func createAlert(_ request: CreateAlertRequest) async throws -> MissingPetAlert {
        let id = "alert-\(UUID().uuidString)"
        createdAlertId = id

        let timestamp = ISO8601DateFormatter().string(from: Date())
        return MissingPetAlert(
            id: id,
            petId: request.petId,
            userId: "user_1",
            status: "active",
            lastSeenLocation: request.lastSeenAddress,
            lastSeenLatitude: request.lastSeenLocation?.lat,
            lastSeenLongitude: request.lastSeenLocation?.lng,
            additionalInfo: request.description,
            createdAt: timestamp,
            updatedAt: timestamp
        )
    }

    func getPets() async throws -> [Pet] {
        []
    }

    func getAlerts() async throws -> [MissingPetAlert] {
        []
    }

    func getNearbyAlerts(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [MissingPetAlert] {
        []
    }

    func updateAlertStatus(id: String, status: String) async throws -> MissingPetAlert {
        throw APIError.serverError("Not implemented for test")
    }

    func markPetFound(petId: String) async throws -> Pet {
        throw APIError.serverError("Not implemented for test")
    }

    func updatePet(id: String, _ request: UpdatePetRequest) async throws -> Pet {
        throw APIError.serverError("Not implemented for test")
    }

    func reportSighting(alertId: String, sighting: ReportSightingRequest) async throws -> Sighting {
        throw APIError.serverError("Not implemented for test")
    }
}
