import SwiftUI

struct ReferralView: View {
    @State private var code: String?
    @State private var expiresAt: String?
    @State private var referrals: [ReferralItem] = []
    @State private var isLoading = true
    @State private var isGenerating = false
    @State private var copied = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            // Referral Code Section
            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView(String(localized: "referral_loading"))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else if let code {
                    codeDisplay(code)
                } else {
                    generateButton
                }
            } header: {
                Text("referral_your_code")
            } footer: {
                Text("referral_share_footer")
            }

            // How It Works
            Section("referral_how_it_works") {
                Label(String(localized: "referral_step_1"), systemImage: "1.circle.fill")
                Label(String(localized: "referral_step_2"), systemImage: "2.circle.fill")
                Label(String(localized: "referral_step_3"), systemImage: "3.circle.fill")
            }

            // Referral History
            Section("referral_history") {
                if referrals.isEmpty {
                    Text("referral_no_referrals")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(referrals) { referral in
                        referralRow(referral)
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
        }
        .navigationTitle("referral_title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStatus()
        }
    }

    // MARK: - Code Display

    private func codeDisplay(_ code: String) -> some View {
        VStack(spacing: 12) {
            Text(code)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

            HStack(spacing: 12) {
                Button(action: copyCode) {
                    Label(copied ? String(localized: "referral_copied") : String(localized: "referral_copy"), systemImage: copied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: shareCode) {
                    Label(String(localized: "referral_share"), systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandOrange)
            }

            if let expiresAt {
                Text(String(format: String(localized: "referral_expires %@"), formatExpiryDate(expiresAt)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: generateCode) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .padding(.trailing, 4)
                }
                Text("referral_generate")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.brandOrange)
        .disabled(isGenerating)
        .padding(.vertical, 8)
    }

    // MARK: - Referral Row

    private func referralRow(_ referral: ReferralItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(referral.refereeEmail ?? String(localized: "referral_pending"))
                    .font(.subheadline)
                Text(statusText(referral.status))
                    .font(.caption)
                    .foregroundColor(statusColor(referral.status))
            }
            Spacer()
            if referral.rewardedAt != nil {
                Image(systemName: "gift.fill")
                    .foregroundColor(.green)
            }
        }
    }

    // MARK: - Actions

    private func loadStatus() async {
        isLoading = true
        do {
            let response = try await APIService.shared.getReferralStatus()
            code = response.code
            expiresAt = response.expiresAt
            referrals = response.referrals
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func generateCode() {
        Task {
            isGenerating = true
            errorMessage = nil
            do {
                let response = try await APIService.shared.generateReferralCode()
                code = response.code
                expiresAt = response.expiresAt
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }

    private func copyCode() {
        guard let code else { return }
        UIPasteboard.general.string = code
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }

    private func shareCode() {
        guard let code else { return }
        let text = "Use my referral code \(code) to get 2 months free on Pet Safety! https://pet-er.app/choose-plan?referral=\(code)"
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(controller, animated: true)
        }
    }

    // MARK: - Helpers

    private func formatExpiryDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: iso) else { return iso }
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        }
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }

    private func statusText(_ status: String) -> String {
        switch status {
        case "pending": return "Pending"
        case "signed_up": return "Signed Up"
        case "subscribed": return "Subscribed"
        case "rewarded": return "Rewarded"
        default: return status.capitalized
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "rewarded": return .green
        case "subscribed": return .blue
        case "signed_up": return .orange
        default: return .secondary
        }
    }
}
