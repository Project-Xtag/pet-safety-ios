import SwiftUI
import UIKit

struct PetsListView: View {
    @StateObject private var viewModel = PetsViewModel()
    @State private var showingAddPet = false
    @State private var showingMarkLostSheet = false
    @State private var showingMarkFoundSheet = false
    @State private var showingOrderMoreTags = false
    @State private var showingPetSelection = false
    @State private var showingSuccessStories = false
    @State private var selectedPetForReplacement: Pet?
    @State private var searchText = ""
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel

    var hasMissingPets: Bool {
        viewModel.pets.contains(where: { $0.isMissing })
    }

    var missingPets: [Pet] {
        viewModel.pets.filter { $0.isMissing }
    }

    var filteredPets: [Pet] {
        if searchText.isEmpty {
            return viewModel.pets
        }
        let query = searchText.lowercased()
        return viewModel.pets.filter { pet in
            pet.name.lowercased().contains(query) ||
            pet.species.lowercased().contains(query) ||
            (pet.breed?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                OfflineIndicator()

                if viewModel.isLoading && viewModel.pets.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.errorMessage != nil && viewModel.pets.isEmpty {
                    ErrorRetryView(message: viewModel.errorMessage ?? "Failed to load pets") {
                        Task { await viewModel.fetchPets() }
                    }
                } else if viewModel.pets.isEmpty {
                    EmptyStateView(
                        icon: "pawprint.fill",
                        title: NSLocalizedString("empty_pets_title", comment: ""),
                        message: NSLocalizedString("empty_pets_message", comment: ""),
                        actionTitle: NSLocalizedString("add_pet", comment: ""),
                        action: { showingAddPet = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header Section
                            headerSection

                            // My Pets Section
                            petsSection

                            // Quick Actions Section
                            quickActionsSection

                            // Success Stories Section
                            successStoriesSection
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
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
        .sheet(isPresented: $showingMarkFoundSheet) {
            NavigationView {
                QuickMarkFoundView(pets: missingPets)
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedPetForReplacement = pet
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingSuccessStories) {
            NavigationView {
                SuccessStoriesTabView()
                    .environmentObject(authViewModel)
            }
        }
        .task {
            await viewModel.fetchPets()
        }
        .refreshable {
            await viewModel.fetchPets()
        }
        .overlay {
            if viewModel.isLoading && !viewModel.pets.isEmpty {
                ProgressView()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("welcome_back_greeting")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.mutedText)
                Text(authViewModel.currentUser?.firstName ?? NSLocalizedString("pet_owner_default", comment: ""))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color.peachBackground)
    }

    // MARK: - Pets Section
    private var petsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("tab_my_pets")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                if viewModel.pets.count > 4 && searchText.isEmpty {
                    Button("view_all") {
                        // Show all pets
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brandOrange)
                }
            }
            .padding(.horizontal, 24)

            // Search bar (only show when >4 pets)
            if viewModel.pets.count > 4 {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.mutedText)
                    TextField("search_pets_hint", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.mutedText)
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }

            // Pet Cards Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(searchText.isEmpty ? Array(viewModel.pets.prefix(4)) : filteredPets) { pet in
                    PetCardView(pet: pet)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("quick_actions")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)

            // First row of quick actions
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: NSLocalizedString("action_add_pet", comment: ""),
                    color: .tealAccent,
                    action: { showingAddPet = true }
                )

                QuickActionButton(
                    icon: hasMissingPets ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                    title: hasMissingPets ? NSLocalizedString("action_mark_found", comment: "") : NSLocalizedString("action_report_missing", comment: ""),
                    color: hasMissingPets ? .green : .red,
                    action: {
                        if hasMissingPets {
                            showingMarkFoundSheet = true
                        } else {
                            showingMarkLostSheet = true
                        }
                    }
                )

                QuickActionButton(
                    icon: "cart.badge.plus",
                    title: NSLocalizedString("action_order_tags", comment: ""),
                    color: .tealAccent,
                    action: { showingOrderMoreTags = true }
                )

                QuickActionButton(
                    icon: "arrow.triangle.2.circlepath",
                    title: NSLocalizedString("action_replace_tag", comment: ""),
                    color: .brandOrange,
                    action: { showOrderReplacementMenu() }
                )
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Success Stories Section
    private var successStoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("success_stories")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)

            // Found Pets Card
            Button(action: { showingSuccessStories = true }) {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 60, height: 60)
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                            .accessibilityLabel(NSLocalizedString("success_stories", comment: ""))
                    }

                    // Text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("found_pets")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("success_stories_subtitle")
                            .font(.system(size: 14))
                            .foregroundColor(.mutedText)
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.mutedText)
                        .accessibilityHidden(true)
                }
                .padding(16)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 24)
        }
    }

    private func showOrderReplacementMenu() {
        if viewModel.pets.isEmpty {
            appState.showError("You don't have any pets yet. Add a pet first to order a replacement tag.")
            return
        }

        if viewModel.pets.count == 1 {
            selectedPetForReplacement = viewModel.pets[0]
        } else {
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
                // Pet Photo
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        if let photoUrl = pet.photoUrl, !photoUrl.isEmpty {
                            AsyncImage(url: URL(string: photoUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ZStack {
                                        Color(UIColor.systemGray6)
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
                    .frame(height: 120)
                    .clipped()

                    // Missing Badge
                    if pet.isMissing {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .accessibilityLabel(NSLocalizedString("missing_badge", comment: ""))
                            Text("missing_badge")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(8)
                        .padding(8)
                    }
                }
                .cornerRadius(16, corners: [.topLeft, .topRight])

                // Pet Name
                Text(pet.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(pet.isMissing ? .red : .primary)
                    .lineLimit(1)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemBackground))
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            .overlay(
                pet.isMissing ?
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red, lineWidth: 2)
                    : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var placeholderImage: some View {
        ZStack {
            Color(UIColor.systemGray6)
            Image(systemName: pet.species.lowercased() == "dog" ? "dog.fill" : "cat.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.mutedText)
                .padding(35)
                .accessibilityLabel(pet.species)
        }
    }
}

// MARK: - Add Pet Card
struct AddPetCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 32))
                    .foregroundColor(.mutedText)
                    .accessibilityLabel(NSLocalizedString("add_pet", comment: ""))
                Text("add_pet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.mutedText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 165)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(Color(UIColor.systemGray4))
            )
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
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.tealAccent)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(BrandButtonStyle())
                .padding(.horizontal, 60)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                        .accessibilityLabel(title)
                }

                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.mutedText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct PetSelectionView: View {
    let pets: [Pet]
    let onPetSelected: (Pet) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(header: Text("select_pet_for_replacement")) {
                ForEach(pets) { pet in
                    Button(action: {
                        onPetSelected(pet)
                    }) {
                        HStack(spacing: 16) {
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
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)

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
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("select_pet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("cancel") {
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
