import SwiftUI

/// Visual indicator showing offline/online status and sync information
/// Displays at the top of views to inform users about connectivity and data freshness
struct OfflineIndicator: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var syncService = SyncService.shared
    @State private var isExpanded = false

    var body: some View {
        if !networkMonitor.isConnected || syncService.pendingActionsCount > 0 || isExpanded {
            VStack(spacing: 0) {
                // Main indicator bar
                HStack(spacing: 12) {
                    // Status icon
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                        .font(.system(size: 16, weight: .semibold))

                    // Status text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(statusSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Expand/collapse button
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(backgroundColor)

                // Expanded details
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()

                        // Pending actions
                        if syncService.pendingActionsCount > 0 {
                            HStack {
                                Image(systemName: "tray.full")
                                    .foregroundColor(.orange)
                                Text("\(syncService.pendingActionsCount) action\(syncService.pendingActionsCount == 1 ? "" : "s") queued")
                                    .font(.caption)
                            }
                        }

                        // Last sync time
                        if let lastSync = syncService.lastSyncDate {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                Text("Last synced: \(syncService.timeSinceLastSync)")
                                    .font(.caption)
                            }
                        }

                        // Sync button
                        if networkMonitor.isConnected {
                            Button(action: {
                                Task {
                                    await syncService.performFullSync()
                                }
                            }) {
                                HStack {
                                    if syncService.isSyncing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text(syncService.isSyncing ? "Syncing..." : "Sync Now")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                            }
                            .disabled(syncService.isSyncing)
                        }

                        // Sync status message
                        if !syncService.syncStatus.isEmpty {
                            Text(syncService.syncStatus)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .background(backgroundColor)
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Computed Properties

    private var statusIcon: String {
        if !networkMonitor.isConnected {
            return "wifi.slash"
        } else if syncService.pendingActionsCount > 0 {
            return "tray.full"
        } else if syncService.isSyncing {
            return "arrow.clockwise"
        } else {
            return "checkmark.circle"
        }
    }

    private var statusTitle: String {
        if !networkMonitor.isConnected {
            return "Offline Mode"
        } else if syncService.isSyncing {
            return "Syncing..."
        } else if syncService.pendingActionsCount > 0 {
            return "Pending Changes"
        } else {
            return "Online"
        }
    }

    private var statusSubtitle: String {
        if !networkMonitor.isConnected {
            return "Changes will sync when online"
        } else if syncService.pendingActionsCount > 0 {
            return "Tap to view queued actions"
        } else {
            return networkMonitor.connectionDescription
        }
    }

    private var statusColor: Color {
        if !networkMonitor.isConnected {
            return .red
        } else if syncService.pendingActionsCount > 0 {
            return .orange
        } else {
            return .green
        }
    }

    private var backgroundColor: Color {
        if !networkMonitor.isConnected {
            return Color.red.opacity(0.1)
        } else if syncService.pendingActionsCount > 0 {
            return Color.orange.opacity(0.1)
        } else {
            return Color.green.opacity(0.1)
        }
    }
}

/// Compact version of offline indicator (badge style)
struct OfflineBadge: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var syncService = SyncService.shared

    var body: some View {
        if !networkMonitor.isConnected || syncService.pendingActionsCount > 0 {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                if syncService.pendingActionsCount > 0 {
                    Text("\(syncService.pendingActionsCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private var icon: String {
        if !networkMonitor.isConnected {
            return "wifi.slash"
        } else {
            return "tray.full"
        }
    }

    private var badgeColor: Color {
        if !networkMonitor.isConnected {
            return .red
        } else {
            return .orange
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        OfflineIndicator()
        Spacer()
    }
}
