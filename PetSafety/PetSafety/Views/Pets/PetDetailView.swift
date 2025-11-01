import SwiftUI

struct PetDetailView: View {
    let pet: Pet
    @StateObject private var viewModel = PetsViewModel()
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

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

                // Basic Info Cards
                VStack(spacing: 16) {
                    InfoCard(title: "Species", value: pet.species.capitalized, icon: "pawprint.fill")

                    if let breed = pet.breed {
                        InfoCard(title: "Breed", value: breed, icon: "list.bullet")
                    }

                    if let color = pet.color {
                        InfoCard(title: "Color", value: color, icon: "paintpalette.fill")
                    }

                    if let age = pet.age {
                        InfoCard(title: "Age", value: age, icon: "calendar")
                    }

                    if let weight = pet.weight {
                        InfoCard(title: "Weight", value: "\(weight) kg", icon: "scalemass.fill")
                    }

                    if let microchip = pet.microchipNumber {
                        InfoCard(title: "Microchip", value: microchip, icon: "number")
                    }
                }
                .padding(.horizontal)

                // Medical Info
                if let medical = pet.medicalInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Medical Information", systemImage: "cross.case.fill")
                            .font(.headline)

                        Text(medical)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Behavior Notes
                if let behavior = pet.behaviorNotes {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Behavior Notes", systemImage: "text.bubble.fill")
                            .font(.headline)

                        Text(behavior)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit Pet Information", systemImage: "pencil")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Pet", systemImage: "trash")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                PetFormView(mode: .edit(pet))
            }
        }
        .alert("Delete Pet", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deletePet(id: pet.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(pet.name)? This action cannot be undone.")
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

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .fontWeight(.semibold)
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

#Preview {
    NavigationView {
        PetDetailView(pet: Pet(
            id: 1,
            userId: 1,
            name: "Max",
            species: "Dog",
            breed: "Golden Retriever",
            color: "Golden",
            dateOfBirth: "2020-01-01T00:00:00Z",
            weight: 30.0,
            microchipNumber: "123456789",
            medicalInfo: "Allergic to chicken",
            behaviorNotes: "Friendly with kids",
            photoUrl: nil,
            isActive: true,
            createdAt: "",
            updatedAt: ""
        ))
    }
}
