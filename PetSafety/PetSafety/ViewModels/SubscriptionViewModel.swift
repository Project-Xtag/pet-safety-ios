import Foundation
import SwiftUI

@MainActor
class SubscriptionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSubscription: UserSubscription?
    @Published var features: SubscriptionFeatures?
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Computed Properties
    var currentPlanName: String {
        currentSubscription?.planName ?? "None"
    }

    var hasActiveSubscription: Bool {
        currentSubscription?.isActive ?? false
    }

    var isOnStarterPlan: Bool {
        currentSubscription?.planName.lowercased() == "starter"
    }

    var canCreateAlerts: Bool {
        features?.canCreateAlerts ?? false
    }

    // MARK: - Initialization
    init() {
        // Listen for SSE subscription_changed events and auto-refresh
        SSEService.shared.onSubscriptionChanged = { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadCurrentSubscription()
                await self?.loadFeatures()
            }
        }
    }

    deinit {
        SSEService.shared.onSubscriptionChanged = nil
    }

    // MARK: - Data Loading
    func loadCurrentSubscription() async {
        do {
            currentSubscription = try await APIService.shared.getMySubscription()
            #if DEBUG
            if let sub = currentSubscription {
                print("✅ Current subscription: \(sub.planName) (\(sub.status))")
            } else {
                print("ℹ️ No active subscription")
            }
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load subscription: \(error)")
            #endif
        }
    }

    func loadFeatures() async {
        do {
            features = try await APIService.shared.getSubscriptionFeatures()
            #if DEBUG
            print("✅ Loaded subscription features")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load features: \(error)")
            #endif
        }
    }

    func loadAll() async {
        isLoading = true
        await loadCurrentSubscription()
        await loadFeatures()
        isLoading = false
    }

    // MARK: - Feature Checks
    func checkPetLimit(currentPetCount: Int) -> Bool {
        guard let features = features else { return true }
        if let maxPets = features.maxPets {
            return currentPetCount < maxPets
        }
        return true
    }

    func checkPhotoLimit(currentPhotoCount: Int) -> Bool {
        guard let features = features else { return true }
        return currentPhotoCount < features.resolvedMaxPhotosPerPet
    }

    func checkContactLimit(currentContactCount: Int) -> Bool {
        guard let features = features else { return true }
        return currentContactCount < features.resolvedMaxEmergencyContacts
    }
}
