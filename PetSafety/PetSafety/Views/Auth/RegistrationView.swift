import SwiftUI
import UserNotifications

struct RegistrationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var otpCode = ""
    @State private var showOTPField = false
    @State private var showBiometricEnrollment = false
    @State private var showPushPrompt = false
    @State private var resendCooldown = 0
    @State private var resendTimer: Timer?

    var onBackToLogin: () -> Void

    private var isValidEmail: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: trimmed)
    }

    var body: some View {
        ZStack {
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

                    // Registration Card
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("create_account")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)

                            Text("enter_details_subtitle")
                                .font(.system(size: 15))
                                .foregroundColor(.mutedText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Form
                        if !showOTPField {
                            VStack(spacing: 16) {
                                // First Name Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("first_name")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)

                                    HStack(spacing: 12) {
                                        Image(systemName: "person")
                                            .foregroundColor(.mutedText)
                                            .frame(width: 20)
                                        TextField("", text: $firstName)
                                            .textContentType(.givenName)
                                            .autocapitalization(.words)
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

                                // Last Name Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("last_name")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)

                                    HStack(spacing: 12) {
                                        Image(systemName: "person")
                                            .foregroundColor(.mutedText)
                                            .frame(width: 20)
                                        TextField("", text: $lastName)
                                            .textContentType(.familyName)
                                            .autocapitalization(.words)
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

                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("email_address")
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

                                    if !email.isEmpty && !isValidEmail {
                                        Text("invalid_email")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                            .padding(.top, 2)
                                    }
                                }

                                // Register Button
                                Button(action: sendOTP) {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("create_account")
                                    }
                                }
                                .buttonStyle(BrandButtonStyle(isDisabled: firstName.isEmpty || !isValidEmail))
                                .disabled(firstName.isEmpty || !isValidEmail || authViewModel.isLoading)
                                .padding(.top, 8)
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
                            Text("by_creating_account_agree")
                                .font(.system(size: 12))
                                .foregroundColor(.mutedText)
                            HStack(spacing: 4) {
                                Link("terms_of_service", destination: URL(string: "https://pet-er.app/terms")!)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.brandOrange)
                                Text("terms_and")
                                    .font(.system(size: 12))
                                    .foregroundColor(.mutedText)
                                Link("privacy_policy", destination: URL(string: "https://pet-er.app/privacy")!)
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

                    // Already have an account? Log in
                    VStack(spacing: 8) {
                        Text("already_have_account")
                            .font(.system(size: 14))
                            .foregroundColor(.mutedText)

                        Button(action: onBackToLogin) {
                            Text("log_in")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.brandOrange)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert(String(format: NSLocalizedString("enable_biometric_type", comment: ""), authViewModel.biometricTypeName), isPresented: $showBiometricEnrollment) {
            Button("enable") {
                authViewModel.setBiometricEnabled(true)
                appState.showSuccess(String(format: NSLocalizedString("biometric_type_enabled", comment: ""), authViewModel.biometricTypeName))
                showPushPromptIfNeeded()
            }
            Button("skip", role: .cancel) {
                showPushPromptIfNeeded()
            }
        } message: {
            Text(String(format: NSLocalizedString("use_biometric_quick_login", comment: ""), authViewModel.biometricTypeName))
        }
        .sheet(isPresented: $showPushPrompt) {
            PushNotificationPromptView(
                onEnable: {
                    AppDelegate.requestPushPermission()
                    UserDefaults.standard.set(true, forKey: "push_prompt_shown")
                },
                onDismiss: {
                    UserDefaults.standard.set(true, forKey: "push_prompt_shown")
                }
            )
        }
    }

    private func showPushPromptIfNeeded() {
        // Only show once per user
        let alreadyShown = UserDefaults.standard.bool(forKey: "push_prompt_shown")
        guard !alreadyShown else { return }

        // Check if permission is not yet determined
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                DispatchQueue.main.async {
                    self.showPushPrompt = true
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
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await authViewModel.verifyOTP(email: trimmedEmail, code: otpCode)
                // Update user profile with name after successful registration
                var updates: [String: Any] = ["first_name": trimmedFirstName]
                if !trimmedLastName.isEmpty {
                    updates["last_name"] = trimmedLastName
                }
                try? await authViewModel.updateProfile(updates: updates)
                // Offer biometric enrollment
                if authViewModel.shouldOfferBiometricEnrollment {
                    showBiometricEnrollment = true
                } else {
                    showPushPromptIfNeeded()
                }
            } catch {
                appState.showError(error.localizedDescription)
            }
        }
    }
}

#Preview {
    RegistrationView(onBackToLogin: {})
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
