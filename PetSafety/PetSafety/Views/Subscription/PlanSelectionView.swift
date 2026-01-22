import SwiftUI
import SafariServices

struct PlanSelectionView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss

    let fromActivation: Bool
    let onComplete: (() -> Void)?

    init(fromActivation: Bool = false, onComplete: (() -> Void)? = nil) {
        self.fromActivation = fromActivation
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else {
                        // Plan Cards
                        planCards

                        // Skip Option (only after activation)
                        if fromActivation {
                            skipButton
                        }

                        // Info Section
                        infoSection
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Your Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !fromActivation {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
            .task {
                await viewModel.loadAll()
            }
            .sheet(isPresented: $viewModel.showCheckoutSheet) {
                if let url = viewModel.checkoutURL {
                    SafariCheckoutView(url: url) { success in
                        Task {
                            if success {
                                await viewModel.handleCheckoutComplete()
                                onComplete?()
                                dismiss()
                            } else {
                                viewModel.handleCheckoutCancelled()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 8) {
            if fromActivation {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)

                Text("Tag Activated!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Choose a plan to unlock all features")
                    .foregroundColor(.secondary)
            } else {
                Text("Upgrade Your Plan")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Get more features for your pets")
                    .foregroundColor(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.top)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading plans...")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 60)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Failed to load plans")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.loadAll()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 40)
    }

    private var planCards: some View {
        VStack(spacing: 16) {
            // Starter Plan
            if let starter = viewModel.starterPlan {
                PlanCard(
                    plan: starter,
                    isCurrentPlan: viewModel.currentSubscription?.planName.lowercased() == "starter",
                    isProcessing: viewModel.isProcessing
                ) {
                    Task {
                        await viewModel.selectPlan(starter)
                        if viewModel.error == nil && starter.isFree {
                            onComplete?()
                            dismiss()
                        }
                    }
                }
            }

            // Standard Plan
            if let standard = viewModel.standardPlan {
                PlanCard(
                    plan: standard,
                    isCurrentPlan: viewModel.currentSubscription?.planName.lowercased() == "standard",
                    isProcessing: viewModel.isProcessing,
                    isPopular: true
                ) {
                    Task {
                        await viewModel.selectPlan(standard)
                    }
                }
            }

            // Ultimate Plan
            if let ultimate = viewModel.ultimatePlan {
                PlanCard(
                    plan: ultimate,
                    isCurrentPlan: viewModel.currentSubscription?.planName.lowercased() == "ultimate",
                    isProcessing: viewModel.isProcessing
                ) {
                    Task {
                        await viewModel.selectPlan(ultimate)
                    }
                }
            }
        }
    }

    private var skipButton: some View {
        Button {
            // Skip = use Starter plan
            Task {
                if let starter = viewModel.starterPlan {
                    await viewModel.selectPlan(starter)
                }
                onComplete?()
                dismiss()
            }
        } label: {
            Text("Skip for now (Free Plan)")
                .foregroundColor(.secondary)
                .underline()
        }
        .padding(.top, 8)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All plans include:")
                .font(.headline)

            FeatureRow(icon: "qrcode", text: "QR tag for your pet")
            FeatureRow(icon: "bell.badge", text: "Instant scan notifications")
            FeatureRow(icon: "person.crop.circle", text: "Public pet profile")
            FeatureRow(icon: "lock.shield", text: "Secure data storage")

            Divider()
                .padding(.vertical, 8)

            Text("Paid plans add:")
                .font(.headline)

            FeatureRow(icon: "megaphone", text: "Lost pet alerts to vets & community")
            FeatureRow(icon: "message.badge", text: "SMS notifications")
            FeatureRow(icon: "photo.stack", text: "Up to 10 photos per pet")
            FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Free tag replacements")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Plan Card Component

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isCurrentPlan: Bool
    let isProcessing: Bool
    var isPopular: Bool = false
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header with Popular Badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.displayName)
                        .font(.title3)
                        .fontWeight(.bold)

                    if let description = plan.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isPopular {
                    Text("Popular")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }

            // Price
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(plan.formattedMonthlyPrice)
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()
            }

            // Features
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(
                    icon: "pawprint",
                    text: "Pets: \(plan.features.maxPetsDisplay)",
                    included: true
                )
                FeatureRow(
                    icon: "photo",
                    text: "\(plan.features.maxPhotosPerPet) photos per pet",
                    included: true
                )
                FeatureRow(
                    icon: "megaphone",
                    text: "Lost pet alerts",
                    included: plan.features.vetAlerts
                )
                FeatureRow(
                    icon: "message",
                    text: "SMS notifications",
                    included: plan.features.smsNotifications
                )
            }

            // Select Button
            Button {
                onSelect()
            } label: {
                Group {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else if isCurrentPlan {
                        Text("Current Plan")
                    } else if plan.isFree {
                        Text("Select Free Plan")
                    } else {
                        Text("Select \(plan.displayName)")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(isCurrentPlan ? .gray : (isPopular ? .blue : .primary))
            .disabled(isCurrentPlan || isProcessing)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPopular ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let text: String
    var included: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(included ? .green : .gray)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(included ? .primary : .secondary)

            Spacer()

            if !included {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Safari Checkout View

struct SafariCheckoutView: UIViewControllerRepresentable {
    let url: URL
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.delegate = context.coordinator
        safari.preferredControlTintColor = .systemBlue
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onComplete: (Bool) -> Void

        init(onComplete: @escaping (Bool) -> Void) {
            self.onComplete = onComplete
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            // User dismissed the Safari view
            // We need to check subscription status to determine if they completed payment
            onComplete(true) // Assume success and let the app verify
        }
    }
}

// MARK: - Preview

#Preview {
    PlanSelectionView(fromActivation: true) {
        print("Plan selection complete")
    }
}
