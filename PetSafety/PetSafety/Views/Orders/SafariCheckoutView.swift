import SwiftUI
import SafariServices

/// SafariView wrapper used to present Stripe Checkout for physical-goods purchases
/// (QR tag orders, replacement shipping). Not used for digital subscriptions —
/// subscriptions are purchased on senra.pet outside the app.
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
            onComplete(true)
        }
    }
}
