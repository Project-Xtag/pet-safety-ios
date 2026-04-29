import XCTest
@testable import PetSafety

/**
 * Regression tests for the SSE subscription-changed handler registry
 * (audit #89).
 *
 * Why this test exists:
 *   Pre-fix `SSEService.shared.onSubscriptionChanged` was a single
 *   closure property. Two `SubscriptionViewModel` instances each
 *   assigned the property in their init; the second assignment
 *   silently overwrote the first, so only the most-recently-instantiated
 *   VM ever saw the SSE event. `deinit` then nilled the slot, also
 *   clobbering whichever other VM was still observing.
 *
 *   Now the service exposes a registry: every observer gets its own
 *   UUID-keyed slot, multiple observers coexist, and each removes its
 *   own handler on deinit without touching others.
 *
 *   These are source-level invariants (we don't drive a real SSE
 *   connection in unit tests) — the goal is to lock the contract so
 *   a refactor cannot regress to the single-callback shape.
 */
final class SubscriptionSSERegistryTests: XCTestCase {

    private func loadSSEServiceSource() throws -> String {
        let testFile = #filePath
        let testDir = (testFile as NSString).deletingLastPathComponent
        let projectRoot = (testDir as NSString).deletingLastPathComponent
        let path = "\(projectRoot)/PetSafety/Services/SSEService.swift"
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    private func loadSubscriptionVMSource() throws -> String {
        let testFile = #filePath
        let testDir = (testFile as NSString).deletingLastPathComponent
        let projectRoot = (testDir as NSString).deletingLastPathComponent
        let path = "\(projectRoot)/PetSafety/ViewModels/SubscriptionViewModel.swift"
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    func testSSEServiceExposesHandlerRegistry() throws {
        let src = try loadSSEServiceSource()
        XCTAssertTrue(
            src.contains("private var subscriptionChangedHandlers: [UUID:"),
            "Registry storage must be a UUID-keyed dictionary so callers can remove their own handler without affecting others (audit #89)"
        )
        XCTAssertTrue(
            src.contains("func addSubscriptionChangedHandler"),
            "Public addSubscriptionChangedHandler API must exist (audit #89)"
        )
        XCTAssertTrue(
            src.contains("func removeSubscriptionChangedHandler"),
            "Public removeSubscriptionChangedHandler API must exist (audit #89)"
        )
    }

    func testSSEServiceFansOutSubscriptionEvents() throws {
        let src = try loadSSEServiceSource()
        // The dispatch site must iterate registered handlers, not call a
        // single closure property. Snapshotting via Array(.values) avoids
        // mutation-during-iteration if a handler removes itself.
        XCTAssertTrue(
            src.contains("Array(self.subscriptionChangedHandlers.values)"),
            "Dispatch must snapshot the values dictionary before iterating (audit #89)"
        )
    }

    func testSSEServiceNoLongerExposesSingleCallbackProperty() throws {
        let src = try loadSSEServiceSource()
        // Make sure the legacy `var onSubscriptionChanged: ((Event) -> Void)?`
        // property has been removed. A drift back to the single-callback
        // pattern is the regression we're locking against.
        XCTAssertFalse(
            src.contains("var onSubscriptionChanged: ((SubscriptionChangedEvent) -> Void)?"),
            "Legacy single-callback property must NOT be re-introduced (audit #89)"
        )
    }

    func testSubscriptionVMUsesRegistryAndStoresToken() throws {
        let src = try loadSubscriptionVMSource()
        XCTAssertTrue(
            src.contains("subscriptionHandlerToken"),
            "SubscriptionViewModel must store the registry token so its deinit can remove ITS handler (audit #89)"
        )
        XCTAssertTrue(
            src.contains("addSubscriptionChangedHandler"),
            "SubscriptionViewModel must register via addSubscriptionChangedHandler (audit #89)"
        )
        XCTAssertTrue(
            src.contains("removeSubscriptionChangedHandler(token)"),
            "SubscriptionViewModel deinit must remove its handler via removeSubscriptionChangedHandler (audit #89)"
        )
    }

    func testSubscriptionVMNoLongerNilsSharedProperty() throws {
        let src = try loadSubscriptionVMSource()
        // The pre-fix deinit did `SSEService.shared.onSubscriptionChanged = nil`
        // which clobbered every other observer. With the registry pattern
        // we only remove our own token.
        XCTAssertFalse(
            src.contains("SSEService.shared.onSubscriptionChanged = nil"),
            "Deinit must not nil the shared service property (audit #89)"
        )
    }
}
