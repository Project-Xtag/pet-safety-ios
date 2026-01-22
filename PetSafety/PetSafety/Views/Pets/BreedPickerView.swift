import SwiftUI

/// A searchable breed picker for Dog and Cat species
struct BreedPickerView: View {
    @Binding var selectedBreed: String
    let species: String
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var showManualEntry = false
    @State private var manualBreed = ""

    private var breeds: [Breed] {
        BreedData.breeds(for: species)
    }

    private var filteredBreeds: [Breed] {
        if searchText.isEmpty {
            return breeds
        }
        return breeds.filter { breed in
            breed.name.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if showManualEntry {
                    manualEntryView
                } else {
                    breedListView
                }
            }
            .navigationTitle("Select Breed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brandOrange)
                }

                if showManualEntry {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            selectedBreed = manualBreed
                            dismiss()
                        }
                        .foregroundColor(.brandOrange)
                        .disabled(manualBreed.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private var breedListView: some View {
        List {
            // Search field
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search breeds...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }

            // Breed list
            Section {
                if filteredBreeds.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Text("No breeds found")
                            .foregroundColor(.secondary)

                        Button {
                            manualBreed = searchText
                            showManualEntry = true
                        } label: {
                            Text("Use \"\(searchText)\" as breed")
                                .foregroundColor(.brandOrange)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    ForEach(filteredBreeds) { breed in
                        Button {
                            selectedBreed = breed.name
                            dismiss()
                        } label: {
                            HStack {
                                Text(breed.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if breed.name == selectedBreed {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.brandOrange)
                                }
                            }
                        }
                    }
                }
            }

            // Manual entry option
            Section {
                Button {
                    showManualEntry = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Not listed - enter manually")
                    }
                    .foregroundColor(.secondary)
                }
            }

            // Clear selection option (if a breed is selected)
            if !selectedBreed.isEmpty {
                Section {
                    Button {
                        selectedBreed = ""
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Clear selection")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var manualEntryView: some View {
        List {
            Section {
                TextField("Enter breed name", text: $manualBreed)
                    .textInputAutocapitalization(.words)
            } header: {
                Text("Custom Breed")
            } footer: {
                Text("Enter the breed name if it's not in our list")
            }

            Section {
                Button {
                    showManualEntry = false
                } label: {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back to breed list")
                    }
                    .foregroundColor(.brandOrange)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

/// A button that shows the breed picker when tapped
struct BreedPickerButton: View {
    @Binding var breed: String
    let species: String
    let disabled: Bool

    @State private var showingPicker = false

    init(breed: Binding<String>, species: String, disabled: Bool = false) {
        self._breed = breed
        self.species = species
        self.disabled = disabled
    }

    /// Check if species supports breed picker (only Dog and Cat)
    private var supportsBreedPicker: Bool {
        let lowercased = species.lowercased()
        return lowercased == "dog" || lowercased == "cat"
    }

    var body: some View {
        if supportsBreedPicker {
            Button {
                showingPicker = true
            } label: {
                HStack {
                    Text(breed.isEmpty ? "Select breed (optional)" : breed)
                        .foregroundColor(breed.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(disabled)
            .sheet(isPresented: $showingPicker) {
                BreedPickerView(selectedBreed: $breed, species: species)
            }
        } else {
            // For other species, show a plain text field
            TextField("Breed (optional)", text: $breed)
                .disabled(disabled)
        }
    }
}

#Preview("Breed Picker") {
    NavigationView {
        BreedPickerView(selectedBreed: .constant(""), species: "Dog")
    }
}

#Preview("Breed Picker Button") {
    Form {
        Section("Dog") {
            HStack {
                Text("Breed")
                    .frame(width: 80, alignment: .leading)
                BreedPickerButton(breed: .constant(""), species: "Dog")
            }
        }
        Section("Cat") {
            HStack {
                Text("Breed")
                    .frame(width: 80, alignment: .leading)
                BreedPickerButton(breed: .constant("Persian"), species: "Cat")
            }
        }
        Section("Bird (no picker)") {
            HStack {
                Text("Breed")
                    .frame(width: 80, alignment: .leading)
                BreedPickerButton(breed: .constant(""), species: "Bird")
            }
        }
    }
}
