import os

/// Centralized logging utility. All logging is DEBUG-only by default.
enum AppLogger {
    private static let subsystem = "pet.senra.app"

    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let sse = Logger(subsystem: subsystem, category: "SSE")
    static let sync = Logger(subsystem: subsystem, category: "Sync")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let general = Logger(subsystem: subsystem, category: "General")
}
