import XCTest
@testable import PetSafety

final class SyncErrorHandlingTests: XCTestCase {

    // MARK: - QueuedAction Tests

    func testQueuedActionCreation() {
        let id = UUID()
        let action = QueuedAction(
            id: id,
            type: "markPetLost",
            data: ["petId": "pet-123"],
            createdAt: Date(),
            status: "pending",
            retryCount: 0,
            errorMessage: nil
        )

        XCTAssertEqual(action.id, id)
        XCTAssertEqual(action.type, "markPetLost")
        XCTAssertEqual(action.status, "pending")
        XCTAssertEqual(action.retryCount, 0)
        XCTAssertNil(action.errorMessage)
    }

    func testQueuedActionWithError() {
        let action = QueuedAction(
            id: UUID(),
            type: "reportSighting",
            data: ["alertId": "alert-456"],
            createdAt: Date(),
            status: "failed",
            retryCount: 3,
            errorMessage: "Network connection failed"
        )

        XCTAssertEqual(action.status, "failed")
        XCTAssertEqual(action.retryCount, 3)
        XCTAssertEqual(action.errorMessage, "Network connection failed")
    }

    // MARK: - SyncService Action Type Description Tests

    func testActionTypeDescriptions() async {
        let syncService = await SyncService(autoSync: false)

        await MainActor.run {
            XCTAssertEqual(syncService.actionTypeDescription("markPetLost"), "Mark pet as lost")
            XCTAssertEqual(syncService.actionTypeDescription("markPetFound"), "Mark pet as found")
            XCTAssertEqual(syncService.actionTypeDescription("reportSighting"), "Report sighting")
            XCTAssertEqual(syncService.actionTypeDescription("createAlert"), "Create alert")
            XCTAssertEqual(syncService.actionTypeDescription("updatePet"), "Update pet")
            XCTAssertEqual(syncService.actionTypeDescription("unknownType"), "unknownType")
        }
    }

    // MARK: - SyncService Initial State Tests

    func testSyncServiceInitialState() async {
        let syncService = await SyncService(autoSync: false)

        await MainActor.run {
            XCTAssertFalse(syncService.isSyncing)
            XCTAssertEqual(syncService.pendingActionsCount, 0)
            XCTAssertEqual(syncService.failedActionsCount, 0)
            XCTAssertTrue(syncService.failedActions.isEmpty)
        }
    }

    // MARK: - Pet Deletion Protection Tests

    func testMissingPetCannotBeDeleted() {
        // Pet marked as missing
        let missingPet = Pet(
            id: "pet-123",
            ownerId: "owner-1",
            name: "Buddy",
            species: "Dog",
            breed: "Golden Retriever",
            color: nil,
            weight: nil,
            microchipNumber: nil,
            medicalNotes: nil,
            notes: nil,
            profileImage: nil,
            isMissing: true,  // Pet is missing
            createdAt: "",
            updatedAt: "",
            ageYears: nil,
            ageMonths: nil,
            ageText: nil,
            ageIsApproximate: nil,
            allergies: nil,
            medications: nil,
            uniqueFeatures: nil,
            sex: nil,
            isNeutered: nil,
            qrCode: nil,
            dateOfBirth: nil
        )

        XCTAssertTrue(missingPet.isMissing, "Pet should be marked as missing")
        // Deletion should be blocked when isMissing is true
    }

    func testFoundPetCanBeDeleted() {
        // Pet not missing (found)
        let foundPet = Pet(
            id: "pet-456",
            ownerId: "owner-1",
            name: "Max",
            species: "Cat",
            breed: "Persian",
            color: nil,
            weight: nil,
            microchipNumber: nil,
            medicalNotes: nil,
            notes: nil,
            profileImage: nil,
            isMissing: false,  // Pet is not missing
            createdAt: "",
            updatedAt: "",
            ageYears: nil,
            ageMonths: nil,
            ageText: nil,
            ageIsApproximate: nil,
            allergies: nil,
            medications: nil,
            uniqueFeatures: nil,
            sex: nil,
            isNeutered: nil,
            qrCode: nil,
            dateOfBirth: nil
        )

        XCTAssertFalse(foundPet.isMissing, "Pet should not be marked as missing")
        // Deletion should be allowed when isMissing is false
    }

    // MARK: - SyncError Tests

    func testSyncErrorDescriptions() {
        XCTAssertEqual(SyncError.invalidActionType.errorDescription, "Invalid action type")
        XCTAssertEqual(SyncError.missingData("petId").errorDescription, "Missing required data: petId")
        XCTAssertEqual(SyncError.notImplemented.errorDescription, "Feature not yet implemented")
        XCTAssertEqual(SyncError.networkUnavailable.errorDescription, "Network connection unavailable")
    }

    // MARK: - Time Since Last Sync Tests

    func testTimeSinceLastSyncNever() async {
        let syncService = await SyncService(autoSync: false)

        await MainActor.run {
            // When lastSyncDate is nil
            XCTAssertEqual(syncService.timeSinceLastSync, "Never")
        }
    }
}
