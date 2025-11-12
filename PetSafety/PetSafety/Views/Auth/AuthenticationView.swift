import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var otpCode = ""
    @State private var showOTPField = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(Color("BrandColor"))

                    Text("Pet Safety")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Keep your pets safe with QR tags")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Login Form
                VStack(spacing: 20) {
                    if !showOTPField {
                        // Email Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }

                        Button(action: sendOTP) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Login Code")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(email.isEmpty || authViewModel.isLoading)
                    } else {
                        // OTP Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter 6-digit code sent to \(email)")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            TextField("000000", text: $otpCode)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 24, weight: .medium))
                        }

                        Button(action: verifyOTP) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Verify Code")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(otpCode.count != 6 || authViewModel.isLoading)

                        Button("Use different email") {
                            showOTPField = false
                            otpCode = ""
                        }
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Privacy and Terms
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
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
            } catch {
                appState.showError(error.localizedDescription)
            }
        }
    }
}

// Custom Text Field Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

// Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color("BrandColor").opacity(0.8) : Color("BrandColor"))
            .foregroundColor(.white)
            .cornerRadius(10)
            .fontWeight(.semibold)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
