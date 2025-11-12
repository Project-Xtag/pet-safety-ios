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
    @State private var weight = ""
    @State private var microchipNumber = ""
    @State private var medicalInfo = ""
    @State private var behaviorNotes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    let speciesOptions = ["Dog", "Cat", "Bird", "Rabbit", "Other"]

    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Pet Name", text: $name)

                Picker("Species", selection: $species) {
                    ForEach(speciesOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                TextField("Breed (optional)", text: $breed)

                TextField("Color (optional)", text: $color)
            }

            Section("Physical Details") {
                DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)

                TextField("Weight (kg)", text: $weight)
                    .keyboardType(.decimalPad)

                TextField("Microchip Number (optional)", text: $microchipNumber)
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
                            Text("Select Photo")
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
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    savePet()
                }
                .disabled(name.isEmpty || viewModel.isLoading)
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
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
        species = pet.species
        breed = pet.breed ?? ""
        color = pet.color ?? ""
        if let dobString = pet.dateOfBirth,
           let dob = ISO8601DateFormatter().date(from: dobString) {
            dateOfBirth = dob
        }
        if let w = pet.weight {
            weight = "\(w)"
        }
        microchipNumber = pet.microchipNumber ?? ""
        medicalInfo = pet.medicalInfo ?? ""
        behaviorNotes = pet.behaviorNotes ?? ""
    }

    private func savePet() {
        Task {
            do {
                let weightValue = Double(weight)
                let formatter = ISO8601DateFormatter()
                let dobString = formatter.string(from: dateOfBirth)

                switch mode {
                case .create:
                    let request = CreatePetRequest(
                        name: name,
                        species: species,
                        breed: breed.isEmpty ? nil : breed,
                        color: color.isEmpty ? nil : color,
                        dateOfBirth: dobString,
                        weight: weightValue,
                        microchipNumber: microchipNumber.isEmpty ? nil : microchipNumber,
                        medicalInfo: medicalInfo.isEmpty ? nil : medicalInfo,
                        behaviorNotes: behaviorNotes.isEmpty ? nil : behaviorNotes
                    )
                    let newPet = try await viewModel.createPet(request)

                    // Upload photo if selected
                    if let image = selectedImage {
                        _ = try await viewModel.uploadPhoto(for: newPet.id, image: image)
                    }

                    appState.showSuccess("Pet added successfully!")

                case .edit(let pet):
                    let request = UpdatePetRequest(
                        name: name,
                        species: species,
                        breed: breed.isEmpty ? nil : breed,
                        color: color.isEmpty ? nil : color,
                        dateOfBirth: dobString,
                        weight: weightValue,
                        microchipNumber: microchipNumber.isEmpty ? nil : microchipNumber,
                        medicalInfo: medicalInfo.isEmpty ? nil : medicalInfo,
                        behaviorNotes: behaviorNotes.isEmpty ? nil : behaviorNotes
                    )
                    _ = try await viewModel.updatePet(id: pet.id, updates: request)

                    // Upload photo if selected
                    if let image = selectedImage {
                        _ = try await viewModel.uploadPhoto(for: pet.id, image: image)
                    }

                    appState.showSuccess("Pet updated successfully!")
                }

                dismiss()
            } catch {
                appState.showError(error.localizedDescription)
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
