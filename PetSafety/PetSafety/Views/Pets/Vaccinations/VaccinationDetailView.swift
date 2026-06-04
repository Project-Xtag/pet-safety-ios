import SwiftUI
import PhotosUI
import UIKit

/// Read-only detail for one vaccination ("health record"), with edit (sheet),
/// delete (confirmed), and record-photo management (add / replace / remove).
///
/// Reads the **live** record from the shared `VaccinationsViewModel` by id, so
/// edits and cert changes reflect immediately and — when the record is deleted —
/// `vaccination` becomes nil and the view pops itself. Reached as a push from
/// `VaccinationsListView` (list = drill-down; edit = a sheet, the locked nav model).
///
/// Refresh split (mirrors the form): **delete** flows through `viewModel.delete`,
/// which fires `onDidMutate → gate.refresh()` (counts change); **cert add/replace/
/// remove** update the local row only, no gate refresh (a cert doesn't affect the
/// home summary). Naming: "record"/"photo" — never "certificate".
struct VaccinationDetailView: View {
    @ObservedObject var viewModel: VaccinationsViewModel
    let vaccinationId: String

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false
    @State private var photoError = false      // undecodable pick
    @State private var certOpFailed = false     // upload/remove failed
    /// The just-picked image, shown immediately after a successful upload so the
    /// new photo appears instantly — `CachedAsyncImage` is slow to surface the
    /// round-tripped URL (the same latency as the pet-photo finding). Cleared on
    /// remove; resets to the server URL when the view is re-entered.
    @State private var localCertImage: UIImage?

    private var vaccination: Vaccination? {
        viewModel.vaccinations.first { $0.id == vaccinationId }
    }

    var body: some View {
        Group {
            if let v = vaccination {
                detail(v)
            } else {
                // Record gone (deleted here or elsewhere) → pop back to the list.
                Color.clear.onAppear { dismiss() }
            }
        }
    }

    private func detail(_ v: Vaccination) -> some View {
        List {
            Section {
                HStack {
                    Text(v.vaccineNameSnapshot)
                        .font(.appFont(size: 16, weight: .semibold))
                        .foregroundColor(.ink)
                    Spacer()
                    VaccinationStatusPill(status: v.status)
                }
                Text("vaccinations_change_vaccine_note")
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
            }

            Section {
                labelled("vaccinations_form_administered", VaccinationDate.displayString(v.administeredAt))
                if let exp = v.expiresAt {
                    labelled("vaccinations_form_expires", VaccinationDate.displayString(exp))
                } else {
                    labelled("vaccinations_form_expires", NSLocalizedString("vaccinations_no_expiry", comment: ""))
                }
            }

            if v.batchNumber != nil || v.vetName != nil || v.vetClinic != nil || (v.notes?.isEmpty == false) {
                Section(header: Text("vaccinations_form_details")) {
                    if let b = v.batchNumber, !b.isEmpty { labelled("vaccinations_form_batch", b) }
                    if let n = v.vetName, !n.isEmpty { labelled("vaccinations_form_vet", n) }
                    if let c = v.vetClinic, !c.isEmpty { labelled("vaccinations_form_clinic", c) }
                    if let notes = v.notes, !notes.isEmpty { labelled("vaccinations_form_notes", notes) }
                }
            }

            Section(header: Text("vaccinations_form_photo_section")) {
                photoSection(v)
            }

            Section {
                Text("vaccinations_disclaimer")
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
            }

            Section {
                Button(role: .destructive) { showingDeleteConfirm = true } label: {
                    HStack { Spacer(); Text("delete"); Spacer() }
                }
                .disabled(viewModel.inFlight)
            }
        }
        .navigationTitle(v.vaccineNameSnapshot)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("vaccinations_edit_title") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditVaccinationView(viewModel: viewModel, vaccination: v)
                .environmentObject(appState)
        }
        .confirmationDialog(
            Text("vaccinations_delete_confirm_title"),
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("delete", role: .destructive) {
                Task {
                    if await viewModel.delete(id: v.id) {   // onDidMutate → gate.refresh; view pops when row disappears
                        appState.showSuccess(String(localized: "vaccinations_toast_deleted"))
                    }
                }
            }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("vaccinations_delete_confirm_msg")
        }
        .alert("vaccinations_form_photo_error", isPresented: $photoError) {
            Button("ok", role: .cancel) {}
        }
        .alert("vaccinations_cert_op_failed", isPresented: $certOpFailed) {
            Button("ok", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func photoSection(_ v: Vaccination) -> some View {
        if let local = localCertImage {
            Image(uiImage: local)
                .resizable().scaledToFit()
                .frame(maxHeight: 240)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            certActions(v)
        } else if let urlString = v.certificateUrl, let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView().frame(maxWidth: .infinity, minHeight: 120)
            }
            .frame(maxHeight: 240)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            certActions(v)
        } else {
            PhotoCaptureView {
                Label("vaccinations_form_add_photo", systemImage: "camera")
            } onCapture: { captured in
                Task { await handleCapture(captured, for: v.id, replacing: false) }
            }
        }
    }

    @ViewBuilder
    private func certActions(_ v: Vaccination) -> some View {
        PhotoCaptureView {
            Label("vaccinations_replace_photo", systemImage: "arrow.triangle.2.circlepath")
        } onCapture: { captured in
            Task { await handleCapture(captured, for: v.id, replacing: true) }
        }
        Button(role: .destructive) {
            Task {
                if await viewModel.deleteCertificate(vaccinationId: v.id) {
                    localCertImage = nil
                    appState.showSuccess(String(localized: "vaccinations_toast_photo_removed"))
                } else {
                    certOpFailed = true
                }
            }
        } label: {
            Label("vaccinations_form_remove_photo", systemImage: "trash")
        }
        .disabled(viewModel.inFlight)
    }

    private func labelled(_ key: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key).font(.appFont(.subheadline)).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.appFont(.body)).foregroundColor(.ink)
                .multilineTextAlignment(.trailing)
        }
    }

    private func handleCapture(_ captured: CapturedImage, for id: String, replacing: Bool) async {
        let result: (data: Data, mime: String)?
        switch captured {
        case .picker(let item): result = await item.loadAsUploadable()
        case .camera(let image): result = image.certificateUploadable()
        }
        guard let result else { photoError = true; return }
        let ok = await viewModel.uploadCertificate(vaccinationId: id, data: result.data, mime: result.mime)
        if ok {
            localCertImage = UIImage(data: result.data)   // instant — masks the URL-fetch latency
            appState.showSuccess(String(localized: replacing ? "vaccinations_toast_photo_replaced"
                                                             : "vaccinations_toast_photo_added"))
        } else {
            certOpFailed = true
        }
    }
}
