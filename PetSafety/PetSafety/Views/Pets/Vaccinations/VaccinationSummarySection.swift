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
/// Scope (this slice = gate proof): rows show the catalog snapshot name + an
/// interim status label. The add CTA is present and tappable to satisfy the
/// on-empty litmus (a flag-on user can reach "add a first record"); its
/// destination — `AddVaccinationView` — is the next slice. The full list, detail,
/// and reusable pill component also land then.
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
                        VaccinationStatusLabel(status: vaccination.status)
                    }
                }
                if viewModel.vaccinations.count > 3 {
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

/// Interim status indicator (icon + colored label) shared by the home card and
/// the pet-detail section. Deliberately minimal — keeps the gate-proof slice
/// walkable without pre-committing the pill's design.
///
/// TODO(list-slice): REPLACE with the reusable `VaccinationStatusPill` (capsule,
/// full styling, status→label/colour mapping in ONE place) and delete this type.
/// Do not let it ossify into a second, parallel status component.
struct VaccinationStatusLabel: View {
    let status: VaccinationStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(labelKey)
        }
        .font(.appFont(size: 13, weight: .semibold))
        .foregroundColor(color)
    }

    private var symbol: String {
        switch status {
        case .valid: return "checkmark.circle.fill"
        case .expiring: return "clock.fill"
        case .expired: return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch status {
        case .valid: return .green
        case .expiring: return .orange
        case .expired: return .red
        }
    }

    private var labelKey: LocalizedStringKey {
        switch status {
        case .valid: return "vaccinations_status_valid"
        case .expiring: return "vaccinations_status_expiring"
        case .expired: return "vaccinations_status_expired"
        }
    }
}
