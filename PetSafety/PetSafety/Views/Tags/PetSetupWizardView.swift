import SwiftUI
import PhotosUI
import UIKit

/// Guided, one-step-per-screen pet-onboarding wizard. Runs after a user
/// scans a new SENRA tag from their order. The pet was auto-registered
/// (name only) at order time; the wizard fills in its details, uploads
/// the photo and activates the scanned tag for it.
/// Multi-tag orders loop back to scan the next tag.
///
/// Copy is Hungarian (the canonical locale); other locales follow via
/// the standard Localizable.strings extraction.
struct PetSetupWizardView: View {
    let tagCode: String
    let onDismiss: () -> Void

    @StateObject private var petsViewModel = PetsViewModel()
    @StateObject private var scannerVM = QRScannerViewModel()
    @StateObject private var subscriptionVM = SubscriptionViewModel()
    @EnvironmentObject var appState: AppState

    /// Optional navigation callbacks for the success screen. When the
    /// wizard is hosted from a sheet that can't navigate (e.g. a deep
    /// link sheet on top of the splash), the caller can leave these nil
    /// and the buttons collapse to the "Go to my pets" CTA only —
    /// matching the web wizard's behaviour when the route stack is
    /// shallow.
    var onSetContactDetails: (() -> Void)?
    var onSetPrivacySettings: (() -> Void)?
    var onScanNextTag: (() -> Void)?

    @State private var step = 1
    @State private var loadingItems = true
    @State private var committing = false
    @State private var committedPetId: String?
    @State private var selectedPetId: String?
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
                        identityLockBanner
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
            .navigationTitle(Text("Biléta beállítása"))
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
                // Single-pet order — pre-select and skip step 1 entirely
                // so the user lands on the intro screen, matching the web
                // wizard's stepOffset=1 behaviour for single-pet orders.
                if orderItems.count == 1 {
                    selectedPetId = orderItems[0].petId
                    petName = orderItems[0].petName
                    step = 2
                }
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

    // MARK: - Identity-lock notice (web parity)

    /// Standing notice above the step content that warns the user the
    /// pet's name / species / breed get locked once registration completes.
    /// Mirrors the orange banner the web wizard shows on every step 1-10.
    private var identityLockBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11, weight: .bold))
            Text("A kedvenc neve, faja és fajtája a regisztráció után már nem módosítható — válaszd ki őket gondosan.")
                .font(.appFont(size: 11, weight: .semibold))
                .multilineTextAlignment(.leading)
        }
        .foregroundColor(Color(red: 0.65, green: 0.32, blue: 0.06))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(brand.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(step). lépés / \(totalSteps)")
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
                        Text("Vissza")
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
                        Text(step == totalSteps ? "Befejezés" : "Tovább")
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
        case 1: return selectedPetId != nil
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
        guard let petId = selectedPetId else { return }
        committing = true
        defer { committing = false }
        do {
            // The pet already exists (auto-registered at order time) — fill
            // in its details, then activate the scanned tag for it.
            if committedPetId != petId {
                let request = UpdatePetRequest(
                    name: petName.trimmingCharacters(in: .whitespaces),
                    species: species.isEmpty ? nil : species,
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
                    isMissing: nil,
                    dateOfBirth: computeDateOfBirth(),
                    dobIsApproximate: computeDateOfBirth() != nil ? true : nil
                )
                _ = try await petsViewModel.updatePet(id: petId, updates: request)
                committedPetId = petId
                if let img = photoImage {
                    _ = try? await petsViewModel.uploadPhoto(for: petId, image: img)
                }
            }
            try await scannerVM.activateTag(code: tagCode, petId: petId)
            NotificationCenter.default.post(name: .tagActivated, object: nil)
            // Pull subscription state fresh so screens that gate on
            // eligible_for_paid_plans (ManageSubscription, ChoosePlan)
            // see "tag active" immediately, not after the SSE event
            // round-trips. Web parity: redesign7's PetSetup calls
            // refreshSubscription() at the same point.
            Task { await subscriptionVM.loadAll() }
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

    private var displayName: String { petName.isEmpty ? "a kedvenced" : petName }

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
        case 1: return "Melyik kedvenced ez?"
        case 2: return "Nagyszerű, hogy \(displayName) csatlakozott!"
        case 3: return "Kutya vagy macska?"
        case 4: return "Milyen fajta \(displayName)?"
        case 5: return "Fiú vagy lány?"
        case 6: return "Hány éves \(displayName)?"
        case 7: return "Milyen színű?"
        case 8: return "Tölts fel egy fotót"
        case 9: return "Allergia vagy gyógyszer?"
        case 10: return "Egyedi ismertetőjelek"
        case 11: return "\(displayName) bilétája kész!"
        default: return "Gratulálunk!"
        }
    }

    private var stepSubtitle: String {
        switch step {
        case 1: return "Válaszd ki, melyik kedvenced bilétáját állítjuk be most."
        case 2: return "Pár pillanat, és beállítjuk a SENRA bilétáját. Kezdjük is!"
        case 4: return "Ha keverék vagy nem tudod, hagyd üresen."
        case 6: return "Elég egy nagyjábóli érték is."
        case 8: return "Nem kötelező — ki is hagyhatod, és később pótolhatod."
        case 9: return "Fontos egészségügyi tudnivalók a megtaláló számára."
        case 10: return "Bármi, ami segít felismerni a kedvenced."
        case 11: return remainingAfterThis == 1
            ? "Még 1 biléta van hátra a rendelésből."
            : "Még \(remainingAfterThis) biléta van hátra a rendelésből."
        case 12: return "\(displayName) mostantól védve van a SENRA közösségével."
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
        case 4: textFieldStep(text: $breed, placeholder: "Pl. magyar vizsla, keverék")
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
                Text("Ehhez a kódhoz nincs beállítható biléta — lehet, hogy már aktiváltad, vagy nem ehhez a fiókhoz tartozik.")
                    .font(.appFont(.subheadline))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                ForEach(orderItems) { item in
                    let name = item.petName.isEmpty ? "Kedvenc" : item.petName
                    let selected = selectedPetId == item.petId
                    Button {
                        selectedPetId = item.petId
                        petName = item.petName
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
        Text("Néhány gyors kérdés a kedvencedről. Bármikor visszaléphetsz — a végén aktiváljuk a bilétát.")
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
            WizardChoiceCard(symbol: "dog.fill", label: "Kutya", selected: species == "dog") { species = "dog" }
            WizardChoiceCard(symbol: "cat.fill", label: "Macska", selected: species == "cat") { species = "cat" }
        }
    }

    private var sexStep: some View {
        HStack(spacing: 10) {
            WizardChoiceCard(symbol: nil, label: "Fiú", selected: sex == "male") { sex = "male" }
            WizardChoiceCard(symbol: nil, label: "Lány", selected: sex == "female") { sex = "female" }
            WizardChoiceCard(symbol: nil, label: "Nem tudom", selected: sex == "unknown") { sex = "unknown" }
        }
    }

    private var ageStep: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Év").font(.appFont(.caption)).foregroundColor(.secondary)
                TextField("0", text: $ageYears)
                    .keyboardType(.numberPad)
                    .textFieldStyle(BrandTextFieldStyle())
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Hónap").font(.appFont(.caption)).foregroundColor(.secondary)
                TextField("0", text: $ageMonths)
                    .keyboardType(.numberPad)
                    .textFieldStyle(BrandTextFieldStyle())
            }
        }
    }

    private var colorStep: some View {
        VStack(spacing: 12) {
            TextField("Pl. fekete-fehér", text: $color)
                .textFieldStyle(BrandTextFieldStyle())
            let chips = ["Fekete", "Fehér", "Barna", "Szürke", "Arany", "Cirmos"]
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
                    Label("Fotó eltávolítása", systemImage: "trash")
                        .font(.appFont(.subheadline))
                        .foregroundColor(.errorColor)
                }
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.appFont(size: 30))
                            .foregroundColor(.secondary)
                        Text("Fotó kiválasztása")
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
                Text("Allergiák").font(.appFont(.caption)).foregroundColor(.secondary)
                TextField("Pl. csirke, bizonyos gyógyszerek", text: $allergies)
                    .textFieldStyle(BrandTextFieldStyle())
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Gyógyszerek").font(.appFont(.caption)).foregroundColor(.secondary)
                TextField("Rendszeresen szedett gyógyszerek", text: $medications)
                    .textFieldStyle(BrandTextFieldStyle())
            }
        }
    }

    private var featuresStep: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Egyedi ismertetőjelek").font(.appFont(.caption)).foregroundColor(.secondary)
            TextField("Pl. fehér folt a mellkason, félénk idegenekkel", text: $uniqueFeatures, axis: .vertical)
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
                Text("Következő lépések").font(.appFont(.headline))
                Label("Irányítsd a kamerát a következő biléta QR-kódjára", systemImage: "1.circle.fill")
                Label("Koppints a linkre, amikor megjelenik a képernyőn", systemImage: "2.circle.fill")
                Label("Kövesd a lépéseket a következő kedvenc beállításához", systemImage: "3.circle.fill")
            }
            .font(.appFont(.subheadline))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.peachBackground)
            .cornerRadius(14)

            // Primary CTA — open the scanner directly when the host
            // provided a callback (typically pops the wizard sheet and
            // switches to the Scan tab). Falls back to closing so the
            // user can navigate manually.
            Button {
                if let onScanNextTag {
                    onScanNextTag()
                } else {
                    onDismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Következő biléta beolvasása").fontWeight(.bold)
                }
            }
            .buttonStyle(TagPrimaryButtonStyle())

            Button { onDismiss() } label: {
                Text("Később folytatom")
                    .font(.appFont(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
    }

    private var congratulationsStep: some View {
        VStack(spacing: 12) {
            Text("\(displayName) mostantól védve van a SENRA közösségével. Állítsd be az elérhetőségeidet és az adatvédelmi beállításokat, hogy a megfelelő információk jelenjenek meg, ha valaki megtalálja.")
                .font(.appFont(.subheadline))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)

            // Primary: contact details. The handler is optional so a
            // sheet-hosted wizard without a destination can still close
            // cleanly; when set it typically dismisses the sheet and
            // pushes the Account → Contacts screen.
            Button {
                if let onSetContactDetails {
                    onSetContactDetails()
                } else {
                    onDismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Elérhetőségek beállítása").fontWeight(.bold)
                }
            }
            .buttonStyle(TagPrimaryButtonStyle())

            // Secondary: privacy settings.
            Button {
                if let onSetPrivacySettings {
                    onSetPrivacySettings()
                } else {
                    onDismiss()
                }
            } label: {
                HStack {
                    Image(systemName: "lock.shield")
                    Text("Adatvédelmi beállítások").fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(brand)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(brand, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)

            // Tertiary: just go to My Pets.
            Button { onDismiss() } label: {
                Text("Ugrás a kedvenceimhez")
                    .font(.appFont(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
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

// MARK: - Primary button style

private struct TagPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color("BrandColor").opacity(0.8) : Color("BrandColor"))
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
