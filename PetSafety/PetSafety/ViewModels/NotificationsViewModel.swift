import Foundation

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var isLoading = false
    @Published var unreadCount = 0
    @Published var hasMore = true

    private let apiService = APIService.shared
    private var currentPage = 1

    func fetchNotifications() async {
        isLoading = true
        currentPage = 1
        do {
            let response = try await apiService.getNotifications(page: 1, limit: 20)
            notifications = response.notifications
            hasMore = response.pagination.page < response.pagination.totalPages
        } catch {
            notifications = []
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        currentPage += 1
        do {
            let response = try await apiService.getNotifications(page: currentPage, limit: 20)
            notifications += response.notifications
            hasMore = response.pagination.page < response.pagination.totalPages
        } catch {
            currentPage -= 1
        }
    }

    func fetchUnreadCount() async {
        do {
            unreadCount = try await apiService.getUnreadNotificationCount()
        } catch {}
    }

    func markAsRead(_ id: String) async {
        do {
            try await apiService.markNotificationAsRead(id)
            if let index = notifications.firstIndex(where: { $0.id == id }) {
                let old = notifications[index]
                let updated = NotificationItem(id: old.id, type: old.type, title: old.title, body: old.body, isRead: true, createdAt: old.createdAt)
                notifications[index] = updated
                unreadCount = max(0, unreadCount - 1)
            }
        } catch {}
    }

    func markAllAsRead() async {
        do {
            try await apiService.markAllNotificationsAsRead()
            notifications = notifications.map { old in
                NotificationItem(id: old.id, type: old.type, title: old.title, body: old.body, isRead: true, createdAt: old.createdAt)
            }
            unreadCount = 0
        } catch {}
    }
}
