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

    /// User-facing name for the current plan. Maps the backend slug
    /// ("starter" / "standard") to the localized branded label
    /// ("Induló csomag" / "Kedvenc csomag" in HU, "Starter pack" /
    /// "Pet pack" in EN). Pre-fix the Profile view rendered the raw
    /// slug `.capitalized`, so HU users saw "Standard" instead of
    /// "Kedvenc csomag" while Android already mapped via string
    /// resources. Falls back to the capitalized slug for legacy or
    /// future plan names that don't have a translation yet.
    var currentPlanDisplayName: String {
        switch currentPlanName.lowercased() {
        case "starter":  return String(localized: "plan_starter_display_name")
        case "standard": return String(localized: "plan_standard_display_name")
        default:         return currentPlanName.capitalized
        }
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

    /// Audit #89 — token returned by SSEService.addSubscriptionChangedHandler.
    /// Stored so we can remove THIS instance's handler in deinit without
    /// affecting any other SubscriptionViewModel that's also observing.
    /// Pre-fix the single-callback property got stomped between instances.
    private var subscriptionHandlerToken: UUID?

    init() {
        // Listen for SSE subscription_changed events and auto-refresh.
        // Multiple SubscriptionViewModels (e.g. nav root + settings sheet)
        // each get their own slot in the registry — none clobber the others.
        subscriptionHandlerToken = SSEService.shared.addSubscriptionChangedHandler { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadCurrentSubscription()
                await self?.loadFeatures()
            }
        }
    }

    deinit {
        if let token = subscriptionHandlerToken {
            SSEService.shared.removeSubscriptionChangedHandler(token)
        }
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
