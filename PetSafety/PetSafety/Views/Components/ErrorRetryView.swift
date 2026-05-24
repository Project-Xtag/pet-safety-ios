import SwiftUI

/// Reusable error state view with retry button
struct ErrorRetryView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.brandOrange.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "wifi.exclamationmark")
                    .font(.appFont(size: 40, weight: .semibold))
                    .foregroundColor(.brandOrangeDeep)
            }

            Text("something_went_wrong")
                .font(.appFont(size: 22, weight: .bold))
                .foregroundColor(.ink)

            Text(message)
                .font(.appFont(size: 15))
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xxl)

            Button(action: onRetry) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("try_again")
                }
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .padding(.horizontal, AppSpacing.xxl + AppSpacing.sm)

            Spacer()
        }
    }
}
