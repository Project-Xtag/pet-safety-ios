import SwiftUI
import SafariServices

struct BillingView: View {
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @EnvironmentObject var appState: AppState
    @State private var invoices: [InvoiceItem] = []
    @State private var isLoading = true
    @State private var isPortalLoading = false
    @State private var portalURL: URL?
    @State private var showSafari = false
    @State private var errorMessage: String?
    @State private var showCancelWarning = false
    @State private var isCancelling = false

    // MARK: - Computed Properties

    private var subscription: UserSubscription? {
        subscriptionViewModel.currentSubscription
    }

    private var canCancel: Bool {
        guard let sub = subscription else { return false }
        return sub.isActive && sub.isPaid && !(sub.cancelAtPeriodEnd ?? false)
    }

    private var periodEndFormatted: String? {
        guard let date = subscription?.currentPeriodEnd else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        // Use the app's preferred language (set by the user in-app or via device settings)
        if let preferredLang = Locale.preferredLanguages.first {
            formatter.locale = Locale(identifier: preferredLang)
        }
        return formatter.string(from: date)
    }

    var body: some View {
        List {
            // Current Plan Section
            if let sub = subscription {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("current_plan")
                                .font(.headline)
                            Spacer()
                            Text(sub.planName)
                                .font(.headline)
                                .foregroundColor(.brandOrange)
                        }

                        HStack {
                            Text(NSLocalizedString("billing_subscription", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            statusBadge(for: sub)
                        }

                        if sub.cancelAtPeriodEnd == true, let endDate = periodEndFormatted {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(String(format: NSLocalizedString("plan_cancels_on", comment: ""), endDate))
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                        } else if sub.isTrialing, let trialEnd = sub.trialEndFormatted {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(String(format: NSLocalizedString("trial_ends_on", comment: ""), trialEnd))
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                            if let days = sub.trialDaysLeft, days <= 7 {
                                Text(NSLocalizedString("trial_upgrade_now", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            }
                        } else if sub.isActive, let endDate = periodEndFormatted {
                            Text(String(format: NSLocalizedString("plan_renews", comment: ""), endDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("current_plan")
                }
            }

            // Past Due Warning
            if subscriptionViewModel.currentSubscription?.status == .pastDue {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("billing_past_due_title")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                        Text("billing_past_due_message")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button(action: openPortal) {
                            Text("billing_update_payment")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(isPortalLoading)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Manage Subscription Section
            Section {
                Button(action: openPortal) {
                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundColor(.brandOrange)
                        Text("billing_manage_subscription")
                        Spacer()
                        if isPortalLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(isPortalLoading)
            } header: {
                Text("billing_subscription")
            } footer: {
                Text("billing_portal_footer")
            }

            // Invoices Section
            Section("billing_invoices") {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView(String(localized: "billing_loading_invoices"))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else if invoices.isEmpty {
                    Text("billing_no_invoices")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(invoices) { invoice in
                        invoiceRow(invoice)
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }

            // Cancel Subscription Section
            if canCancel {
                Section {
                    Button(action: { showCancelWarning = true }) {
                        HStack {
                            if isCancelling {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                            }
                            Text("cancel_confirm")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    .disabled(isCancelling)
                }
            }
        }
        .navigationTitle("billing_title")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await subscriptionViewModel.loadCurrentSubscription()
            await loadInvoices()
        }
        .task {
            await subscriptionViewModel.loadCurrentSubscription()
            await loadInvoices()
        }
        .sheet(isPresented: $showSafari) {
            if let url = portalURL {
                SafariView(url: url)
            }
        }
        .confirmationDialog(
            NSLocalizedString("cancel_subscription_title", comment: ""),
            isPresented: $showCancelWarning,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("cancel_confirm", comment: ""), role: .destructive) {
                performCancelSubscription()
            }
            Button(NSLocalizedString("keep_subscription", comment: ""), role: .cancel) { }
        } message: {
            let warnings = [
                NSLocalizedString("cancel_warning_a", comment: ""),
                NSLocalizedString("cancel_warning_b", comment: ""),
                NSLocalizedString("cancel_warning_c", comment: ""),
                NSLocalizedString("cancel_warning_d", comment: "")
            ]
            let accessLine = periodEndFormatted.map {
                String(format: NSLocalizedString("cancel_access_until", comment: ""), $0)
            } ?? ""
            Text(warnings.joined(separator: "\n") + (accessLine.isEmpty ? "" : "\n\n\(accessLine)"))
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private func statusBadge(for sub: UserSubscription) -> some View {
        let color: Color = {
            if sub.cancelAtPeriodEnd == true { return .orange }
            switch sub.status {
            case .active, .trialing: return .green
            case .pastDue: return .orange
            case .cancelled, .expired: return .red
            default: return .secondary
            }
        }()
        Text(sub.displayStatus)
            .font(.caption.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }

    // MARK: - Invoice Row

    private func invoiceRow(_ invoice: InvoiceItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.number ?? String(localized: "billing_invoice"))
                    .font(.subheadline.weight(.medium))
                Text(formatDate(invoice.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatAmount(invoice.amount, currency: invoice.currency))
                    .font(.subheadline.weight(.semibold))
                Text(invoice.status?.capitalized ?? String(localized: "billing_unknown"))
                    .font(.caption)
                    .foregroundColor(invoice.status == "paid" ? .green : .orange)
            }

            if let pdfUrl = invoice.pdfUrl, let url = URL(string: pdfUrl) {
                Link(destination: url) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.brandOrange)
                }
                .padding(.leading, 8)
            }
        }
    }

    // MARK: - Actions

    private func openPortal() {
        Task {
            isPortalLoading = true
            errorMessage = nil
            do {
                let response = try await APIService.shared.createPortalSession()
                if let url = URL(string: response.url) {
                    portalURL = url
                    showSafari = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isPortalLoading = false
        }
    }

    private func performCancelSubscription() {
        isCancelling = true
        Task {
            await subscriptionViewModel.cancelSubscription()
            await MainActor.run {
                isCancelling = false
                let dateStr = periodEndFormatted ?? ""
                appState.showSuccess(String(format: NSLocalizedString("cancel_success", comment: ""), dateStr))
            }
        }
    }

    private func loadInvoices() async {
        isLoading = true
        do {
            invoices = try await APIService.shared.getInvoices()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Formatting

    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatAmount(_ amount: Int, currency: String) -> String {
        let value = Double(amount) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.uppercased()
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency) \(value)"
    }
}

// MARK: - Safari View

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
