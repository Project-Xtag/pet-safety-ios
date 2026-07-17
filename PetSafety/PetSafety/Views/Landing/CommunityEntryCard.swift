import SwiftUI

/// Zone 3's community row (spec §B.1).
///
/// A **composition over shipping primitives**, not a net-new styled component
/// (G-b, path (ii)): `.elevatedCard()` (`AppColors.swift:273`) wrapping the
/// Success-Stories row body lifted from `PetsListView.swift:449-479` — the 60pt
/// tinted disc + title/subtitle `VStack` + `Spacer` + trailing chevron.
///
/// Built **standalone for the landing only** (spec §B.3). Phase 1 deliberately
/// does NOT refactor `PetsListView` to consume this — that would reach into
/// authed-home internals under `MainTabView`. The pre-existing inline
/// duplication stays recorded as G10, deferred.
///
/// Two deliberate differences from the lifted original, both because the token
/// is the sanctioned form and the hand-rolled values are what G10 exists to
/// retire:
/// - corner radius 16 → `AppRadius.lg` (20), via `.elevatedCard()`
/// - the hand-rolled `systemBackground` + `cornerRadius` + `shadow` trio at
///   `PetsListView.swift:476-479` → the one modifier that encapsulates it
struct CommunityEntryCard: View {
    let entry: CommunityEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.lg) {
                // Icon disc — lifted composition (PetsListView.swift:449-456).
                ZStack {
                    Circle()
                        .fill(Color.brandOrange.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: entry.systemImage)
                        .font(.appFont(size: 30))
                        .foregroundColor(.brandOrange)
                }
                // The disc is decorative: the row's label comes from the
                // combined element below, so an icon label would double-read.
                .accessibilityHidden(true)

                // Text — lifted composition (PetsListView.swift:458-466).
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(entry.titleKey)
                        .font(.appFont(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Text(entry.subtitleKey)
                        .font(.appFont(size: 14))
                        .foregroundColor(.mutedText)
                        .multilineTextAlignment(.leading)
                        // Localized subtitles run long (HU/DE); let the row grow
                        // rather than truncate. 13 locales, HU canonical.
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.sm)

                Image(systemName: "chevron.right")
                    .font(.appFont(size: 14, weight: .semibold))
                    .foregroundColor(.mutedText)
                    .accessibilityHidden(true)
            }
            .elevatedCard(padding: AppSpacing.lg)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        ForEach(CommunityEntry.seed) { entry in
            CommunityEntryCard(entry: entry) {}
        }
    }
    .padding(AppSpacing.lg)
    .background(Color("BackgroundColor"))
}
