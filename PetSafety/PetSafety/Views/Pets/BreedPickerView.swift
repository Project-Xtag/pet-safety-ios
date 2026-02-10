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
            .navigationTitle("breed_select_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brandOrange)
                }

                if showManualEntry {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("done") {
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
                    TextField(String(localized: "breed_search_placeholder"), text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }

            // Breed list
            Section {
                if filteredBreeds.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Text("breed_no_results")
                            .foregroundColor(.secondary)

                        Button {
                            manualBreed = searchText
                            showManualEntry = true
                        } label: {
                            Text("breed_use_custom \(searchText)")
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
                        Text("breed_manual_entry")
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
                            Text("breed_clear_selection")
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
                TextField(String(localized: "breed_enter_name"), text: $manualBreed)
                    .textInputAutocapitalization(.words)
            } header: {
                Text("breed_custom")
            } footer: {
                Text("breed_custom_footer")
            }

            Section {
                Button {
                    showManualEntry = false
                } label: {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("breed_back_to_list")
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
                    Text(breed.isEmpty ? String(localized: "breed_select_optional") : breed)
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
            TextField(String(localized: "breed_optional"), text: $breed)
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
