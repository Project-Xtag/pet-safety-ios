import Testing
import Foundation
@testable import PetSafety

/// C1 — 1.1a routing-seam tests.
///
/// ViewInspector-free (§9.1): every assertion runs against the pure
/// `RootRoute.resolve` router and the `RootNavState` value type — plus the real
/// `AuthViewModel` for the logout acceptance check. No SwiftUI introspection.
@Suite("RootRoute / RootNavState — C1 shell routing", .serialized)
@MainActor
struct RootRouteTests {

    // MARK: - Default

    @Test("landingIsDefaultWhenLoggedOut — logged out, no overlay ⇒ .landing")
    func landingIsDefaultWhenLoggedOut() {
        #expect(RootRoute.resolve(isAuthenticated: false, overlay: .none) == .landing)
    }

    // MARK: - Acceptance (verbatim)

    /// [VERBATIM — §4 1.1a] After a real logout the VM is unauthenticated and
    /// the router lands on `.landing` (not `.login`).
    @Test("logoutRoutesToLanding")
    func logoutRoutesToLanding() async {
        let viewModel = AuthViewModel()
        await viewModel.logout()

        #expect(viewModel.isAuthenticated == false)
        #expect(RootRoute.resolve(isAuthenticated: viewModel.isAuthenticated, overlay: .none) == .landing)
    }

    // MARK: - CTA transitions (assert the nav-state closures, not any button)

    /// Renamed from `landingSignInCTAOpensAuth`: asserts the `enterLogin()`
    /// state transition resolves to `.login`. It exercises the closure the
    /// Sign-in CTA is wired to — not a button (there is no view here to tap).
    @Test("enterLoginResolvesToLoginRoute")
    func enterLoginResolvesToLoginRoute() {
        var nav = RootNavState()
        nav.enterLogin()
        #expect(RootRoute.resolve(isAuthenticated: false, overlay: nav.overlay) == .login)
    }

    /// Renamed from `landingRegisterCTAOpensRegistration`: asserts the
    /// `enterRegister()` transition resolves to `.register` — the closure the
    /// Register CTA is wired to, not a button.
    @Test("enterRegisterResolvesToRegisterRoute")
    func enterRegisterResolvesToRegisterRoute() {
        var nav = RootNavState()
        nav.enterRegister()
        #expect(RootRoute.resolve(isAuthenticated: false, overlay: nav.overlay) == .register)
    }

    // MARK: - Back (verbatim)

    /// [VERBATIM — §4 1.1a] Backing out of an auth surface returns to landing.
    @Test("backFromAuthReturnsToLanding")
    func backFromAuthReturnsToLanding() {
        var nav = RootNavState()
        nav.enterRegister()
        nav.dismissAuth()
        #expect(RootRoute.resolve(isAuthenticated: false, overlay: nav.overlay) == .landing)
    }

    // MARK: - Mutual exclusion (semantics guard)

    /// Later intent wins; the "both set" state is unrepresentable by the type,
    /// so this guards precedence-free clearing rather than flag ordering.
    @Test("laterOverlayIntentWins — enterRegister then enterLogin ⇒ .login")
    func laterOverlayIntentWins() {
        var nav = RootNavState()
        nav.enterRegister()
        nav.enterLogin()
        #expect(nav.overlay == .login)
    }

    // MARK: - Stale overlay (new — the bug the inline chain hid)

    /// A register overlay set before authenticating must not survive the
    /// session: `authenticated()` clears it, so a *later* logout resolves to
    /// `.landing`, not `.register`.
    @Test("staleOverlayDoesNotSurviveLogout")
    func staleOverlayDoesNotSurviveLogout() {
        var nav = RootNavState()
        nav.enterRegister()
        #expect(nav.overlay == .register)

        nav.authenticated()               // isAuthenticated flips true ⇒ overlay clears
        #expect(nav.overlay == .none)

        // Later logout: isAuthenticated = false, overlay already cleared.
        #expect(RootRoute.resolve(isAuthenticated: false, overlay: nav.overlay) == .landing)
    }

    // MARK: - Session expiry (verbatim) — drives the real checkAuthStatus bounce

    /// [VERBATIM — §4 1.1a] The mid-session bounce: a stored token ⇒
    /// `checkAuthStatus()` authenticates, then the injected fetch throws ⇒
    /// `logout()` ⇒ `isAuthenticated == false` ⇒ `.landing`.
    ///
    /// Fully hermetic via three defaulted seams on `AuthViewModel`: the gate is
    /// injected (so no global keychain write to race parallel suites), the fetch
    /// throws in-process (no network), and the SSE side-effect is a no-op (no
    /// real connection). Awaits the real bounce task deterministically — the
    /// `.serialized` suite + no keychain write means no flake, no polling.
    @Test("sessionExpiryRoutesToLanding")
    func sessionExpiryRoutesToLanding() async {
        final class Flag: @unchecked Sendable { var value = false }
        let sseFlag = Flag()
        struct ExpiredSession: Error {}

        let viewModel = AuthViewModel(
            hasStoredToken: { true },
            fetchCurrentUser: { throw ExpiredSession() },
            connectSSE: { sseFlag.value = true }
        )

        // checkAuthStatus() set this synchronously in init (authed branch entered).
        #expect(viewModel.isAuthenticated == true)

        // Await the real bounce deterministically — the throwing fetch drives
        // logout(). No polling: authCheckTask is the bounce's completion handle.
        await viewModel.authCheckTask?.value

        #expect(viewModel.isAuthenticated == false)
        #expect(RootRoute.resolve(isAuthenticated: viewModel.isAuthenticated, overlay: .none) == .landing)

        // The eager `async let` still fires the SSE side-effect on the throw
        // path — proving the seam preserves production behavior (Condition A).
        #expect(sseFlag.value, "connectSSE must run eagerly even when the fetch throws")
    }
}
