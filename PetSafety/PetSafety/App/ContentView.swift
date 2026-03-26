import SwiftUI
import UIKit
import os

private let viewLog = Logger(subsystem: "com.petsafety.PetSafety", category: "ContentView")

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @StateObject private var deepLinkService = DeepLinkService.shared
    @State private var showRegistration = false

    var body: some View {
        let _ = viewLog.notice("⏱️ ContentView.body evaluated — isAuth: \(authViewModel.isAuthenticated), biometric: \(authViewModel.showBiometricPrompt), reg: \(showRegistration)")
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else if showRegistration {
                RegistrationView(onBackToLogin: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showRegistration = false
                    }
                })
                .transition(.opacity)
            } else {
                AuthenticationView(onNavigateToRegister: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showRegistration = true
                    }
                })
                .transition(.opacity)
            }
        }
        .onAppear {
            viewLog.notice("⏱️ ContentView.onAppear fired — UI is now visible")
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: showRegistration)
        .alert(appState.alertTitle, isPresented: $appState.showAlert) {
            Button("ok", role: .cancel) { }
        } message: {
            Text(appState.alertMessage)
        }
        .overlay {
            if appState.isLoading {
                LoadingView()
            }
        }
        // Handle deep links for tag activation (inactive tags)
        .sheet(isPresented: $deepLinkService.showTagActivation) {
            if let tagCode = deepLinkService.pendingTagCode {
                if authViewModel.isAuthenticated {
                    TagActivationView(tagCode: tagCode) {
                        deepLinkService.clearPendingLink()
                    }
                    .environmentObject(appState)
                } else {
                    // User not logged in - show message
                    DeepLinkLoginPromptView(tagCode: tagCode) {
                        deepLinkService.clearPendingLink()
                    }
                }
            }
        }
        // Handle deep links for active tags with a pet — show public pet profile
        .sheet(isPresented: $deepLinkService.showScannedPetProfile) {
            if let lookup = deepLinkService.scannedTagLookup,
               let pet = lookup.pet,
               let tagCode = deepLinkService.pendingTagCode {
                DeepLinkScannedPetView(pet: pet, tagCode: tagCode) {
                    deepLinkService.clearPendingLink()
                }
            }
        }
        // Show loading overlay while looking up tag
        .overlay {
            if deepLinkService.isLookingUpTag {
                LoadingView()
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        #if DEBUG
        print("Received URL: \(url.absoluteString)")
        #endif

        // Let the DeepLinkService handle the URL
        deepLinkService.handleURL(url)
    }
}

// MARK: - Deep Link Login Prompt
struct DeepLinkLoginPromptView: View {
    let tagCode: String
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.brandOrange.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.brandOrange)
                }

                Text(String(localized: "login_required"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text(String(localized: "login_required_activate_tag"))
                    .font(.system(size: 15))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                VStack(spacing: 8) {
                    Text(String(localized: "tag_code_label"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.mutedText)

                    Text(tagCode)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.vertical)

                Text(String(localized: "login_activate_instructions"))
                    .font(.system(size: 13))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                Button(action: onDismiss) {
                    Text(String(localized: "ok"))
                }
                .buttonStyle(BrandButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationTitle(String(localized: "tag_activate_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("close") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    NavigationView {
                        PetsListView(
                            onScanTag: { selectedTab = 1 },
                            onExploreAccount: { selectedTab = 3 }
                        )
                    }
                    .navigationViewStyle(.stack)
                    .transition(.opacity)
                case 1:
                    NavigationView {
                        QRScannerView()
                    }
                    .navigationViewStyle(.stack)
                    .transition(.opacity)
                case 2:
                    AlertsTabView()
                        .transition(.opacity)
                case 3:
                    NavigationView {
                        ProfileView()
                    }
                    .navigationViewStyle(.stack)
                    .transition(.opacity)
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(
                icon: "pawprint.fill",
                title: String(localized: "tab_my_pets"),
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )

            TabBarItem(
                icon: "qrcode.viewfinder",
                title: String(localized: "tab_scan_qr"),
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )

            TabBarItem(
                icon: "exclamationmark.triangle.fill",
                title: String(localized: "tab_alerts"),
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )

            TabBarItem(
                icon: "person.fill",
                title: String(localized: "tab_account"),
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -5)
        )
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .brandOrange : .mutedText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                isSelected
                    ? Color.peachBackground.opacity(0.8)
                    : Color.clear
            )
            .cornerRadius(16)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.brandOrange)
            }
            .frame(width: 100, height: 100)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
    }
}

// MARK: - Adaptive Layout Helpers (iPad-friendly)
extension View {
    func adaptiveContainer(maxWidth: CGFloat = 700) -> some View {
        self
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 24)
    }

    func adaptiveList(maxWidth: CGFloat = 700) -> some View {
        self
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Deep Link Scanned Pet View (Active tag with linked pet)
struct DeepLinkScannedPetView: View {
    let pet: TagLookupPet
    let tagCode: String
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingShareLocation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pet Photo
                    CachedAsyncImage(url: URL(string: pet.profileImage ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            Circle()
                                .fill(Color.tealAccent.opacity(0.2))
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.tealAccent)
                                .accessibilityLabel(String(localized: "accessibility_pet_photo"))
                        }
                    }
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // Pet Name & Info
                    VStack(spacing: 8) {
                        Text(String(format: NSLocalizedString("hello_pet_name", comment: ""), pet.name))
                            .font(.system(size: 26, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("scanned_tag_thanks")
                            .font(.system(size: 15))
                            .foregroundColor(.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // Pet details row
                        HStack(spacing: 16) {
                            if let breed = pet.breed {
                                Text("**\(NSLocalizedString("scanner_breed", comment: "")):** \(breed)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            if let age = pet.age {
                                Text("**\(NSLocalizedString("scanner_age", comment: "")):** \(age)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            if let color = pet.color {
                                Text("**\(NSLocalizedString("scanner_color", comment: "")):** \(color)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            if let sex = pet.sex, !sex.isEmpty {
                                Text("**\(NSLocalizedString("sex_label", comment: "")):** \(sex)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            if let neutered = pet.isNeutered {
                                Text("**\(NSLocalizedString("neutered_label", comment: "")):** \(neutered ? NSLocalizedString("yes", comment: "") : NSLocalizedString("no", comment: ""))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                        }
                    }

                    // Share Location Button
                    if let qrCode = pet.qrCode {
                        VStack(spacing: 8) {
                            Button(action: {
                                showingShareLocation = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "location.fill")
                                        .accessibilityLabel(String(localized: "accessibility_share_location"))
                                    Text("share_location_with_owner")
                                }
                            }
                            .buttonStyle(BrandButtonStyle())
                            .padding(.horizontal, 24)

                            Text(String(format: NSLocalizedString("owner_notified_sms_email", comment: ""), pet.name))
                                .font(.system(size: 12))
                                .foregroundColor(.mutedText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .sheet(isPresented: $showingShareLocation) {
                            ShareLocationView(qrCode: qrCode, petName: pet.name)
                        }
                    }

                    // Contact Owner Section
                    if pet.ownerPhone != nil || pet.ownerEmail != nil {
                        VStack(spacing: 16) {
                            Text("contact_owner")
                                .font(.system(size: 18, weight: .bold))

                            if let ownerName = pet.ownerName, !ownerName.trimmingCharacters(in: .whitespaces).isEmpty {
                                Text(ownerName)
                                    .font(.system(size: 15, weight: .medium))
                            }

                            Text("contact_owner_plea")
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                                .multilineTextAlignment(.center)

                            VStack(spacing: 12) {
                                if let phone = pet.ownerPhone {
                                    Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "phone.fill")
                                                .foregroundColor(.tealAccent)
                                                .accessibilityLabel(String(localized: "accessibility_call_owner"))
                                            Text(String(format: NSLocalizedString("call_phone", comment: ""), phone))
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.mutedText)
                                                .accessibilityHidden(true)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(14)
                                    }
                                }

                                if let email = pet.ownerEmail {
                                    Link(destination: URL(string: "mailto:\(email)")!) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "envelope.fill")
                                                .foregroundColor(.tealAccent)
                                                .accessibilityLabel(String(localized: "accessibility_email_owner"))
                                            Text(String(format: NSLocalizedString("email_contact", comment: ""), email))
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.mutedText)
                                                .accessibilityHidden(true)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(14)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Owner Address Section
                    if let address = pet.ownerAddress {
                        VStack(spacing: 12) {
                            Text("scanner_owner_location")
                                .font(.system(size: 18, weight: .bold))

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "house.fill")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)
                                    .accessibilityLabel(String(localized: "accessibility_owner_address"))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(address)
                                        .font(.system(size: 15, weight: .medium))
                                    if let line2 = pet.ownerAddressLine2, !line2.isEmpty {
                                        Text(line2)
                                            .font(.system(size: 14))
                                            .foregroundColor(.mutedText)
                                    }
                                    let cityLine = [pet.ownerCity, pet.ownerPostalCode].compactMap { $0 }.joined(separator: ", ")
                                    if !cityLine.isEmpty {
                                        Text(cityLine)
                                            .font(.system(size: 14))
                                            .foregroundColor(.mutedText)
                                    }
                                    if let country = pet.ownerCountry {
                                        Text(country)
                                            .font(.system(size: 14))
                                            .foregroundColor(.mutedText)
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                    }

                    // Medical Information
                    if let medical = pet.medicalInfo, !medical.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "cross.case.fill")
                                    .foregroundColor(.red)
                                    .accessibilityLabel(String(localized: "accessibility_medical_info"))
                                Text("scanner_medical_info")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            Text(medical)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    }

                    // Allergies
                    if let allergies = pet.allergies, !allergies.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .accessibilityLabel(String(localized: "accessibility_allergies"))
                                Text("scanner_allergies")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            Text(allergies)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    }

                    // Notes
                    if let notes = pet.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "note.text")
                                    .foregroundColor(.blue)
                                    .accessibilityLabel(String(localized: "accessibility_notes"))
                                Text("scanner_notes")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            Text(notes)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    }

                    // How It Works Card
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("scanner_how_it_works")
                                .font(.system(size: 18, weight: .bold))
                            Text(String(format: NSLocalizedString("help_reunite_pet", comment: ""), pet.name))
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HowItWorksStep(number: "1", title: NSLocalizedString("step_share_location", comment: ""), description: String(format: NSLocalizedString("scanner_step1_dynamic_desc", comment: ""), pet.name))
                            HowItWorksStep(number: "2", title: NSLocalizedString("step_owner_notified", comment: ""), description: NSLocalizedString("step_owner_notified_desc", comment: ""))
                            HowItWorksStep(number: "3", title: NSLocalizedString("step_quick_reunion", comment: ""), description: String(format: NSLocalizedString("scanner_step3_dynamic_desc", comment: ""), pet.name))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)

                    // Privacy Notice
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.mutedText)
                            .accessibilityLabel(String(localized: "accessibility_privacy_notice"))
                        Text(String(format: NSLocalizedString("privacy_notice", comment: ""), pet.name))
                            .font(.system(size: 12))
                            .foregroundColor(.mutedText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle(Text(String(format: NSLocalizedString("found_pet_title", comment: ""), pet.name)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done") {
                        onDismiss()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.brandOrange)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppState())
}
