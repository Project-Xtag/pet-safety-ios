import Foundation

/// Builds web URLs for the HU market.
///
/// **The country segment is the literal `hu`, and it must stay a literal.** The
/// apps are distributed in the Hungarian store only, so every mobile user is an
/// HU-market customer by construction — HUF pricing, Kedvenc csomag, the HU
/// catalog. Deriving the segment from device region is the `/uk/` bug: a
/// Hungarian customer on an English-region phone is an HU customer, not a UK
/// one, and the segment decides which market's prices they are shown.
///
/// Device region is a *language* signal, never a market one. `Locale.current`
/// must not appear in this file: `.language` is permitted elsewhere for
/// `locale_hint`, `.region` is banned outright in the URL-building path, and
/// the two are one word apart. See `WEB-HANDOFF-CONTRACT.md` §3 and §5.
///
/// If mobile ever ships outside HU, market resolution becomes a *server-side*
/// chain reached through the handoff endpoint — not a lookup reintroduced here.
/// That is the whole reason the URL is built on the server and this helper is
/// only the fallback path.
enum WebURLHelper {
    /// Web app host for the active build configuration.
    ///
    /// Mirrors `apiBaseURL`'s mechanism exactly: `WEB_BASE_URL` is injected by
    /// the active xcconfig into `Info.plist`, and falls back to prod when the
    /// key is missing or still holds an unresolved `$(...)`.
    ///
    /// ⚠️ Staging carries the `-app` prefix and prod does **not**. That
    /// asymmetry is deliberate and is not a typo — `app.senra.pet` has no DNS
    /// record of any type, so a build pointed there would open a dead host with
    /// no way to recover.
    ///
    /// `bundle` is a defaulted seam so tests can supply a fake; every call site
    /// uses the default.
    static func host(bundle: Bundle = .main) -> String {
        ConfigurationManager.infoPlistURL("WEB_BASE_URL", fallback: "https://senra.pet", bundle: bundle)
    }

    /// Builds `{host}/hu{path}`. The `hu` is a literal — see the type comment.
    ///
    /// ⚠️ **The force-unwrap is total only for literal call-site paths.** The
    /// fallback string is not fully literal — it interpolates `clean`. Every
    /// caller today passes a hardcoded path (`"/choose-plan"`,
    /// `"/terms-conditions"`, `"/privacy-policy"`), so no input can make
    /// `URL(string:)` return nil and the unwrap is unreachable. The fallback
    /// exists because `host` became configuration-driven, which introduced a nil
    /// case a hardcoded host did not have.
    ///
    /// **Before passing the first DYNAMIC path here** — a pet id, a slug, any
    /// server-supplied string — percent-encode it, or change this to return
    /// `URL?`. A character that is invalid in a URL path would make both
    /// expressions nil and crash a money-path call site.
    static func url(path: String, bundle: Bundle = .main) -> URL {
        let clean = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: "\(host(bundle: bundle))/hu\(clean)")
            ?? URL(string: "https://senra.pet/hu\(clean)")!
    }

    static var termsURL: URL { url(path: "/terms-conditions") }
    static var privacyURL: URL { url(path: "/privacy-policy") }

    /// Country codes that may appear as a path prefix on an **inbound** universal
    /// link, e.g. `/hu/qr/ABC`.
    ///
    /// This is parsing what the server sent us — a different concern from
    /// choosing a market, and the only one that legitimately needs a set of
    /// codes. Its two consumers are both in `DeepLinkService`, stripping the
    /// prefix before routing. Do not reuse it to build an outbound URL.
    static let validCountryCodes: Set<String> = [
        "uk", "hu", "sk", "at", "de", "cz", "es", "pt", "fr", "it", "pl", "ro", "hr"
    ]
}
