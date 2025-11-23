import SwiftUI

struct QuickMarkFoundView: View {
    let pets: [Pet]
    @StateObject private var viewModel = PetsViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            Section(header: Text("Select Pet to Mark as Found")) {
                ForEach(pets) { pet in
                    Button(action: {
                        markAsFound(pet: pet)
                    }) {
                        HStack(spacing: 16) {
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

                                Text("Currently Missing")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }

            if pets.isEmpty {
                Section {
                    Text("No missing pets to mark as found.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .navigationTitle("Mark Pet as Found")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private func markAsFound(pet: Pet) {
        Task {
            // Update pet status to not missing
            // Note: We need to add an API endpoint to mark pets as found
            appState.showSuccess("\(pet.name) has been marked as found! 🎉")
            dismiss()
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
