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
            .navigationTitle(String(localized: "shelter_promo_claim_tag_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "close")) {
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
                        .font(.appFont(size: 40))
                        .foregroundColor(.brandOrange)

                    Text(String(format: NSLocalizedString("shelter_promo_welcome_format", comment: ""), promoInfo.shelterName))
                        .font(.appFont(.title2))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(String(format: NSLocalizedString("shelter_promo_register_subtitle_format", comment: ""), promoInfo.shelterName))
                        .font(.appFont(.subheadline))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)

                // Toggle: new vs existing pet
                if !viewModel.pets.isEmpty {
                    Picker(String(localized: "shelter_promo_pet_picker_label"), selection: $useExistingPet) {
                        Text(String(localized: "shelter_promo_new_pet")).tag(false)
                        Text(String(localized: "shelter_promo_existing_pet")).tag(true)
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
                        .font(.appFont(.caption))
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
                                .font(.appFont(.caption))
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
                    Text(String(localized: "shelter_promo_claim_tag_button"))
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
                    Text(String(localized: "shelter_promo_name_label_required"))
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                    TextField(String(localized: "shelter_promo_pet_name_placeholder"), text: $petName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "shelter_promo_species_label_required"))
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                    Picker(String(localized: "shelter_promo_species_label_required"), selection: $species) {
                        Text(String(localized: "shelter_promo_select_placeholder")).tag("")
                        Text(String(localized: "species_dog")).tag("dog")
                        Text(String(localized: "species_cat")).tag("cat")
                        Text(String(localized: "species_bird")).tag("bird")
                        Text(String(localized: "species_rabbit")).tag("rabbit")
                        Text(String(localized: "species_other")).tag("other")
                    }
                    .pickerStyle(.menu)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "breed"))
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                    TextField(String(localized: "breed"), text: $breed)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "color"))
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                    TextField(String(localized: "color"), text: $color)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "sex_label"))
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                    Picker(String(localized: "sex_label"), selection: $sex) {
                        Text(String(localized: "shelter_promo_select_placeholder")).tag("")
                        Text(String(localized: "sex_male")).tag("male")
                        Text(String(localized: "sex_female")).tag("female")
                    }
                    .pickerStyle(.menu)
                }

                Toggle(String(localized: "shelter_promo_neutered_spayed"), isOn: $isNeutered)
            }

            Button {
                guard !petName.isEmpty, !species.isEmpty else { return }
                let petData = CreatePetRequest(
                    name: petName,
                    species: species,
                    breed: breed.isEmpty ? nil : breed,
                    color: color.isEmpty ? nil : color,
                    weight: nil,
                    microchipNumber: nil,
                    medicalNotes: nil,
                    allergies: nil,
                    medications: nil,
                    notes: nil,
                    uniqueFeatures: nil,
                    sex: sex.isEmpty ? nil : sex,
                    isNeutered: isNeutered,
                    dateOfBirth: nil,
                    dobIsApproximate: nil
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
                    Text(String(localized: "shelter_promo_register_and_claim_button"))
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
                    .font(.appFont(size: 60))
                    .foregroundColor(.green)

                Text(String(localized: "shelter_promo_claim_success_title"))
                    .font(.appFont(.title))
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    if let pet = result.pet {
                        Label(pet.name, systemImage: "pawprint.fill")
                            .font(.appFont(.headline))
                    }
                    if let tag = result.tag {
                        Label(tag.qrCode, systemImage: "qrcode")
                            .font(.appFont(.subheadline))
                            .foregroundColor(.secondary)
                    }
                    if let details = result.promoDetails {
                        Label(
                            String(format: NSLocalizedString("shelter_promo_active_until_format", comment: ""), formatDate(details.trialEndDate)),
                            systemImage: "checkmark.seal.fill"
                        )
                        .font(.appFont(.subheadline))
                        .foregroundColor(.brandOrange)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)

                Button(String(localized: "done")) {
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
