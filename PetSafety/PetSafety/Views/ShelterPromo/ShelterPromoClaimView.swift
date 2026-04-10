import SwiftUI

struct ShelterPromoClaimView: View {
    let tagCode: String
    let promoInfo: PromoTagInfo

    @StateObject private var viewModel = ShelterPromoClaimViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var useExistingPet = false
    @State private var selectedPetId: String?

    // New pet form fields
    @State private var petName = ""
    @State private var species = ""
    @State private var breed = ""
    @State private var dateOfBirth = ""
    @State private var color = ""
    @State private var sex = ""
    @State private var isNeutered = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .success(let result):
                    successView(result)
                default:
                    claimFormView
                }
            }
            .navigationTitle(String(localized: "Claim Tag"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "Close")) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadPets()
        }
    }

    // MARK: - Claim Form

    private var claimFormView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome banner
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.brandOrange)

                    Text(String(localized: "Welcome from \(promoInfo.shelterName)!"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "Register your pet to activate this tag and get \(promoInfo.promoDurationMonths) months of free Standard plan."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)

                // Toggle: new vs existing pet
                if !viewModel.pets.isEmpty {
                    Picker(String(localized: "Pet"), selection: $useExistingPet) {
                        Text(String(localized: "New Pet")).tag(false)
                        Text(String(localized: "Existing Pet")).tag(true)
                    }
                    .pickerStyle(.segmented)
                }

                if useExistingPet {
                    existingPetSection
                } else {
                    newPetFormSection
                }

                // Error message
                if case .error(let message) = viewModel.state {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .padding()
        }
    }

    // MARK: - Existing Pet Selection

    private var existingPetSection: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.pets, id: \.id) { pet in
                Button {
                    selectedPetId = pet.id
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(pet.name)
                                .fontWeight(.medium)
                            Text(pet.species ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedPetId == pet.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.brandOrange)
                        }
                    }
                    .padding()
                    .background(selectedPetId == pet.id ? Color.orange.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }

            Button {
                guard let petId = selectedPetId else { return }
                Task {
                    await viewModel.claimWithExistingPet(qrCode: tagCode, petId: petId)
                }
            } label: {
                HStack {
                    if case .loading = viewModel.state {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(String(localized: "Claim Tag"))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandOrange)
            .disabled(selectedPetId == nil || viewModel.state is ShelterPromoClaimViewModel.ClaimState == false)
            .controlSize(.large)
        }
    }

    // MARK: - New Pet Form

    private var newPetFormSection: some View {
        VStack(spacing: 16) {
            Group {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Name *"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "Pet name"), text: $petName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Species *"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker(String(localized: "Species"), selection: $species) {
                        Text(String(localized: "Select...")).tag("")
                        Text(String(localized: "Dog")).tag("dog")
                        Text(String(localized: "Cat")).tag("cat")
                        Text(String(localized: "Bird")).tag("bird")
                        Text(String(localized: "Rabbit")).tag("rabbit")
                        Text(String(localized: "Other")).tag("other")
                    }
                    .pickerStyle(.menu)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Breed"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "Breed"), text: $breed)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Color"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField(String(localized: "Color"), text: $color)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Sex"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker(String(localized: "Sex"), selection: $sex) {
                        Text(String(localized: "Select...")).tag("")
                        Text(String(localized: "Male")).tag("male")
                        Text(String(localized: "Female")).tag("female")
                    }
                    .pickerStyle(.menu)
                }

                Toggle(String(localized: "Neutered / Spayed"), isOn: $isNeutered)
            }

            Button {
                guard !petName.isEmpty, !species.isEmpty else { return }
                let petData = CreatePetRequest(
                    name: petName,
                    species: species,
                    breed: breed.isEmpty ? nil : breed,
                    color: color.isEmpty ? nil : color,
                    sex: sex.isEmpty ? nil : sex,
                    is_neutered: isNeutered
                )
                Task {
                    await viewModel.claimWithNewPet(qrCode: tagCode, petData: petData)
                }
            } label: {
                HStack {
                    if case .loading = viewModel.state {
                        ProgressView()
                            .tint(.white)
                    }
                    Image(systemName: "pawprint.fill")
                    Text(String(localized: "Register Pet & Claim Tag"))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandOrange)
            .disabled(petName.isEmpty || species.isEmpty)
            .controlSize(.large)
        }
    }

    // MARK: - Success View

    private func successView(_ result: ClaimPromoTagResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text(String(localized: "Tag Claimed!"))
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    if let pet = result.pet {
                        Label(pet.name, systemImage: "pawprint.fill")
                            .font(.headline)
                    }
                    if let tag = result.tag {
                        Label(tag.qrCode, systemImage: "qrcode")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let details = result.promoDetails {
                        Label(
                            String(localized: "Free Standard plan until \(formatDate(details.trialEndDate))"),
                            systemImage: "crown.fill"
                        )
                        .font(.subheadline)
                        .foregroundColor(.brandOrange)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)

                if result.subscriptionAction == "override_only" {
                    Text(String(localized: "Your new pet has Standard features for \(promoInfo.promoDurationMonths) months. Upgrade to Maximum to keep all pets covered."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(String(localized: "Done")) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate, .withTime, .withColonSeparatorInTime]
        if let date = formatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            return displayFormatter.string(from: date)
        }
        return isoString
    }
}
