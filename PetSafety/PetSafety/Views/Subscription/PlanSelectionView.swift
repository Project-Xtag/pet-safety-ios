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
            .navigationTitle("plan_choose_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !fromActivation {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("close") {
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
                    .foregroundColor(.tealAccent)

                Text("plan_tag_activated")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("plan_choose_subtitle")
                    .foregroundColor(.secondary)
            } else {
                Text("plan_upgrade_title")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("plan_upgrade_subtitle")
                    .foregroundColor(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.top)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("plan_loading")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 60)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("plan_load_failed")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("retry") {
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
            Text("plan_skip_free")
                .foregroundColor(.secondary)
                .underline()
        }
        .padding(.top, 8)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("plan_all_include")
                .font(.headline)

            FeatureRow(icon: "qrcode", text: String(localized: "plan_feature_qr_tag"))
            FeatureRow(icon: "bell.badge", text: String(localized: "plan_feature_scan_notif"))
            FeatureRow(icon: "person.crop.circle", text: String(localized: "plan_feature_public_profile"))
            FeatureRow(icon: "lock.shield", text: String(localized: "plan_feature_secure_storage"))

            Divider()
                .padding(.vertical, 8)

            Text("plan_paid_add")
                .font(.headline)

            FeatureRow(icon: "megaphone", text: String(localized: "plan_feature_lost_alerts"))
            FeatureRow(icon: "message.badge", text: String(localized: "plan_feature_sms"))
            FeatureRow(icon: "photo.stack", text: String(localized: "plan_feature_photos"))
            FeatureRow(icon: "arrow.triangle.2.circlepath", text: String(localized: "plan_feature_replacements"))
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
                    Text("plan_popular")
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
                    text: String(format: String(localized: "plan_feature_pets_count"), plan.features.maxPetsDisplay),
                    included: true
                )
                FeatureRow(
                    icon: "photo",
                    text: String(format: String(localized: "plan_feature_photos_count"), plan.features.maxPhotosPerPet),
                    included: true
                )
                FeatureRow(
                    icon: "megaphone",
                    text: String(localized: "plan_feature_lost_alerts_short"),
                    included: plan.features.vetAlerts
                )
                FeatureRow(
                    icon: "message",
                    text: String(localized: "plan_feature_sms"),
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
                        Text("plan_current")
                    } else if plan.isFree {
                        Text("plan_select_free")
                    } else {
                        Text("plan_select \(plan.displayName)")
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
                .foregroundColor(included ? .tealAccent : .gray)
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
        #if DEBUG
        print("Plan selection complete")
        #endif
    }
}
