import Foundation

@MainActor
class OrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchOrders() async {
        isLoading = true
        errorMessage = nil

        do {
            orders = try await apiService.getOrders()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func createOrder(
        guestEmail: String?,
        items: [OrderItemRequest]
    ) async throws -> PaymentIntentResponse {
        isLoading = true
        errorMessage = nil

        let request = CreateOrderRequest(guestEmail: guestEmail, items: items)

        do {
            let response = try await apiService.createOrder(request)
            isLoading = false
            return response
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
