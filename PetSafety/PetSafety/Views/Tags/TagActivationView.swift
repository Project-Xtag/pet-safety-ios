import SwiftUI
import UIKit

/// View for activating a QR tag and linking it to a pet
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
    @State private var showPlanSelection = false

    private let grayBackground = Color(UIColor.systemGray6)

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
            .navigationTitle(Text("tag_activate_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "cancel")) {
                        onDismiss()
                    }
                }
            }
            .task {
                await petsViewModel.fetchPets()
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("tag_loading_pets")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Success View
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.tealAccent)

            Text("tag_activated")
                .font(.title)
                .fontWeight(.bold)

            if let pet = selectedPet {
                Text("tag_activated_message \(pet.name)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // Pet Photo
                CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: pet.species.lowercased() == "dog" ? "dog.fill" : "cat.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                }
                .frame(width: 100, height: 100)
                .background(grayBackground)
                .clipShape(Circle())
            }

            Text("tag_choose_plan")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                showPlanSelection = true
            } label: {
                Text("tag_choose_plan_button")
                    .fontWeight(.semibold)
            }
            .buttonStyle(TagPrimaryButtonStyle())
            .padding(.horizontal, 24)

            Button {
                onDismiss()
            } label: {
                Text("tag_skip_for_now")
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)
        }
        .fullScreenCover(isPresented: $showPlanSelection) {
            PlanSelectionView(fromActivation: true) {
                onDismiss()
            }
        }
    }

    // MARK: - No Pets View
    private var noPetsView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "pawprint.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("tag_no_pets")
                .font(.title2)
                .fontWeight(.bold)

            Text("tag_no_pets_message")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Text("tag_code_label")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(tagCode)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(grayBackground)
                    .cornerRadius(8)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("close")
                    .fontWeight(.semibold)
            }
            .buttonStyle(TagSecondaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Pet Selection View
    private var petSelectionView: some View {
        VStack(spacing: 0) {
            // Tag Info Header
            VStack(spacing: 12) {
                Image(systemName: "qrcode")
                    .font(.system(size: 40))
                    .foregroundColor(Color("BrandColor"))

                Text("tag_code_label")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(tagCode)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(grayBackground)
                    .cornerRadius(8)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(grayBackground.opacity(0.5))

            // Instructions
            Text("tag_select_pet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Error Message
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            // Pet List
            ScrollView {
                LazyVStack(spacing: 12) {
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
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
        }
    }

    // MARK: - Activate Tag
    private func activateTag() {
        guard let pet = selectedPet else { return }

        isActivating = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.activateTag(code: tagCode, petId: pet.id)
                withAnimation {
                    activationSuccess = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isActivating = false
        }
    }
}

// MARK: - Pet Selection Row
struct TagPetSelectionRow: View {
    let pet: Pet
    let isSelected: Bool
    let onSelect: () -> Void

    private let grayBackground = Color(UIColor.systemGray6)

    var body: some View {
        Button(action: onSelect) {
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
                .frame(width: 56, height: 56)
                .background(grayBackground)
                .cornerRadius(12)

                // Pet Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Text(pet.species.capitalized)
                        if let breed = pet.breed {
                            Text("-")
                            Text(breed)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Selection Indicator
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

// MARK: - Button Styles (prefixed to avoid conflicts)
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
