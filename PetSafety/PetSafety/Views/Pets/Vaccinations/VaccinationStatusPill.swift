import SwiftUI

/// The single source of truth for rendering a `VaccinationStatus` — a colored
/// capsule with an SF Symbol + localized label.
///
/// Used by every vaccination surface (home summary card, pet-detail section,
/// full list, detail view), so the status → colour / icon / label mapping lives
/// here and ONLY here. It replaces the interim `VaccinationStatusLabel` that the
/// gate-proof slice carried; do not reintroduce a second, parallel status view.
///
/// Both inputs flow through the same `VaccinationStatus`: the per-pet CRUD rows
/// derive it client-side (`Vaccination.status`) and the home summary consumes the
/// server's verbatim `status` — so a record reads identically everywhere
/// (Stage B decision #3, consistency requirement).
struct VaccinationStatusPill: View {
    let status: VaccinationStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(labelKey)
        }
        .font(.appFont(size: 12, weight: .semibold))
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        switch status {
        case .valid:    return "checkmark.circle.fill"
        case .expiring: return "clock.fill"
        case .expired:  return "exclamationmark.triangle.fill"
        }
    }

    private var tint: Color {
        switch status {
        case .valid:    return .green
        case .expiring: return .orange
        case .expired:  return .red
        }
    }

    private var labelKey: LocalizedStringKey {
        switch status {
        case .valid:    return "vaccinations_status_valid"
        case .expiring: return "vaccinations_status_expiring"
        case .expired:  return "vaccinations_status_expired"
        }
    }
}
