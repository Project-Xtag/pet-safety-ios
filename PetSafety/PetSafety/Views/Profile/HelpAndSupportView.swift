import SwiftUI

private func localizedString(_ key: String) -> String {
    let current = NSLocalizedString(key, comment: "")
    if current != key {
        return current
    }

    guard
        let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
        let enBundle = Bundle(path: enPath)
    else {
        return key
    }

    let englishValue = enBundle.localizedString(forKey: key, value: nil, table: nil)
    return englishValue == key ? key : englishValue
}

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
                Link(destination: URL(string: "https://senra.pet/terms-conditions")!) {
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

                Link(destination: URL(string: "https://senra.pet/privacy-policy")!) {
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

    let categories: [(key: String, label: String)] = [
        ("General", NSLocalizedString("help_cat_general", comment: "")),
        ("Technical Issue", NSLocalizedString("help_cat_technical", comment: "")),
        ("Account", NSLocalizedString("help_cat_account", comment: "")),
        ("Billing", NSLocalizedString("help_cat_billing", comment: "")),
        ("Feature Request", NSLocalizedString("help_cat_feature", comment: "")),
        ("Other", NSLocalizedString("help_cat_other", comment: "")),
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("help_category")) {
                    Picker("help_category", selection: $selectedCategory) {
                        ForEach(categories, id: \.key) { category in
                            Text(category.label).tag(category.key)
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
                                    .tint(.white)
                                Text("help_sending")
                                    .foregroundColor(.white)
                            } else {
                                Text("help_submit_request")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        (subject.isEmpty || message.isEmpty || isSubmitting)
                            ? Color.brandOrange.opacity(0.4)
                            : Color.brandOrange
                    )
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
                    appState.showSuccess(NSLocalizedString("help_request_submitted", comment: ""))
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
    let faqGroups: [FAQGroup] = [
        FAQGroup(titleKey: "help_faq_group_getting_started", indices: [1, 2, 3, 13]),
        FAQGroup(titleKey: "help_faq_group_tags_scanning", indices: [4, 5, 6, 7, 25]),
        FAQGroup(titleKey: "help_faq_group_missing_pets", indices: [8, 9, 14, 18, 23, 26]),
        FAQGroup(titleKey: "help_faq_group_billing_plans", indices: [10, 11, 12, 21]),
        FAQGroup(titleKey: "help_faq_group_privacy_account", indices: [15, 19, 22, 24]),
        FAQGroup(titleKey: "help_faq_group_troubleshooting", indices: [16, 17, 20, 27]),
    ]

    var body: some View {
        List {
            ForEach(faqGroups) { group in
                Section(header: Text(localizedString(group.titleKey))) {
                    ForEach(group.items) { faq in
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
                }
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
    var guides: [GuideArticle] {
        [
            GuideArticle(
                title: localizedString("help_guide_qr_tags_title"),
                body: localizedString("help_guide_qr_tags_desc")
            ),
            GuideArticle(
                title: localizedString("help_guide_materials_title"),
                body: localizedString("help_guide_materials_desc")
            ),
            GuideArticle(
                title: localizedString("help_guide_emergency_title"),
                body: localizedString("help_guide_emergency_desc")
            ),
            GuideArticle(
                title: localizedString("help_guide_profile_title"),
                body: localizedString("help_guide_profile_desc")
            ),
            GuideArticle(
                title: localizedString("help_guide_missing_alerts_title"),
                body: localizedString("help_guide_missing_alerts_desc")
            ),
            GuideArticle(
                title: localizedString("help_guide_community_title"),
                body: localizedString("help_guide_community_desc")
            ),
        ]
    }

    var body: some View {
        List(guides) { guide in
            NavigationLink(destination: GuideDetailView(title: guide.title, content: guide.body)) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.cyan)
                    Text(guide.title)
                }
            }
        }
        .navigationTitle("help_guides_title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GuideDetailView: View {
    let title: String
    let content: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(content)
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
    let id: Int
    let question: String
    let answer: String
}

struct FAQGroup: Identifiable {
    let id = UUID()
    let titleKey: String
    let indices: [Int]

    var items: [FAQ] {
        indices.map { index in
            FAQ(
                id: index,
                question: localizedString("help_faq_q\(index)"),
                answer: localizedString("help_faq_a\(index)")
            )
        }
    }
}

struct GuideArticle: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

#Preview {
    NavigationView {
        HelpAndSupportView()
            .environmentObject(AppState())
            .environmentObject(AuthViewModel())
    }
}
