import SwiftUI

/// Home-screen vaccination summary card (the Kedvenceim landing, `PetsListView`).
///
/// GATING (Stage B decisions #2/#6) — this view is a *display* of an already
/// non-empty summary. The single source of truth is `VaccinationGate`, resolved
/// on the home landing's `.task` (see `PetsListView`). The parent only inserts
/// this view when `gate.availability.showsHomeCard` is true, so:
///   • feature off (.off / .unknown) → parent inserts nothing → zero surface
///   • feature on but no records (showsHomeCard == false) → parent inserts nothing
///   • feature on with records → parent passes the summary → this card renders
///
/// The gate must be the only place a summary 404 is interpreted; this view never
/// touches the API. Keeping the conditional in the parent's `ViewBuilder` (rather
/// than an internal `if`) is deliberate — an empty custom view still claims a
/// slot in the parent `VStack(spacing:)` and would double the surrounding gap, a
/// visible leak when the feature is off.
///
/// Scope: this slice proves the gate. The richer card (pet thumbnails, day-count
/// copy, tap-through to a pet's vaccination list) lands with the list/detail slice.
struct VaccinationHomeSummarySection: View {
    let summary: VaccinationHomeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("vaccinations_home_title")
                .font(.appFont(size: 20, weight: .bold))
                .foregroundColor(.ink)

            if summary.urgent.isEmpty {
                // Records exist but none within 30 days — the reassurance state
                // (#6: an all-valid user keeps the card, doesn't get hidden).
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("vaccinations_home_all_up_to_date")
                        .font(.appFont(size: 15))
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(summary.urgent) { item in
                        urgentRow(item)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func urgentRow(_ item: VaccinationHomeSummary.UrgentVaccination) -> some View {
        HStack(spacing: 12) {
            // Pet thumbnail + name lead the row so it's unmistakable WHOSE
            // vaccine each line is — the card is account-wide (all pets), and
            // with 2+ pets / 4+ rows a vaccine name alone doesn't say which pet.
            petThumbnail(item.petProfileImage)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.petName)
                    .font(.appFont(size: 15, weight: .semibold))
                    .foregroundColor(.ink)
                Text(item.vaccineName)
                    .font(.appFont(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
            // Server `status` consumed verbatim (never re-derived on summary rows).
            VaccinationStatusPill(status: item.status)
        }
    }

    @ViewBuilder
    private func petThumbnail(_ urlString: String?) -> some View {
        CachedAsyncImage(url: URL(string: urlString ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                Circle().fill(Color.tealAccent.opacity(0.2))
                Image(systemName: "pawprint.fill")
                    .font(.appFont(size: 15))
                    .foregroundColor(.tealAccent)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
}
