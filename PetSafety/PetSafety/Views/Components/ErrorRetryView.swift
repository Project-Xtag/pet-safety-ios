import SwiftUI

/// Reusable error state view with retry button
struct ErrorRetryView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 100, height: 100)
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 44))
                    .foregroundColor(.brandOrange)
            }

            Text("something_went_wrong")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("try_again")
                }
            }
            .buttonStyle(BrandButtonStyle())
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}
