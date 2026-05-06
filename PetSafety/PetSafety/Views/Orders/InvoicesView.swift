import SwiftUI
import UIKit

/// Invoices tab content — renders the user's Stripe-billed invoices
/// with a tap-to-open-PDF affordance. Subscription management lives
/// elsewhere (Account → Subscription) so this view stays focused.
struct InvoicesView: View {
    @StateObject private var viewModel = InvoicesViewModel()
    @Environment(\.locale) private var locale

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.invoices.isEmpty {
                ProgressView()
            } else if let error = viewModel.errorMessage, viewModel.invoices.isEmpty {
                VStack(spacing: 12) {
                    Text(error)
                        .font(.appFont(.subheadline))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button(String(localized: "retry")) {
                        Task { await viewModel.fetchInvoices() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.invoices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 56))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text(String(localized: "billing_no_invoices"))
                        .font(.appFont(.subheadline))
                        .foregroundColor(.secondary)
                }
            } else {
                List(viewModel.invoices) { invoice in
                    InvoiceRow(invoice: invoice)
                        .listRowSeparator(.visible)
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.fetchInvoices()
                }
            }
        }
        .task {
            if viewModel.invoices.isEmpty {
                await viewModel.fetchInvoices()
            }
        }
    }
}

private struct InvoiceRow: View {
    let invoice: Invoice
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let s = invoice.pdfUrl, let url = URL(string: s) {
                openURL(url)
            } else if let s = invoice.hostedUrl, let url = URL(string: s) {
                openURL(url)
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invoice.number ?? String(localized: "billing_invoice"))
                        .font(.appFont(.body, weight: .medium))
                        .foregroundColor(.primary)
                    Text(formattedDate)
                        .font(.appFont(.caption))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedAmount)
                        .font(.appFont(.body, weight: .semibold))
                        .foregroundColor(.primary)
                    Text((invoice.status ?? String(localized: "billing_unknown")).capitalized)
                        .font(.appFont(.caption))
                        .foregroundColor(invoice.status == "paid" ? .green : .brandOrange)
                }

                if invoice.pdfUrl != nil || invoice.hostedUrl != nil {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                        .foregroundColor(.brandOrange)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var formattedDate: String {
        let date = Date(timeIntervalSince1970: invoice.date)
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private var formattedAmount: String {
        let value = Double(invoice.amount) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = invoice.currency.uppercased()
        return formatter.string(from: NSNumber(value: value))
            ?? "\(invoice.currency.uppercased()) \(String(format: "%.2f", value))"
    }
}
