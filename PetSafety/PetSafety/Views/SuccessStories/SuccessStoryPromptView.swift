import SwiftUI
import CoreLocation

/// Prompt shown after marking a pet as found to encourage sharing a success story
struct SuccessStoryPromptView: View {
    let pet: Pet
    let onDismiss: () -> Void
    let onStorySubmitted: () -> Void

    @State private var showShareForm = false
    @State private var storyText = ""
    @State private var reunionCity = ""
    @State private var isPublic = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    private let maxStoryLength = 150

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showShareForm {
                    shareFormView
                } else {
                    promptView
                }
            }
            .navigationTitle(showShareForm ? "Share Your Story" : "Great News!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(showShareForm ? "Back" : "Skip") {
                        if showShareForm {
                            withAnimation {
                                showShareForm = false
                            }
                        } else {
                            onDismiss()
                        }
                    }
                }

                if showShareForm {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Post") {
                            submitStory()
                        }
                        .fontWeight(.semibold)
                        .disabled(isSubmitting)
                    }
                }
            }
        }
    }

    // MARK: - Prompt View
    private var promptView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success Animation
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.tealAccent.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.tealAccent.opacity(0.25))
                        .frame(width: 90, height: 90)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                }

                Text("\(pet.name) is home!")
                    .font(.title)
                    .fontWeight(.bold)
            }

            // Pet Photo
            AsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: pet.species.lowercased() == "dog" ? "dog.fill" : "cat.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, height: 100)
            .background(Color(.systemGray6))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.tealAccent, lineWidth: 3)
            )

            // Message
            VStack(spacing: 12) {
                Text("Share your reunion story!")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Help inspire other pet owners by sharing how \(pet.name) was reunited with you. Your story could give hope to others.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    withAnimation {
                        showShareForm = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Share My Story")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.tealAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Maybe Later")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Share Form View
    private var shareFormView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Pet Header
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: pet.species.lowercased() == "dog" ? "dog.fill" : "cat.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pet.name)
                            .font(.headline)
                        Text("Reunited!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Story Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Story")
                        .font(.headline)

                    TextEditor(text: $storyText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: storyText) { _, newValue in
                            if newValue.count > maxStoryLength {
                                storyText = String(newValue.prefix(maxStoryLength))
                            }
                        }

                    HStack {
                        Text("Share how \(pet.name) was found and reunited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(storyText.count)/\(maxStoryLength)")
                            .font(.caption)
                            .foregroundColor(storyText.count >= maxStoryLength ? .orange : .secondary)
                    }
                }

                // Reunion City
                VStack(alignment: .leading, spacing: 8) {
                    Text("City/Area (Optional)")
                        .font(.headline)

                    TextField("e.g., London, Manchester", text: $reunionCity)
                        .textFieldStyle(.roundedBorder)
                }

                // Privacy Toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $isPublic) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share Publicly")
                                .font(.headline)
                            Text("Allow others nearby to see your story")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.green)
                }

                // Error Message
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }

                // Submit Button
                Button {
                    submitStory()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSubmitting ? "Posting..." : "Share Story")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(storyText.isEmpty ? Color.gray : Color.tealAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(storyText.isEmpty || isSubmitting)

                // Info
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Your contact information will not be shared.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }

    // MARK: - Submit Story
    private func submitStory() {
        guard !storyText.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                _ = try await APIService.shared.createSuccessStorySimple(
                    petId: pet.id,
                    alertId: nil,
                    storyText: storyText.trimmingCharacters(in: .whitespacesAndNewlines),
                    reunionCity: reunionCity.isEmpty ? nil : reunionCity.trimmingCharacters(in: .whitespacesAndNewlines),
                    isPublic: isPublic
                )

                appState.showSuccess("Your story has been shared! Thank you for inspiring others.")
                onStorySubmitted()
            } catch {
                errorMessage = error.localizedDescription
            }

            isSubmitting = false
        }
    }
}

#Preview {
    SuccessStoryPromptView(
        pet: Pet(
            id: "1",
            ownerId: "1",
            name: "Max",
            species: "Dog",
            breed: "Golden Retriever",
            color: "Golden",
            weight: 30.0,
            microchipNumber: nil,
            medicalNotes: nil,
            notes: nil,
            profileImage: nil,
            isMissing: false,
            createdAt: "",
            updatedAt: ""
        ),
        onDismiss: {},
        onStorySubmitted: {}
    )
    .environmentObject(AppState())
}
