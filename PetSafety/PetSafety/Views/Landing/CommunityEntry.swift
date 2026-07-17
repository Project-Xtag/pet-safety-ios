import SwiftUI

/// Where a Zone-3 Community card sends the user.
///
/// C3 (1.1b) **emits the intent only** — resolution is Phase-2's read-decoupling
/// of 2.3 (board) / 2.4 (places), the single explicit Phase-1 → Phase-2
/// dependency edge (spec §C.2). No user sees a dead CTA because the landing is
/// not released until those handlers are live (spec §C.0's DEPENDENCY). If the
/// release model ever goes phased, §C.0 says this seam must be revisited.
enum CommunityDestination: Equatable, CaseIterable {
    case lostAndFound
    case petFriendlyPlaces
}

/// One row of Zone 3's data-driven Community list (plan §2 Shape A; spec §D.1).
///
/// Adding a future community feature = append one descriptor + its destination
/// case + its Phase-2 route handler. **No landing-layout change** — that is the
/// entire point of the array. G-a holds by construction: the section renders
/// complete from its data, so there is no "coming soon" slot to leave empty.
struct CommunityEntry: Identifiable, Equatable {
    /// Stable key — NOT the array index. Seed order is presentation, not identity.
    let id: String
    let systemImage: String
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey
    let destination: CommunityDestination

    /// The only two entries today (spec §D.1).
    ///
    /// ⚠️ Title/subtitle keys are the **shipping** ones, not new `community_*`
    /// twins. `lost_and_found_title`, `pet_friendly_entry_title` and
    /// `pet_friendly_entry_subtitle` already exist at **13/13 locales**, and
    /// `pet_friendly_entry_*` is already this exact title+subtitle pair
    /// (`PetsListView.swift:489-511`) — it was built for this shape. Minting
    /// `community_*` duplicates would be two names for one string, which is this
    /// project's documented failure genre. Approved 2026-07-17; spec §F:241's key
    /// list is corrected by reference in the plan's gaps register, not edited.
    ///
    /// `community_lost_found_subtitle` IS new: the existing
    /// `lost_and_found_description` carries a trailing owner-facing clause
    /// ("és a saját eltűnési riasztásaid") that is wrong on a logged-out landing.
    static let seed: [CommunityEntry] = [
        CommunityEntry(
            id: "lost_and_found",
            systemImage: "exclamationmark.triangle.fill",
            titleKey: "lost_and_found_title",
            subtitleKey: "community_lost_found_subtitle",
            destination: .lostAndFound
        ),
        CommunityEntry(
            id: "pet_friendly",
            systemImage: "mappin.and.ellipse",
            titleKey: "pet_friendly_entry_title",
            subtitleKey: "pet_friendly_entry_subtitle",
            destination: .petFriendlyPlaces
        )
    ]
}
