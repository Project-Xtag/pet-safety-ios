import Foundation
import Combine

/// Orchestrates synchronization between local offline data and remote server
/// Handles queued actions, conflict resolution, and automatic syncing
@MainActor
class SyncService: ObservableObject {
    /// Singleton instance for app-wide sync coordination
    static let shared = SyncService()

    /// Published property indicating if sync is currently in progress
    @Published private(set) var isSyncing: Bool = false

    /// Published property indicating the last successful sync date
    @Published private(set) var lastSyncDate: Date?

    /// Published property for pending action count
    @Published private(set) var pendingActionsCount: Int = 0

    /// Published property for sync status message
    @Published private(set) var syncStatus: String = ""

    private let offlineManager: OfflineDataManager
    private let networkMonitor: NetworkMonitoring
    private let apiService: APIServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?

    /// Action types that can be queued
    enum ActionType: String {
        case markPetLost = "markPetLost"
        case markPetFound = "markPetFound"
        case reportSighting = "reportSighting"
        case createAlert = "createAlert"
        case updatePet = "updatePet"
    }

    init(
        offlineManager: OfflineDataManager = OfflineDataManager.shared,
        networkMonitor: NetworkMonitoring = NetworkMonitor.shared,
        apiService: APIServiceProtocol = APIService.shared,
        autoSync: Bool = true
    ) {
        self.offlineManager = offlineManager
        self.networkMonitor = networkMonitor
        self.apiService = apiService

        setupNetworkObserver()
        loadLastSyncDate()
        updatePendingCount()

        if autoSync {
            // Auto-sync every 5 minutes when online
            startAutoSync()
        }
    }

    // MARK: - Network Observation

    private func setupNetworkObserver() {
        networkMonitor.isConnectedPublisher
            .dropFirst() // Ignore initial value
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.syncWhenOnline()
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Sync Operations

    /// Perform full synchronization (fetch remote data and process queue)
    func performFullSync() async {
        guard networkMonitor.isConnected else {
            syncStatus = "Cannot sync: No internet connection"
            return
        }

        guard !isSyncing else {
            return // Already syncing
        }

        isSyncing = true
        syncStatus = "Syncing..."

        do {
            // 1. Process queued actions first
            try await processQueuedActions()

            // 2. Fetch fresh data from server
            try await fetchRemoteData()

            // 3. Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")

            syncStatus = "Sync completed"
            print("✅ Full sync completed successfully")

        } catch {
            syncStatus = "Sync failed: \(error.localizedDescription)"
            print("❌ Sync failed: \(error.localizedDescription)")
        }

        isSyncing = false
        updatePendingCount()
    }

    /// Sync when coming back online
    private func syncWhenOnline() async {
        print("🌐 Network connection restored, starting sync...")
        await performFullSync()
    }

    // MARK: - Queue Management

    /// Queue an action to be performed when online
    func queueAction(type: ActionType, data: [String: Any]) async throws -> UUID {
        let actionId = try offlineManager.queueAction(type: type.rawValue, data: data)
        updatePendingCount()

        print("📝 Queued action: \(type.rawValue) (ID: \(actionId))")

        // Try to sync immediately if online
        if networkMonitor.isConnected {
            Task {
                await performFullSync()
            }
        }

        return actionId
    }

    /// Process all queued actions
    private func processQueuedActions() async throws {
        let actions = try offlineManager.fetchPendingActions()

        guard !actions.isEmpty else {
            print("✅ No pending actions to process")
            return
        }

        print("📤 Processing \(actions.count) queued action(s)...")

        for action in actions {
            do {
                try await processAction(action)
                try offlineManager.completeAction(withId: action.id)
                print("✅ Completed action: \(action.type) (ID: \(action.id))")
            } catch {
                let errorMessage = error.localizedDescription
                try offlineManager.failAction(withId: action.id, error: errorMessage)
                print("❌ Failed action: \(action.type) - \(errorMessage)")
            }
        }
    }

    /// Process a single queued action
    private func processAction(_ action: QueuedAction) async throws {
        guard let actionType = ActionType(rawValue: action.type) else {
            throw SyncError.invalidActionType
        }

        switch actionType {
        case .markPetLost:
            _ = try await processMarkPetLost(action)

        case .markPetFound:
            try await processMarkPetFound(action)

        case .reportSighting:
            try await processReportSighting(action)

        case .createAlert:
            try await processCreateAlert(action)

        case .updatePet:
            try await processUpdatePet(action)
        }
    }

    // MARK: - Action Processors

    private func processMarkPetLost(_ action: QueuedAction) async throws -> MissingPetAlert {
        guard let petId = action.data["petId"] as? String else {
            throw SyncError.missingData("petId")
        }

        let lastSeenAddress = action.data["lastSeenAddress"] as? String
        let lastSeenLatitude = action.data["latitude"] as? Double
        let lastSeenLongitude = action.data["longitude"] as? Double
        let additionalInfo = action.data["description"] as? String

        let request = CreateAlertRequest(
            petId: petId,
            lastSeenLocation: (lastSeenLatitude != nil && lastSeenLongitude != nil)
                ? LocationCoordinate(lat: lastSeenLatitude!, lng: lastSeenLongitude!)
                : nil,
            lastSeenAddress: lastSeenAddress,
            description: additionalInfo,
            rewardAmount: nil,
            alertRadiusKm: nil
        )

        return try await apiService.createAlert(request)
    }

    private func processMarkPetFound(_ action: QueuedAction) async throws {
        guard let petId = action.data["petId"] as? String else {
            throw SyncError.missingData("petId")
        }

        _ = try await apiService.markPetFound(petId: petId)
    }

    private func processReportSighting(_ action: QueuedAction) async throws {
        guard let alertId = action.data["alertId"] as? String else {
            throw SyncError.missingData("alertId")
        }

        let latitude = action.data["latitude"] as? Double
        let longitude = action.data["longitude"] as? Double

        let request = ReportSightingRequest(
            reporterName: action.data["reporterName"] as? String,
            reporterPhone: action.data["reporterPhone"] as? String,
            reporterEmail: action.data["reporterEmail"] as? String,
            location: (latitude != nil && longitude != nil)
                ? LocationCoordinate(lat: latitude!, lng: longitude!)
                : nil,
            address: action.data["address"] as? String,
            description: action.data["description"] as? String,
            photoUrl: nil,
            sightedAt: nil
        )

        _ = try await apiService.reportSighting(alertId: alertId, sighting: request)
    }

    private func processCreateAlert(_ action: QueuedAction) async throws {
        let createdAlert = try await processMarkPetLost(action)

        if let localAlertId = action.data["localAlertId"] as? String {
            try? offlineManager.deleteAlert(withId: localAlertId)
        }

        try? offlineManager.saveAlert(createdAlert)
    }

    private func processUpdatePet(_ action: QueuedAction) async throws {
        guard let petId = action.data["petId"] as? String else {
            throw SyncError.missingData("petId")
        }

        // Extract optional update fields from action data
        let name = action.data["name"] as? String
        let species = action.data["species"] as? String
        let breed = action.data["breed"] as? String
        let color = action.data["color"] as? String
        let age = action.data["age"] as? String
        let weight = action.data["weight"] as? Double
        let microchipNumber = action.data["microchipNumber"] as? String
        let medicalNotes = action.data["medicalNotes"] as? String
        let allergies = action.data["allergies"] as? String
        let medications = action.data["medications"] as? String
        let notes = action.data["notes"] as? String
        let uniqueFeatures = action.data["uniqueFeatures"] as? String
        let sex = action.data["sex"] as? String
        let isNeutered = action.data["isNeutered"] as? Bool
        let isMissing = action.data["isMissing"] as? Bool

        let request = UpdatePetRequest(
            name: name,
            species: species,
            breed: breed,
            color: color,
            age: age,
            weight: weight,
            microchipNumber: microchipNumber,
            medicalNotes: medicalNotes,
            allergies: allergies,
            medications: medications,
            notes: notes,
            uniqueFeatures: uniqueFeatures,
            sex: sex,
            isNeutered: isNeutered,
            isMissing: isMissing
        )

        _ = try await apiService.updatePet(id: petId, request)
    }

    // MARK: - Remote Data Fetching

    /// Fetch fresh data from server and cache locally
    private func fetchRemoteData() async throws {
        print("📥 Fetching remote data...")

        // Fetch pets
        let pets = try await apiService.getPets()
        try offlineManager.savePets(pets)
        print("✅ Cached \(pets.count) pet(s)")

        // Fetch alerts
        let alerts = try await apiService.getAlerts()
        if !alerts.isEmpty {
            for alert in alerts {
                try offlineManager.saveAlert(alert)
            }
            print("✅ Cached \(alerts.count) alert(s)")
        }
    }

    // MARK: - Auto Sync

    private func startAutoSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self,
                      self.networkMonitor.isConnected,
                      !self.isSyncing else {
                    return
                }
                await self.performFullSync()
            }
        }
    }

    // MARK: - Utilities

    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }

    private func updatePendingCount() {
        pendingActionsCount = (try? offlineManager.getPendingActionCount()) ?? 0
    }

    /// Get time since last sync in human-readable format
    var timeSinceLastSync: String {
        guard let lastSync = lastSyncDate else {
            return "Never"
        }

        let interval = Date().timeIntervalSince(lastSync)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }

    deinit {
        syncTimer?.invalidate()
    }
}

// MARK: - Errors

enum SyncError: LocalizedError {
    case invalidActionType
    case missingData(String)
    case notImplemented
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidActionType:
            return "Invalid action type"
        case .missingData(let field):
            return "Missing required data: \(field)"
        case .notImplemented:
            return "Feature not yet implemented"
        case .networkUnavailable:
            return "Network connection unavailable"
        }
    }
}
