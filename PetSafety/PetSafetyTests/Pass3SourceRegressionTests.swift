import Testing
import Foundation

/// Pass 3 audit fix regression tests.
///
/// Source-level guards — cheaper to run than full XCUI against the
/// Simulator and enough to pin the specific shapes the audit introduced
/// into function bodies. If a test fails, somebody regressed a Pass 3
/// fix and should re-read the plan file before continuing.
@Suite("Pass 3 — source regression guards")
struct Pass3SourceRegressionTests {

    private static let projectRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("PetSafety")

    private static func readSource(_ rel: String) throws -> String {
        try String(contentsOf: projectRoot.appendingPathComponent(rel), encoding: .utf8)
    }

    // MARK: - QRScannerView localization + torch feedback

    @Test("QRScannerView renders breed/sex through PetLocalizer (not raw DB values)")
    func testQRScannerBreedSexLocalized() throws {
        let src = try Self.readSource("Views/QRScanner/QRScannerView.swift")
        #expect(src.contains("PetLocalizer.localizeBreed(breed, species: pet.species)"))
        #expect(src.contains("PetLocalizer.localizeSex(sex, species: pet.species)"))
    }

    @Test("QRScannerView surfaces torch errors to the user (no DEBUG-only swallow)")
    func testQRScannerTorchError() throws {
        let src = try Self.readSource("Views/QRScanner/QRScannerView.swift")
        #expect(src.contains("torchErrorMessage"))
        #expect(src.contains("qr_torch_unavailable"))
    }

    // MARK: - AlertDetailView format string

    @Test("AlertDetailView uses String(format:NSLocalizedString) for mark_found title + message")
    func testAlertDetailViewFormatString() throws {
        let src = try Self.readSource("Views/Alerts/AlertDetailView.swift")
        #expect(src.contains("String(format: NSLocalizedString(\"alert_mark_found_title\""))
        #expect(src.contains("String(format: NSLocalizedString(\"alert_mark_found_message\""))
        // Regression: the old broken `"key \(value)"` interpolation is gone
        #expect(!src.contains("\"alert_mark_found_title \\("))
    }

    // MARK: - MarkAsLostView reward + address caps

    @Test("MarkAsLostView reward field uses decimalPad + filters + length cap")
    func testMarkAsLostRewardField() throws {
        let src = try Self.readSource("Views/Pets/MarkAsLostView.swift")
        #expect(src.contains(".keyboardType(.decimalPad)"))
        #expect(src.contains("filter { $0.isNumber || $0 == \".\" || $0 == \",\" }"))
        #expect(src.contains("String(filtered.prefix(20))"))
    }

    @Test("MarkAsLostView custom address is capped at 500 chars")
    func testMarkAsLostAddressCap() throws {
        let src = try Self.readSource("Views/Pets/MarkAsLostView.swift")
        #expect(src.contains("newValue.count > 500"))
        #expect(src.contains("String(newValue.prefix(500))"))
    }

    // MARK: - ReportSightingView phone + coord validation

    @Test("ReportSightingView validates phone via InputValidators (not length-only)")
    func testReportSightingPhoneValidator() throws {
        let src = try Self.readSource("Views/Alerts/ReportSightingView.swift")
        #expect(src.contains("InputValidators.isValidPhone(trimmedPhone)"))
    }

    @Test("ReportSightingView validates geocoded coordinate (null-island / range)")
    func testReportSightingCoordValidator() throws {
        let src = try Self.readSource("Views/Alerts/ReportSightingView.swift")
        #expect(src.contains("InputValidators.isValidCoordinate(latitude: finalCoord.latitude, longitude: finalCoord.longitude)"))
        #expect(src.contains("sighting_location_invalid"))
    }

    // MARK: - PetsViewModel Sentry on offline cache delete + alert resolution

    @Test("PetsViewModel captures offline-cache delete errors to Sentry")
    func testPetsViewModelOfflineCacheSentry() throws {
        let src = try Self.readSource("ViewModels/PetsViewModel.swift")
        #expect(src.contains("offline_cache_delete"))
        // Regression: the old bare try? was the audit trigger.
        // After the fix we still have try? in other cache paths, but the
        // specific delete-after-sync path must go through a logged catch.
        #expect(src.contains("offline_cache_delete_after_api_delete"))
    }

    @Test("PetsViewModel captures mark-found alert resolution failures to Sentry")
    func testPetsViewModelAlertResolutionSentry() throws {
        let src = try Self.readSource("ViewModels/PetsViewModel.swift")
        #expect(src.contains("mark_found_alert_resolution"))
    }

    // MARK: - CreateAlertView geocoding with coord validation

    @Test("CreateAlertView validates geocoded coord (no more silent try?)")
    func testCreateAlertGeocodeValidation() throws {
        let src = try Self.readSource("Views/Alerts/CreateAlertView.swift")
        #expect(src.contains("InputValidators.isValidCoordinate(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)"))
        // Two geocode paths (registered + custom) must both use the guard
        let occurrences = src.components(separatedBy: "InputValidators.isValidCoordinate(latitude: loc.coordinate.latitude").count - 1
        #expect(occurrences >= 2)
    }
}
