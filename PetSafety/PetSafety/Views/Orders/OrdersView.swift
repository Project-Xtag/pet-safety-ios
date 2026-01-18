import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()

    var body: some View {
        ZStack {
            if viewModel.orders.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "cart.fill",
                    title: "No Orders",
                    message: "You haven't placed any orders yet"
                )
            } else {
                List {
                    ForEach(viewModel.orders) { order in
                        NavigationLink(destination: OrderDetailView(order: order)) {
                            OrderRowView(order: order)
                        }
                    }
                }
                .listStyle(.inset)
                .adaptiveList()
            }
        }
        .navigationTitle("Orders")
        .task {
            await viewModel.fetchOrders()
        }
        .refreshable {
            await viewModel.fetchOrders()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

struct OrderRowView: View {
    let order: Order

    var statusColor: Color {
        switch order.orderStatus {
        case "completed": return .green
        case "pending": return .orange
        case "failed": return .red
        case "processing": return .blue
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Order #\(order.id)")
                    .font(.headline)

                Spacer()

                Text(order.formattedAmount)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(order.orderStatus.capitalized)
                    .font(.subheadline)
                    .foregroundColor(statusColor)

                Spacer()

                Text(formatDate(order.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let items = order.items, !items.isEmpty {
                let totalItems = items.reduce(0) { $0 + $1.quantity }
                Text("\(totalItems) item\(totalItems == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}

struct OrderDetailView: View {
    let order: Order

    var body: some View {
        List {
            Section("Order Information") {
                HStack {
                    Text("Order ID")
                    Spacer()
                    Text("#\(order.id)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Status")
                    Spacer()
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                Text(order.orderStatus.capitalized)
                            .foregroundColor(statusColor)
                    }
                }

                HStack {
                    Text("Total Amount")
                    Spacer()
                    Text(order.formattedAmount)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("Order Date")
                    Spacer()
                    Text(formatDate(order.createdAt))
                        .foregroundColor(.secondary)
                }
            }

            if let items = order.items, !items.isEmpty {
                Section("Items") {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemType.capitalized)
                                .font(.headline)

                            Text("Quantity: \(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Text(item.qrTagId == nil ? "QR Tag pending" : "QR Tag assigned")
                                        .font(.caption)
                                    .foregroundColor(item.qrTagId == nil ? .orange : .blue)

                                Spacer()

                                Text(formatCurrency(item.price))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .adaptiveList()
    }

    private var statusColor: Color {
        switch order.orderStatus {
        case "completed": return .green
        case "pending": return .orange
        case "failed": return .red
        case "processing": return .blue
        default: return .gray
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .long
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: NSNumber(value: amount)) ?? "GBP \(amount)"
    }
}

#Preview {
    NavigationView {
        OrdersView()
    }
}
