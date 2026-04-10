import Foundation

@MainActor
class ShelterPromoClaimViewModel: ObservableObject {
    enum ClaimState {
        case idle
        case loading
        case success(ClaimPromoTagResponse)
        case error(String)
    }

    @Published var state: ClaimState = .idle
    @Published var pets: [Pet] = []
    @Published var isLoadingPets: Bool = false

    func loadPets() async {
        isLoadingPets = true
        do {
            pets = try await APIService.shared.fetchPets()
        } catch {
            // Non-blocking — user can still register new pet
        }
        isLoadingPets = false
    }

    func claimWithNewPet(qrCode: String, petData: CreatePetRequest) async {
        state = .loading
        do {
            let response = try await APIService.shared.claimPromoTag(qrCode: qrCode, pet: petData)
            state = .success(response)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func claimWithExistingPet(qrCode: String, petId: String) async {
        state = .loading
        do {
            let response = try await APIService.shared.claimPromoTag(qrCode: qrCode, petId: petId)
            state = .success(response)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
