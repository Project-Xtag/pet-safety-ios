import SwiftUI
import PhotosUI

enum PetFormMode {
    case create
    case edit(Pet)

    var title: String {
        switch self {
        case .create: return NSLocalizedString("add_pet", comment: "")
        case .edit: return NSLocalizedString("edit_pet", comment: "")
        }
    }

    var isEdit: Bool {
        if case .edit = self {
            return true
        }
        return false
    }
}

struct PetFormView: View {
    let mode: PetFormMode
    @StateObject private var viewModel = PetsViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var name = ""
    @State private var species = "Dog"
    @State private var breed = ""
    @State private var color = ""
    @State private var dateOfBirth = Date()
    @State private var microchipNumber = ""
    @State private var medicalInfo = ""
    @State private var behaviorNotes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingDeleteAlert = false
    @State private var showingCannotDeleteAlert = false
    @State private var photoWasChanged = false

    // Additional fields from web app
    @State private var weight: String = ""
    @State private var sex = "Unknown"
    @State private var isNeutered = false
    @State private var uniqueFeatures = ""
    @State private var allergies = ""
    @State private var medications = ""

    let speciesOptions = ["Dog", "Cat", "Bird", "Rabbit", "Other"]
    let sexOptions = ["Unknown", "Male", "Female"]

    private var existingPet: Pet? {
        if case .edit(let pet) = mode { return pet }
        return nil
    }

    var body: some View {
        Form {
            // Profile completion warning
            if mode.isEdit, let pet = existingPet, pet.qrCode != nil,
               pet.color == nil && pet.weight == nil {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("profile_incomplete_warning")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("profile_incomplete_desc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Locked fields info banner
            if mode.isEdit, let pet = existingPet, pet.qrCode != nil {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("identity_locked_title")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("identity_locked_desc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Photo section moved to top
            Section("photo") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                                .frame(width: 100, height: 100)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading) {
                            Text(mode.isEdit ? "edit_photo" : "select_photo")
                                .font(.headline)
                            Text("choose_photo_hint")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)

                        Spacer()
                    }
                }
            }

            Section("basic_information") {
                HStack {
                    Text("name")
                        .frame(width: 80, alignment: .leading)
                    TextField("pet_name", text: $name)
                        .onChange(of: name) { _, new in if new.count > InputValidators.maxPetName { name = String(new.prefix(InputValidators.maxPetName)) } }
                }

                if mode.isEdit {
                    // In edit mode, show species as read-only text
                    HStack {
                        Text("species")
                            .frame(width: 80, alignment: .leading)
                        Text(species)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                } else {
                    // In create mode, show species picker
                    Picker("species", selection: $species) {
                        ForEach(speciesOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }

                HStack {
                    Text("breed")
                        .frame(width: 80, alignment: .leading)
                    BreedPickerButton(breed: $breed, species: species)
                }

                HStack {
                    Text("colour")
                        .frame(width: 80, alignment: .leading)
                    TextField("colour_optional", text: $color)
                        .onChange(of: color) { _, new in if new.count > InputValidators.maxColor { color = String(new.prefix(InputValidators.maxColor)) } }
                }

                // Age display
                if mode.isEdit, case .edit(let pet) = mode, let age = pet.age {
                    HStack {
                        Text("age")
                            .frame(width: 80, alignment: .leading)
                        Text(age)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                } else if !mode.isEdit {
                    DatePicker("date_of_birth", selection: $dateOfBirth, displayedComponents: .date)
                }

                HStack {
                    Text("microchip")
                        .frame(width: 80, alignment: .leading)
                    TextField("microchip_optional", text: $microchipNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: microchipNumber) { _, new in if new.count > InputValidators.maxMicrochip { microchipNumber = String(new.prefix(InputValidators.maxMicrochip)) } }
                }

                // Physical details (merged into basic information)
                HStack {
                    Text("weight")
                        .frame(width: 80, alignment: .leading)
                    TextField("weight_optional", text: $weight)
                        .keyboardType(.decimalPad)
                        .onChange(of: weight) { _, new in if new.count > 10 { weight = String(new.prefix(10)) } }
                }

                Picker("sex", selection: $sex) {
                    ForEach(sexOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                Toggle("neutered_spayed", isOn: $isNeutered)
            }

            Section("health_information") {
                TextEditor(text: $medicalInfo)
                    .frame(minHeight: 120)
                    .onChange(of: medicalInfo) { _, new in if new.count > InputValidators.maxMedicalNotes { medicalInfo = String(new.prefix(InputValidators.maxMedicalNotes)) } }
                    .overlay(alignment: .topLeading) {
                        if medicalInfo.isEmpty {
                            Text("health_info_hint")
                                .foregroundColor(.mutedText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }

                TextEditor(text: $allergies)
                    .frame(minHeight: 60)
                    .onChange(of: allergies) { _, new in if new.count > InputValidators.maxAllergies { allergies = String(new.prefix(InputValidators.maxAllergies)) } }
                    .overlay(alignment: .topLeading) {
                        if allergies.isEmpty {
                            Text("allergies_hint")
                                .foregroundColor(.mutedText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }

                TextEditor(text: $medications)
                    .frame(minHeight: 60)
                    .onChange(of: medications) { _, new in if new.count > InputValidators.maxMedications { medications = String(new.prefix(InputValidators.maxMedications)) } }
                    .overlay(alignment: .topLeading) {
                        if medications.isEmpty {
                            Text("medications_hint")
                                .foregroundColor(.mutedText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            }

            Section("additional_information") {
                TextEditor(text: $uniqueFeatures)
                    .frame(minHeight: 60)
                    .onChange(of: uniqueFeatures) { _, new in if new.count > InputValidators.maxUniqueFeatures { uniqueFeatures = String(new.prefix(InputValidators.maxUniqueFeatures)) } }
                    .overlay(alignment: .topLeading) {
                        if uniqueFeatures.isEmpty {
                            Text("unique_features_hint")
                                .foregroundColor(.mutedText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }

                TextEditor(text: $behaviorNotes)
                    .frame(minHeight: 80)
                    .onChange(of: behaviorNotes) { _, new in if new.count > InputValidators.maxNotes { behaviorNotes = String(new.prefix(InputValidators.maxNotes)) } }
                    .overlay(alignment: .topLeading) {
                        if behaviorNotes.isEmpty {
                            Text("behavior_notes_hint")
                                .foregroundColor(.mutedText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            }

            // Save button
            Section {
                Button(action: { savePet() }) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("save_changes")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(name.isEmpty || viewModel.isLoading ? Color.brandOrange.opacity(0.4) : Color.brandOrange)
                )
                .foregroundColor(.white)
                .disabled(name.isEmpty || viewModel.isLoading)
            }

            // Delete Pet button - only show in edit mode
            if case .edit(let pet) = mode {
                Section {
                    Button(action: {
                        // Block deletion if pet is missing
                        if pet.isMissing {
                            showingCannotDeleteAlert = true
                        } else {
                            showingDeleteAlert = true
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("delete_pet_button")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .adaptiveList()
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("cancel") {
                    dismiss()
                }
                .foregroundColor(.brandOrange)
            }
        }
        .alert(deleteWarningTitle, isPresented: $showingDeleteAlert) {
            Button("cancel", role: .cancel) { }
            Button(String(localized: "delete_pet_warning_confirm"), role: .destructive) {
                deletePet()
            }
        } message: {
            Text(deleteWarningMessage)
        }
        .alert(NSLocalizedString("cannot_delete_missing_pet", comment: ""), isPresented: $showingCannotDeleteAlert) {
            Button("ok", role: .cancel) { }
        } message: {
            Text("cannot_delete_missing_message_short")
        }
        .alert(String(localized: "pet_limit_reached"), isPresented: $viewModel.showUpgradePrompt) {
            Button("ok", role: .cancel) { }
        } message: {
            Text("pet_limit_reached_info")
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    photoWasChanged = true  // Mark that user selected a new photo
                }
            }
        }
        .onAppear {
            if case .edit(let pet) = mode {
                populateFields(with: pet)
            }
        }
    }

    private func populateFields(with pet: Pet) {
        name = pet.name
        // Capitalize species to match picker options
        species = pet.species.capitalized
        breed = pet.breed ?? ""
        color = pet.color ?? ""
        if let dobString = pet.dateOfBirth,
           let dob = ISO8601DateFormatter().date(from: dobString) {
            dateOfBirth = dob
        }
        microchipNumber = pet.microchipNumber ?? ""
        medicalInfo = pet.medicalInfo ?? ""
        behaviorNotes = pet.behaviorNotes ?? ""

        // Additional fields
        if let petWeight = pet.weight {
            weight = String(format: "%.1f", petWeight)
        }
        sex = pet.sex ?? "Unknown"
        isNeutered = pet.isNeutered ?? false
        uniqueFeatures = pet.uniqueFeatures ?? ""
        allergies = pet.allergies ?? ""
        medications = pet.medications ?? ""

        // Load existing photo if available
        if let imageUrlString = pet.profileImage,
           let imageUrl = URL(string: imageUrlString) {
            Task {
                await loadImage(from: imageUrl)
            }
        }
    }

    private func loadImage(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        } catch {
            #if DEBUG
            print("Failed to load image: \(error.localizedDescription)")
            #endif
        }
    }

    private func savePet() {
        Task {
            do {
                #if DEBUG
                print("🔄 Starting save pet operation...")
                #endif

                switch mode {
                case .create:
                    #if DEBUG
                    print("📝 Creating new pet")
                    #endif

                    let weightValue = Double(weight)
                    let request = CreatePetRequest(
                        name: name,
                        species: species,
                        breed: breed.isEmpty ? nil : breed,
                        color: color.isEmpty ? nil : color,
                        age: nil, // Age will be calculated from date of birth by backend
                        weight: weightValue,
                        microchipNumber: microchipNumber.isEmpty ? nil : microchipNumber,
                        medicalNotes: medicalInfo.isEmpty ? nil : medicalInfo,
                        allergies: allergies.isEmpty ? nil : allergies,
                        medications: medications.isEmpty ? nil : medications,
                        notes: behaviorNotes.isEmpty ? nil : behaviorNotes,
                        uniqueFeatures: uniqueFeatures.isEmpty ? nil : uniqueFeatures,
                        sex: sex == "Unknown" ? nil : sex.lowercased(),
                        isNeutered: isNeutered
                    )

                    #if DEBUG
                    print("Creating pet with data: name=\(name), species=\(species), breed=\(breed)")
                    #endif
                    let newPet = try await viewModel.createPet(request)
                    #if DEBUG
                    print("✅ Pet created successfully with ID: \(newPet.id)")
                    #endif

                    // Upload photo if selected
                    if let image = selectedImage {
                        #if DEBUG
                        print("📸 Uploading photo...")
                        #endif
                        _ = try await viewModel.uploadPhoto(for: newPet.id, image: image)
                        #if DEBUG
                        print("✅ Photo uploaded successfully")
                        #endif
                    }

                    appState.showSuccess(NSLocalizedString("pet_created", comment: ""))

                case .edit(let pet):
                    #if DEBUG
                    print("✏️ Updating pet with ID: \(pet.id)")
                    #endif

                    // Send all editable fields from the form
                    let editWeightValue = Double(weight)
                    let request = UpdatePetRequest(
                        name: name,
                        species: nil,  // Species is read-only in edit mode, don't update it
                        breed: breed.isEmpty ? nil : breed,
                        color: color.isEmpty ? nil : color,
                        age: nil,  // Age is derived from date of birth, don't send it
                        weight: editWeightValue,
                        microchipNumber: microchipNumber.isEmpty ? nil : microchipNumber,
                        medicalNotes: medicalInfo.isEmpty ? nil : medicalInfo,
                        allergies: allergies.isEmpty ? nil : allergies,
                        medications: medications.isEmpty ? nil : medications,
                        notes: behaviorNotes.isEmpty ? nil : behaviorNotes,
                        uniqueFeatures: uniqueFeatures.isEmpty ? nil : uniqueFeatures,
                        sex: sex == "Unknown" ? nil : sex.lowercased(),
                        isNeutered: isNeutered,
                        isMissing: nil  // Not in form - use mark lost/found feature
                    )

                    #if DEBUG
                    print("Updating pet with: name=\(name), breed=\(breed), color=\(color)")
                    #endif
                    let updatedPet = try await viewModel.updatePet(id: pet.id, updates: request)
                    #if DEBUG
                    print("✅ Pet updated successfully")
                    print("📥 Received pet data: \(updatedPet.name), species: \(updatedPet.species)")
                    #endif

                    // Upload photo only if user selected a new one
                    if photoWasChanged, let image = selectedImage {
                        do {
                            #if DEBUG
                            print("📸 Uploading new photo...")
                            #endif
                            _ = try await viewModel.uploadPhoto(for: pet.id, image: image)
                            #if DEBUG
                            print("✅ Photo uploaded successfully")
                            #endif
                            appState.showSuccess(NSLocalizedString("pet_updated", comment: ""))
                        } catch {
                            #if DEBUG
                            print("❌ Photo upload failed: \(error)")
                            // Pet was saved successfully, just warn about photo
                            if let apiError = error as? APIError {
                                print("API Error details: \(apiError)")
                            }
                            #endif
                            appState.showSuccess(NSLocalizedString("pet_updated_photo_failed", comment: ""))
                        }
                    } else {
                        appState.showSuccess(NSLocalizedString("pet_updated", comment: ""))
                    }
                }

                #if DEBUG
                print("✅ Save operation completed successfully")
                #endif
                dismiss()
            } catch let error as APIError {
                #if DEBUG
                print("❌ Save operation failed: \(error)")
                print("API Error type: \(error.errorDescription ?? "Unknown")")
                #endif
                // Don't show generic error for pet limit — the alert handles it
                if case .petLimitExceeded = error { return }
                appState.showError(error.localizedDescription)
            } catch {
                #if DEBUG
                print("❌ Save operation failed: \(error)")
                #endif
                appState.showError(error.localizedDescription)
            }
        }
    }

    private var deleteWarningTitle: String {
        String(format: NSLocalizedString("delete_pet_warning_title", comment: ""), name)
    }

    private var deleteWarningMessage: String {
        String(format: NSLocalizedString("delete_pet_warning_message", comment: ""), name)
    }

    private func deletePet() {
        guard case .edit(let pet) = mode else { return }

        Task {
            do {
                try await viewModel.deletePet(id: pet.id)
                appState.showSuccess(String(format: NSLocalizedString("pet_deleted", comment: ""), pet.name))
                dismiss()
            } catch {
                appState.showError(String(format: NSLocalizedString("delete_pet_failed", comment: ""), error.localizedDescription))
            }
        }
    }
}

#Preview {
    NavigationView {
        PetFormView(mode: .create)
            .environmentObject(AppState())
    }
}
