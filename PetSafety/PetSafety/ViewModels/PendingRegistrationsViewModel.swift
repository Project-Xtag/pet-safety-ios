import Foundation

@MainActor
class PendingRegistrationsViewModel: ObservableObject {
    @Published var registrations: [PendingRegistration] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    var readyToActivate: [PendingRegistration] {
        registrations.filter { ["shipped", "delivered"].contains($0.orderStatus.lowercased()) }
    }

    var stillProcessing: [PendingRegistration] {
        registrations.filter { !["shipped", "delivered"].contains($0.orderStatus.lowercased()) }
    }

    func fetchPendingRegistrations() async {
        isLoading = true
        errorMessage = nil
        do {
            registrations = try await apiService.getPendingRegistrations()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
