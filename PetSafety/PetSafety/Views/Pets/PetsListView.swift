import SwiftUI

struct PetsListView: View {
    @StateObject private var viewModel = PetsViewModel()
    @State private var showingAddPet = false

    var body: some View {
        ZStack {
            if viewModel.pets.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "pawprint.fill",
                    title: "No Pets Yet",
                    message: "Add your first pet to get started with Pet Safety",
                    actionTitle: "Add Pet",
                    action: { showingAddPet = true }
                )
            } else {
                List {
                    ForEach(viewModel.pets) { pet in
                        NavigationLink(destination: PetDetailView(pet: pet)) {
                            PetRowView(pet: pet)
                        }
                    }
                    .onDelete(perform: deletePet)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("My Pets")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddPet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPet) {
            NavigationView {
                PetFormView(mode: .create)
            }
        }
        .task {
            await viewModel.fetchPets()
        }
        .refreshable {
            await viewModel.fetchPets()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    private func deletePet(at offsets: IndexSet) {
        for index in offsets {
            let pet = viewModel.pets[index]
            Task {
                try? await viewModel.deletePet(id: pet.id)
            }
        }
    }
}

struct PetRowView: View {
    let pet: Pet

    var body: some View {
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
                    .padding(16)
            }
            .frame(width: 70, height: 70)
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Pet Info
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(pet.species.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let breed = pet.breed {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(breed)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if let age = pet.age {
                    Text(age)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
            }
        }
    }
}

#Preview {
    NavigationView {
        PetsListView()
    }
}
