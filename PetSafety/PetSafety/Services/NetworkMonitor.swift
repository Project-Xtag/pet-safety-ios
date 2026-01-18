import Foundation
import Network
import Combine

/// Monitors network connectivity status and publishes changes
/// Uses NWPathMonitor for robust network detection
@MainActor
class NetworkMonitor: ObservableObject {
    /// Singleton instance for app-wide network monitoring
    static let shared = NetworkMonitor()

    /// Published property indicating if device is currently connected to network
    @Published private(set) var isConnected: Bool = true

    /// Published property indicating the type of connection (wifi, cellular, etc.)
    @Published private(set) var connectionType: NWInterface.InterfaceType?

    /// Published property indicating if connection is expensive (cellular data)
    @Published private(set) var isExpensive: Bool = false

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.petsafety.networkmonitor")

    #if DEBUG
    enum NetworkOverrideMode: String, CaseIterable, Identifiable {
        case system
        case offline
        case online

        var id: String { rawValue }
    }

    @Published var overrideMode: NetworkOverrideMode = .system
    #endif

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    /// Start monitoring network connectivity
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                #if DEBUG
                if self.overrideMode != .system {
                    self.isConnected = self.overrideMode == .online
                    return
                }
                #endif

                self.isConnected = path.status == .satisfied
                self.isExpensive = path.isExpensive

                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wiredEthernet
                } else {
                    self.connectionType = nil
                }

                // Notify about connection change
                NotificationCenter.default.post(
                    name: .networkStatusChanged,
                    object: nil,
                    userInfo: ["isConnected": self.isConnected]
                )
            }
        }

        monitor.start(queue: queue)
    }

    /// Stop monitoring network connectivity
    func stopMonitoring() {
        monitor.cancel()
    }

    /// Returns a user-friendly description of the current connection status
    var connectionDescription: String {
        guard isConnected else {
            return "Offline"
        }

        switch connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return isExpensive ? "Cellular (Limited)" : "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        default:
            return "Online"
        }
    }
}

// MARK: - Protocols
@MainActor
protocol NetworkMonitoring {
    var isConnected: Bool { get }
    var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
}

@MainActor
extension NetworkMonitor: NetworkMonitoring {
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        $isConnected.eraseToAnyPublisher()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
