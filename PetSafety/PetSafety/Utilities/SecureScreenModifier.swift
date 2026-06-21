import SwiftUI
import UIKit
import Combine

/// View modifier that blurs content when screen recording or mirroring is detected.
/// iOS equivalent of Android's FLAG_SECURE.
struct SecureScreenModifier: ViewModifier {
    @State private var isCaptured = UIScreen.main.isCaptured

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isCaptured ? 30 : 0)

            if isCaptured {
                VStack(spacing: 16) {
                    Image(systemName: "eye.slash.fill")
                        .font(.appFont(size: 48))
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    Text("screen_protected")
                        .font(.appFont(.headline))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            isCaptured = UIScreen.main.isCaptured
        }
    }
}

extension View {
    /// Applies screen-capture protection (blur + overlay while recording/mirroring).
    /// Disabled in DEBUG builds so product demos can be recorded; release builds
    /// (App Store / TestFlight) keep the protection.
    @ViewBuilder
    func secureScreen() -> some View {
        #if DEBUG
        self
        #else
        modifier(SecureScreenModifier())
        #endif
    }
}
