import SwiftUI

struct QuickMarkLostView: View {
    let pets: [Pet]
    @State private var selectedPet: Pet?
    @State private var showingMarkLostFlow = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            Section(header: Text("Select Pet to Report Missing")) {
                ForEach(pets.filter { !$0.isMissing }) { pet in
                    Button(action: {
                        selectedPet = pet
                        showingMarkLostFlow = true
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
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if pets.filter({ !$0.isMissing }).isEmpty {
                Section {
                    Text("All your pets are already marked as missing or you have no pets to report.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .navigationTitle("Report Missing Pet")
        .adaptiveList()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingMarkLostFlow) {
            if let pet = selectedPet {
                NavigationView {
                    MarkAsLostView(pet: pet)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        QuickMarkLostView(pets: [
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
                isMissing: false,
                createdAt: "",
                updatedAt: ""
            )
        ])
        .environmentObject(AppState())
    }
}
