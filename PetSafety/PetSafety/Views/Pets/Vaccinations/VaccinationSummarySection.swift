import SwiftUI

/// Pet-detail vaccinations section + add CTA.
///
/// GATING (Stage B decisions #2 & #6): the parent (`PetDetailView`) inserts this
/// view only when `VaccinationGate.availability.isOn`. Emptiness is a *display*
/// concern here, never a gate — an on-but-empty pet still shows the section and a
/// reachable add affordance (that's the point of #6: empty ≠ hidden, that's only
/// true for the home card).
///
/// The view is gate-agnostic: it renders from the injected per-pet
/// `VaccinationsViewModel`. The VM's `load()` and `onDidMutate` hook are driven by
/// `PetDetailView` (which owns the reliable, gate-keyed `.task`), so this view has
/// no lifecycle of its own and no direct knowledge of the gate.
///
/// Scope: rows show the catalog snapshot name + the reusable
/// `VaccinationStatusPill`, and "Show all (N)" pushes the full
/// `VaccinationsListView` (sharing this same VM). The add CTA's destination —
/// `AddVaccinationView` — is the next slice (still inert here).
struct VaccinationSummarySection: View {
    @ObservedObject var viewModel: VaccinationsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("vaccinations_title", systemImage: "syringe")
                .font(.appFont(.headline))

            if viewModel.isLoading && viewModel.vaccinations.isEmpty {
                ProgressView()
                    .padding(.vertical, 8)
            } else if viewModel.vaccinations.isEmpty {
                Text("vaccinations_section_empty")
                    .font(.appFont(.body))
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.vaccinations.prefix(3)) { vaccination in
                    HStack(spacing: 12) {
                        Text(vaccination.vaccineNameSnapshot)
                            .font(.appFont(size: 15, weight: .medium))
                            .foregroundColor(.ink)
                        Spacer()
                        // CRUD list rows carry no server status → derive client-side
                        // (same <30-day boundary the server uses on summary rows).
                        VaccinationStatusPill(status: vaccination.status)
                    }
                }
                // Always reachable when records exist (not only when > 3) so the
                // full list — and, next slice, per-record detail/edit/delete — is
                // accessible even with 1–3 records. Shares this VM instance.
                NavigationLink(destination: VaccinationsListView(viewModel: viewModel)) {
                    Text(String(format: NSLocalizedString("vaccinations_show_all", comment: ""), viewModel.vaccinations.count))
                        .font(.appFont(.subheadline))
                        .foregroundColor(.brandOrange)
                }
            }

            Button(action: {
                // TODO(next slice): present AddVaccinationView (the form).
                // This slice proves the gate + reachable add affordance only.
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("vaccinations_add_cta")
                }
            }
            .buttonStyle(BrandButtonStyle())
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
