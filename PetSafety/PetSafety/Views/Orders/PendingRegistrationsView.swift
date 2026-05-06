import SwiftUI

struct PendingRegistrationsView: View {
    @StateObject private var viewModel = PendingRegistrationsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if viewModel.registrations.isEmpty && !viewModel.isLoading {
                emptyState
            } else if !viewModel.registrations.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Ready to Activate Section
                        if !viewModel.readyToActivate.isEmpty {
                            readyToActivateSection
                        }

                        // Still Processing Section
                        if !viewModel.stillProcessing.isEmpty {
                            stillProcessingSection
                        }

                        // Help Section
                        helpSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(Text("pending_registrations_title"))
        .task {
            await viewModel.fetchPendingRegistrations()
        }
        .refreshable {
            await viewModel.fetchPendingRegistrations()
        }
        .overlay {
            if viewModel.isLoading && viewModel.registrations.isEmpty {
                ProgressView()
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.appFont(size: 60))
                .foregroundColor(.green)
            Text("all_caught_up")
                .font(.appFont(.title2))
                .fontWeight(.bold)
            Text("all_caught_up_description")
                .font(.appFont(.body))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            NavigationLink(destination: OrderMoreTagsView()) {
                Text("order_tags")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.brandOrange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Ready to Activate
    private var readyToActivateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("ready_to_activate")
                    .font(.appFont(.title3))
                    .fontWeight(.semibold)
            }

            ForEach(viewModel.readyToActivate) { reg in
                pendingCard(reg, isReady: true)
            }
        }
    }

    // MARK: - Still Processing
    private var stillProcessingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox")
                    .foregroundColor(.secondary)
                Text("still_processing")
                    .font(.appFont(.title3))
                    .fontWeight(.semibold)
            }

            ForEach(viewModel.stillProcessing) { reg in
                pendingCard(reg, isReady: false)
            }
        }
    }

    // MARK: - Card
    private func pendingCard(_ reg: PendingRegistration, isReady: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reg.petName)
                        .font(.appFont(.headline))
                    Text(formatDate(reg.createdAt))
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                }
                Spacer()
                statusBadge(for: reg.orderStatus)
            }

            if isReady {
                // 2026-05-05: removed the tracking link. Carrier
                // tracking URLs are unreliable across our shipping
                // partners (some carriers don't expose a stable
                // public URL, the link 404s for ~20% of HU orders),
                // so users hit a dead end more often than they hit a
                // working tracker. Order status is now communicated
                // via the status badge above + email updates from
                // the carrier directly.

                HStack(spacing: 12) {
                    NavigationLink(destination: QRScannerView()) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("scan_tag_now")
                        }
                        .font(.appFont(.subheadline))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.brandOrange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    NavigationLink(destination: PetFormView(mode: .create)) {
                        Text("create_profile_first")
                            .font(.appFont(.subheadline))
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.clear)
                            .foregroundColor(.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            } else {
                NavigationLink(destination: PetFormView(mode: .create)) {
                    Text("create_profile_while_waiting")
                        .font(.appFont(.subheadline))
                        .fontWeight(.medium)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.clear)
                        .foregroundColor(.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isReady ? Color.green.opacity(0.05) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isReady ? Color.green.opacity(0.2) : Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Help Section
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("activation_help_title")
                .font(.appFont(.headline))

            VStack(alignment: .leading, spacing: 6) {
                helpStep(number: "1", text: String(localized: "activation_help_step1"))
                helpStep(number: "2", text: String(localized: "activation_help_step2"))
                helpStep(number: "3", text: String(localized: "activation_help_step3"))
                helpStep(number: "4", text: String(localized: "activation_help_step4"))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func helpStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.appFont(.caption))
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(Color.brandOrange.opacity(0.15))
                .foregroundColor(.brandOrange)
                .cornerRadius(10)
            Text(text)
                .font(.appFont(.subheadline))
                .foregroundColor(.secondary)
        }
    }

    private func statusBadge(for status: String) -> some View {
        let (text, color): (String, Color) = {
            switch status.lowercased() {
            case "shipped": return (String(localized: "status_shipped"), .blue)
            case "delivered": return (String(localized: "status_delivered"), .green)
            case "processing": return (String(localized: "status_processing"), .orange)
            default: return (String(localized: "status_pending"), .gray)
            }
        }()

        return Text(text)
            .font(.appFont(.caption))
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    private func formatDate(_ dateString: String) -> String {
        // 2026-05-05 fix: the previous implementation used a single
        // `ISO8601DateFormatter` that rejected timestamps with
        // fractional seconds (the backend emits both forms depending
        // on the source row). On a parse failure we returned the raw
        // ISO string — users saw "2026-05-04T17:31:42.123Z" verbatim.
        // Try with-fractional-seconds first, fall back to plain
        // RFC3339, and only last-resort show the raw string. Use
        // .medium style with the user's current locale so HU sees
        // "2026. máj. 5." instead of US-format "May 5, 2026".
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]

        let date = withFractional.date(from: dateString) ?? plain.date(from: dateString)
        guard let date else { return dateString }

        let displayFormatter = DateFormatter()
        displayFormatter.locale = .current
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}
