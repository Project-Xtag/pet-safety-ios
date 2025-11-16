import SwiftUI

struct PetsListView: View {
    @StateObject private var viewModel = PetsViewModel()
    @State private var showingAddPet = false
    @State private var showingMarkLostSheet = false
    @State private var showingOrderMoreTags = false
    @State private var showingOrderReplacementTag = false
    @State private var showingPetSelection = false
    @State private var selectedPetForReplacement: Pet?
    @EnvironmentObject var appState: AppState

    var hasMissingPets: Bool {
        viewModel.pets.contains(where: { $0.isMissing })
    }

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
                    Section(header: Text("My Pets")) {
                        ForEach(viewModel.pets) { pet in
                            NavigationLink(destination: PetDetailView(pet: pet)) {
                                PetRowView(pet: pet)
                            }
                        }
                        .onDelete(perform: deletePet)
                    }

                    // Quick Actions Section - shown at bottom
                    Section(header: Text("Quick Actions")) {
                        Button(action: { showingMarkLostSheet = true }) {
                            HStack {
                                Image(systemName: hasMissingPets ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                Text(hasMissingPets ? "Report Missing / Mark Found" : "Report Missing")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(QuickActionButtonStyle())

                        Button(action: { showingOrderMoreTags = true }) {
                            HStack {
                                Image(systemName: "cart.badge.plus")
                                Text("Order More Tags")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(QuickActionButtonStyle())

                        Button(action: { showOrderReplacementMenu() }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Order Replacement Tag")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(QuickActionButtonStyle())
                    }
                }
                .listStyle(.insetGrouped)
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
        .sheet(isPresented: $showingMarkLostSheet) {
            NavigationView {
                QuickMarkLostView(pets: viewModel.pets)
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showingOrderMoreTags) {
            NavigationView {
                OrderMoreTagsView()
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showingOrderReplacementTag) {
            if let pet = selectedPetForReplacement {
                NavigationView {
                    OrderReplacementTagView(pet: pet)
                        .environmentObject(appState)
                }
            }
        }
        .sheet(isPresented: $showingPetSelection) {
            NavigationView {
                PetSelectionView(
                    pets: viewModel.pets,
                    onPetSelected: { pet in
                        selectedPetForReplacement = pet
                        showingPetSelection = false
                        showingOrderReplacementTag = true
                    }
                )
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

    private func showOrderReplacementMenu() {
        if viewModel.pets.isEmpty {
            appState.showError("You don't have any pets yet. Add a pet first to order a replacement tag.")
            return
        }

        // If only one pet, go directly to replacement order
        if viewModel.pets.count == 1 {
            selectedPetForReplacement = viewModel.pets[0]
            showingOrderReplacementTag = true
        } else {
            // If multiple pets, show selection sheet
            showingPetSelection = true
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

struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(.primary)
    }
}

struct PetSelectionView: View {
    let pets: [Pet]
    let onPetSelected: (Pet) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(header: Text("Select Pet for Replacement Tag")) {
                ForEach(pets) { pet in
                    Button(action: {
                        onPetSelected(pet)
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
                                    .padding(16)
                            }
                            .frame(width: 50, height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

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
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Select Pet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        PetsListView()
            .environmentObject(AppState())
    }
}
