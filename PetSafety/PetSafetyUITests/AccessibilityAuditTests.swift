//
//  AccessibilityAuditTests.swift
//  PetSafetyUITests
//
//  H65 chunk 3 — runs Apple's `XCUIApplication.performAccessibilityAudit()`
//  (iOS 17+) against the launched app. The audit covers Apple's WCAG-style
//  automated checks: missing accessibility labels, hit-region size, dynamic
//  type compliance, contrast, element traits.
//
//  This is a smoke baseline — it audits the screen the user sees on launch
//  (auth/login). To extend per-screen coverage, drive navigation in the test
//  before calling `performAccessibilityAudit()`. We deliberately keep the
//  surface small here so the test runs in CI without flakiness from real
//  network/login flows; the full per-flow audit is a follow-up workstream.
//

import XCTest

@available(iOS 17.0, *)
final class AccessibilityAuditTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Audit categories Apple ships in the framework. We exclude
    /// `.dynamicType` from the launch-screen audit because the splash/auth
    /// view uses fixed-size logo art that does not (and should not) scale —
    /// scaling app branding breaks layout. Re-enable once we add per-screen
    /// audits for the main TabView, where dynamic-type matters.
    private var auditTypes: XCUIAccessibilityAuditType {
        var types: XCUIAccessibilityAuditType = .all
        types.remove(.dynamicType)
        return types
    }

    @MainActor
    func testLaunchScreenPassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTesting")
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // Let the SwiftUI tree settle. Without this we audit the splash
        // before the auth view paints, which gives noisy false negatives.
        let firstInteractive = app.buttons.firstMatch
        _ = firstInteractive.waitForExistence(timeout: 5)

        try app.performAccessibilityAudit(for: auditTypes) { issue in
            // Return `true` to ignore. We currently ignore nothing — every
            // automatically-detected issue should fail the test, and we fix
            // it at the source. If we ever need to allow one through, do it
            // with a narrowly scoped reason (element + audit type) so it's
            // searchable in the codebase.
            return false
        }
    }
}
