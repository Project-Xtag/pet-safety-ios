import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    @State private var selectedTab = 0
    // Re-fetch orders on foreground so a status flip (e.g. admin
    // marked the order shipped while the user had the app
    // backgrounded) shows up the next time they look. The nested
    // PendingRegistrationsView observes scenePhase too, so its list
    // wakes up alongside this one.
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text(String(localized: "orders_title")).tag(0)
                Text(String(localized: "pending_registrations_title")).tag(1)
                Text(String(localized: "billing_invoices")).tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch selectedTab {
            case 0:
                ordersContent
            case 1:
                PendingRegistrationsView()
            case 2:
                InvoicesView()
            default:
                ordersContent
            }
        }
        .navigationTitle(Text("profile_orders_invoices"))
        .task {
            await viewModel.fetchOrders()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await viewModel.fetchOrders() }
            }
        }
    }

    private var ordersContent: some View {
        // Three states share one container so `.refreshable` works in
        // every branch — empty-state and error-state used to be plain
        // VStacks where pull-to-refresh silently no-ops. The wrapping
        // List + listRowSeparator(.hidden) trick keeps the empty UI
        // visually centered while remaining a refreshable scroll view.
        List {
            if let error = viewModel.errorMessage, viewModel.orders.isEmpty {
                // Error state. Previously the same case rendered as
                // "no orders" — a transient 5xx or token-refresh race
                // on the initial fetch silently looked identical to
                // the legitimate empty state, leaving the user with
                // no signal that anything was wrong and no way to
                // retry short of backgrounding + foregrounding the
                // app.
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text(error)
                        .font(.appFont(.subheadline))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button {
                        Task { await viewModel.fetchOrders() }
                    } label: {
                        Text("retry")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.brandOrange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 320)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else if viewModel.orders.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "cart.fill",
                    title: String(localized: "orders_no_orders"),
                    message: String(localized: "orders_no_orders_message")
                )
                .frame(maxWidth: .infinity, minHeight: 320)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.orders) { order in
                    NavigationLink(destination: OrderDetailView(order: order)) {
                        OrderRowView(order: order)
                    }
                }
            }
        }
        .listStyle(.inset)
        .adaptiveList()
        .refreshable {
            await viewModel.fetchOrders()
        }
        .overlay {
            if viewModel.isLoading && viewModel.orders.isEmpty {
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
                Text("order_number \(order.id)")
                    .font(.appFont(.headline))

                Spacer()

                Text(order.formattedAmount)
                    .font(.appFont(.headline))
                    .foregroundColor(.primary)
            }

            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(localizedStatus(order.orderStatus))
                    .font(.appFont(.subheadline))
                    .foregroundColor(statusColor)

                Spacer()

                Text(formatDate(order.createdAt))
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
            }

            if order.orderStatus == "shipped" && order.mplTrackingNumber != nil {
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill")
                        .font(.appFont(.caption))
                        .foregroundColor(.brandOrange)
                    Text("track_package")
                        .font(.appFont(.caption))
                        .foregroundColor(.brandOrange)
                }
            }

            if let items = order.items, !items.isEmpty {
                let totalItems = items.reduce(0) { $0 + $1.quantity }
                Text(String(localized: "orders_item_count \(totalItems)"))
                    .font(.appFont(.caption))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func localizedStatus(_ status: String) -> String {
        switch status {
        case "completed": return String(localized: "order_status_completed")
        case "pending": return String(localized: "order_status_pending")
        case "failed": return String(localized: "order_status_failed")
        case "processing": return String(localized: "order_status_processing")
        case "shipped": return String(localized: "order_status_shipped")
        case "delivered": return String(localized: "order_status_delivered")
        case "cancelled": return String(localized: "order_status_cancelled")
        default: return status.capitalized
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        // Fixed yyyy.MM.dd. across every locale — unambiguous,
        // sortable, matches the HU convention the product uses
        // everywhere else. en_US_POSIX locks the pattern against
        // the user's calendar/locale settings overriding it.
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "en_US_POSIX")
        displayFormatter.dateFormat = "yyyy.MM.dd."
        return displayFormatter.string(from: date)
    }
}

struct OrderDetailView: View {
    let order: Order

    var body: some View {
        List {
            Section(header: Text("orders_information")) {
                HStack {
                    Text("orders_order_id")
                    Spacer()
                    Text("#\(order.id)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("orders_status")
                    Spacer()
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                Text(localizedStatus(order.orderStatus))
                            .foregroundColor(statusColor)
                    }
                }

                HStack {
                    Text("orders_total_amount")
                    Spacer()
                    Text(order.formattedAmount)
                        .fontWeight(.bold)
                }

                HStack {
                    Text("orders_order_date")
                    Spacer()
                    Text(formatDate(order.createdAt))
                        .foregroundColor(.secondary)
                }
            }

            if order.mplTrackingNumber != nil {
                Section(header: Text("shipping_section_title")) {
                    HStack {
                        Text("tracking_number_label")
                        Spacer()
                        Text(order.mplTrackingNumber ?? "")
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                    }

                    // 2026-05-06: dropped the "Track package" deep link.
                    // The MPL international tracking page returned 404
                    // on fresh tracking numbers and confused users — we
                    // keep the tracking number visible so they can paste
                    // it into whichever carrier site fits their region.

                    if let method = order.deliveryMethod {
                        HStack {
                            Text("delivery_method_label")
                            Spacer()
                            Text(method == "postapoint" ? String(localized: "delivery_postapoint") : String(localized: "delivery_home"))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if let items = order.items, !items.isEmpty {
                Section(header: Text("orders_items")) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemType.capitalized)
                                .font(.appFont(.headline))

                            Text("orders_quantity \(item.quantity)")
                                .font(.appFont(.subheadline))
                                .foregroundColor(.secondary)

                            HStack {
                                Text(item.qrTagId == nil ? String(localized: "orders_tag_pending") : String(localized: "orders_tag_assigned"))
                                        .font(.appFont(.caption))
                                    .foregroundColor(item.qrTagId == nil ? .orange : .blue)

                                Spacer()

                                Text(formatCurrency(item.price))
                                    .font(.appFont(.subheadline))
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(Text("orders_detail_title"))
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

        // Same fixed yyyy.MM.dd. format as the orders list — no time
        // shown. The detail view used to include HH:mm but the order
        // timestamp is the placement moment, which isn't useful at
        // minute granularity.
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "en_US_POSIX")
        displayFormatter.dateFormat = "yyyy.MM.dd."
        return displayFormatter.string(from: date)
    }

    private func localizedStatus(_ status: String) -> String {
        switch status {
        case "completed": return String(localized: "order_status_completed")
        case "pending": return String(localized: "order_status_pending")
        case "failed": return String(localized: "order_status_failed")
        case "processing": return String(localized: "order_status_processing")
        case "shipped": return String(localized: "order_status_shipped")
        case "delivered": return String(localized: "order_status_delivered")
        case "cancelled": return String(localized: "order_status_cancelled")
        default: return status.capitalized
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter.string(from: NSNumber(value: amount)) ?? "€\(amount)"
    }
}

#Preview {
    NavigationView {
        OrdersView()
    }
}
