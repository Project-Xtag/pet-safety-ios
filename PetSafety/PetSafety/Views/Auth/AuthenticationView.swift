import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var otpCode = ""
    @State private var showOTPField = false
    @State private var showBiometricEnrollment = false
    @State private var showOrderTagSheet = false
    @State private var resendCooldown = 0
    @State private var resendTimer: Timer?
    var onNavigateToRegister: (() -> Void)?

    private var isValidEmail: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: trimmed)
    }

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
                            Text("welcome_back")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)

                            Text("enter_email_subtitle")
                                .font(.system(size: 15))
                                .foregroundColor(.mutedText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Form
                        if !showOTPField {
                            VStack(spacing: 16) {
                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("email_address")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)

                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope")
                                            .foregroundColor(.mutedText)
                                            .frame(width: 20)
                                            .accessibilityHidden(true)
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

                                    if !email.isEmpty && !isValidEmail {
                                        Text("invalid_email")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                            .padding(.top, 2)
                                    }
                                }

                                // Send Code Button
                                Button(action: sendOTP) {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("send_login_code")
                                    }
                                }
                                .buttonStyle(BrandButtonStyle(isDisabled: !isValidEmail))
                                .disabled(!isValidEmail || authViewModel.isLoading)
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
                                                .accessibilityLabel(NSLocalizedString("biometric_login_title", comment: ""))
                                            Text(String(format: NSLocalizedString("login_with_biometric_type", comment: ""), authViewModel.biometricTypeName))
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
                                    Text("otp_sent_to")
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
                                        Text("verify_code")
                                    }
                                }
                                .buttonStyle(BrandButtonStyle(isDisabled: otpCode.count != 6))
                                .disabled(otpCode.count != 6 || authViewModel.isLoading)

                                // Resend code
                                VStack(spacing: 8) {
                                    if resendCooldown > 0 {
                                        Text(String(format: NSLocalizedString("resend_code_cooldown", comment: ""), resendCooldown))
                                            .font(.system(size: 14))
                                            .foregroundColor(.mutedText)
                                    } else {
                                        Button(action: resendOTP) {
                                            Text("resend_code_prompt")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.brandOrange)
                                        }
                                        .disabled(authViewModel.isLoading)
                                    }
                                }

                                Button("use_different_email") {
                                    showOTPField = false
                                    otpCode = ""
                                    stopResendTimer()
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.mutedText)
                            }
                        }

                        // T&Cs and Privacy Policy Disclaimer
                        VStack(spacing: 4) {
                            Text("terms_login_prefix")
                                .font(.system(size: 12))
                                .foregroundColor(.mutedText)
                            HStack(spacing: 4) {
                                Link("terms_of_service", destination: URL(string: "https://senra.pet/terms-conditions")!)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.brandOrange)
                                Text("terms_and")
                                    .font(.system(size: 12))
                                    .foregroundColor(.mutedText)
                                Link("privacy_policy", destination: URL(string: "https://senra.pet/privacy-policy")!)
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

                    // Register & Order Tag CTAs for new users (outside card)
                    VStack(spacing: 8) {
                        Text("dont_have_account")
                            .font(.system(size: 14))
                            .foregroundColor(.mutedText)

                        Button(action: { onNavigateToRegister?() }) {
                            Text("register")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.brandOrange)
                        }

                        Button(action: { showOrderTagSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 14))
                                Text("start_here_order_free_tag")
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
        .alert(String(format: NSLocalizedString("enable_biometric_type", comment: ""), authViewModel.biometricTypeName), isPresented: $showBiometricEnrollment) {
            Button("enable") {
                authViewModel.setBiometricEnabled(true)
                appState.showSuccess(String(format: NSLocalizedString("biometric_type_enabled", comment: ""), authViewModel.biometricTypeName))
            }
            Button("skip", role: .cancel) {}
        } message: {
            Text(String(format: NSLocalizedString("use_biometric_quick_login", comment: ""), authViewModel.biometricTypeName))
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
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await authViewModel.login(email: trimmedEmail)
                showOTPField = true
                appState.showSuccess(String(format: NSLocalizedString("code_sent_to_email", comment: ""), trimmedEmail))
                startResendTimer()
            } catch {
                appState.showError(error.localizedDescription)
            }
        }
    }

    private func resendOTP() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await authViewModel.login(email: trimmedEmail)
                appState.showSuccess(String(format: NSLocalizedString("new_code_sent_to_email", comment: ""), trimmedEmail))
                startResendTimer()
            } catch {
                appState.showError(error.localizedDescription)
            }
        }
    }

    private func startResendTimer() {
        resendCooldown = 60
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                if resendCooldown > 0 {
                    resendCooldown -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    private func stopResendTimer() {
        resendTimer?.invalidate()
        resendTimer = nil
        resendCooldown = 0
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
