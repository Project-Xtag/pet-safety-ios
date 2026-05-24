import SwiftUI

/// Welcome landing screen for new users with no registered pets.
/// Shows a friendly onboarding experience with clear next steps.
struct WelcomeView: View {
    var onScanTag: () -> Void
    var onExploreAccount: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 20)

                // Hero logo
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                // Headline
                VStack(spacing: 10) {
                    Text("welcome_to_senra")
                        .font(.appFont(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    Text("welcome_subtitle")
                        .font(.appFont(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // 3-step explainer
                VStack(spacing: 16) {
                    WelcomeStep(number: "1", text: String(localized: "welcome_step_1"), icon: "qrcode.viewfinder")
                    WelcomeStep(number: "2", text: String(localized: "welcome_step_2"), icon: "square.and.pencil")
                    WelcomeStep(number: "3", text: String(localized: "welcome_step_3"), icon: "checkmark.shield.fill")
                }
                .padding(.horizontal, 32)

                // CTAs
                VStack(spacing: AppSpacing.md) {
                    Button(action: onScanTag) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "qrcode.viewfinder")
                            Text("welcome_scan_first_tag")
                        }
                    }
                    .buttonStyle(PrimaryPillButtonStyle())
                    .padding(.horizontal, AppSpacing.xl)

                    Button(action: onExploreAccount) {
                        Text("welcome_explore_account")
                            .font(.appFont(size: 15, weight: .semibold))
                            .foregroundColor(.brandOrangeDeep)
                    }
                }

                Spacer().frame(height: 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Welcome Step Row
private struct WelcomeStep: View {
    let number: String
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.brandGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.brandOrange.opacity(0.32), radius: 6, x: 0, y: 3)
                Text(number)
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.appFont(size: 18, weight: .semibold))
                    .foregroundColor(.brandOrangeDeep)
                    .frame(width: 24)
                Text(text)
                    .font(.appFont(size: 15, weight: .medium))
                    .foregroundColor(.ink)
            }

            Spacer()
        }
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.lg)
        .background(Color.cream)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(Color.softBorder, lineWidth: 1)
        )
    }
}
