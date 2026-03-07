import Foundation
import Combine
import UserNotifications

/// Service for managing Server-Sent Events (SSE) connections
/// Provides real-time notifications for tag scans, sightings, and pet updates
class SSEService: NSObject, ObservableObject {
    static let shared = SSEService()

    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var lastEvent: String?

    // MARK: - Private Properties
    private let baseURL = "https://api.senra.pet"
    private var urlSession: URLSession?
    private var dataTask: URLSessionDataTask?
    private var buffer = ""
    private var shouldReconnect = true
    private var reconnectTimer: Timer?
    private var watchdogTimer: Timer?
    private let watchdogInterval: TimeInterval = 90.0 // Expect data within 90s (server sends keep-alive pings)
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let baseReconnectDelay: TimeInterval = 1.0 // Start with 1 second
    private var isRefreshingToken = false

    // MARK: - Event Handlers
    var onTagScanned: ((TagScannedEvent) -> Void)?
    var onSightingReported: ((SightingReportedEvent) -> Void)?
    var onPetFound: ((PetFoundEvent) -> Void)?
    var onAlertCreated: ((AlertCreatedEvent) -> Void)?
    var onAlertUpdated: ((AlertUpdatedEvent) -> Void)?
    var onSubscriptionChanged: ((SubscriptionChangedEvent) -> Void)?
    var onReferralUsed: ((ReferralUsedEvent) -> Void)?
    var onConnected: ((ConnectionEvent) -> Void)?

    // MARK: - Initialization
    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Connect to SSE endpoint
    func connect() {
        #if DEBUG
        print("🔌 SSEService: Attempting to connect...")
        #endif

        shouldReconnect = true

        guard let token = KeychainService.shared.getAuthToken() else {
            #if DEBUG
            print("❌ SSEService: No auth token available")
            #endif
            connectionError = "Authentication required"
            return
        }

        guard let url = URL(string: "\(baseURL)/api/sse/events") else {
            #if DEBUG
            print("❌ SSEService: Invalid URL")
            #endif
            connectionError = "Invalid server URL"
            return
        }

        // Disconnect existing connection
        disconnect()

        // Configure URLSession
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval.infinity
        configuration.timeoutIntervalForResource = TimeInterval.infinity
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

        // Create request
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"

        // Start connection
        dataTask = urlSession?.dataTask(with: request)
        dataTask?.resume()

        #if DEBUG
        print("✅ SSEService: Connection initiated")
        #endif
    }

    /// Disconnect from SSE endpoint
    func disconnect() {
        #if DEBUG
        print("🔌 SSEService: Disconnecting...")
        #endif

        shouldReconnect = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        watchdogTimer?.invalidate()
        watchdogTimer = nil
        dataTask?.cancel()
        dataTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        buffer = ""
        isConnected = false
        reconnectAttempts = 0

        #if DEBUG
        print("✅ SSEService: Disconnected")
        #endif
    }

    /// Manually trigger reconnection
    func reconnect() {
        #if DEBUG
        print("🔄 SSEService: Manual reconnect triggered")
        #endif

        reconnectAttempts = 0
        connect()
    }

    #if DEBUG
    /// Reset state for tests to avoid cross-test contamination.
    func resetForTesting() {
        disconnect()
        connectionError = nil
        lastEvent = nil
        shouldReconnect = true
        reconnectAttempts = 0
    }
    #endif

    // MARK: - Private Methods

    /// Handle a 401 response by refreshing the token before reconnecting.
    /// If the refresh fails, stop reconnecting to avoid an infinite loop with expired credentials.
    private func handleUnauthorized() {
        guard !isRefreshingToken else {
            #if DEBUG
            print("⏳ SSEService: Token refresh already in progress, skipping")
            #endif
            return
        }

        isRefreshingToken = true

        Task { [weak self] in
            defer { self?.isRefreshingToken = false }

            let refreshSucceeded = await APIService.shared.attemptTokenRefresh()

            guard let self = self else { return }

            if refreshSucceeded {
                #if DEBUG
                print("✅ SSEService: Token refreshed successfully, reconnecting")
                #endif

                // Reset reconnect attempts since this is not a connectivity issue
                self.reconnectAttempts = 0
                DispatchQueue.main.async {
                    self.connect()
                }
            } else {
                #if DEBUG
                print("❌ SSEService: Token refresh failed — stopping reconnection")
                #endif

                DispatchQueue.main.async {
                    self.shouldReconnect = false
                    self.isConnected = false
                    self.connectionError = "Authentication expired. Please log in again."
                }
            }
        }
    }

    /// Resets the watchdog timer. Called each time data is received.
    /// If no data arrives within `watchdogInterval`, the connection is assumed dead
    /// and a reconnect is triggered.
    private func resetWatchdog() {
        watchdogTimer?.invalidate()
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: watchdogInterval, repeats: false) { [weak self] _ in
            guard let self = self, self.shouldReconnect else { return }
            #if DEBUG
            print("⏰ SSEService: Watchdog timeout — no data received in \(self.watchdogInterval)s, reconnecting")
            #endif
            DispatchQueue.main.async {
                self.isConnected = false
                self.connectionError = "Connection stale — reconnecting"
            }
            self.dataTask?.cancel()
            self.dataTask = nil
            self.scheduleReconnect()
        }
    }

    private func scheduleReconnect() {
        guard shouldReconnect && reconnectAttempts < maxReconnectAttempts else {
            #if DEBUG
            print("❌ SSEService: Max reconnection attempts reached")
            #endif
            connectionError = "Connection failed after multiple attempts"
            return
        }

        reconnectAttempts += 1

        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        let delay = baseReconnectDelay * pow(2.0, Double(reconnectAttempts - 1))

        #if DEBUG
        print("⏱️ SSEService: Scheduling reconnect attempt \(reconnectAttempts) in \(delay)s")
        #endif

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }

    private func processBuffer() {
        let lines = buffer.components(separatedBy: "\n")
        var event = ""
        var data = ""

        for line in lines {
            if line.isEmpty {
                // Empty line signals end of event
                if !event.isEmpty && !data.isEmpty {
                    handleEvent(type: event, data: data)
                    event = ""
                    data = ""
                }
            } else if line.hasPrefix("event:") {
                event = line.replacingOccurrences(of: "event:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                let lineData = line.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)
                if !data.isEmpty {
                    data += "\n"
                }
                data += lineData
            } else if line.hasPrefix(":") {
                // Comment line (keep-alive ping)
                #if DEBUG
                print("💓 SSEService: Keep-alive ping received")
                #endif
            }
        }

        // Keep any incomplete data in buffer
        if let lastLine = lines.last, !lastLine.isEmpty {
            buffer = lastLine
        } else {
            buffer = ""
        }
    }

    private func handleEvent(type: String, data: String) {
        #if DEBUG
        print("📨 SSEService: Received event type: \(type)")
        #endif

        DispatchQueue.main.async { [weak self] in
            self?.lastEvent = type
        }

        guard let jsonData = data.data(using: .utf8) else {
            #if DEBUG
            print("❌ SSEService: Failed to convert data to JSON")
            #endif
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            switch type {
            case "connected":
                let event = try decoder.decode(ConnectionEvent.self, from: jsonData)
                DispatchQueue.main.async { [weak self] in
                    self?.isConnected = true
                    self?.connectionError = nil
                    self?.reconnectAttempts = 0
                    self?.onConnected?(event)
                }
                #if DEBUG
                print("✅ SSEService: Connected successfully")
                #endif

            case "tag_scanned":
                let event = try decoder.decode(TagScannedEvent.self, from: jsonData)
                DispatchQueue.main.async { [weak self] in
                    self?.onTagScanned?(event)
                }
                showNotification(
                    title: "\(event.petName) Found!",
                    body: "Someone scanned your pet's tag at \(event.address ?? "an unknown location")"
                )

            case "sighting_reported":
                let event = try decoder.decode(SightingReportedEvent.self, from: jsonData)
                DispatchQueue.main.async { [weak self] in
                    self?.onSightingReported?(event)
                }
                showNotification(
                    title: "\(event.petName) Sighted!",
                    body: "Someone reported seeing your pet\(event.address != nil ? " at \(event.address!)" : "")"
                )

            case "pet_found":
                let event = try decoder.decode(PetFoundEvent.self, from: jsonData)
                DispatchQueue.main.async { [weak self] in
                    self?.onPetFound?(event)
                }
                showNotification(
                    title: "Great News!",
                    body: "\(event.petName) has been found!"
                )

            case "alert_created":
                let event = try decoder.decode(AlertCreatedEvent.self, from: jsonData)
                DispatchQueue.main.async { [weak self] in
                    self?.onAlertCreated?(event)
                }

            case "alert_updated":
                let event = try decoder.decode(AlertUpdatedEvent.self, from: jsonData)
                DispatchQueue.main.async { [weak self] in
                    self?.onAlertUpdated?(event)
                }

            case "subscription_changed":
                let event = try decoder.decode(SubscriptionChangedEvent.self, from: jsonData)
                DispatchQueue.main.async { [weak self] in
                    self?.onSubscriptionChanged?(event)
                }
                showNotification(
                    title: NSLocalizedString("sse_subscription_title", comment: ""),
                    body: String(format: NSLocalizedString("sse_subscription_message", comment: ""), event.planName, event.status)
                )

            case "referral_used":
                let event = try decoder.decode(ReferralUsedEvent.self, from: jsonData)
                DispatchQueue.main.async { [weak self] in
                    self?.onReferralUsed?(event)
                }
                showNotification(
                    title: NSLocalizedString("sse_referral_title", comment: ""),
                    body: String(format: NSLocalizedString("sse_referral_message", comment: ""), event.refereeName ?? event.refereeEmail ?? "Someone")
                )

            default:
                #if DEBUG
                print("⚠️ SSEService: Unknown event type: \(type)")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ SSEService: Failed to decode event: \(error)")
            #endif
        }
    }

    private func showNotification(title: String, body: String) {
        // Request notification permission if not already granted
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )

                UNUserNotificationCenter.current().add(request) { error in
                    #if DEBUG
                    if let error = error {
                        print("❌ SSEService: Failed to show notification: \(error)")
                    } else {
                        print("✅ SSEService: Notification shown")
                    }
                    #endif
                }
            }
        }
    }
}

// MARK: - URLSessionDelegate (Certificate Pinning)
extension SSEService: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Delegate certificate pinning to CertificatePinningService
        CertificatePinningService.shared.urlSession(
            session,
            didReceive: challenge,
            completionHandler: completionHandler
        )
    }
}

// MARK: - URLSessionDataDelegate
extension SSEService: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let string = String(data: data, encoding: .utf8) else {
            #if DEBUG
            print("❌ SSEService: Failed to decode data")
            #endif
            return
        }

        buffer += string
        resetWatchdog()
        processBuffer()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            #if DEBUG
            print("❌ SSEService: Connection error: \(error.localizedDescription)")
            #endif

            DispatchQueue.main.async { [weak self] in
                self?.isConnected = false
                self?.connectionError = error.localizedDescription
            }

            // Attempt to reconnect
            scheduleReconnect()
        } else {
            #if DEBUG
            print("✅ SSEService: Connection completed by server")
            #endif

            DispatchQueue.main.async { [weak self] in
                self?.isConnected = false
            }

            // Server closed the connection gracefully — reconnect if we should
            if shouldReconnect {
                scheduleReconnect()
            }
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }

        #if DEBUG
        print("📡 SSEService: HTTP Status: \(httpResponse.statusCode)")
        #endif

        if httpResponse.statusCode == 200 {
            completionHandler(.allow)
        } else if httpResponse.statusCode == 401 {
            #if DEBUG
            print("🔑 SSEService: Received 401 — attempting token refresh before reconnect")
            #endif

            completionHandler(.cancel)
            handleUnauthorized()
        } else {
            #if DEBUG
            print("❌ SSEService: Unexpected status code: \(httpResponse.statusCode)")
            #endif

            DispatchQueue.main.async { [weak self] in
                self?.connectionError = "Server returned status code \(httpResponse.statusCode)"
            }

            completionHandler(.cancel)
            scheduleReconnect()
        }
    }
}
