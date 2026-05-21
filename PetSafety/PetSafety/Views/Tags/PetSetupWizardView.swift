import SwiftUI
import PhotosUI
import UIKit

/// Guided, one-step-per-screen pet-onboarding wizard. Runs after a user
/// scans a new SENRA tag from their order: pick the pet name registered
/// at order time, walk through the pet's details, then in one commit
/// create the pet, upload the photo and activate the scanned tag.
/// Multi-tag orders loop back to scan the next tag.
struct PetSetupWizardView: View {
    let tagCode: String
    let onDismiss: () -> Void

    @StateObject private var petsViewModel = PetsViewModel()
    @StateObject private var scannerVM = QRScannerViewModel()
    @EnvironmentObject var appState: AppState

    @State private var step = 1
    @State private var loadingItems = true
    @State private var committing = false
    @State private var committedPetId: String?
    @State private var orderItems: [UnactivatedOrderItem] = []
    @State private var errorMessage: String?

    // Pet draft — held in-memory, committed in one go after step 10.
    @State private var petName = ""
    @State private var species = ""   // "dog" | "cat"
    @State private var breed = ""
    @State private var sex = ""       // "male" | "female" | "unknown"
    @State private var ageYears = ""
    @State private var ageMonths = ""
    @State private var color = ""
    @State private var allergies = ""
    @State private var medications = ""
    @State private var uniqueFeatures = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: UIImage?

    private let totalSteps = 10
    private let brand = Color("BrandColor")

    private var remainingAfterThis: Int { max(0, orderItems.count - 1) }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if loadingItems {
                    Spacer()
                    ProgressView().scaleEffect(1.4)
                    Spacer()
                } else {
                    if step <= totalSteps {
                        progressBar
                    }
                    ScrollView {
                        VStack(spacing: 0) {
                            WizardStepGraphic(symbol: stepSymbol)
                                .padding(.top, 28)
                            Text(stepTitle)
                                .font(.appFont(.title2))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.top, 18)
                                .padding(.horizontal, 24)
                            if !stepSubtitle.isEmpty {
                                Text(stepSubtitle)
                                    .font(.appFont(.subheadline))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 6)
                                    .padding(.horizontal, 28)
                            }
                            stepContent
                                .padding(.horizontal, 24)
                                .padding(.top, 22)
                        }
                        .padding(.bottom, 24)
                    }
                    if step <= totalSteps {
                        footer
                    }
                }
            }
            .navigationTitle(Text("Set up your tag"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "cancel")) { onDismiss() }
                }
            }
            .task {
                do {
                    orderItems = try await APIService.shared.getUnactivatedTagsForQRCode(tagCode)
                } catch {
                    orderItems = []
                }
                let names = orderItems.compactMap { $0.petName }
                if names.count == 1 { petName = names[0] }
                loadingItems = false
            }
            .task(id: photoItem) {
                guard let item = photoItem else { return }
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    photoImage = img
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Step \(step) of \(totalSteps)")
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
                Spacer()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.systemGray5)).frame(height: 6)
                    Capsule().fill(brand)
                        .frame(width: geo.size.width * CGFloat(step) / CGFloat(totalSteps), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            if let error = errorMessage {
                Text(error)
                    .font(.appFont(.caption))
                    .foregroundColor(.errorColor)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 12) {
                Button {
                    goBack()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.appFont(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .disabled(committing)

                Button {
                    goNext()
                } label: {
                    HStack(spacing: 6) {
                        if committing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(step == totalSteps ? "Finish" : "Next")
                            .fontWeight(.bold)
                    }
                }
                .buttonStyle(TagPrimaryButtonStyle())
                .disabled(!canProceed || committing)
                .opacity(canProceed ? 1.0 : 0.6)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Navigation

    private var canProceed: Bool {
        switch step {
        case 1: return !petName.trimmingCharacters(in: .whitespaces).isEmpty
        case 3: return !species.isEmpty
        default: return true
        }
    }

    private func goNext() {
        errorMessage = nil
        if step == totalSteps {
            Task { await commit() }
            return
        }
        withAnimation { step += 1 }
    }

    private func goBack() {
        errorMessage = nil
        if step == 1 {
            onDismiss()
            return
        }
        withAnimation { step -= 1 }
    }

    // MARK: - Commit

    private func commit() async {
        committing = true
        defer { committing = false }
        do {
            var petId = committedPetId
            if petId == nil {
                let request = CreatePetRequest(
                    name: petName.trimmingCharacters(in: .whitespaces),
                    species: species,
                    breed: nilIfEmpty(breed),
                    color: nilIfEmpty(color),
                    weight: nil,
                    microchipNumber: nil,
                    medicalNotes: nil,
                    allergies: nilIfEmpty(allergies),
                    medications: nilIfEmpty(medications),
                    notes: nil,
                    uniqueFeatures: nilIfEmpty(uniqueFeatures),
                    sex: (sex.isEmpty || sex == "unknown") ? nil : sex,
                    isNeutered: nil,
                    dateOfBirth: computeDateOfBirth(),
                    dobIsApproximate: computeDateOfBirth() != nil ? true : nil
                )
                let newPet = try await petsViewModel.createPet(request)
                petId = newPet.id
                committedPetId = newPet.id
                if let img = photoImage {
                    _ = try? await petsViewModel.uploadPhoto(for: newPet.id, image: img)
                }
            }
            guard let resolvedId = petId else { return }
            try await scannerVM.activateTag(code: tagCode, petId: resolvedId)
            NotificationCenter.default.post(name: .tagActivated, object: nil)
            withAnimation { step = remainingAfterThis > 0 ? 11 : 12 }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func computeDateOfBirth() -> String? {
        let years = Int(ageYears) ?? 0
        let months = Int(ageMonths) ?? 0
        guard years > 0 || months > 0 else { return nil }
        guard let date = Calendar.current.date(
            byAdding: DateComponents(year: -years, month: -months), to: Date()
        ) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    private func nilIfEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Step metadata

    private var displayName: String { petName.isEmpty ? "your pet" : petName }

    private var stepSymbol: String {
        switch step {
        case 1: return "tag.fill"
        case 2: return "sparkles"
        case 3: return "pawprint.fill"
        case 4: return "magnifyingglass"
        case 5: return "heart.fill"
        case 6: return "calendar"
        case 7: return "paintpalette.fill"
        case 8: return "camera.fill"
        case 9: return "pills.fill"
        case 10: return "star.fill"
        case 11: return "qrcode"
        default: return "party.popper.fill"
        }
    }

    private var stepTitle: String {
        switch step {
        case 1: return "Which pet is this tag for?"
        case 2: return "Great to have \(displayName) on board!"
        case 3: return "Dog or cat?"
        case 4: return "What breed is \(displayName)?"
        case 5: return "Boy or girl?"
        case 6: return "How old is \(displayName)?"
        case 7: return "What colour is \(displayName)?"
        case 8: return "Add a photo"
        case 9: return "Allergies or medications?"
        case 10: return "Any unique features?"
        case 11: return "\(displayName)'s tag is ready!"
        default: return "Congratulations!"
        }
    }

    private var stepSubtitle: String {
        switch step {
        case 1: return "Pick which pet you're setting this tag up for."
        case 2: return "Set up your SENRA tag in a few quick steps. Let's go!"
        case 4: return "If it's a mix or you're not sure, leave it blank."
        case 6: return "A rough age is fine."
        case 8: return "Optional — you can skip this and add one later."
        case 9: return "Important health information for whoever finds your pet."
        case 10: return "Anything that helps someone recognise your pet."
        case 11: return remainingAfterThis == 1
            ? "There's 1 more tag left to set up."
            : "There are \(remainingAfterThis) more tags left to set up."
        case 12: return "\(displayName) is now protected by the SENRA community."
        default: return ""
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 1: nameStep
        case 2: introStep
        case 3: speciesStep
        case 4: textFieldStep(text: $breed, placeholder: "e.g. Hungarian Vizsla, mixed")
        case 5: sexStep
        case 6: ageStep
        case 7: colorStep
        case 8: photoStep
        case 9: healthStep
        case 10: featuresStep
        case 11: scanNextStep
        default: congratulationsStep
        }
    }

    private var nameStep: some View {
        VStack(spacing: 10) {
            if orderItems.isEmpty {
                Text("There's no tag to set up for this code — it may already be activated, or it belongs to a different account.")
                    .font(.appFont(.subheadline))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                ForEach(orderItems) { item in
                    let name = item.petName ?? "Pet"
                    let selected = !(item.petName ?? "").isEmpty && petName == item.petName
                    Button {
                        petName = item.petName ?? ""
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(selected ? brand : Color(UIColor.systemGray4), lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                if selected {
                                    Circle().fill(brand).frame(width: 14, height: 14)
                                }
                            }
                            Image(systemName: "pawprint.fill").foregroundColor(brand)
                            Text(name).font(.appFont(.headline))
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selected ? brand.opacity(0.08) : Color(UIColor.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selected ? brand : Color(UIColor.systemGray4), lineWidth: selected ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var introStep: some View {
        Text("A few quick questions about your pet. You can go back any time — we'll activate the tag at the end.")
            .font(.appFont(.subheadline))
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.peachBackground)
            .cornerRadius(14)
    }

    private var speciesStep: some View {
        HStack(spacing: 12) {
            WizardChoiceCard(symbol: "dog.fill", label: "Dog", selected: species == "dog") { species = "dog" }
            WizardChoiceCard(symbol: "cat.fill", label: "Cat", selected: species == "cat") { species = "cat" }
        }
    }

    private var sexStep: some View {
        HStack(spacing: 10) {
            WizardChoiceCard(symbol: nil, label: "Boy", selected: sex == "male") { sex = "male" }
            WizardChoiceCard(symbol: nil, label: "Girl", selected: sex == "female") { sex = "female" }
            WizardChoiceCard(symbol: nil, label: "Not sure", selected: sex == "unknown") { sex = "unknown" }
        }
    }

    private var ageStep: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Years").font(.appFont(.caption)).foregroundColor(.secondary)
                TextField("0", text: $ageYears)
                    .keyboardType(.numberPad)
                    .textFieldStyle(BrandTextFieldStyle())
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Months").font(.appFont(.caption)).foregroundColor(.secondary)
                TextField("0", text: $ageMonths)
                    .keyboardType(.numberPad)
                    .textFieldStyle(BrandTextFieldStyle())
            }
        }
    }

    private var colorStep: some View {
        VStack(spacing: 12) {
            TextField("e.g. black and white", text: $color)
                .textFieldStyle(BrandTextFieldStyle())
            let chips = ["Black", "White", "Brown", "Grey", "Golden", "Tabby"]
            FlowChips(options: chips, selected: color) { color = $0 }
        }
    }

    private var photoStep: some View {
        VStack(spacing: 14) {
            if let image = photoImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Button {
                    photoImage = nil
                    photoItem = nil
                } label: {
                    Label("Remove photo", systemImage: "trash")
                        .font(.appFont(.subheadline))
                        .foregroundColor(.errorColor)
                }
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.appFont(size: 30))
                            .foregroundColor(.secondary)
                        Text("Choose a photo")
                            .font(.appFont(.headline))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundColor(Color(UIColor.systemGray3))
                    )
                }
            }
        }
    }

    private var healthStep: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Allergies").font(.appFont(.caption)).foregroundColor(.secondary)
                TextField("e.g. chicken, certain medication", text: $allergies)
                    .textFieldStyle(BrandTextFieldStyle())
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Medications").font(.appFont(.caption)).foregroundColor(.secondary)
                TextField("Any regular medication", text: $medications)
                    .textFieldStyle(BrandTextFieldStyle())
            }
        }
    }

    private var featuresStep: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Unique features").font(.appFont(.caption)).foregroundColor(.secondary)
            TextField("e.g. white chest patch, shy with strangers", text: $uniqueFeatures, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .textFieldStyle(BrandTextFieldStyle())
        }
    }

    private func textFieldStep(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(BrandTextFieldStyle())
    }

    private var scanNextStep: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Next steps").font(.appFont(.headline))
                Label("Point your camera at the QR code on the next tag", systemImage: "1.circle.fill")
                Label("Tap the link when it appears on screen", systemImage: "2.circle.fill")
                Label("Follow the steps to set up your next pet", systemImage: "3.circle.fill")
            }
            .font(.appFont(.subheadline))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.peachBackground)
            .cornerRadius(14)

            Button {
                onDismiss()
            } label: {
                Text("Done for now").fontWeight(.bold)
            }
            .buttonStyle(TagPrimaryButtonStyle())
        }
    }

    private var congratulationsStep: some View {
        VStack(spacing: 12) {
            Text("Set up your contact details and privacy settings so the right information shows when someone finds your pet.")
                .font(.appFont(.subheadline))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)
            Button {
                onDismiss()
            } label: {
                Text("Go to my pets").fontWeight(.bold)
            }
            .buttonStyle(TagPrimaryButtonStyle())
        }
    }
}

// MARK: - Step graphic

private struct WizardStepGraphic: View {
    let symbol: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color("BrandColor"), Color("BrandColor").opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 104, height: 104)
                .shadow(color: Color("BrandColor").opacity(0.4), radius: 16, x: 0, y: 10)
            Image(systemName: symbol)
                .font(.appFont(size: 44))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Choice card

private struct WizardChoiceCard: View {
    let symbol: String?
    let label: String
    let selected: Bool
    let action: () -> Void

    private let brand = Color("BrandColor")

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let symbol = symbol {
                    Image(systemName: symbol)
                        .font(.appFont(size: 26))
                        .foregroundColor(selected ? brand : .secondary)
                }
                Text(label)
                    .font(.appFont(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selected ? brand.opacity(0.08) : Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? brand : Color(UIColor.systemGray4), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Color chips

private struct FlowChips: View {
    let options: [String]
    let selected: String
    let onPick: (String) -> Void

    private let brand = Color("BrandColor")
    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    onPick(option)
                } label: {
                    Text(option)
                        .font(.appFont(size: 13, weight: .semibold))
                        .foregroundColor(selected == option ? brand : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(selected == option ? brand.opacity(0.1) : Color(UIColor.systemGray6))
                        )
                        .overlay(
                            Capsule().stroke(selected == option ? brand : Color.clear, lineWidth: 1.5)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
