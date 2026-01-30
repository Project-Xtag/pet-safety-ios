import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var otpCode = ""
    @State private var showOTPField = false
    @State private var showBiometricEnrollment = false
    @State private var showOrderTagSheet = false

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Logo Section
                    VStack(spacing: 0) {
                        Image("LogoNew")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .padding(.top, 60)
                            .padding(.bottom, 20)
                    }

                    // Login Card
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome Back!")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Enter your email to receive a login code.")
                                .font(.system(size: 15))
                                .foregroundColor(.mutedText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Form
                        if !showOTPField {
                            VStack(spacing: 16) {
                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email Address")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)

                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope")
                                            .foregroundColor(.mutedText)
                                            .frame(width: 20)
                                        TextField("", text: $email)
                                            .textContentType(.emailAddress)
                                            .autocapitalization(.none)
                                            .keyboardType(.emailAddress)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                                    )
                                }

                                // Send Code Button
                                Button(action: sendOTP) {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Send Login Code")
                                    }
                                }
                                .buttonStyle(BrandButtonStyle(isDisabled: email.isEmpty))
                                .disabled(email.isEmpty || authViewModel.isLoading)
                                .padding(.top, 8)

                                // Biometric Login Option (if enabled and has stored session)
                                if authViewModel.canUseBiometric && authViewModel.biometricEnabled {
                                    Button(action: {
                                        Task {
                                            await authViewModel.authenticateWithBiometric()
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: authViewModel.biometricIconName)
                                                .font(.system(size: 18))
                                            Text("Log in with \(authViewModel.biometricTypeName)")
                                                .font(.system(size: 15, weight: .medium))
                                        }
                                        .foregroundColor(.brandOrange)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        } else {
                            // OTP Verification
                            VStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Enter 6-digit code sent to")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text(email)
                                        .font(.system(size: 14))
                                        .foregroundColor(.brandOrange)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                TextField("000000", text: $otpCode)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
                                    )

                                Button(action: verifyOTP) {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Verify Code")
                                    }
                                }
                                .buttonStyle(BrandButtonStyle(isDisabled: otpCode.count != 6))
                                .disabled(otpCode.count != 6 || authViewModel.isLoading)

                                Button("Use different email") {
                                    showOTPField = false
                                    otpCode = ""
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.mutedText)
                            }
                        }

                        // T&Cs and Privacy Policy Disclaimer
                        VStack(spacing: 4) {
                            Text("By logging in, you agree to our")
                                .font(.system(size: 12))
                                .foregroundColor(.mutedText)
                            HStack(spacing: 4) {
                                Link("Terms of Service", destination: URL(string: "https://pet-er.app/terms")!)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.brandOrange)
                                Text("and")
                                    .font(.system(size: 12))
                                    .foregroundColor(.mutedText)
                                Link("Privacy Policy", destination: URL(string: "https://pet-er.app/privacy")!)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.brandOrange)
                            }
                        }
                        .padding(.top, 8)

                    }
                    .padding(28)
                    .background(Color.cardBackground)
                    .cornerRadius(40)
                    .padding(.horizontal, 16)

                    // Order Free Tag CTA for new users (outside card)
                    VStack(spacing: 8) {
                        Text("Don't have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.mutedText)

                        Button(action: { showOrderTagSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 14))
                                Text("Start here & order your free tag")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.brandOrange)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showOrderTagSheet) {
            NavigationView {
                OrderMoreTagsView()
                    .environmentObject(appState)
                    .environmentObject(authViewModel)
            }
        }
        .alert("Enable \(authViewModel.biometricTypeName)?", isPresented: $showBiometricEnrollment) {
            Button("Enable") {
                authViewModel.setBiometricEnabled(true)
                appState.showSuccess("\(authViewModel.biometricTypeName) enabled")
            }
            Button("Skip", role: .cancel) {}
        } message: {
            Text("Use \(authViewModel.biometricTypeName) to quickly log in next time.")
        }
        .onAppear {
            // Show biometric prompt on appear if available
            if authViewModel.showBiometricPrompt {
                Task {
                    await authViewModel.authenticateWithBiometric()
                }
            }
        }
    }

    private func sendOTP() {
        Task {
            do {
                try await authViewModel.login(email: email)
                showOTPField = true
                appState.showSuccess("Code sent to \(email)")
            } catch {
                appState.showError(error.localizedDescription)
            }
        }
    }

    private func verifyOTP() {
        Task {
            do {
                try await authViewModel.verifyOTP(email: email, code: otpCode)
                // Offer biometric enrollment if available and not already enabled
                if authViewModel.shouldOfferBiometricEnrollment {
                    showBiometricEnrollment = true
                }
            } catch {
                appState.showError(error.localizedDescription)
            }
        }
    }
}

// Keep the original styles for backward compatibility
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color.brandOrange.opacity(0.8) : Color.brandOrange)
            .foregroundColor(.white)
            .cornerRadius(14)
            .fontWeight(.semibold)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
