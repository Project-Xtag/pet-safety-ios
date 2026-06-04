import SwiftUI

/// Edit sheet for an existing vaccination record. Presented from
/// `VaccinationDetailView` (forms = sheets).
///
/// `vaccine_code` is **immutable** — shown read-only with a "delete and re-add"
/// note; `UpdateVaccinationRequest` doesn't even carry it. Editable: administered
/// date, expiry, and the optional details. PUT goes through `viewModel.update`,
/// whose `onDidMutate` keeps the home card in sync; a validation 400 (e.g. the
/// rabies floor on a changed administered date) surfaces via `actionError`.
///
/// Expiry: if the record already has one, the date is editable (clearing it =
/// delete + re-add, not offered here). If it has none, a toggle adds one.
/// Detail text fields are sent as their current value (incl. empty), so an edit
/// that clears a field persists.
struct EditVaccinationView: View {
    @ObservedObject var viewModel: VaccinationsViewModel
    let vaccination: Vaccination

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var administeredDate: Date
    @State private var hasExpiry: Bool
    @State private var expiryDate: Date
    @State private var batchNumber: String
    @State private var vetName: String
    @State private var vetClinic: String
    @State private var notes: String

    private let hadExpiry: Bool

    init(viewModel: VaccinationsViewModel, vaccination: Vaccination) {
        self.viewModel = viewModel
        self.vaccination = vaccination
        let admin = VaccinationDate.parse(vaccination.administeredAt) ?? Date()
        let exp = vaccination.expiresAt.flatMap { VaccinationDate.parse($0) }
        self.hadExpiry = vaccination.expiresAt != nil
        _administeredDate = State(initialValue: admin)
        _hasExpiry = State(initialValue: vaccination.expiresAt != nil)
        _expiryDate = State(initialValue: exp ?? admin)
        _batchNumber = State(initialValue: vaccination.batchNumber ?? "")
        _vetName = State(initialValue: vaccination.vetName ?? "")
        _vetClinic = State(initialValue: vaccination.vetClinic ?? "")
        _notes = State(initialValue: vaccination.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("vaccinations_form_vaccine").foregroundColor(.secondary)
                        Spacer()
                        Text(vaccination.vaccineNameSnapshot).foregroundColor(.ink)
                    }
                    Text("vaccinations_change_vaccine_note")
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                }

                Section {
                    DatePicker("vaccinations_form_administered", selection: $administeredDate,
                               in: ...Date(), displayedComponents: .date)
                    if hadExpiry {
                        DatePicker("vaccinations_form_expires", selection: $expiryDate,
                                   displayedComponents: .date)
                    } else {
                        Toggle("vaccinations_form_set_expiry", isOn: $hasExpiry)
                        if hasExpiry {
                            DatePicker("vaccinations_form_expires", selection: $expiryDate,
                                       displayedComponents: .date)
                        }
                    }
                }

                Section(header: Text("vaccinations_form_details")) {
                    TextField("vaccinations_form_batch", text: $batchNumber)
                    TextField("vaccinations_form_vet", text: $vetName)
                    TextField("vaccinations_form_clinic", text: $vetClinic)
                    TextField("vaccinations_form_notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("vaccinations_edit_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") { submit() }.disabled(viewModel.inFlight)
                }
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

    private func submit() {
        let body = UpdateVaccinationRequest(
            administeredAt: wireDate(administeredDate),
            expiresAt: (hadExpiry || hasExpiry) ? wireDate(expiryDate) : nil,
            batchNumber: batchNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            vetName: vetName.trimmingCharacters(in: .whitespacesAndNewlines),
            vetClinic: vetClinic.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        Task {
            if await viewModel.update(id: vaccination.id, body) {
                appState.showSuccess(String(localized: "vaccinations_toast_saved"))
                dismiss()
            }
            // else: actionError alert shows; stay on the sheet
        }
    }

    /// "YYYY-MM-DD" from the user-picked Date using the CURRENT calendar, so the
    /// shown day is the day sent (no UTC day-shift). Matches the add form.
    private func wireDate(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }
}
