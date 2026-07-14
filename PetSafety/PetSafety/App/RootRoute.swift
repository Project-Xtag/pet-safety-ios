import Foundation

/// Pure routing seam for the app root (C1 — 1.1a).
///
/// Extracted so the four verbatim acceptance tests are writable *without*
/// ViewInspector (§9.1: SwiftUI view internals are not introspectable). Tests
/// assert on `RootRoute.resolve` + `RootNavState` directly instead of poking at
/// `ContentView.body`.
///
/// This is **branch selection only** — `isAuthenticated` is still derived by
/// `AuthViewModel`, untouched. Nothing here computes or caches auth state.
enum RootRoute: Equatable {
    case main
    case register
    case login
    case landing

    /// Pure router: an authenticated session always resolves to `.main`;
    /// otherwise the logged-out `overlay` selects the surface, defaulting to
    /// `.landing`.
    static func resolve(isAuthenticated: Bool, overlay: AuthOverlay) -> RootRoute {
        if isAuthenticated { return .main }
        switch overlay {
        case .login:    return .login
        case .register: return .register
        case .none:     return .landing
        }
    }
}

/// The logged-out overlay above the landing surface.
///
/// A single enum (not two `Bool`s) makes "login *and* register at once"
/// **unrepresentable** — mutual exclusion holds by construction, not by
/// remembering to clear a second flag.
enum AuthOverlay: Equatable {
    case none
    case login
    case register
}

/// Value-type root nav state, held in `@State` (no `ObservableObject`/Combine).
///
/// `overlay` is `private(set)`: callers transition only through the intent
/// methods, so the illegal "both set" state is never reachable and the last
/// intent always wins.
struct RootNavState: Equatable {
    private(set) var overlay: AuthOverlay = .none

    /// Landing → sign-in surface.
    mutating func enterLogin() { overlay = .login }

    /// Landing → registration surface.
    mutating func enterRegister() { overlay = .register }

    /// Back out of an auth surface, returning to landing.
    mutating func dismissAuth() { overlay = .none }

    /// Clear any pending logged-out overlay because a session just became
    /// active. `ContentView` invokes this when `isAuthenticated` flips true, so
    /// a stale overlay (e.g. from a register attempt) can't survive the
    /// authenticated session and mis-route a *later* logout to `.register`
    /// instead of `.landing` (see `staleOverlayDoesNotSurviveLogout`).
    mutating func authenticated() { overlay = .none }
}
