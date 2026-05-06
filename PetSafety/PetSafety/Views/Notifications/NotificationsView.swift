import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()

    var body: some View {
        ZStack {
            if viewModel.notifications.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                List {
                    ForEach(viewModel.notifications) { notification in
                        NotificationRow(notification: notification) {
                            if !notification.isRead {
                                Task { await viewModel.markAsRead(notification.id) }
                            }
                        }
                        .listRowBackground(
                            notification.isRead ? Color.clear : Color.blue.opacity(0.05)
                        )
                    }

                    if viewModel.hasMore {
                        Button {
                            Task { await viewModel.loadMore() }
                        } label: {
                            Text("load_more")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.brandOrange)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(Text("notifications_title"))
        .toolbar {
            if viewModel.unreadCount > 0 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.markAllAsRead() }
                    } label: {
                        Text("mark_all_read")
                            .font(.caption)
                            .foregroundColor(.brandOrange)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchNotifications()
            await viewModel.fetchUnreadCount()
        }
        .refreshable {
            await viewModel.fetchNotifications()
            await viewModel.fetchUnreadCount()
        }
        .overlay {
            if viewModel.isLoading && viewModel.notifications.isEmpty {
                ProgressView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("no_notifications")
                .font(.title2)
                .fontWeight(.bold)
            Text("no_notifications_desc")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NotificationRow: View {
    let notification: NotificationItem
    let onTap: () -> Void
    @State private var expanded = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName(for: notification.type))
                .font(.system(size: 16))
                .foregroundColor(iconColor(for: notification.type))
                .frame(width: 36, height: 36)
                .background(iconColor(for: notification.type).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .regular : .bold)

                    Spacer()

                    if !notification.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }

                // Body collapses to 2 lines by default; tapping the row
                // toggles the full text — previously the row only ever
                // showed the truncated preview and the user couldn't read
                // the rest.
                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(expanded ? nil : 2)
                    .fixedSize(horizontal: false, vertical: expanded)

                Text(formatDate(notification.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
            onTap()
        }
    }

    private func iconName(for type: String) -> String {
        switch type {
        case "tag_scanned": return "tag.fill"
        case "sighting_reported": return "eye.fill"
        case "pet_found": return "pawprint.fill"
        case "missing_pet_alert": return "exclamationmark.triangle.fill"
        case "subscription_activated", "subscription_cancelled": return "star.fill"
        case "referral_used", "referral_reward": return "person.2.fill"
        default: return "bell.fill"
        }
    }

    private func iconColor(for type: String) -> Color {
        switch type {
        case "tag_scanned": return .blue
        case "sighting_reported": return .orange
        case "pet_found": return .green
        case "missing_pet_alert": return .red
        case "subscription_activated", "subscription_cancelled": return .orange
        case "referral_used", "referral_reward": return .teal
        default: return .gray
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        let now = Date()
        let diff = now.timeIntervalSince(date)
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        if minutes < 1 { return String(localized: "just_now") }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}
