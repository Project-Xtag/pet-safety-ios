import CoreLocation

/// Shared map defaults — the ONE home for the app's default map center.
///
/// Role-named deliberately: this is "the default center" (which happens to be
/// HU's capital, matching the HU-only launch), not "budapest" — naming it after
/// the city would re-encode the exact assumption the no-hardcoded-map-defaults
/// rule exists to surface. Byte-identical to the literal it replaced
/// (Fix 2: pure refactor, no behavioral change).
enum MapDefaults {
    static let defaultMapCenter = CLLocationCoordinate2D(latitude: 47.4979, longitude: 19.0402)
}
