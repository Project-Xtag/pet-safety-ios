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

    func createOrder(_ orderData: CreateOrderRequest) async throws -> CreateTagOrderResponse {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.createOrder(orderData)
            isLoading = false
            return response
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
