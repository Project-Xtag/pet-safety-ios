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

    // Encoded, upload-ready certificate bytes (nil until a valid image is picked).
    @State private var capturedData: Data?
    @State private var capturedMime: String?
    @State private var certPreview: UIImage?
    @State private var photoError = false

    @State private var loadingCatalog = true

    private var sortedCatalog: [VaccineCatalogEntry] {
        viewModel.catalog.sorted { $0.sortOrder < $1.sortOrder }
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
                        .disabled(selectedCode == nil || viewModel.inFlight)
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
                Picker("vaccinations_form_vaccine", selection: $selectedCode) {
                    Text("vaccinations_form_select").tag(String?.none)
                    ForEach(sortedCatalog) { entry in
                        Text(entry.displayName).tag(Optional(entry.code))
                    }
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
