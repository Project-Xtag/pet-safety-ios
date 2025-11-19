import SwiftUI

struct HelpAndSupportView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingContactForm = false

    var body: some View {
        List {
            Section(header: Text("Quick Actions")) {
                Button(action: { showingContactForm = true }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Text("Contact Support")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Resources")) {
                NavigationLink(destination: FAQView()) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Text("Frequently Asked Questions")
                    }
                }

                NavigationLink(destination: GuidesView()) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Text("User Guides")
                    }
                }
            }

            Section(header: Text("Legal")) {
                Link(destination: URL(string: "https://pet-er.app/terms")!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.cyan)
                            .frame(width: 24)
                        Text("Terms of Service")
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
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("App Information")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("2024.11.001")
                        .foregroundColor(.secondary)
                }
            }

            Section(footer: Text("We're here to help! Our support team typically responds within 24 hours.")) {
                EmptyView()
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingContactForm) {
            ContactSupportView()
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
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }

                Section(header: Text("Subject")) {
                    TextField("Brief description of your issue", text: $subject)
                }

                Section(header: Text("Message")) {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                }

                Section {
                    Button(action: { submitRequest() }) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                Text("Sending...")
                            } else {
                                Text("Submit Request")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(subject.isEmpty || message.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func submitRequest() {
        isSubmitting = true

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            appState.showSuccess("Support request submitted! We'll get back to you within 24 hours.")
            dismiss()
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
        .navigationTitle("FAQ")
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
        .navigationTitle("FAQ")
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
        .navigationTitle("User Guides")
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

                Text("Detailed guide content will be available here.")
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
    }
}
