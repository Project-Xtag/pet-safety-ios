import SwiftUI

/// Branded splash shown while the app finishes wiring up, then hands off to
/// `ContentView` via `onFinished()`.
///
/// **Contract preserved — do NOT change:** calls `onFinished()` after
/// `holdDuration`, which `PetSafetyApp` uses to drop the `showSplash` gate.
///
/// C0 makes this the app's single branded logo moment: the launch storyboard is
/// bare, so the splash shows the plain "X" **mark** (no wordmark) on
/// `BackgroundColor`, blooming in via a soft glow + fade/scale reveal (skipped
/// under Reduce Motion). Touches no routing or auth.
struct SplashScreenView: View {
    var onFinished: () -> Void

    /// How long the mark holds before handing off. The launch storyboard is now
    /// bare (no logo), so this hold is where the brand mark actually registers —
    /// lengthened from the original 0.8s to 2.0s so it reads as a deliberate
    /// moment rather than a blink before the 0.4s cross-fade.
    static let holdDuration: TimeInterval = 2.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()

            // Soft brand-warm glow behind the mark — subtle enough to keep the
            // mark legible on both the light and dark `BackgroundColor` variants.
            RadialGradient(
                colors: [Color.brandOrange.opacity(0.12), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 340
            )
            .ignoresSafeArea()
            .opacity(appeared ? 1 : 0)

            // The plain brushstroke "X" mark (no wordmark). The localized
            // "SENRA / tagline" lockup lives on the content screens; a mark-only
            // splash is language-neutral and a bolder, bigger hero than the thin
            // 3:1 lockup was. (Dark mode: the mark isn't recolored — same as the
            // brand's own dark lockup — so check the darker strokes in dark QA.)
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240)   // square mark → strong centred presence; tune in visual QA
                .shadow(color: Color.brandOrange.opacity(0.10), radius: 24, x: 0, y: 8)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.94)
        }
        .onAppear {
            // Refined entrance (disabled under Reduce Motion for accessibility).
            // ~0.32s in leaves the mark at full opacity for the rest of the 2.0s
            // hold before the 0.4s cross-fade — a settled beat, not a flicker.
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.32)) {
                    appeared = true
                }
            }

            // Handoff contract — unchanged: brief hold, then drop the splash.
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.holdDuration) {
                onFinished()
            }
        }
    }
}
