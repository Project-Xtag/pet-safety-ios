import SwiftUI
import UserNotifications

/// Custom pre-permission prompt for push notifications.
/// Explains the benefits before triggering the system dialog.
/// Shows as a sheet after registration or on first authenticated visit.
struct PushNotificationPromptView: View {
    @Environment(\.dismiss) private var dismiss
    let onEnable: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.brandOrange)

            Text("push_prompt_title")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(
                    icon: "qrcode.viewfinder",
                    text: String(localized: "push_prompt_benefit_scan")
                )
                BenefitRow(
                    icon: "eye.fill",
                    text: String(localized: "push_prompt_benefit_sighting")
                )
                BenefitRow(
                    icon: "heart.fill",
                    text: String(localized: "push_prompt_benefit_found")
                )
                BenefitRow(
                    icon: "exclamationmark.triangle.fill",
                    text: String(localized: "push_prompt_benefit_missing")
                )
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onEnable()
                    dismiss()
                } label: {
                    Text("push_prompt_enable")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandOrange)

                Button {
                    onDismiss()
                    dismiss()
                } label: {
                    Text("push_prompt_later")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding()
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brandOrange)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
        }
    }
}
