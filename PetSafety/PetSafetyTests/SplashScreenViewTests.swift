import Testing
import SwiftUI
import UIKit
@testable import PetSafety

/// Smoke coverage for the C0 splash.
///
/// There is no ViewInspector in this project, so a SwiftUI view's body and
/// `.onAppear` aren't introspectable in a unit test. These pin only the
/// contract surfaces the splash must not break; the entrance animation, the
/// hold timing, and the actual splash→content handoff are visual-QA, not
/// asserted here.
@Suite("SplashScreenView (C0)")
struct SplashScreenViewTests {

    /// The host-app bundle, where the asset catalogs compile to. The test target
    /// is app-hosted (`TEST_HOST`), so an app `class` resolves to that bundle.
    private static let appBundle = Bundle(for: KeychainService.self)

    @Test("holdDuration constant equals 2.0s — pins the value only, not that the view waits that long")
    func holdDurationConstantIsTwoSeconds() {
        // Asserts only the constant's value. That the view actually holds this
        // long before calling onFinished is timing behaviour, covered by visual
        // QA — not provable here without a rendered host.
        #expect(SplashScreenView.holdDuration == 2.0)
    }

    @Test("onFinished is a stored, callable closure — API-shape guard only")
    func onFinishedIsAStoredCallableClosure() {
        // Guards the initializer / stored-property shape: constructing the view
        // with a closure and invoking the STORED closure runs it. This does NOT
        // prove the splash's own `.onAppear` invokes it after the hold — that
        // path needs a rendered host (visual QA / a UI test), not a unit test.
        var invoked = false
        let sut = SplashScreenView(onFinished: { invoked = true })
        sut.onFinished()
        #expect(invoked)
    }

    @Test("the splash mark asset (LaunchLogo) exists in the compiled catalog")
    func splashMarkAssetExists() {
        // The splash draws the language-neutral brushstroke "X" mark `LaunchLogo`
        // (the localized `LogoNew_*` lockups live on the content screens, not
        // here). Fails if the asset is renamed or removed.
        let image = UIImage(named: "LaunchLogo", in: Self.appBundle, compatibleWith: nil)
        #expect(image != nil, "Missing splash mark asset: LaunchLogo")
    }
}
