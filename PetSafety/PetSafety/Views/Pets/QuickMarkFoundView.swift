import SwiftUI
import UIKit

struct QuickMarkFoundView: View {
    let pets: [Pet]
    @StateObject private var viewModel = PetsViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var isProcessing = false
    @State private var showSuccessStoryPrompt = false
    @State private var foundPet: Pet?
    @State private var showingFoundConfirmation = false
    @State private var petToMarkFound: Pet?

    var body: some View {
        List {
            Section(header: Text("quick_found_select_pet")) {
                ForEach(pets) { pet in
                    Button(action: {
                        petToMarkFound = pet
                        showingFoundConfirmation = true
                    }) {
                        HStack(spacing: 16) {
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
                                    .padding(12)
                            }
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                            // Pet Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pet.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(pet.species.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text("quick_found_currently_missing")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }

                            Spacer()

                            if isProcessing && foundPet?.id == pet.id {
                                ProgressView()
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.successColor)
                            }
                        }
                    }
                    .disabled(isProcessing)
                }
            }

            if pets.isEmpty {
                Section {
                    Text("quick_found_no_missing")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .navigationTitle("quick_found_title")
        .adaptiveList()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("cancel") {
                    dismiss()
                }
                .disabled(isProcessing)
            }
        }
        .fullScreenCover(isPresented: $showSuccessStoryPrompt) {
            if let pet = foundPet {
                SuccessStoryPromptView(
                    pet: pet,
                    onDismiss: {
                        showSuccessStoryPrompt = false
                        dismiss()
                    },
                    onStorySubmitted: {
                        showSuccessStoryPrompt = false
                        dismiss()
                    }
                )
                .environmentObject(appState)
            }
        }
        .alert("alert_mark_found_title \(petToMarkFound?.name ?? String(localized: "pet_default"))", isPresented: $showingFoundConfirmation) {
            Button("cancel", role: .cancel) {
                petToMarkFound = nil
            }
            Button("mark_as_found") {
                if let pet = petToMarkFound {
                    markAsFound(pet: pet)
                }
                petToMarkFound = nil
            }
        } message: {
            Text("alert_mark_found_message \(petToMarkFound?.name ?? String(localized: "pet_default"))")
        }
    }

    private func markAsFound(pet: Pet) {
        isProcessing = true
        foundPet = pet

        Task {
            do {
                _ = try await viewModel.markPetFound(petId: pet.id)
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    isProcessing = false
                }
                // Small delay to allow alert to dismiss before showing fullScreenCover
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                await MainActor.run {
                    showSuccessStoryPrompt = true
                }
            } catch {
                await MainActor.run {
                    appState.showError(String(format: String(localized: "quick_found_mark_failed"), pet.name, error.localizedDescription))
                    foundPet = nil
                    isProcessing = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        QuickMarkFoundView(pets: [
            Pet(
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
                isMissing: true,
                createdAt: "",
                updatedAt: ""
            )
        ])
        .environmentObject(AppState())
    }
}
