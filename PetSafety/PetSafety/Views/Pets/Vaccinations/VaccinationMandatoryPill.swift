import SwiftUI

/// The "Kötelező" (legally mandatory) badge. Shown ALONGSIDE
/// `VaccinationStatusPill`, never instead of it — the status pill is left
/// untouched. This copies the StatusPill capsule pattern verbatim (same font,
/// padding, shape) rather than abstracting over it: a sibling that reuses the
/// pattern, not a new bespoke badge.
///
/// Tone: neutral grey (`.secondary`), deliberately NOT green/orange/red so it
/// never reads as a fourth status. The design system has no info/blue role, so
/// per the locked colour call we use a neutral grey (a DS grey token swaps in at
/// the Stage-C visual pass). Driven by the record's `is_mandatory` (current
/// catalog value; dog-HU rabies only at launch).
struct VaccinationMandatoryPill: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.shield.fill")
            Text("vaccinations_mandatory")
        }
        .font(.appFont(size: 12, weight: .semibold))
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.secondary.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }
}
