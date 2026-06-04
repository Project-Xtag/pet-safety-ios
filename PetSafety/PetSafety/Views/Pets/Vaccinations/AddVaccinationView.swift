import SwiftUI
import PhotosUI
import UIKit

/// Form for adding a vaccination ("health record") entry. Presented as a sheet
/// (forms = modal tasks; the list/detail are pushes).
///
/// Key behaviors (Stage B locked decisions):
///  • Vaccine picker is opaque-code: shows `display_name`, the selection binds to
///    `code`, and `code` is submitted verbatim — never parsed.
///  • `administered_at` is required (capped at today). `expires_at` is omitted by
///    default so the SERVER derives it from the catalog's validity period — we do
///    NOT preview a client-computed expiry (would risk diverging from the stored
///    value at month-end edges).
///  • The rabies floor is enforced server-side; its localized 400 surfaces via
///    `viewModel.actionError`. No client-side check off the code string.
///  • Certificate is optional and runs through `VaccinationCertificateEncoder`
///    (HEIC→JPEG). An undecodable pick shows "couldn't use that image", never a
///    silent no-op. Create-then-upload is two-step: a cert failure keeps the
///    saved record and shows a recoverable message (the photo is addable later).
///  • Catalog can legitimately be empty (country with no catalog, or no country):
///    show an explicit region state, not a blank picker.
///  • Naming: "record"/"photo" only — never "certificate"/"passport"/"official".
struct AddVaccinationView: View {
    @ObservedObject var viewModel: VaccinationsViewModel
    let species: String

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCode: String?
    @State private var administeredDate = Date()
    @State private var hasExpiry = false
    @State private var expiryDate = Date()
    @State private var batchNumber = ""
    @State private var vetName = ""
    @State private var vetClinic = ""
    @State private var notes = ""
    // "Egyéb" free-text vaccine name — sent only when an is_freetext entry is picked.
    @State private var freeText = ""
    // Expansion state for the custom (capped + scrollable) vaccine dropdown.
    @State private var vaccineListOpen = false

    // Encoded, upload-ready certificate bytes (nil until a valid image is picked).
    @State private var capturedData: Data?
    @State private var capturedMime: String?
    @State private var certPreview: UIImage?
    @State private var photoError = false

    @State private var loadingCatalog = true

    private var sortedCatalog: [VaccineCatalogEntry] {
        viewModel.catalog.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// The picked catalog entry (nil until a vaccine is selected). Lets the form
    /// read the entry's flags WITHOUT parsing the opaque code: isFreetext reveals
    /// the name field, rabiesSpecific drives the first-shot/booster hint.
    private var selectedEntry: VaccineCatalogEntry? {
        guard let code = selectedCode else { return nil }
        return viewModel.catalog.first { $0.code == code }
    }
    private var isFreetext: Bool { selectedEntry?.isFreetext ?? false }
    private var isRabies: Bool { selectedEntry?.rabiesSpecific ?? false }

    /// Freetext picked but no name typed → block Save (the server would 400).
    private var freetextNameMissing: Bool {
        isFreetext && freeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Real vaccines (scroll) vs the "Egyéb" freetext sentinel(s). The freetext
    /// rows are PINNED below the scroll so they're always reachable — sort 999
    /// would otherwise sit below the fold (the web scroll-fold lesson: pin Egyéb,
    /// don't make the user scroll to it).
    private var regularCatalog: [VaccineCatalogEntry] { sortedCatalog.filter { !$0.isFreetext } }
    private var freetextCatalog: [VaccineCatalogEntry] { sortedCatalog.filter { $0.isFreetext } }

    @ViewBuilder
    private func vaccineRow(_ entry: VaccineCatalogEntry) -> some View {
        Button {
            selectedCode = entry.code
            withAnimation(.easeInOut(duration: 0.15)) { vaccineListOpen = false }
        } label: {
            HStack(alignment: .top) {
                Text(entry.displayName)   // \n → two lines for "Egyéb"
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if entry.code == selectedCode {
                    Image(systemName: "checkmark").foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        NavigationView {
            Group {
                if loadingCatalog {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.catalog.isEmpty {
                    noCatalogState
                } else {
                    form
                }
            }
            .navigationTitle("vaccinations_add_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") { submit() }
                        .disabled(selectedCode == nil || freetextNameMissing || viewModel.inFlight)
                }
            }
            .task { await loadCatalog() }
            .alert("vaccinations_form_photo_error", isPresented: $photoError) {
                Button("ok", role: .cancel) {}
            }
            .alert(
                Text("vaccinations_action_failed_title"),
                isPresented: Binding(
                    get: { viewModel.actionError != nil },
                    set: { if !$0 { viewModel.actionError = nil } }
                )
            ) {
                Button("ok", role: .cancel) {}
            } message: {
                Text(viewModel.actionError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var form: some View {
        Form {
            Section {
                // Custom dropdown instead of a native Picker: the catalog list is long
                // now, and the menu style runs off-screen while navigationLink takes
                // the WHOLE screen. This caps the open list to ~5 rows and scrolls,
                // and its rows render the server display_name verbatim — so the
                // "Egyéb\n(add meg a nevét)" sentinel shows on two lines.
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { vaccineListOpen.toggle() }
                } label: {
                    HStack {
                        Text("vaccinations_form_vaccine").foregroundColor(.primary)
                        Spacer()
                        Text(selectedEntry.map { $0.displayName.replacingOccurrences(of: "\n", with: " ") }
                                ?? String(localized: "vaccinations_form_select"))
                            .foregroundColor(selectedCode == nil ? .secondary : .primary)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if vaccineListOpen {
                    VStack(spacing: 0) {
                        // Real vaccines: scroll, capped to ~5 rows.
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(regularCatalog) { entry in
                                    vaccineRow(entry)
                                    if entry.id != regularCatalog.last?.id { Divider() }
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                        // "Egyéb" sentinel(s) PINNED below the scroll — always visible
                        // (sort 999 would otherwise sit below the fold).
                        ForEach(freetextCatalog) { entry in
                            Divider()
                            vaccineRow(entry)
                        }
                    }
                }
                // "Egyéb" free-text name — revealed when an is_freetext sentinel is
                // picked. Sent as vaccine_name on create; the server freezes it as
                // the snapshot (create-only — a typo is delete-and-re-add).
                if isFreetext {
                    TextField("vaccinations_freetext_label", text: $freeText)
                }
                // Rabies first-shot/booster hint — UI cue only (the server derives
                // the +6/+12 validity). Shown for ANY rabies_specific vaccine
                // (dog OR cat — the server derives it for both); never gated on
                // species. The owner can override the expiry below for a restart.
                if isRabies {
                    // Blue info callout — matches the web rabies hint (#1d4ed8 on a
                    // light-blue row), deliberately NOT the grey Kötelező-pill tone.
                    Text("vaccinations_rabies_hint")
                        .font(.appFont(.caption))
                        .foregroundColor(Color(red: 0.114, green: 0.306, blue: 0.847))
                        .listRowBackground(Color(red: 0.114, green: 0.306, blue: 0.847).opacity(0.08))
                }
            }

            Section {
                DatePicker(
                    "vaccinations_form_administered",
                    selection: $administeredDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                Toggle("vaccinations_form_set_expiry", isOn: $hasExpiry)
                if hasExpiry {
                    DatePicker(
                        "vaccinations_form_expires",
                        selection: $expiryDate,
                        displayedComponents: .date
                    )
                } else {
                    Text("vaccinations_form_expiry_hint")
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("vaccinations_form_details")) {
                TextField("vaccinations_form_batch", text: $batchNumber)
                TextField("vaccinations_form_vet", text: $vetName)
                TextField("vaccinations_form_clinic", text: $vetClinic)
                TextField("vaccinations_form_notes", text: $notes, axis: .vertical)
            }

            Section(header: Text("vaccinations_form_photo_section")) {
                certRow
            }

            Section {
                Text("vaccinations_disclaimer")
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var certRow: some View {
        if let preview = certPreview {
            HStack(spacing: 12) {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Spacer()
                Button(role: .destructive) {
                    certPreview = nil
                    capturedData = nil
                    capturedMime = nil
                } label: {
                    Text("vaccinations_form_remove_photo")
                }
            }
        } else {
            PhotoCaptureView {
                HStack(spacing: 8) {
                    Image(systemName: "camera")
                    Text("vaccinations_form_add_photo")
                }
            } onCapture: { captured in
                Task { await handleCapture(captured) }
            }
        }
    }

    private var noCatalogState: some View {
        VStack(spacing: 12) {
            Image(systemName: "syringe")
                .font(.appFont(size: 40))
                .foregroundColor(.secondary)
            Text("vaccinations_no_catalog_region")
                .font(.appFont(.body))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadCatalog() async {
        loadingCatalog = true
        defer { loadingCatalog = false }
        // Country comes from the user's stored profile (the feature is HU/ES-only,
        // so this is the right binding). A nil/empty country can't form the query
        // → leave the catalog empty → the explicit region state renders.
        guard let country = authViewModel.currentUser?.country, !country.isEmpty else { return }
        await viewModel.loadCatalog(species: species, country: country)
    }

    private func handleCapture(_ captured: CapturedImage) async {
        let result: (data: Data, mime: String)?
        switch captured {
        case .picker(let item): result = await item.loadAsUploadable()
        case .camera(let image): result = image.certificateUploadable()
        }
        guard let result else {
            photoError = true   // undecodable pick — surfaced, never a silent no-op
            return
        }
        capturedData = result.data
        capturedMime = result.mime
        certPreview = UIImage(data: result.data)
    }

    private func submit() {
        guard let code = selectedCode else { return }
        let body = CreateVaccinationRequest(
            vaccineCode: code,
            vaccineName: isFreetext ? freeText.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            administeredAt: wireDate(administeredDate),
            expiresAt: hasExpiry ? wireDate(expiryDate) : nil,   // nil → server derives
            batchNumber: trimmedOrNil(batchNumber),
            vetName: trimmedOrNil(vetName),
            vetClinic: trimmedOrNil(vetClinic),
            notes: trimmedOrNil(notes)
        )
        Task {
            guard let created = await viewModel.create(body) else {
                return   // viewModel.actionError set → alert; stay on the form
            }
            // Two-step: a cert upload failure keeps the saved record and tells the
            // user it's addable later — never roll the record back.
            if let data = capturedData, let mime = capturedMime {
                let uploaded = await viewModel.uploadCertificate(
                    vaccinationId: created.id, data: data, mime: mime
                )
                if uploaded {
                    appState.showSuccess(String(localized: "vaccinations_toast_added"))
                } else {
                    appState.showError(String(localized: "vaccinations_saved_photo_failed"))
                }
            } else {
                appState.showSuccess(String(localized: "vaccinations_toast_added"))
            }
            dismiss()
        }
    }

    // MARK: - Helpers

    /// Format a user-picked `Date` to the "YYYY-MM-DD" wire value using the
    /// CURRENT calendar — so the day the user saw in the picker is the day sent
    /// (a UTC formatter here would shift the date for negative-offset zones). The
    /// server stores it as a plain calendar date; round-tripping through
    /// `VaccinationDate` (UTC) on read yields the same day since there's no time.
    private func wireDate(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }

    private func trimmedOrNil(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
