import Foundation
import SwiftUI

@MainActor
class SubscriptionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var plans: [SubscriptionPlan] = []
    @Published var currentSubscription: UserSubscription?
    @Published var features: SubscriptionFeatures?
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var error: String?
    @Published var checkoutURL: URL?
    @Published var showCheckoutSheet = false

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

    var starterPlan: SubscriptionPlan? {
        plans.first { $0.name.lowercased() == "starter" }
    }

    var standardPlan: SubscriptionPlan? {
        plans.first { $0.name.lowercased() == "standard" }
    }

    var ultimatePlan: SubscriptionPlan? {
        plans.first { $0.name.lowercased() == "ultimate" }
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

    // MARK: - Data Loading
    func loadPlans() async {
        isLoading = true
        error = nil

        do {
            let fetchedPlans = try await APIService.shared.getSubscriptionPlans()
            plans = fetchedPlans
            #if DEBUG
            print("✅ Loaded \(plans.count) subscription plans")
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load plans: \(error)")
            #endif
        }

        isLoading = false
    }

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
        await loadPlans()
        await loadCurrentSubscription()
        await loadFeatures()
        isLoading = false
    }

    // MARK: - Plan Selection
    func selectPlan(_ plan: SubscriptionPlan, billingPeriod: String = "monthly") async {
        isProcessing = true
        error = nil

        do {
            if plan.isFree {
                // Free plan - direct upgrade
                let subscription = try await APIService.shared.upgradeToStarter()
                currentSubscription = subscription
                #if DEBUG
                print("✅ Upgraded to Starter plan")
                #endif
            } else {
                // Paid plan - create checkout session
                let checkout = try await APIService.shared.createSubscriptionCheckout(
                    planName: plan.name,
                    billingPeriod: billingPeriod
                )

                if let url = URL(string: checkout.url) {
                    checkoutURL = url
                    showCheckoutSheet = true
                    #if DEBUG
                    print("✅ Created checkout session, URL: \(checkout.url)")
                    #endif
                } else {
                    error = "Invalid checkout URL"
                }
            }
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to select plan: \(error)")
            #endif
        }

        isProcessing = false
    }

    // MARK: - Subscription Management
    func cancelSubscription() async {
        isProcessing = true
        error = nil

        do {
            let subscription = try await APIService.shared.cancelSubscription()
            currentSubscription = subscription
            #if DEBUG
            print("✅ Subscription cancelled")
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Failed to cancel subscription: \(error)")
            #endif
        }

        isProcessing = false
    }

    // MARK: - Post-Checkout
    func handleCheckoutComplete() async {
        // Reload subscription status after Stripe checkout
        await loadCurrentSubscription()
        await loadFeatures()
        showCheckoutSheet = false
        checkoutURL = nil
    }

    func handleCheckoutCancelled() {
        showCheckoutSheet = false
        checkoutURL = nil
    }

    // MARK: - Feature Checks
    func checkPetLimit(currentPetCount: Int) -> Bool {
        guard let features = features else { return true }
        if let maxPets = features.maxPets {
            return currentPetCount < maxPets
        }
        return true // Unlimited
    }

    func checkPhotoLimit(currentPhotoCount: Int) -> Bool {
        guard let features = features else { return true }
        return currentPhotoCount < features.maxPhotosPerPet
    }

    func checkContactLimit(currentContactCount: Int) -> Bool {
        guard let features = features else { return true }
        return currentContactCount < features.maxEmergencyContacts
    }
}
