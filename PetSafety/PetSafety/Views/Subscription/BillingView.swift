import SwiftUI
import SafariServices

struct BillingView: View {
    @State private var invoices: [InvoiceItem] = []
    @State private var isLoading = true
    @State private var isPortalLoading = false
    @State private var portalURL: URL?
    @State private var showSafari = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            // Manage Subscription Section
            Section {
                Button(action: openPortal) {
                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundColor(.brandOrange)
                        Text("Manage Subscription")
                        Spacer()
                        if isPortalLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(isPortalLoading)
            } header: {
                Text("Subscription")
            } footer: {
                Text("Opens the Stripe billing portal to manage your payment method, change plan, or cancel.")
            }

            // Invoices Section
            Section("Invoices") {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading invoices...")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else if invoices.isEmpty {
                    Text("No invoices yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(invoices) { invoice in
                        invoiceRow(invoice)
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Billing & Invoices")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInvoices()
        }
        .sheet(isPresented: $showSafari) {
            if let url = portalURL {
                SafariView(url: url)
            }
        }
    }

    // MARK: - Invoice Row

    private func invoiceRow(_ invoice: InvoiceItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.number ?? "Invoice")
                    .font(.subheadline.weight(.medium))
                Text(formatDate(invoice.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatAmount(invoice.amount, currency: invoice.currency))
                    .font(.subheadline.weight(.semibold))
                Text(invoice.status?.capitalized ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(invoice.status == "paid" ? .green : .orange)
            }

            if let pdfUrl = invoice.pdfUrl, let url = URL(string: pdfUrl) {
                Link(destination: url) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.brandOrange)
                }
                .padding(.leading, 8)
            }
        }
    }

    // MARK: - Actions

    private func openPortal() {
        Task {
            isPortalLoading = true
            errorMessage = nil
            do {
                let response = try await APIService.shared.createPortalSession()
                if let url = URL(string: response.url) {
                    portalURL = url
                    showSafari = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isPortalLoading = false
        }
    }

    private func loadInvoices() async {
        isLoading = true
        do {
            invoices = try await APIService.shared.getInvoices()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Formatting

    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatAmount(_ amount: Int, currency: String) -> String {
        let value = Double(amount) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.uppercased()
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency) \(value)"
    }
}

// MARK: - Safari View

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
