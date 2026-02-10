import SwiftUI
import UIKit

struct PetDetailView: View {
    @State private var pet: Pet
    @StateObject private var viewModel = PetsViewModel()

    init(pet: Pet) {
        _pet = State(initialValue: pet)
    }
    @StateObject private var alertsViewModel = AlertsViewModel()
    @StateObject private var successStoriesVM = SuccessStoriesViewModel()
    @State private var petSuccessStory: SuccessStory?
    @State private var showRemoveStoryConfirmation = false
    @State private var showingEditSheet = false
    @State private var showingMarkLostSheet = false
    @State private var showingMarkFoundConfirmation = false
    @State private var showingSuccessStoryPrompt = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pet Photo
                AsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: pet.species.lowercased() == "dog" ? "dog.fill" : "cat.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.secondary)
                        .padding(40)
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .padding(.horizontal)

                // Pet Name
                Text(pet.name)
                    .font(.system(size: 32, weight: .bold))

                // View Photos Button (under pet name)
                NavigationLink(destination: PhotoGalleryView(pet: pet)) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                        Text(String(format: NSLocalizedString("view_pet_photos", comment: ""), pet.name))
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.tealAccent)
                    .cornerRadius(14)
                }
                .padding(.horizontal)

                // Mark as Lost/Found Buttons
                HStack(spacing: 12) {
                    if pet.isMissing {
                        Button(action: { showingMarkFoundConfirmation = true }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("mark_as_found")
                            }
                        }
                        .buttonStyle(FoundButtonStyle())
                    } else {
                        Button(action: { showingMarkLostSheet = true }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("mark_as_lost")
                            }
                        }
                        .buttonStyle(LostButtonStyle())
                    }
                }
                .padding(.horizontal)

                // Success Story Buttons (only for previously-missing pets that have/had stories)
                if !pet.isMissing && petSuccessStory != nil {
                    Button(action: { showRemoveStoryConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("remove_from_success_stories")
                        }
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .padding(.horizontal)
                }

                // Basic Info Cards
                VStack(spacing: 16) {
                    InfoCard(title: NSLocalizedString("species", comment: ""), value: pet.species.capitalized, icon: "pawprint.fill")

                    if let breed = pet.breed {
                        InfoCard(title: NSLocalizedString("breed", comment: ""), value: breed, icon: "list.bullet")
                    }

                    if let color = pet.color {
                        InfoCard(title: NSLocalizedString("color", comment: ""), value: color, icon: "paintpalette.fill")
                    }

                    if let age = pet.age {
                        InfoCard(title: NSLocalizedString("age", comment: ""), value: age, icon: "calendar")
                    }

                    if let weight = pet.weight {
                        InfoCard(title: NSLocalizedString("weight", comment: ""), value: String(format: "%.1f kg", weight), icon: "scalemass.fill")
                    }

                    if let sex = pet.sex, sex.lowercased() != "unknown" {
                        InfoCard(title: NSLocalizedString("sex", comment: ""), value: sex.capitalized, icon: "figure.stand")
                    }

                    if let isNeutered = pet.isNeutered, isNeutered {
                        InfoCard(title: NSLocalizedString("neutered_spayed", comment: ""), value: NSLocalizedString("yes", comment: ""), icon: "checkmark.seal.fill")
                    }

                    if let microchip = pet.microchipNumber {
                        InfoCard(title: NSLocalizedString("microchip", comment: ""), value: microchip, icon: "number")
                    }
                }
                .padding(.horizontal)

                // Health Information
                if pet.medicalInfo != nil || pet.allergies != nil || pet.medications != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("health_information", systemImage: "cross.case.fill")
                            .font(.headline)

                        if let medical = pet.medicalInfo, !medical.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("medical_notes")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(medical)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let allergies = pet.allergies, !allergies.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("allergies")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(allergies)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let medications = pet.medications, !medications.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("medications")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(medications)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Additional Information
                if pet.behaviorNotes != nil || pet.uniqueFeatures != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("additional_information", systemImage: "text.bubble.fill")
                            .font(.headline)

                        if let uniqueFeatures = pet.uniqueFeatures, !uniqueFeatures.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("unique_features")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(uniqueFeatures)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let behavior = pet.behaviorNotes, !behavior.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("behavior_notes")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(behavior)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    // View Public Profile Button
                    NavigationLink(destination: PetPublicProfileView(pet: pet)) {
                        HStack(spacing: 8) {
                            Image(systemName: "eye")
                            Text(String(format: NSLocalizedString("view_public_profile", comment: ""), pet.name))
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.tealAccent)
                        .cornerRadius(14)
                    }

                    Button(action: { showingEditSheet = true }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text(String(format: NSLocalizedString("edit_pet_profile", comment: ""), pet.name))
                        }
                    }
                    .buttonStyle(BrandButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 100) // Add padding to prevent button from being hidden under tab bar
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet, onDismiss: refreshPet) {
            NavigationView {
                PetFormView(mode: .edit(pet))
            }
            .adaptiveContainer()
        }
        .sheet(isPresented: $showingMarkLostSheet, onDismiss: refreshPet) {
            NavigationView {
                MarkAsLostView(pet: pet)
            }
            .environmentObject(appState)
            .environmentObject(authViewModel)
        }
        .alert(String(format: NSLocalizedString("mark_found_confirm_title", comment: ""), pet.name), isPresented: $showingMarkFoundConfirmation) {
            Button("cancel", role: .cancel) { }
            Button("mark_as_found") {
                markAsFound()
            }
        } message: {
            Text(String(format: NSLocalizedString("mark_found_confirm_message", comment: ""), pet.name))
        }
        .fullScreenCover(isPresented: $showingSuccessStoryPrompt) {
            SuccessStoryPromptView(
                pet: pet,
                onDismiss: {
                    showingSuccessStoryPrompt = false
                    appState.showSuccess(String(format: NSLocalizedString("marked_found_message", comment: ""), pet.name))
                    dismiss()
                },
                onStorySubmitted: {
                    showingSuccessStoryPrompt = false
                    Task {
                        await successStoriesVM.fetchStoriesForPet(petId: pet.id)
                        petSuccessStory = successStoriesVM.stories.first
                    }
                    dismiss()
                }
            )
            .environmentObject(appState)
        }
        .task {
            await successStoriesVM.fetchStoriesForPet(petId: pet.id)
            petSuccessStory = successStoriesVM.stories.first
        }
        .alert(String(localized: "remove_story_confirm_title"), isPresented: $showRemoveStoryConfirmation) {
            Button("cancel", role: .cancel) { }
            Button("remove", role: .destructive) {
                Task {
                    if let story = petSuccessStory {
                        do {
                            try await successStoriesVM.deleteSuccessStory(id: story.id)
                            await MainActor.run {
                                petSuccessStory = nil
                                appState.showSuccess(String(localized: "removed_from_success_stories"))
                            }
                        } catch {
                            await MainActor.run {
                                appState.showError(error.localizedDescription)
                            }
                        }
                    }
                }
            }
        } message: {
            Text("remove_story_confirm_message")
        }
    }

    private func markAsFound() {
        Task {
            do {
                _ = try await viewModel.markPetFound(petId: pet.id)
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                // Small delay to allow alert to dismiss before showing fullScreenCover
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                await MainActor.run {
                    showingSuccessStoryPrompt = true
                }
            } catch {
                await MainActor.run {
                    appState.showError(String(format: NSLocalizedString("mark_found_failed", comment: ""), error.localizedDescription))
                }
            }
        }
    }

    private func refreshPet() {
        Task {
            await viewModel.fetchPets()
            if let updated = viewModel.pets.first(where: { $0.id == pet.id }) {
                pet = updated
            }
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(10)
            .fontWeight(.semibold)
    }
}

struct LostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(10)
            .fontWeight(.semibold)
            .shadow(radius: 2)
    }
}

struct FoundButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.tealAccent.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(14)
    }
}

#Preview {
    NavigationView {
        PetDetailView(pet: Pet(
            id: "1",
            ownerId: "1",
            name: "Max",
            species: "Dog",
            breed: "Golden Retriever",
            color: "Golden",
            weight: 30.0,
            microchipNumber: "123456789",
            medicalNotes: "Allergic to chicken",
            notes: "Friendly with kids",
            profileImage: nil,
            isMissing: false,
            createdAt: "",
            updatedAt: "",
            ageYears: 4,
            ageMonths: 6,
            ageText: "4 years 6 months",
            ageIsApproximate: false,
            allergies: nil,
            medications: nil,
            uniqueFeatures: nil,
            sex: "Male",
            isNeutered: true,
            qrCode: "ABC123",
            dateOfBirth: "2020-01-01"
        ))
    }
    .environmentObject(AppState())
    .environmentObject(AuthViewModel())
}
