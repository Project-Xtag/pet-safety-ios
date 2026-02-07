import SwiftUI

struct HelpAndSupportView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingContactForm = false
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var missingPetNames: [String] = []
    @State private var isCheckingDelete = false
    @State private var isDeleting = false

    var body: some View {
        List {
            Section(header: Text("help_quick_actions")) {
                Button(action: { showingContactForm = true }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Text("help_contact_support")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("help_resources")) {
                NavigationLink(destination: FAQView()) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Text("help_faq")
                    }
                }

                NavigationLink(destination: GuidesView()) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Text("help_user_guides")
                    }
                }
            }

            Section(header: Text("help_legal")) {
                Link(destination: URL(string: "https://pet-er.app/terms")!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Text("help_terms")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: URL(string: "https://pet-er.app/privacy")!) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Text("help_privacy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("help_app_info")) {
                HStack {
                    Text("help_version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("help_build")
                    Spacer()
                    Text("2024.11.001")
                        .foregroundColor(.secondary)
                }
            }

            Section(footer: Text("help_support_footer")) {
                EmptyView()
            }

            // Danger Zone Section
            Section(header: Text("profile_danger_zone").foregroundColor(.red)) {
                Button(action: { checkAndDeleteAccount() }) {
                    HStack {
                        if isCheckingDelete || isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24)
                        }
                        Text(isDeleting ? NSLocalizedString("profile_deleting", comment: "") : NSLocalizedString("profile_delete_account", comment: ""))
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
                .disabled(isCheckingDelete || isDeleting)
            }

            // Extra space for tab bar
            Section {
                Color.clear
                    .frame(height: 60)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("help_title")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingContactForm) {
            ContactSupportView()
        }
        .alert("profile_delete_account", isPresented: $showingDeleteConfirmation) {
            Button("cancel", role: .cancel) { }
            Button("delete_account", role: .destructive) {
                performDeleteAccount()
            }
        } message: {
            Text("delete_account_full_warning")
        }
        .alert("profile_cannot_delete", isPresented: $showingDeleteError) {
            Button("ok", role: .cancel) { }
        } message: {
            if missingPetNames.isEmpty {
                Text(deleteErrorMessage)
            } else {
                Text(String(format: NSLocalizedString("missing_pets_label", comment: ""), missingPetNames.joined(separator: ", ")))
            }
        }
    }

    // MARK: - Delete Account Helpers
    private func checkAndDeleteAccount() {
        isCheckingDelete = true

        Task {
            do {
                let response = try await APIService.shared.canDeleteAccount()

                await MainActor.run {
                    isCheckingDelete = false

                    if response.canDelete {
                        showingDeleteConfirmation = true
                    } else {
                        deleteErrorMessage = response.message ?? NSLocalizedString("profile_cannot_delete_message", comment: "")
                        missingPetNames = response.missingPets?.map { $0.name } ?? []
                        showingDeleteError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingDelete = false
                    deleteErrorMessage = error.localizedDescription
                    missingPetNames = []
                    showingDeleteError = true
                }
            }
        }
    }

    private func performDeleteAccount() {
        isDeleting = true

        Task {
            do {
                _ = try await APIService.shared.deleteAccount()
                await MainActor.run {
                    authViewModel.logout()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    deleteErrorMessage = error.localizedDescription
                    missingPetNames = []
                    showingDeleteError = true
                }
            }
        }
    }
}

// MARK: - Contact Support Form
struct ContactSupportView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedCategory = "General"
    @State private var isSubmitting = false

    let categories = ["General", "Technical Issue", "Account", "Billing", "Feature Request", "Other"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("help_category")) {
                    Picker("help_category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }

                Section(header: Text("help_subject")) {
                    TextField("help_subject_placeholder", text: $subject)
                }

                Section(header: Text("help_message")) {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                }

                Section {
                    Button(action: { submitRequest() }) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                Text("help_sending")
                            } else {
                                Text("help_submit_request")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(subject.isEmpty || message.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("help_contact_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func submitRequest() {
        isSubmitting = true

        Task {
            do {
                let response = try await APIService.shared.submitSupportRequest(
                    category: selectedCategory,
                    subject: subject,
                    message: message
                )
                await MainActor.run {
                    isSubmitting = false
                    appState.showSuccess("Support request submitted! Ticket ID: \(response.ticketId). We'll get back to you within 24 hours.")
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    appState.showError(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - FAQ View
struct FAQView: View {
    let faqs = [
        FAQ(question: "How do I activate my QR tag?", answer: "To activate your QR tag, scan it with your phone's camera and follow the on-screen instructions to link it to your pet's profile."),
        FAQ(question: "What should I do if my pet goes missing?", answer: "Immediately mark your pet as missing in the app. This will send alerts to nearby users, vets, and shelters. Update your pet's last known location and add any additional information that might help."),
        FAQ(question: "How do I order a replacement tag?", answer: "Go to the Profile tab, select 'Order Replacement Tag', choose your pet, and confirm your shipping address. Premium members get free replacements."),
        FAQ(question: "Can I have multiple pets?", answer: "Yes! You can add as many pets as you want to your account. Each pet can have its own QR tag."),
        FAQ(question: "How do notifications work?", answer: "You'll receive push notifications for pet sightings, nearby missing pet alerts, and important account updates. You can customize your notification preferences in Settings."),
    ]

    var body: some View {
        List(faqs) { faq in
            NavigationLink(destination: FAQDetailView(faq: faq)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(faq.question)
                        .font(.headline)
                    Text(faq.answer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("help_faq_title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQDetailView: View {
    let faq: FAQ

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(faq.question)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(faq.answer)
                    .font(.body)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("help_faq_title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Guides View
struct GuidesView: View {
    let guides = [
        "Getting Started with Pet Safety",
        "How to Use QR Tags",
        "Reporting a Missing Pet",
        "Finding Lost Pets Near You",
        "Managing Your Profile",
        "Understanding Subscription Benefits"
    ]

    var body: some View {
        List(guides, id: \.self) { guide in
            NavigationLink(destination: GuideDetailView(title: guide)) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.cyan)
                    Text(guide)
                }
            }
        }
        .navigationTitle("help_guides_title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GuideDetailView: View {
    let title: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)

                Text("help_guide_placeholder")
                    .font(.body)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Models
struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

#Preview {
    NavigationView {
        HelpAndSupportView()
            .environmentObject(AppState())
            .environmentObject(AuthViewModel())
    }
}
