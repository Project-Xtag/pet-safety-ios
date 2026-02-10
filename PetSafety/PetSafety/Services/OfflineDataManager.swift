import Foundation
import CoreData
import os

/// Manages offline data persistence using Core Data
/// Provides thread-safe CRUD operations for offline entities
class OfflineDataManager {
    /// Singleton instance for app-wide data management
    static let shared = OfflineDataManager()

    /// Main persistent container for Core Data stack
    private let container: NSPersistentContainer

    /// Indicates whether the persistent SQLite store is available
    private(set) var isPersistentStoreAvailable: Bool = true

    /// Stores the last persistent store load error (if any)
    private(set) var storeLoadError: Error?

    private let logger = Logger(subsystem: "com.petsafety.app", category: "OfflineDataManager")

    /// View context for UI operations (main thread)
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Background context for background operations
    private var backgroundContext: NSManagedObjectContext {
        container.newBackgroundContext()
    }

    init(storeType: String = NSSQLiteStoreType) {
        let storeName = "PetSafety"

        do {
            container = try Self.loadContainer(name: storeName, storeType: storeType)
        } catch {
            logger.error("Core Data store failed to load: \(error.localizedDescription)")
            storeLoadError = error

            if storeType == NSSQLiteStoreType, let storeURL = Self.defaultStoreURL(for: storeName) {
                do {
                    try Self.destroyPersistentStore(at: storeURL, name: storeName)
                    container = try Self.loadContainer(name: storeName, storeType: NSSQLiteStoreType)
                    logger.warning("Core Data store was reset and reloaded successfully")
                } catch {
                    logger.error("Core Data store recovery failed: \(error.localizedDescription)")
                    storeLoadError = error
                    isPersistentStoreAvailable = false
                    container = (try? Self.loadContainer(name: storeName, storeType: NSInMemoryStoreType))
                        ?? NSPersistentContainer(name: storeName)
                }
            } else {
                isPersistentStoreAvailable = false
                container = (try? Self.loadContainer(name: storeName, storeType: NSInMemoryStoreType))
                    ?? NSPersistentContainer(name: storeName)
            }
        }

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func loadContainer(name: String, storeType: String) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: name)

        if let description = container.persistentStoreDescriptions.first {
            description.type = storeType
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        var loadError: Error?
        let group = DispatchGroup()
        group.enter()
        container.loadPersistentStores { _, error in
            loadError = error
            group.leave()
        }
        group.wait()

        if let loadError = loadError {
            throw loadError
        }

        return container
    }

    private static func defaultStoreURL(for name: String) -> URL? {
        NSPersistentContainer(name: name).persistentStoreDescriptions.first?.url
    }

    private static func destroyPersistentStore(at url: URL, name: String) throws {
        let model = NSPersistentContainer(name: name).managedObjectModel
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
    }

    // MARK: - Pet Operations

    /// Save pet to local database
    func savePet(_ pet: Pet) throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<PetEntity> = PetEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", pet.id)

            let existingPet = try context.fetch(fetchRequest).first ?? PetEntity(context: context)

            // Update all attributes
            existingPet.id = pet.id
            existingPet.ownerId = pet.ownerId
            existingPet.name = pet.name
            existingPet.species = pet.species
            existingPet.breed = pet.breed
            existingPet.color = pet.color
            existingPet.weight = pet.weight ?? 0
            existingPet.microchipNumber = pet.microchipNumber
            existingPet.medicalNotes = pet.medicalNotes
            existingPet.notes = pet.notes
            existingPet.profileImage = pet.profileImage
            existingPet.isMissing = pet.isMissing
            existingPet.createdAt = pet.createdAt
            existingPet.updatedAt = pet.updatedAt
            existingPet.ageYears = Int32(pet.ageYears ?? 0)
            existingPet.ageMonths = Int32(pet.ageMonths ?? 0)
            existingPet.ageText = pet.ageText
            existingPet.ageIsApproximate = pet.ageIsApproximate ?? false
            existingPet.allergies = pet.allergies
            existingPet.medications = pet.medications
            existingPet.uniqueFeatures = pet.uniqueFeatures
            existingPet.sex = pet.sex
            existingPet.isNeutered = pet.isNeutered ?? false
            existingPet.qrCode = pet.qrCode
            existingPet.dateOfBirth = pet.dateOfBirth
            existingPet.ownerName = pet.ownerName
            existingPet.ownerPhone = pet.ownerPhone
            existingPet.ownerEmail = pet.ownerEmail
            existingPet.lastSyncedAt = Date()

            try context.save()
        }
    }

    /// Save multiple pets to local database
    func savePets(_ pets: [Pet]) throws {
        for pet in pets {
            try savePet(pet)
        }
    }

    /// Fetch all pets from local database
    func fetchPets() throws -> [Pet] {
        let context = viewContext
        let fetchRequest: NSFetchRequest<PetEntity> = PetEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { convertPetEntityToPet($0) }
    }

    /// Fetch a single pet by ID from local database
    func fetchPet(byId id: String) throws -> Pet? {
        let context = viewContext
        let fetchRequest: NSFetchRequest<PetEntity> = PetEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1

        guard let entity = try context.fetch(fetchRequest).first else {
            return nil
        }
        return convertPetEntityToPet(entity)
    }

    /// Delete a pet from local database
    func deletePet(withId id: String) throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<PetEntity> = PetEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)

            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                try context.save()
            }
        }
    }

    // MARK: - Alert Operations

    /// Save alert to local database
    func saveAlert(_ alert: MissingPetAlert) throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<AlertEntity> = AlertEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", alert.id)

            let existingAlert = try context.fetch(fetchRequest).first ?? AlertEntity(context: context)

            existingAlert.id = alert.id
            existingAlert.petId = alert.petId
            existingAlert.userId = alert.userId
            existingAlert.status = alert.status
            existingAlert.lastSeenLocation = alert.lastSeenLocation
            existingAlert.lastSeenLatitude = alert.lastSeenLatitude ?? 0
            existingAlert.lastSeenLongitude = alert.lastSeenLongitude ?? 0
            existingAlert.additionalInfo = alert.additionalInfo
            existingAlert.createdAt = alert.createdAt
            existingAlert.updatedAt = alert.updatedAt
            existingAlert.lastSyncedAt = Date()

            try context.save()
        }
    }

    /// Fetch all alerts from local database
    func fetchAlerts() throws -> [MissingPetAlert] {
        let context = viewContext
        let fetchRequest: NSFetchRequest<AlertEntity> = AlertEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { convertAlertEntityToAlert($0) }
    }

    /// Fetch alerts for a specific pet
    func fetchAlerts(forPetId petId: String) throws -> [MissingPetAlert] {
        let context = viewContext
        let fetchRequest: NSFetchRequest<AlertEntity> = AlertEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "petId == %@", petId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { convertAlertEntityToAlert($0) }
    }

    /// Delete an alert from local database
    func deleteAlert(withId id: String) throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<AlertEntity> = AlertEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)

            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                try context.save()
            }
        }
    }

    // MARK: - Success Story Operations

    /// Save success story to local database
    func saveSuccessStory(_ story: SuccessStory) throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<SuccessStoryEntity> = SuccessStoryEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", story.id)

            let existingStory = try context.fetch(fetchRequest).first ?? SuccessStoryEntity(context: context)

            existingStory.id = story.id
            existingStory.alertId = story.alertId
            existingStory.petId = story.petId
            existingStory.ownerId = story.ownerId
            existingStory.reunionCity = story.reunionCity
            existingStory.reunionLatitude = story.reunionLatitude ?? 0
            existingStory.reunionLongitude = story.reunionLongitude ?? 0
            existingStory.storyText = story.storyText
            existingStory.isPublic = story.isPublic
            existingStory.isConfirmed = story.isConfirmed
            existingStory.missingSince = story.missingSince
            existingStory.foundAt = story.foundAt
            existingStory.createdAt = story.createdAt
            existingStory.updatedAt = story.updatedAt
            existingStory.deletedAt = story.deletedAt
            existingStory.lastSyncedAt = Date()

            try context.save()
        }
    }

    /// Fetch all success stories from local database
    func fetchSuccessStories() throws -> [SuccessStory] {
        let context = viewContext
        let fetchRequest: NSFetchRequest<SuccessStoryEntity> = SuccessStoryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "deletedAt == nil AND isPublic == true AND isConfirmed == true")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "foundAt", ascending: false)]

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { convertSuccessStoryEntityToStory($0) }
    }

    /// Fetch success stories for a specific pet
    func fetchSuccessStories(forPetId petId: String) throws -> [SuccessStory] {
        let context = viewContext
        let fetchRequest: NSFetchRequest<SuccessStoryEntity> = SuccessStoryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "petId == %@ AND deletedAt == nil", petId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "foundAt", ascending: false)]

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { convertSuccessStoryEntityToStory($0) }
    }

    /// Delete a success story from local database
    func deleteSuccessStory(withId id: String) throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<SuccessStoryEntity> = SuccessStoryEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)

            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                try context.save()
            }
        }
    }

    // MARK: - Action Queue Operations

    /// Queue an action to be performed when online
    func queueAction(type: String, data: [String: Any]) throws -> UUID {
        let context = backgroundContext
        var actionId: UUID!

        try context.performAndWait {
            let action = ActionQueueEntity(context: context)
            action.id = UUID()
            action.actionType = type
            action.createdAt = Date()
            action.status = "pending"
            action.retryCount = 0

            // Serialize action data to JSON
            if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                action.actionData = jsonString
            }

            actionId = action.id
            try context.save()
        }

        return actionId
    }

    /// Fetch all pending actions from queue
    func fetchPendingActions() throws -> [QueuedAction] {
        let context = viewContext
        let fetchRequest: NSFetchRequest<ActionQueueEntity> = ActionQueueEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", "pending")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { entity -> QueuedAction? in
            guard let id = entity.id,
                  let type = entity.actionType,
                  let dataString = entity.actionData,
                  let data = dataString.data(using: .utf8),
                  let actionData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let createdAt = entity.createdAt,
                  let status = entity.status else {
                return nil
            }

            return QueuedAction(
                id: id,
                type: type,
                data: actionData,
                createdAt: createdAt,
                status: status,
                retryCount: Int(entity.retryCount),
                errorMessage: entity.errorMessage
            )
        }
    }

    /// Mark an action as completed
    func completeAction(withId id: UUID) throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<ActionQueueEntity> = ActionQueueEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                try context.save()
            }
        }
    }

    /// Mark an action as failed with error message
    func failAction(withId id: UUID, error: String, incrementRetry: Bool = true) throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<ActionQueueEntity> = ActionQueueEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            if let entity = try context.fetch(fetchRequest).first {
                entity.errorMessage = error
                if incrementRetry {
                    entity.retryCount += 1
                }

                // Delete if too many retries
                if entity.retryCount >= 5 {
                    context.delete(entity)
                } else {
                    entity.status = "failed"
                }

                try context.save()
            }
        }
    }

    /// Get count of pending actions
    func getPendingActionCount() throws -> Int {
        let context = viewContext
        let fetchRequest: NSFetchRequest<ActionQueueEntity> = ActionQueueEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", "pending")
        return try context.count(for: fetchRequest)
    }

    /// Fetch all failed actions from queue
    func fetchFailedActions() throws -> [QueuedAction] {
        let context = viewContext
        let fetchRequest: NSFetchRequest<ActionQueueEntity> = ActionQueueEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", "failed")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        let entities = try context.fetch(fetchRequest)
        return entities.compactMap { entity -> QueuedAction? in
            guard let id = entity.id,
                  let type = entity.actionType,
                  let dataString = entity.actionData,
                  let data = dataString.data(using: .utf8),
                  let actionData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let createdAt = entity.createdAt,
                  let status = entity.status else {
                return nil
            }

            return QueuedAction(
                id: id,
                type: type,
                data: actionData,
                createdAt: createdAt,
                status: status,
                retryCount: Int(entity.retryCount),
                errorMessage: entity.errorMessage
            )
        }
    }

    /// Get count of failed actions
    func getFailedActionCount() throws -> Int {
        let context = viewContext
        let fetchRequest: NSFetchRequest<ActionQueueEntity> = ActionQueueEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", "failed")
        return try context.count(for: fetchRequest)
    }

    /// Reset a failed action to pending for retry
    func retryAction(withId id: UUID) throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<ActionQueueEntity> = ActionQueueEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            if let entity = try context.fetch(fetchRequest).first {
                entity.status = "pending"
                entity.errorMessage = nil
                try context.save()
            }
        }
    }

    /// Dismiss (delete) a failed action
    func dismissAction(withId id: UUID) throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<ActionQueueEntity> = ActionQueueEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                try context.save()
            }
        }
    }

    /// Retry all failed actions (reset to pending)
    func retryAllFailedActions() throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<ActionQueueEntity> = ActionQueueEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "status == %@", "failed")

            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                entity.status = "pending"
                entity.errorMessage = nil
            }
            try context.save()
        }
    }

    /// Dismiss all failed actions
    func dismissAllFailedActions() throws {
        let context = backgroundContext
        try context.performAndWait {
            let fetchRequest: NSFetchRequest<ActionQueueEntity> = ActionQueueEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "status == %@", "failed")

            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }

    // MARK: - Conversion Helpers

    private func convertPetEntityToPet(_ entity: PetEntity) -> Pet? {
        guard let id = entity.id,
              let ownerId = entity.ownerId,
              let name = entity.name,
              let species = entity.species,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            return nil
        }

        return Pet(
            id: id,
            ownerId: ownerId,
            name: name,
            species: species,
            breed: entity.breed,
            color: entity.color,
            weight: entity.weight != 0 ? entity.weight : nil,
            microchipNumber: entity.microchipNumber,
            medicalNotes: entity.medicalNotes,
            notes: entity.notes,
            profileImage: entity.profileImage,
            isMissing: entity.isMissing,
            createdAt: createdAt,
            updatedAt: updatedAt,
            ageYears: entity.ageYears != 0 ? Int(entity.ageYears) : nil,
            ageMonths: entity.ageMonths != 0 ? Int(entity.ageMonths) : nil,
            ageText: entity.ageText,
            ageIsApproximate: entity.ageIsApproximate,
            allergies: entity.allergies,
            medications: entity.medications,
            uniqueFeatures: entity.uniqueFeatures,
            sex: entity.sex,
            isNeutered: entity.isNeutered,
            qrCode: entity.qrCode,
            dateOfBirth: entity.dateOfBirth,
            ownerName: entity.ownerName,
            ownerPhone: entity.ownerPhone,
            ownerEmail: entity.ownerEmail
        )
    }

    private func convertAlertEntityToAlert(_ entity: AlertEntity) -> MissingPetAlert? {
        guard let id = entity.id,
              let petId = entity.petId,
              let userId = entity.userId,
              let status = entity.status,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            return nil
        }

        return MissingPetAlert(
            id: id,
            petId: petId,
            userId: userId,
            status: status,
            lastSeenLocation: entity.lastSeenLocation,
            lastSeenLatitude: entity.lastSeenLatitude != 0 ? entity.lastSeenLatitude : nil,
            lastSeenLongitude: entity.lastSeenLongitude != 0 ? entity.lastSeenLongitude : nil,
            additionalInfo: entity.additionalInfo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            pet: nil,
            sightings: nil
        )
    }

    private func convertSuccessStoryEntityToStory(_ entity: SuccessStoryEntity) -> SuccessStory? {
        guard let id = entity.id,
              let petId = entity.petId,
              let foundAt = entity.foundAt,
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            return nil
        }

        return SuccessStory(
            id: id,
            alertId: entity.alertId,
            petId: petId,
            ownerId: entity.ownerId,
            reunionCity: entity.reunionCity,
            reunionLatitude: entity.reunionLatitude != 0 ? entity.reunionLatitude : nil,
            reunionLongitude: entity.reunionLongitude != 0 ? entity.reunionLongitude : nil,
            storyText: entity.storyText,
            isPublic: entity.isPublic,
            isConfirmed: entity.isConfirmed,
            missingSince: entity.missingSince,
            foundAt: foundAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: entity.deletedAt,
            petName: nil,
            petSpecies: nil,
            petPhotoUrl: nil,
            distanceKm: nil,
            photos: nil
        )
    }

    // MARK: - Utility Methods

    /// Clear all offline data (for logout or reset)
    func clearAllData() throws {
        let context = backgroundContext
        try context.performAndWait {
            // Delete all pets
            let petFetch: NSFetchRequest<NSFetchRequestResult> = PetEntity.fetchRequest()
            let petDelete = NSBatchDeleteRequest(fetchRequest: petFetch)
            try context.execute(petDelete)

            // Delete all alerts
            let alertFetch: NSFetchRequest<NSFetchRequestResult> = AlertEntity.fetchRequest()
            let alertDelete = NSBatchDeleteRequest(fetchRequest: alertFetch)
            try context.execute(alertDelete)

            // Delete all success stories
            let storyFetch: NSFetchRequest<NSFetchRequestResult> = SuccessStoryEntity.fetchRequest()
            let storyDelete = NSBatchDeleteRequest(fetchRequest: storyFetch)
            try context.execute(storyDelete)

            // Delete all queued actions
            let actionFetch: NSFetchRequest<NSFetchRequestResult> = ActionQueueEntity.fetchRequest()
            let actionDelete = NSBatchDeleteRequest(fetchRequest: actionFetch)
            try context.execute(actionDelete)

            try context.save()
        }
    }
}

// MARK: - Supporting Types

/// Represents a queued action to be performed when online
struct QueuedAction: Identifiable {
    let id: UUID
    let type: String
    let data: [String: Any]
    let createdAt: Date
    let status: String
    let retryCount: Int
    let errorMessage: String?
}
