//
//  PetSafetyUITests.swift
//  PetSafetyUITests
//
//  Created by Viktor Szasz on 02/11/2025.
//

import XCTest

final class PetSafetyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }
}
