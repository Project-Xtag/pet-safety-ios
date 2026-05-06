import Foundation
import SwiftUI

@MainActor
final class InvoicesViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchInvoices() async {
        isLoading = true
        errorMessage = nil
        do {
            invoices = try await APIService.shared.getInvoices()
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ Failed to load invoices: \(error)")
            #endif
        }
        isLoading = false
    }
}
