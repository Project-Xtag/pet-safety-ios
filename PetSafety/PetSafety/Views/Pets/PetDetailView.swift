import SwiftUI
import UIKit

struct PetDetailView: View {
    @State private var pet: Pet
    @StateObject private var viewModel = PetsViewModel()
    @StateObject private var vaccinationsVM: VaccinationsViewModel

    init(pet: Pet) {
        _pet = State(initialValue: pet)
        _vaccinationsVM = StateObject(wrappedValue: VaccinationsViewModel(petId: pet.id))
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
    @EnvironmentObject var subscriptionViewModel: SubscriptionViewModel
    @EnvironmentObject var vaccinationGate: VaccinationGate

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pet Photo
                CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
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
                .frame(height: horizontalSizeClass == .regular ? 400 : 300)
                .frame(maxWidth: .infinity)
                .background(Color.cream)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                        .stroke(Color.softBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 8)
                .padding(.horizontal)

                // Pet Name
                Text(pet.name)
                    .font(.appFont(size: 34, weight: .bold))
                    .foregroundColor(.ink)

                // View Photos — refreshed to the new pill style.
                // Brand gradient lifts the action above the cream
                // info-cards below so the eye lands on it first.
                NavigationLink(destination: PhotoGalleryView(pet: pet)) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "photo.on.rectangle")
                        Text(String(format: NSLocalizedString("view_pet_photos", comment: ""), pet.name))
                    }
                }
                .buttonStyle(PrimaryPillButtonStyle())
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
                    } else if pet.hasActiveTag == true {
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
                    InfoCard(title: NSLocalizedString("species", comment: ""), value: PetLocalizer.localizeSpecies(pet.species), icon: "pawprint.fill")

                    if let breed = pet.breed {
                        InfoCard(title: NSLocalizedString("breed", comment: ""), value: PetLocalizer.localizeBreed(breed, species: pet.species), icon: "list.bullet")
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
                        InfoCard(title: NSLocalizedString("sex", comment: ""), value: PetLocalizer.localizeSex(sex, species: pet.species), icon: "circle.lefthalf.filled")
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
                            .font(.appFont(.headline))

                        if let medical = pet.medicalInfo, !medical.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("medical_notes")
                                    .font(.appFont(.subheadline))
                                    .fontWeight(.medium)
                                Text(medical)
                                    .font(.appFont(.body))
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let allergies = pet.allergies, !allergies.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("allergies")
                                    .font(.appFont(.subheadline))
                                    .fontWeight(.medium)
                                Text(allergies)
                                    .font(.appFont(.body))
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let medications = pet.medications, !medications.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("medications")
                                    .font(.appFont(.subheadline))
                                    .fontWeight(.medium)
                                Text(medications)
                                    .font(.appFont(.body))
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

                // Vaccinations (Stage B) — gated section + add CTA. Conditional
                // in THIS ViewBuilder so an off/unknown gate inserts nothing and
                // leaves zero surface (no card, no add affordance); an empty
                // custom view would still claim a VStack slot and leak spacing.
                // `isOn` is true only on a definitive summary 200 (decision #2);
                // emptiness here is a display concern, never a gate (decision #6).
                if vaccinationGate.availability.isOn {
                    VaccinationSummarySection(viewModel: vaccinationsVM)
                }

                // Additional Information
                if pet.behaviorNotes != nil || pet.uniqueFeatures != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("additional_information", systemImage: "text.bubble.fill")
                            .font(.appFont(.headline))

                        if let uniqueFeatures = pet.uniqueFeatures, !uniqueFeatures.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("unique_features")
                                    .font(.appFont(.subheadline))
                                    .fontWeight(.medium)
                                Text(uniqueFeatures)
                                    .font(.appFont(.body))
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let behavior = pet.behaviorNotes, !behavior.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("behavior_notes")
                                    .font(.appFont(.subheadline))
                                    .fontWeight(.medium)
                                Text(behavior)
                                    .font(.appFont(.body))
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
                        .font(.appFont(size: 16, weight: .semibold))
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
            .adaptiveContainer(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
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
            .navigationViewStyle(.stack)
            .environmentObject(appState)
            .environmentObject(authViewModel)
            .environmentObject(subscriptionViewModel)
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
                alertId: viewModel.lastResolvedAlertId,
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
        // Self-heal the gate on this gated entry, not just the home landing: a
        // VACCINATION_DUE deep-link can cold-launch straight into pet detail,
        // bypassing PetsListView's `.task`, leaving the gate at `.unknown` and the
        // section wrongly hidden. Idempotent; `resolve()` preserves an established
        // `.on` on a transient blip and only flips to `.off` on a definitive 404.
        .task {
            await vaccinationGate.resolve()
        }
        // Load the per-pet vaccination list only once the gate is on. Keyed off
        // `isOn` so it re-runs when the gate resolves `.unknown` → `.on` (incl. via
        // the self-heal above) while this view is already on screen — and never
        // fires a per-pet CRUD call for a feature-off user. `onDidMutate` is bound
        // here: the single hook that keeps the home card in sync after a
        // create/update/delete (no scattered `gate.refresh()` call sites).
        .task(id: vaccinationGate.availability.isOn) {
            guard vaccinationGate.availability.isOn else { return }
            vaccinationsVM.onDidMutate = { Task { await vaccinationGate.refresh() } }
            await vaccinationsVM.load()
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
        HStack(spacing: AppSpacing.md) {
            // Tinted icon disc, mirroring the QuickActionButton
            // surface. Each row reads as a unit instead of a flat
            // label/value pair on a gray plate.
            ZStack {
                Circle()
                    .fill(Color.brandOrange.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.appFont(size: 15, weight: .semibold))
                    .foregroundColor(.brandOrangeDeep)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appFont(size: 12, weight: .semibold))
                    .foregroundColor(.mutedText)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(value)
                    .font(.appFont(size: 16, weight: .semibold))
                    .foregroundColor(.ink)
            }

            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(Color.cream)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(Color.softBorder, lineWidth: 1)
        )
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .foregroundColor(.errorColor)
            .font(.appFont(size: 15, weight: .semibold))
            .background(
                configuration.isPressed
                    ? Color.errorColor.opacity(0.18)
                    : Color.errorColor.opacity(0.10)
            )
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.errorColor.opacity(0.32), lineWidth: 1))
    }
}

struct LostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .foregroundColor(.white)
            .font(.appFont(size: 16, weight: .bold))
            .background(
                configuration.isPressed
                    ? Color.errorColor.opacity(0.85)
                    : Color.errorColor
            )
            .clipShape(Capsule())
            .shadow(color: Color.errorColor.opacity(0.32), radius: 12, x: 0, y: 6)
    }
}

struct FoundButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .foregroundColor(.white)
            .font(.appFont(size: 16, weight: .bold))
            .background(
                configuration.isPressed
                    ? Color.successColor.opacity(0.82)
                    : Color.successColor
            )
            .clipShape(Capsule())
            .shadow(color: Color.successColor.opacity(0.32), radius: 12, x: 0, y: 6)
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
    .environmentObject(SubscriptionViewModel())
    .environmentObject(VaccinationGate())
}
