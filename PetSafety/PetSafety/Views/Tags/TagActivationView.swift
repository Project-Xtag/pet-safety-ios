import SwiftUI
import UIKit

/// Wrapper to pass pet name into sheet via .sheet(item:)
private struct CreatePetContext: Identifiable {
    let id = UUID()
    let petName: String?
}

/// View for activating a QR tag and linking it to a pet.
/// Supports multi-tag orders: after activating one tag, prompts to set up remaining tags.
struct TagActivationView: View {
    let tagCode: String
    let onDismiss: () -> Void

    @StateObject private var petsViewModel = PetsViewModel()
    @StateObject private var viewModel = QRScannerViewModel()
    @EnvironmentObject var appState: AppState

    @State private var selectedPet: Pet?
    @State private var isActivating = false
    @State private var activationSuccess = false
    @State private var errorMessage: String?
    @State private var createPetContext: CreatePetContext?
    @State private var orderItems: [UnactivatedOrderItem] = []
    @State private var petIdsBeforeCreate: Set<String> = []
    @State private var currentTagCode: String

    private let grayBackground = Color(UIColor.systemGray6)

    init(tagCode: String, onDismiss: @escaping () -> Void) {
        self.tagCode = tagCode
        self.onDismiss = onDismiss
        self._currentTagCode = State(initialValue: tagCode)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if petsViewModel.isLoading {
                    loadingView
                } else if activationSuccess {
                    successView
                } else if petsViewModel.pets.isEmpty {
                    noPetsView
                } else {
                    petSelectionView
                }
            }
            .navigationTitle(Text(activationSuccess ? "tag_activated" : "setup_your_tags"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "cancel")) {
                        onDismiss()
                    }
                }
            }
            .task {
                async let petsTask: () = petsViewModel.fetchPets()
                async let orderTask: [UnactivatedOrderItem] = {
                    do {
                        return try await APIService.shared.getUnactivatedTagsForQRCode(currentTagCode)
                    } catch {
                        return []
                    }
                }()
                await petsTask
                orderItems = await orderTask
            }
            .background(
                // Hidden NavigationLink to push PetFormView within the existing NavigationView
                NavigationLink(
                    destination: Group {
                        if let context = createPetContext {
                            let otherNames = Array(Set(orderItems.compactMap { $0.petName }))
                                .filter { $0.lowercased() != (context.petName ?? "").lowercased() }
                                .sorted()
                            PetFormView(
                                mode: .create,
                                initialPetName: context.petName,
                                remainingPetNames: otherNames,
                                onRegisterNextPet: { nextName in
                                    // Activation already completed in onPetCreated.
                                    createPetContext = nil
                                    // Small delay to let navigation pop, then push again
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        petIdsBeforeCreate = Set(petsViewModel.pets.map { $0.id })
                                        createPetContext = CreatePetContext(petName: nextName)
                                    }
                                },
                                onAllDone: {
                                    // Activation already completed in onPetCreated.
                                    createPetContext = nil
                                    onDismiss()
                                },
                                onPetCreated: { newPet in
                                    // Hard precondition for the post-save "Tag activated"
                                    // screen: actually activate the tag and let the call
                                    // throw if it fails. PetFormView awaits this and only
                                    // shows the success screen on success; if it throws,
                                    // the user is bounced back with an error.
                                    try await viewModel.activateTag(code: currentTagCode, petId: newPet.id)
                                    NotificationCenter.default.post(name: .tagActivated, object: nil)
                                    selectedPet = newPet
                                }
                            )
                            .environmentObject(appState)
                        }
                    },
                    isActive: Binding(
                        get: { createPetContext != nil },
                        set: { if !$0 { createPetContext = nil } }
                    ),
                    label: { EmptyView() }
                )
                .hidden()
            )
        }
    }

    /// After PetFormView pops back, refresh pets and auto-activate the tag for the newly created pet.
    private func handlePetCreated() {
        Task {
            await petsViewModel.fetchPets()
            if let newPet = petsViewModel.pets.first(where: { !petIdsBeforeCreate.contains($0.id) }) {
                selectedPet = newPet
                activateTag()
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("tag_loading_pets")
                .font(.appFont(.body))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Success View
    private var successView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // Celebration
                Image(systemName: "checkmark.circle.fill")
                    .font(.appFont(size: 80))
                    .foregroundColor(.tealAccent)

                if let pet = selectedPet {
                    Text("tag_activated_for \(pet.name)")
                        .font(.appFont(.title2))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("pet_now_protected")
                        .font(.appFont(.body))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    // Pet Photo
                    CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: pet.species.lowercased() == "dog" ? "dog.fill" : "cat.fill")
                            .font(.appFont(size: 40))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 100, height: 100)
                    .background(grayBackground)
                    .clipShape(Circle())
                }

                // Remaining tags section
                let remaining = orderItems.filter { $0.tagStatus != "active" }
                if !remaining.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(Color("BrandColor"))
                            Text("more_tags_to_setup")
                                .font(.appFont(.subheadline))
                                .fontWeight(.semibold)
                        }

                        ForEach(remaining, id: \.orderItemId) { item in
                            Button {
                                setupNextTag(item)
                            } label: {
                                HStack {
                                    Image(systemName: "pawprint.fill")
                                        .foregroundColor(Color("BrandColor"))
                                    Text("setup_pet_tag \(item.petName ?? "Pet")")
                                        .font(.appFont(.subheadline))
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.appFont(.caption))
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color("BrandColor").opacity(0.08))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    // All done — show next steps
                    allDoneView
                }

                Spacer().frame(height: 10)

                // Go to Home button
                Button {
                    onDismiss()
                } label: {
                    Text("go_to_home")
                        .fontWeight(.semibold)
                }
                .buttonStyle(TagPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - All Done (no more tags to activate)
    private var allDoneView: some View {
        VStack(spacing: 16) {
            Text("thank_you_senra")
                .font(.appFont(.headline))
                .foregroundColor(.primary)

            Text("whats_next")
                .font(.appFont(.subheadline))
                .foregroundColor(.secondary)

            NextStepCard(icon: "cross.case.fill", text: String(localized: "register_your_vet")) {
                onDismiss()
            }

            NextStepCard(icon: "person.crop.circle.fill", text: String(localized: "update_contact_details")) {
                onDismiss()
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - No Pets View
    private var noPetsView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "pawprint.fill")
                .font(.appFont(size: 60))
                .foregroundColor(Color("BrandColor"))

            // Show order pet names if available
            if !orderItems.isEmpty {
                Text("setup_your_tags")
                    .font(.appFont(.title2))
                    .fontWeight(.bold)

                Text("setup_your_tags_subtitle")
                    .font(.appFont(.body))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Text("tap_pet_name_hint")
                    .font(.appFont(.subheadline))
                    .foregroundColor(Color("BrandColor"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)

                // Deduplicated pet names from order
                let uniqueNames = Array(Set(orderItems.compactMap { $0.petName })).sorted()
                ForEach(uniqueNames, id: \.self) { petName in
                    Button {
                        petIdsBeforeCreate = Set(petsViewModel.pets.map { $0.id })
                        createPetContext = CreatePetContext(petName: petName)
                    } label: {
                        HStack {
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(Color("BrandColor"))
                            Text(petName)
                                .font(.appFont(.headline))
                            Spacer()
                            Text("ready_to_setup")
                                .font(.appFont(.caption))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                        .padding()
                        .background(grayBackground)
                        .cornerRadius(14)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 24)
                }
            } else {
                Text("tag_no_pets")
                    .font(.appFont(.title2))
                    .fontWeight(.bold)

                Text("tag_no_pets_message")
                    .font(.appFont(.body))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button {
                    petIdsBeforeCreate = Set(petsViewModel.pets.map { $0.id })
                    createPetContext = CreatePetContext(petName: nil)
                } label: {
                    Text("create_pet_profile")
                        .fontWeight(.semibold)
                }
                .buttonStyle(TagPrimaryButtonStyle())
                .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("close")
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Pet Selection View
    private var petSelectionView: some View {
        VStack(spacing: 0) {
            // Tag Info Header
            VStack(spacing: 12) {
                Image(systemName: "qrcode")
                    .font(.appFont(size: 40))
                    .foregroundColor(Color("BrandColor"))

                Text("tag_select_pet")
                    .font(.appFont(.subheadline))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(grayBackground.opacity(0.5))

            // Error Message
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.appFont(.subheadline))
                        .foregroundColor(.orange)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // Pet List
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Section 1: Pets from order (if order context exists)
                    if !orderItems.isEmpty {
                        let orderPetNames = orderItems.compactMap { $0.petName?.lowercased() }
                        let matchingPets = petsViewModel.pets.filter { pet in
                            orderPetNames.contains(pet.name.lowercased())
                        }
                        let unmatchedNames = orderItems.compactMap { $0.petName }.filter { name in
                            !petsViewModel.pets.contains { $0.name.lowercased() == name.lowercased() }
                        }
                        let otherPets = petsViewModel.pets.filter { pet in
                            !orderPetNames.contains(pet.name.lowercased())
                        }

                        if !matchingPets.isEmpty || !unmatchedNames.isEmpty {
                            HStack {
                                Text("pets_from_order")
                                    .font(.appFont(.subheadline))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.bottom, 4)

                            ForEach(matchingPets) { pet in
                                TagPetSelectionRow(
                                    pet: pet,
                                    isSelected: selectedPet?.id == pet.id,
                                    badge: String(localized: "from_your_order"),
                                    onSelect: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedPet = pet
                                            errorMessage = nil
                                        }
                                    }
                                )
                            }

                            ForEach(unmatchedNames, id: \.self) { name in
                                UnmatchedPetCard(petName: name, onCreateProfile: {
                                    petIdsBeforeCreate = Set(petsViewModel.pets.map { $0.id })
                                    createPetContext = CreatePetContext(petName: name)
                                })
                            }
                        }

                        if !otherPets.isEmpty {
                            HStack {
                                Text("other_pets")
                                    .font(.appFont(.subheadline))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                            ForEach(otherPets) { pet in
                                TagPetSelectionRow(
                                    pet: pet,
                                    isSelected: selectedPet?.id == pet.id,
                                    onSelect: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedPet = pet
                                            errorMessage = nil
                                        }
                                    }
                                )
                            }
                        }
                    } else {
                        // No order context - show flat list
                        ForEach(petsViewModel.pets) { pet in
                            TagPetSelectionRow(
                                pet: pet,
                                isSelected: selectedPet?.id == pet.id,
                                onSelect: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedPet = pet
                                        errorMessage = nil
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }

            // Activate Button
            VStack(spacing: 12) {
                Button {
                    activateTag()
                } label: {
                    HStack {
                        if isActivating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isActivating ? String(localized: "tag_activating") : String(localized: "tag_activate_button"))
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(TagPrimaryButtonStyle())
                .disabled(selectedPet == nil || isActivating)
                .opacity(selectedPet == nil ? 0.6 : 1.0)

                Text("tag_link_message")
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
        }
    }

    // MARK: - Actions

    private func activateTag() {
        guard let pet = selectedPet else { return }

        isActivating = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.activateTag(code: currentTagCode, petId: pet.id)
                // Re-fetch unactivated items to update remaining count
                if let refreshed = try? await APIService.shared.getUnactivatedTagsForQRCode(currentTagCode) {
                    orderItems = refreshed
                }
                // Tell PetsListView's PetsViewModel to refresh so the
                // "TAG ON ITS WAY" badge drops immediately rather than
                // waiting for the next view-appear/pull-to-refresh.
                NotificationCenter.default.post(name: .tagActivated, object: nil)
                withAnimation {
                    activationSuccess = true
                }
            } catch {
                errorMessage = classifyActivationError(error.localizedDescription)
            }
            isActivating = false
        }
    }

    private func setupNextTag(_ item: UnactivatedOrderItem) {
        // Reset state for the next tag
        currentTagCode = item.qrCode ?? tagCode
        selectedPet = nil
        errorMessage = nil
        activationSuccess = false

        // If pet with this name already exists, pre-select it
        if let petName = item.petName,
           let matchingPet = petsViewModel.pets.first(where: { $0.name.lowercased() == petName.lowercased() }) {
            selectedPet = matchingPet
        }
    }

    private func classifyActivationError(_ msg: String) -> String {
        if msg.contains("not found") && msg.contains("QR") {
            return String(localized: "activation_error_qr_not_found")
        } else if msg.contains("already activated") {
            return String(localized: "activation_error_already_activated")
        } else if msg.contains("not been linked") {
            return String(localized: "activation_error_not_linked")
        } else if msg.contains("not been shipped") {
            return String(localized: "activation_error_not_shipped")
        } else if msg.contains("do not own") {
            return String(localized: "activation_error_not_owner")
        }
        return msg
    }
}

// MARK: - Next Step Card
private struct NextStepCard: View {
    let icon: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.appFont(size: 18))
                    .foregroundColor(Color("BrandColor"))
                    .frame(width: 24)
                Text(text)
                    .font(.appFont(.subheadline))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Pet Selection Row
struct TagPetSelectionRow: View {
    let pet: Pet
    let isSelected: Bool
    var badge: String? = nil
    let onSelect: () -> Void

    private let grayBackground = Color(UIColor.systemGray6)

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
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
                .frame(width: 56, height: 56)
                .background(grayBackground)
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.appFont(.headline))
                        .foregroundColor(.primary)

                    if let badge = badge {
                        Text(badge)
                            .font(.appFont(.caption2))
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color("BrandColor").opacity(0.15))
                            .foregroundColor(Color("BrandColor"))
                            .cornerRadius(4)
                    }

                    HStack(spacing: 4) {
                        Text(PetLocalizer.localizeSpecies(pet.species))
                        if let breed = pet.breed {
                            Text("-")
                            Text(breed)
                        }
                    }
                    .font(.appFont(.subheadline))
                    .foregroundColor(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color("BrandColor") : Color(UIColor.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color("BrandColor"))
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: isSelected ? Color("BrandColor").opacity(0.3) : Color.black.opacity(0.05),
                            radius: isSelected ? 4 : 2,
                            x: 0,
                            y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color("BrandColor") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Unmatched Pet Card
struct UnmatchedPetCard: View {
    let petName: String
    let onCreateProfile: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.appFont(size: 24))
                .foregroundColor(.orange)
                .frame(width: 56, height: 56)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(petName)
                    .font(.appFont(.headline))
                    .foregroundColor(.primary)

                Text("needs_profile")
                    .font(.appFont(.caption))
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
            }

            Spacer()

            Button(action: onCreateProfile) {
                Text("create_profile_first")
                    .font(.appFont(.caption))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("BrandColor"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundColor(.orange.opacity(0.3))
        )
    }
}

// MARK: - Button Styles
struct TagPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color("BrandColor").opacity(0.8) : Color("BrandColor"))
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct TagSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

#Preview {
    TagActivationView(tagCode: "PS-TEST1234") {
        #if DEBUG
        print("Dismissed")
        #endif
    }
    .environmentObject(AppState())
}
