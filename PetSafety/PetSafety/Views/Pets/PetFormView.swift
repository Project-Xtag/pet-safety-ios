import SwiftUI
import PhotosUI

enum PetFormMode {
    case create
    case edit(Pet)

    var title: String {
        switch self {
        case .create: return "Add Pet"
        case .edit: return "Edit Pet"
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
    @State private var photoWasChanged = false

    // Additional fields from web app
    @State private var weight: String = ""
    @State private var sex = "Unknown"
    @State private var isNeutered = false
    @State private var allergies = ""
    @State private var medications = ""
    @State private var uniqueFeatures = ""

    let speciesOptions = ["Dog", "Cat", "Bird", "Rabbit", "Other"]
    let sexOptions = ["Unknown", "Male", "Female"]

    var body: some View {
        Form {
            // Photo section moved to top
            Section("Photo") {
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
                            Text(mode.isEdit ? "Edit Photo" : "Select Photo")
                                .font(.headline)
                            Text("Choose a photo of your pet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)

                        Spacer()
                    }
                }
            }

            Section("Basic Information") {
                HStack {
                    Text("Name")
                        .frame(width: 80, alignment: .leading)
                    TextField("Pet Name", text: $name)
                }

                if mode.isEdit {
                    // In edit mode, show species as read-only text
                    HStack {
                        Text("Species")
                            .frame(width: 80, alignment: .leading)
                        Text(species)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                } else {
                    // In create mode, show species picker
                    Picker("Species", selection: $species) {
                        ForEach(speciesOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }

                HStack {
                    Text("Breed")
                        .frame(width: 80, alignment: .leading)
                    TextField("Breed (optional)", text: $breed)
                }

                HStack {
                    Text("Colour")
                        .frame(width: 80, alignment: .leading)
                    TextField("Colour (optional)", text: $color)
                }

                // Age display (merged from Physical Details)
                if mode.isEdit, case .edit(let pet) = mode, let age = pet.age {
                    HStack {
                        Text("Age")
                            .frame(width: 80, alignment: .leading)
                        Text(age)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                } else if !mode.isEdit {
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                }

                // Microchip Number (merged from Physical Details)
                HStack {
                    Text("Microchip")
                        .frame(width: 80, alignment: .leading)
                    TextField("Microchip Number (optional)", text: $microchipNumber)
                        .keyboardType(.numberPad)
                }
            }

            Section("Physical Details") {
                HStack {
                    Text("Weight")
                        .frame(width: 80, alignment: .leading)
                    TextField("Weight in kg (optional)", text: $weight)
                        .keyboardType(.decimalPad)
                }

                Picker("Sex", selection: $sex) {
                    ForEach(sexOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                Toggle("Neutered/Spayed", isOn: $isNeutered)
            }

            Section("Health Information") {
                TextEditor(text: $medicalInfo)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if medicalInfo.isEmpty {
                            Text("Medical notes (conditions, surgeries, etc.)")
                                .foregroundColor(.mutedText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }

                TextEditor(text: $allergies)
                    .frame(minHeight: 60)
                    .overlay(alignment: .topLeading) {
                        if allergies.isEmpty {
                            Text("Allergies (food, medication, etc.)")
                                .foregroundColor(.mutedText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }

                TextEditor(text: $medications)
                    .frame(minHeight: 60)
                    .overlay(alignment: .topLeading) {
                        if medications.isEmpty {
                            Text("Current medications")
                                .foregroundColor(.mutedText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            }

            Section("Additional Information") {
                TextEditor(text: $uniqueFeatures)
                    .frame(minHeight: 60)
                    .overlay(alignment: .topLeading) {
                        if uniqueFeatures.isEmpty {
                            Text("Unique features (markings, scars, etc.)")
                                .foregroundColor(.mutedText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }

                TextEditor(text: $behaviorNotes)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if behaviorNotes.isEmpty {
                            Text("Behavior notes (temperament, training, etc.)")
                                .foregroundColor(.mutedText)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }
            }

            // Action buttons section
            Section {
                Button(action: { savePet() }) {
                    HStack {
                        Spacer()
                        Text("Save Changes")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(name.isEmpty || viewModel.isLoading)

                Button(action: { dismiss() }) {
                    HStack {
                        Spacer()
                        Text("Cancel")
                        Spacer()
                    }
                }
                .foregroundColor(.secondary)
            }

            // Delete Pet button - only show in edit mode
            if case .edit = mode {
                Section {
                    Button(action: { showingDeleteAlert = true }) {
                        HStack {
                            Spacer()
                            Text("Delete Pet")
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
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.brandOrange)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    savePet()
                }
                .foregroundColor(.brandOrange)
                .disabled(name.isEmpty || viewModel.isLoading)
            }
        }
        .alert("Delete Pet", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePet()
            }
        } message: {
            Text("Are you sure you want to delete this pet? This action cannot be undone.")
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
        allergies = pet.allergies ?? ""
        medications = pet.medications ?? ""
        uniqueFeatures = pet.uniqueFeatures ?? ""

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
            print("Failed to load image: \(error.localizedDescription)")
        }
    }

    private func savePet() {
        Task {
            do {
                print("🔄 Starting save pet operation...")

                switch mode {
                case .create:
                    print("📝 Creating new pet")

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
                        sex: sex == "Unknown" ? nil : sex,
                        isNeutered: isNeutered
                    )

                    print("Creating pet with data: name=\(name), species=\(species), breed=\(breed)")
                    let newPet = try await viewModel.createPet(request)
                    print("✅ Pet created successfully with ID: \(newPet.id)")

                    // Upload photo if selected
                    if let image = selectedImage {
                        print("📸 Uploading photo...")
                        _ = try await viewModel.uploadPhoto(for: newPet.id, image: image)
                        print("✅ Photo uploaded successfully")
                    }

                    appState.showSuccess("Pet added successfully!")

                case .edit(let pet):
                    print("✏️ Updating pet with ID: \(pet.id)")

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
                        sex: sex == "Unknown" ? nil : sex,
                        isNeutered: isNeutered,
                        isMissing: nil  // Not in form - use mark lost/found feature
                    )

                    print("Updating pet with: name=\(name), breed=\(breed), color=\(color)")
                    let updatedPet = try await viewModel.updatePet(id: pet.id, updates: request)
                    print("✅ Pet updated successfully")
                    print("📥 Received pet data: \(updatedPet.name), species: \(updatedPet.species)")

                    // Upload photo only if user selected a new one
                    if photoWasChanged, let image = selectedImage {
                        do {
                            print("📸 Uploading new photo...")
                            _ = try await viewModel.uploadPhoto(for: pet.id, image: image)
                            print("✅ Photo uploaded successfully")
                            appState.showSuccess("Pet and photo updated successfully!")
                        } catch {
                            print("❌ Photo upload failed: \(error)")
                            // Pet was saved successfully, just warn about photo
                            if let apiError = error as? APIError {
                                print("API Error details: \(apiError)")
                            }
                            appState.showSuccess("Pet updated! Photo upload failed - please try again later.")
                        }
                    } else {
                        appState.showSuccess("Pet updated successfully!")
                    }
                }

                print("✅ Save operation completed successfully")
                dismiss()
            } catch {
                print("❌ Save operation failed: \(error)")
                if let apiError = error as? APIError {
                    print("API Error type: \(apiError.errorDescription ?? "Unknown")")
                }
                appState.showError(error.localizedDescription)
            }
        }
    }

    private func deletePet() {
        guard case .edit(let pet) = mode else { return }

        Task {
            do {
                try await viewModel.deletePet(id: pet.id)
                appState.showSuccess("\(pet.name) has been deleted.")
                dismiss()
            } catch {
                appState.showError("Failed to delete \(pet.name): \(error.localizedDescription)")
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
