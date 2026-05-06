import Foundation

/// Stripe-billed invoice as exposed by /api/billing/invoices.
/// Matches the Android model field-for-field so the renderer code on
/// both clients can carry the same expectations (cents amounts, unix
/// seconds for `date`, optional pdfUrl when Stripe finalised the PDF).
struct Invoice: Codable, Identifiable {
    let id: String
    let number: String?
    let status: String?
    let amount: Int          // cents
    let currency: String
    let date: TimeInterval   // unix seconds
    let pdfUrl: String?
    let hostedUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, number, status, amount, currency, date
        case pdfUrl, hostedUrl
    }
}

struct InvoicesResponse: Codable {
    let invoices: [Invoice]
}
