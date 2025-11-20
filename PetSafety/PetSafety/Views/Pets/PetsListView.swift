import SwiftUI

struct PetsListView: View {
    @StateObject private var viewModel = PetsViewModel()
    @State private var showingAddPet = false
    @State private var showingMarkLostSheet = false
    @State private var showingOrderMoreTags = false
    @State private var showingPetSelection = false
    @State private var selectedPetForReplacement: Pet?
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel

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
                ScrollView {
                    VStack(spacing: 20) {
                        // Pets Grid Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Pets")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)

                            if viewModel.pets.count == 1 {
                                // Center single pet card
                                HStack {
                                    Spacer()
                                    PetCardView(pet: viewModel.pets[0])
                                        .frame(width: 160)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            } else {
                                // Grid layout for multiple pets
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ], spacing: 16) {
                                    ForEach(viewModel.pets) { pet in
                                        PetCardView(pet: pet)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Quick Actions Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)

                            VStack(spacing: 12) {
                                QuickActionButton(
                                    icon: hasMissingPets ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                                    title: hasMissingPets ? "Report Missing / Mark Found" : "Report Missing",
                                    action: { showingMarkLostSheet = true }
                                )

                                QuickActionButton(
                                    icon: "cart.badge.plus",
                                    title: "Order More Tags",
                                    action: { showingOrderMoreTags = true }
                                )

                                QuickActionButton(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Order Replacement Tag",
                                    action: { showOrderReplacementMenu() }
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 20)
                    }
                }
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
                    .environmentObject(authViewModel)
            }
        }
        .sheet(item: $selectedPetForReplacement) { pet in
            NavigationView {
                OrderReplacementTagView(pet: pet)
                    .environmentObject(appState)
                    .environmentObject(authViewModel)
            }
        }
        .sheet(isPresented: $showingPetSelection) {
            NavigationView {
                PetSelectionView(
                    pets: viewModel.pets,
                    onPetSelected: { pet in
                        showingPetSelection = false
                        // Delay slightly to ensure sheet dismisses before opening new one
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedPetForReplacement = pet
                        }
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


    private func showOrderReplacementMenu() {
        if viewModel.pets.isEmpty {
            appState.showError("You don't have any pets yet. Add a pet first to order a replacement tag.")
            return
        }

        // If only one pet, go directly to replacement order
        if viewModel.pets.count == 1 {
            selectedPetForReplacement = viewModel.pets[0]
        } else {
            // If multiple pets, show selection sheet
            showingPetSelection = true
        }
    }
}

// MARK: - Pet Card View
struct PetCardView: View {
    let pet: Pet

    var body: some View {
        NavigationLink(destination: PetDetailView(pet: pet)) {
            VStack(spacing: 0) {
                // Pet Photo - upper 2/3
                ZStack {
                    if let photoUrl = pet.photoUrl, !photoUrl.isEmpty {
                        AsyncImage(url: URL(string: photoUrl)) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Color(.systemGray6)
                                    ProgressView()
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                placeholderImage
                            @unknown default:
                                placeholderImage
                            }
                        }
                    } else {
                        placeholderImage
                    }
                }
                .frame(height: 160)
                .clipped()

                // Pet Name - lower 1/3
                VStack(spacing: 4) {
                    Text(pet.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            .frame(height: 220)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var placeholderImage: some View {
        ZStack {
            Color(.systemGray6)
            Image(systemName: pet.species.lowercased() == "dog" ? "dog.fill" : "cat.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.secondary)
                .padding(40)
        }
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

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.cyan)
                    .frame(width: 30)

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
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
            .environmentObject(AuthViewModel())
    }
}
