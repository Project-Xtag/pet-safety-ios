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
                VStack(spacing: 14) {
                    Button(action: onScanTag) {
                        HStack(spacing: 8) {
                            Image(systemName: "qrcode.viewfinder")
                            Text("welcome_scan_first_tag")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("TealAccent"))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)

                    Button(action: onExploreAccount) {
                        Text("welcome_explore_account")
                            .font(.appFont(size: 15, weight: .medium))
                            .foregroundColor(Color("TealAccent"))
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
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color("TealAccent"))
                    .frame(width: 36, height: 36)
                Text(number)
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.appFont(size: 18))
                    .foregroundColor(Color("TealAccent"))
                    .frame(width: 24)
                Text(text)
                    .font(.appFont(size: 15))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}
