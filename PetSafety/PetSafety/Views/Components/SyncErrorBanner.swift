import SwiftUI

/// A banner component that displays sync error information and provides retry/dismiss options
struct SyncErrorBanner: View {
    @ObservedObject var syncService: SyncService
    @State private var isExpanded = false

    var body: some View {
        if syncService.failedActionsCount > 0 {
            VStack(spacing: 0) {
                // Main banner
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)

                        Text("\(syncService.failedActionsCount) action\(syncService.failedActionsCount == 1 ? "" : "s") failed to sync")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                }
                .buttonStyle(PlainButtonStyle())

                // Expanded details
                if isExpanded {
                    VStack(spacing: 0) {
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    await syncService.retryAllFailedActions()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry All")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            }

                            Button(action: {
                                syncService.dismissAllFailedActions()
                                withAnimation {
                                    isExpanded = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: "xmark")
                                    Text("Dismiss All")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))

                        // List of failed actions
                        ForEach(syncService.failedActions) { action in
                            SyncErrorRow(
                                action: action,
                                syncService: syncService
                            )
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

/// A row displaying a single failed action with retry/dismiss options
struct SyncErrorRow: View {
    let action: QueuedAction
    @ObservedObject var syncService: SyncService
    @State private var isRetrying = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(syncService.actionTypeDescription(action.type))
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let errorMessage = action.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text("Tried \(action.retryCount) time\(action.retryCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                // Retry button
                Button(action: {
                    isRetrying = true
                    Task {
                        await syncService.retryFailedAction(action)
                        isRetrying = false
                    }
                }) {
                    if isRetrying {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.orange)
                    }
                }
                .disabled(isRetrying)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)

                // Dismiss button
                Button(action: {
                    syncService.dismissFailedAction(action)
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .frame(width: 32, height: 32)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))

        Divider()
            .padding(.leading, 16)
    }
}

/// A compact sync status indicator for use in navigation bars or toolbars
struct SyncStatusIndicator: View {
    @ObservedObject var syncService: SyncService

    var body: some View {
        HStack(spacing: 6) {
            if syncService.isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Syncing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if syncService.failedActionsCount > 0 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("\(syncService.failedActionsCount) failed")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if syncService.pendingActionsCount > 0 {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text("\(syncService.pendingActionsCount) pending")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
}

#Preview("Banner with errors") {
    VStack {
        SyncErrorBanner(syncService: SyncService.shared)
        Spacer()
    }
}

#Preview("Status indicator") {
    SyncStatusIndicator(syncService: SyncService.shared)
}
