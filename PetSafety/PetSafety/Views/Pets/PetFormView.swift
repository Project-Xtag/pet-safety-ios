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
    var initialPetName: String? = nil
    /// Names of remaining pets to register (tag activation flow)
    var remainingPetNames: [String] = []
    /// Called when user taps "Register next pet" with the next pet's name
    var onRegisterNextPet: ((String) -> Void)?
    /// Called when all pets are done (show thank-you / go home)
    var onAllDone: (() -> Void)?
    /// Tag activation flow: after a pet is created, perform any follow-up work
    /// (typically activate the QR tag) and wait for it to succeed BEFORE the
    /// "Tag activated for X" success screen is shown. If this throws, the
    /// success screen is suppressed and the caller's onAllDone is invoked so
    /// the user is dismissed back with the error visible.
    var onPetCreated: ((Pet) async throws -> Void)?

    @StateObject private var viewModel = PetsViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var name: String
    @State private var showPostSaveScreen = false
    @State private var savedPetName: String = ""
    /// Active while the post-create hook (e.g. tag activation) is running so the
    /// save button stays disabled until we know whether to show success or error.
    @State private var isRunningPostCreateHook = false
    @State private var species = "Dog"
    @State private var breed = ""
    @State private var color = ""
    @State private var dateOfBirth = Date()
    @State private var hasDob = false
    @State private var dobIsApproximate = false
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

    init(mode: PetFormMode, initialPetName: String? = nil, remainingPetNames: [String] = [], onRegisterNextPet: ((String) -> Void)? = nil, onAllDone: (() -> Void)? = nil, onPetCreated: ((Pet) async throws -> Void)? = nil) {
        self.mode = mode
        self.initialPetName = initialPetName
        self.remainingPetNames = remainingPetNames
        self.onRegisterNextPet = onRegisterNextPet
        self.onAllDone = onAllDone
        self.onPetCreated = onPetCreated
        if case .edit(let pet) = mode {
            _name = State(initialValue: pet.name)
        } else {
            _name = State(initialValue: initialPetName ?? "")
        }
    }

    private var existingPet: Pet? {
        if case .edit(let pet) = mode { return pet }
        return nil
    }

    var body: some View {
        if showPostSaveScreen {
            postSaveView
        } else {
        Form {
            // Tag activation context banner
            if let tagPetName = initialPetName, !tagPetName.isEmpty {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "tag.fill")
                            .foregroundColor(Color("BrandColor"))
                        Text("setting_up_tag_for \(tagPetName)")
                            .font(.appFont(.subheadline))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Profile completion warning
            if mode.isEdit, let pet = existingPet, pet.qrCode != nil,
               pet.color == nil && pet.weight == nil {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("profile_incomplete_warning")
                                .font(.appFont(.subheadline))
                                .fontWeight(.semibold)
                            Text("profile_incomplete_desc")
                                .font(.appFont(.caption))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Locked fields info banner
            Section {
                HStack(spacing: 12) {
                    Image(systemName: mode.isEdit ? "lock.fill" : "info.circle.fill")
                        .foregroundColor(mode.isEdit ? .blue : .orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.isEdit ? String(localized: "identity_locked_title") : String(localized: "identity_will_lock_title"))
                            .font(.appFont(.subheadline))
                            .fontWeight(.semibold)
                        Text(mode.isEdit ? String(localized: "identity_locked_desc") : String(localized: "identity_will_lock_desc"))
                            .font(.appFont(.caption))
                            .foregroundColor(.secondary)
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
                                .font(.appFont(.largeTitle))
                                .foregroundColor(.secondary)
                                .frame(width: 100, height: 100)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        VStack(alignment: .leading) {
                            Text(mode.isEdit ? "edit_photo" : "select_photo")
                                .font(.appFont(.headline))
                            Text("choose_photo_hint")
                                .font(.appFont(.caption))
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)

                        Spacer()
                    }
                }
            }

            Section("basic_information") {
                if mode.isEdit {
                    // In edit mode, name is locked (read-only) — no translation needed, it's a proper noun
                    HStack {
                        Text("name")
                            .frame(width: 80, alignment: .leading)
                        Text(name)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.appFont(.caption))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Text("name")
                            .frame(width: 80, alignment: .leading)
                        TextField(String(localized: "pet_name"), text: $name)
                            .onChange(of: name) { _, new in if new.count > InputValidators.maxPetName { name = String(new.prefix(InputValidators.maxPetName)) } }
                    }
                }

                if mode.isEdit {
                    // In edit mode, show species as localized read-only text
                    HStack {
                        Text("species")
                            .frame(width: 80, alignment: .leading)
                        Text(PetLocalizer.localizeSpecies(species))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.appFont(.caption))
                            .foregroundColor(.secondary)
                    }
                } else {
                    // In create mode, show species picker (localized labels, English tags)
                    Picker("species", selection: $species) {
                        ForEach(speciesOptions, id: \.self) { option in
                            Text(PetLocalizer.localizeSpecies(option)).tag(option)
                        }
                    }
                }

                if mode.isEdit {
                    // In edit mode, breed is locked and localized
                    HStack {
                        Text("breed")
                            .frame(width: 80, alignment: .leading)
                        Text(breed.isEmpty ? "-" : PetLocalizer.localizeBreed(breed, species: species))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.appFont(.caption))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Text("breed")
                            .frame(width: 80, alignment: .leading)
                        BreedPickerButton(breed: $breed, species: species)
                    }
                }

                HStack {
                    Text("colour")
                        .frame(width: 80, alignment: .leading)
                    TextField(String(localized: "colour_optional"), text: $color)
                        .onChange(of: color) { _, new in if new.count > InputValidators.maxColor { color = String(new.prefix(InputValidators.maxColor)) } }
                }

                Toggle(String(localized: "dob_set_date"), isOn: $hasDob)

                if hasDob {
                    DatePicker(String(localized: "date_of_birth"), selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)

                    Toggle(String(localized: "dob_approximate"), isOn: $dobIsApproximate)
                }

                HStack {
                    Text("microchip")
                        .frame(width: 80, alignment: .leading)
                    TextField(String(localized: "microchip_optional"), text: $microchipNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: microchipNumber) { _, new in if new.count > InputValidators.maxMicrochip { microchipNumber = String(new.prefix(InputValidators.maxMicrochip)) } }
                }

                // Physical details (merged into basic information)
                HStack {
                    Text("weight")
                        .frame(width: 80, alignment: .leading)
                    TextField(String(localized: "weight_optional"), text: $weight)
                        .keyboardType(.decimalPad)
                        .onChange(of: weight) { _, new in if new.count > 10 { weight = String(new.prefix(10)) } }
                }

                Picker("sex", selection: $sex) {
                    ForEach(sexOptions, id: \.self) { option in
                        Text(PetLocalizer.localizeSex(option, species: species)).tag(option)
                    }
                }

                Toggle("neutered_spayed", isOn: $isNeutered)
            }

            Section("health_information") {
                TextEditor(text: $medicalInfo)
                    .frame(minHeight: 80)
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
                    .frame(minHeight: 80)
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
                    .frame(minHeight: 80)
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
                        if viewModel.isLoading || isRunningPostCreateHook {
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
                        .fill(name.isEmpty || viewModel.isLoading || isRunningPostCreateHook ? Color.brandOrange.opacity(0.4) : Color.brandOrange)
                )
                .foregroundColor(.white)
                .disabled(name.isEmpty || viewModel.isLoading || isRunningPostCreateHook)
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
        .adaptiveList(maxWidth: 900)
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
        } // end else (form vs postSaveView)
    }

    // MARK: - Post-Save Screen (tag activation flow)
    private var postSaveView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "checkmark.circle.fill")
                    .font(.appFont(size: 70))
                    .foregroundColor(.tealAccent)

                Text("tag_activated_for \(savedPetName)")
                    .font(.appFont(.title2))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("pet_now_protected")
                    .font(.appFont(.body))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if !remainingPetNames.isEmpty {
                    // More pets to register
                    VStack(spacing: 16) {
                        Text("more_tags_to_setup")
                            .font(.appFont(.subheadline))
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        ForEach(remainingPetNames, id: \.self) { petName in
                            Button {
                                onRegisterNextPet?(petName)
                            } label: {
                                HStack {
                                    Image(systemName: "pawprint.fill")
                                        .foregroundColor(Color("BrandColor"))
                                    Text("setup_pet_tag \(petName)")
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
                    // All done
                    VStack(spacing: 16) {
                        Text("thank_you_senra")
                            .font(.appFont(.headline))

                        Text("whats_next")
                            .font(.appFont(.subheadline))
                            .foregroundColor(.secondary)

                        VStack(spacing: 10) {
                            postSaveActionCard(icon: "person.crop.circle.fill", text: String(localized: "update_contact_details")) {
                                onAllDone?()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer().frame(height: 20)

                Button {
                    onAllDone?() ?? dismiss()
                } label: {
                    Text("go_to_home")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("BrandColor"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(Text("tag_activated"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func postSaveActionCard(icon: String, text: String, action: @escaping () -> Void) -> some View {
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

    private func populateFields(with pet: Pet) {
        name = pet.name
        // Capitalize species to match picker options
        species = pet.species.capitalized
        breed = pet.breed ?? ""
        color = pet.color ?? ""
        if let dobString = pet.dateOfBirth,
           let dob = ISO8601DateFormatter().date(from: dobString) ?? {
               let f = DateFormatter()
               f.dateFormat = "yyyy-MM-dd"
               return f.date(from: dobString)
           }() {
            dateOfBirth = dob
            hasDob = true
        }
        dobIsApproximate = pet.dobIsApproximate ?? false
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
                    let dobString: String? = hasDob ? {
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd"
                        return f.string(from: dateOfBirth)
                    }() : nil
                    let request = CreatePetRequest(
                        name: name,
                        species: species,
                        breed: breed.isEmpty ? nil : breed,
                        color: color.isEmpty ? nil : color,
                        weight: weightValue,
                        microchipNumber: microchipNumber.isEmpty ? nil : microchipNumber,
                        medicalNotes: medicalInfo.isEmpty ? nil : medicalInfo,
                        allergies: allergies.isEmpty ? nil : allergies,
                        medications: medications.isEmpty ? nil : medications,
                        notes: behaviorNotes.isEmpty ? nil : behaviorNotes,
                        uniqueFeatures: uniqueFeatures.isEmpty ? nil : uniqueFeatures,
                        sex: sex == "Unknown" ? nil : sex.lowercased(),
                        isNeutered: isNeutered,
                        dateOfBirth: dobString,
                        dobIsApproximate: hasDob ? dobIsApproximate : nil
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

                    // Tag-activation context: run the post-create hook (activate the
                    // QR tag) BEFORE the "Tag activated for X" success screen
                    // appears. Without this gate the success copy used to render
                    // even when activation never happened, leaving the tag stuck
                    // at status='shipped' on the backend.
                    if let onPetCreated = onPetCreated {
                        isRunningPostCreateHook = true
                        do {
                            try await onPetCreated(newPet)
                            isRunningPostCreateHook = false
                        } catch {
                            isRunningPostCreateHook = false
                            #if DEBUG
                            print("❌ Post-create hook (tag activation) failed: \(error)")
                            #endif
                            // Pet was created; tag activation failed. Tell the
                            // user honestly and dismiss back so they can retry
                            // by re-scanning — the new pet shows up in their
                            // list with the "TAG ON ITS WAY" badge.
                            appState.showError(
                                String(format: NSLocalizedString("pet_created_tag_activation_failed", comment: ""), error.localizedDescription)
                            )
                            if let onAllDone = onAllDone {
                                onAllDone()
                            } else {
                                dismiss()
                            }
                            return
                        }
                    }

                case .edit(let pet):
                    #if DEBUG
                    print("✏️ Updating pet with ID: \(pet.id)")
                    #endif

                    // Send only editable fields — name, species, breed are locked after registration
                    let editWeightValue = Double(weight)
                    let editDobString: String? = hasDob ? {
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd"
                        return f.string(from: dateOfBirth)
                    }() : nil
                    let request = UpdatePetRequest(
                        name: nil,     // Locked after registration
                        species: nil,  // Locked after registration
                        breed: nil,    // Locked after registration
                        color: color.isEmpty ? nil : color,
                        weight: editWeightValue,
                        microchipNumber: microchipNumber.isEmpty ? nil : microchipNumber,
                        medicalNotes: medicalInfo.isEmpty ? nil : medicalInfo,
                        allergies: allergies.isEmpty ? nil : allergies,
                        medications: medications.isEmpty ? nil : medications,
                        notes: behaviorNotes.isEmpty ? nil : behaviorNotes,
                        uniqueFeatures: uniqueFeatures.isEmpty ? nil : uniqueFeatures,
                        sex: sex == "Unknown" ? nil : sex.lowercased(),
                        isNeutered: isNeutered,
                        isMissing: nil,
                        dateOfBirth: editDobString,
                        dobIsApproximate: hasDob ? dobIsApproximate : nil
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

                // In tag activation context, show post-save screen instead of dismissing.
                // By this point, if onPetCreated was provided, the tag activation
                // has already succeeded (the .create branch above awaits it before
                // continuing), so the postSaveView's "Tag activated for X" copy
                // is accurate.
                if onRegisterNextPet != nil || onAllDone != nil {
                    savedPetName = name
                    withAnimation { showPostSaveScreen = true }
                } else {
                    dismiss()
                }
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
