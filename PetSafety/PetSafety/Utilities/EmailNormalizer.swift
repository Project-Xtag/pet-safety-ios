import Foundation

/// Canonical email normalization for the iOS client.
///
/// Mirrors the backend's `normalizeEmail` (TypeScript) and the Android
/// `EmailNormalizer.normalize`. Trim + lowercase. Apply at every call site
/// that sends an email to the server (login, verify-otp, register) so the
/// same human address always hits the same backend row regardless of how
/// the user typed it.
///
/// Pre-fix, an iOS user logging in on Android with the same address but
/// different casing got a freshly auto-provisioned empty user — the bug
/// behind "I logged in on Android and my pets are gone."
enum EmailNormalizer {
    static func normalize(_ input: String?) -> String {
        guard let input = input else { return "" }
        return input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
