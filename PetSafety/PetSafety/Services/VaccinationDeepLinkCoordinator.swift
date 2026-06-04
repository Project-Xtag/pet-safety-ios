import SwiftUI

/// One routing channel for "open a pet's vaccination list from OUTSIDE pet
/// detail" — the home urgent-row tap AND the `VACCINATION_DUE` push both feed it
/// (and defect A's future inbox-row tap will reuse it). The list is presented as
/// a sheet by `PetsListView` (cross-context, focused-task entry = sheet-shaped;
/// the within-pet-detail drill-down stays a push).
///
/// Cold-launch safe by design: a killed-app push fires the handler before the
/// root view mounts, so a fire-and-forget `NotificationCenter` post would be
/// missed. Instead the handler stores `pendingPetId` here; `PetsListView`
/// consumes it once its pets are loaded (clearing it — consume exactly once) and
/// no-ops gracefully if that pet is gone between the push and the tap.
@MainActor
final class VaccinationDeepLinkCoordinator: ObservableObject {
    static let shared = VaccinationDeepLinkCoordinator()

    /// Target pet whose vaccination list should open. Set by the push handler /
    /// home tap; cleared by `PetsListView` on consume.
    @Published var pendingPetId: String?

    private init() {}

    func request(petId: String) {
        guard !petId.isEmpty else { return }
        pendingPetId = petId
    }
}
