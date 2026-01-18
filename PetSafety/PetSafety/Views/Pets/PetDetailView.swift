import SwiftUI

struct PetDetailView: View {
    let pet: Pet
    @StateObject private var viewModel = PetsViewModel()
    @StateObject private var alertsViewModel = AlertsViewModel()
    @State private var showingEditSheet = false
    @State private var showingMarkLostSheet = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

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

                // Mark as Lost/Found Buttons
                HStack(spacing: 12) {
                    if pet.isMissing {
                        Button(action: { markAsFound() }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark as Found")
                            }
                        }
                        .buttonStyle(FoundButtonStyle())
                    } else {
                        Button(action: { showingMarkLostSheet = true }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Mark as Lost")
                            }
                        }
                        .buttonStyle(LostButtonStyle())
                    }
                }
                .padding(.horizontal)

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

                // Additional Information
                if let behavior = pet.behaviorNotes {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Additional Information", systemImage: "text.bubble.fill")
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
                    // Photo Gallery Button
                    NavigationLink(destination: PhotoGalleryView(pet: pet)) {
                        Label("View Photo Gallery", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(10)
                            .fontWeight(.semibold)
                    }

                    Button(action: { showingEditSheet = true }) {
                        Label("Edit Pet Information", systemImage: "pencil")
                    }
                    .buttonStyle(SecondaryButtonStyle())
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
            .adaptiveContainer()
        }
        .sheet(isPresented: $showingMarkLostSheet) {
            NavigationView {
                MarkAsLostView(pet: pet)
            }
        }
    }

    private func markAsFound() {
        Task {
            do {
                _ = try await viewModel.markPetFound(petId: pet.id)
                appState.showSuccess("\(pet.name) has been marked as found! 🎉")
                dismiss()
            } catch {
                appState.showError("Failed to mark \(pet.name) as found: \(error.localizedDescription)")
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
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(10)
            .fontWeight(.semibold)
            .shadow(radius: 2)
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
}
