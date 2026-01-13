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

    let speciesOptions = ["Dog", "Cat", "Bird", "Rabbit", "Other"]

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
                }
            }

            Section("Health & Behavior") {
                TextEditor(text: $medicalInfo)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if medicalInfo.isEmpty {
                            Text("Medical information (allergies, conditions, etc.)")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                    }

                TextEditor(text: $behaviorNotes)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if behaviorNotes.isEmpty {
                            Text("Behavior notes (temperament, training, etc.)")
                                .foregroundColor(.secondary)
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
            if case .edit(let pet) = mode {
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
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    savePet()
                }
                .foregroundColor(.white)
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

                    let request = CreatePetRequest(
                        name: name,
                        species: species,
                        breed: breed.isEmpty ? nil : breed,
                        color: color.isEmpty ? nil : color,
                        age: nil, // Age will be calculated from date of birth by backend
                        weight: nil,
                        microchipNumber: microchipNumber.isEmpty ? nil : microchipNumber,
                        medicalNotes: medicalInfo.isEmpty ? nil : medicalInfo,
                        allergies: nil,
                        medications: nil,
                        notes: behaviorNotes.isEmpty ? nil : behaviorNotes,
                        uniqueFeatures: nil,
                        sex: nil,
                        isNeutered: nil
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

                    // Only send fields that are actually editable in the form
                    // Keep existing values for fields not in the form (weight, species, etc.)
                    let request = UpdatePetRequest(
                        name: name,
                        species: nil,  // Species is read-only in edit mode, don't update it
                        breed: breed.isEmpty ? nil : breed,
                        color: color.isEmpty ? nil : color,
                        age: nil,  // Age is derived from date of birth, don't send it
                        weight: nil,  // Weight field was removed from UI, preserve existing value
                        microchipNumber: microchipNumber.isEmpty ? nil : microchipNumber,
                        medicalNotes: medicalInfo.isEmpty ? nil : medicalInfo,
                        allergies: nil,  // Not in form
                        medications: nil,  // Not in form
                        notes: behaviorNotes.isEmpty ? nil : behaviorNotes,
                        uniqueFeatures: nil,  // Not in form
                        sex: nil,  // Not in form
                        isNeutered: nil,  // Not in form
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
                appState.showError("Failed to delete pet: \(error.localizedDescription)")
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
