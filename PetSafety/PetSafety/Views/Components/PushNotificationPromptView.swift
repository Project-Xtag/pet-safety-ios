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

            Text("Stay Connected")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(
                    icon: "qrcode.viewfinder",
                    text: "Get instant alerts when your pet's tag is scanned"
                )
                BenefitRow(
                    icon: "eye.fill",
                    text: "Receive sighting reports from the community"
                )
                BenefitRow(
                    icon: "heart.fill",
                    text: "Be the first to know when your pet is found"
                )
                BenefitRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "Get notified about missing pets in your area"
                )
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onEnable()
                    dismiss()
                } label: {
                    Text("Enable Notifications")
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
                    Text("Maybe Later")
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
