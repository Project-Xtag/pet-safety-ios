import SwiftUI

struct SplashScreenView: View {
    var onFinished: () -> Void

    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()

            Image(LocalizedLogo.imageName)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 40)
        }
        .onAppear {
            // Brief hold so the localized logo is visible, then transition to content.
            // The storyboard launch screen already covered the ~5s init time,
            // so this just ensures a smooth branded handoff.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onFinished()
            }
        }
    }
}
