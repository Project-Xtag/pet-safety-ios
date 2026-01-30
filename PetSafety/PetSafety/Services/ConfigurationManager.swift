import Foundation
import FirebaseCore
import FirebaseAppCheck
import FirebaseRemoteConfig

/**
 * ConfigurationManager - Centralized configuration management
 *
 * Responsibilities:
 * - Configure Firebase App Check for API protection
 * - Fetch runtime configuration from Firebase Remote Config
 * - Provide cached access to sensitive config values (Sentry DSN, API URLs)
 *
 * Usage:
 * 1. Call `ConfigurationManager.configureAppCheck()` BEFORE `FirebaseApp.configure()`
 * 2. After Firebase init, call `ConfigurationManager.shared.fetchConfiguration()`
 * 3. Access config values via `ConfigurationManager.shared.sentryDSN`, etc.
 */
final class ConfigurationManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ConfigurationManager()

    // MARK: - Published Configuration Values

    /// Sentry DSN for error tracking (empty string if not configured)
    @Published private(set) var sentryDSN: String = ""

    /// API base URL for backend requests
    @Published private(set) var apiBaseURL: String = "https://pet-er.app/api"

    /// SSE base URL for real-time events
    @Published private(set) var sseBaseURL: String = "https://pet-er.app"

    // MARK: - Private Properties

    private let remoteConfig: RemoteConfig
    private var isConfigured = false

    /// Default values used when Remote Config is unavailable
    private let defaults: [String: NSObject] = [
        "sentry_dsn_ios": "" as NSObject,
        "api_base_url": "https://pet-er.app/api" as NSObject,
        "sse_base_url": "https://pet-er.app" as NSObject
    ]

    // MARK: - Initialization

    private init() {
        remoteConfig = RemoteConfig.remoteConfig()

        // Configure fetch settings
        let settings = RemoteConfigSettings()
        #if DEBUG
        // Fetch immediately in debug mode for testing
        settings.minimumFetchInterval = 0
        #else
        // Cache for 1 hour in production
        settings.minimumFetchInterval = 3600
        #endif
        remoteConfig.configSettings = settings

        // Set default values for offline/fallback scenarios
        remoteConfig.setDefaults(defaults)
    }

    // MARK: - App Check Configuration

    /**
     * Configure Firebase App Check
     *
     * IMPORTANT: This MUST be called BEFORE `FirebaseApp.configure()`
     *
     * In Debug builds, uses the debug provider (works on simulator).
     * In Release builds, uses DeviceCheck (requires physical device).
     */
    static func configureAppCheck() {
        #if DEBUG
        // Debug provider for simulator and development
        let providerFactory = AppCheckDebugProviderFactory()
        print("[ConfigurationManager] Using App Check debug provider")
        #else
        // DeviceCheck provider for production (physical devices only)
        let providerFactory = DeviceCheckProviderFactory()
        print("[ConfigurationManager] Using App Check DeviceCheck provider")
        #endif

        AppCheck.setAppCheckProviderFactory(providerFactory)
    }

    // MARK: - Remote Config

    /**
     * Fetch configuration from Firebase Remote Config
     *
     * Call this after Firebase is initialized. Safe to call multiple times.
     * Uses cached values if fetch fails or is rate-limited.
     */
    func fetchConfiguration() async throws {
        do {
            // Fetch and activate remote config
            let status = try await remoteConfig.fetch()

            if status == .success {
                try await remoteConfig.activate()
                #if DEBUG
                print("[ConfigurationManager] Remote Config fetched and activated")
                #endif
            } else {
                #if DEBUG
                print("[ConfigurationManager] Remote Config fetch status: \(status)")
                #endif
            }

            updateConfigValues()
            isConfigured = true

        } catch {
            #if DEBUG
            print("[ConfigurationManager] Remote Config fetch failed: \(error)")
            #endif

            // Use cached/default values on failure
            updateConfigValues()
            throw error
        }
    }

    /**
     * Update local properties from Remote Config values
     */
    private func updateConfigValues() {
        // Sentry DSN
        let dsn = remoteConfig["sentry_dsn_ios"].stringValue
        if !dsn.isEmpty {
            sentryDSN = dsn
        }

        // API Base URL
        let apiURL = remoteConfig["api_base_url"].stringValue
        if !apiURL.isEmpty {
            apiBaseURL = apiURL
        }

        // SSE Base URL
        let sseURL = remoteConfig["sse_base_url"].stringValue
        if !sseURL.isEmpty {
            sseBaseURL = sseURL
        }

        #if DEBUG
        print("[ConfigurationManager] Config values updated:")
        print("  - sentryDSN: \(sentryDSN.isEmpty ? "(not configured)" : "(configured)")")
        print("  - apiBaseURL: \(apiBaseURL)")
        print("  - sseBaseURL: \(sseBaseURL)")
        #endif
    }

    // MARK: - App Check Token

    /**
     * Get a Firebase App Check token for backend API calls
     *
     * The token should be included in the `X-Firebase-AppCheck` header
     * for requests to protected backend endpoints.
     *
     * Returns nil if App Check is not available or token retrieval fails.
     */
    func getAppCheckToken() async -> String? {
        do {
            let token = try await AppCheck.appCheck().token(forcingRefresh: false)
            return token.token
        } catch {
            #if DEBUG
            print("[ConfigurationManager] Failed to get App Check token: \(error)")
            #endif
            return nil
        }
    }

    /**
     * Get a fresh App Check token (forces refresh)
     *
     * Use this if a request fails with an invalid token error.
     */
    func getAppCheckTokenForced() async -> String? {
        do {
            let token = try await AppCheck.appCheck().token(forcingRefresh: true)
            return token.token
        } catch {
            #if DEBUG
            print("[ConfigurationManager] Failed to force refresh App Check token: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Status

    /**
     * Check if configuration has been fetched at least once
     */
    var isReady: Bool {
        return isConfigured
    }
}
