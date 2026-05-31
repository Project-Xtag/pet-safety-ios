import SwiftUI

/// Sheet host for the deep-link / home-tap entry into a pet's vaccination list.
///
/// Unlike the pet-detail push (which shares `PetDetailView`'s VM), this entry has
/// no VM to borrow — so it **owns** a `VaccinationsViewModel` for the target pet
/// (`@StateObject`, tied to the sheet's lifetime) and **binds `onDidMutate` to
/// `gate.refresh()`** here, exactly as `PetDetailView` does. Without that hook an
/// edit/delete made from the deep-link sheet wouldn't refresh the home card.
///
/// Wrapped in its own `NavigationView` so `VaccinationsListView`'s row → detail
/// push and its add-record sheet work inside the modal.
struct VaccinationsDeepLinkSheet: View {
    let pet: Pet
    @EnvironmentObject private var vaccinationGate: VaccinationGate
    @StateObject private var viewModel: VaccinationsViewModel

    init(pet: Pet) {
        self.pet = pet
        _viewModel = StateObject(wrappedValue: VaccinationsViewModel(petId: pet.id))
    }

    var body: some View {
        NavigationView {
            VaccinationsListView(viewModel: viewModel, species: pet.species)
        }
        .navigationViewStyle(.stack)
        .task {
            // Same single hook PetDetailView binds: any successful CRUD here keeps
            // the home card in sync. Bind once, then load.
            viewModel.onDidMutate = { Task { await vaccinationGate.refresh() } }
            await viewModel.load()
        }
    }
}
