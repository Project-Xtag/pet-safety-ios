import Testing
import Foundation
@testable import PetSafety

/// Regression tests pinning Localizable.strings parity across all 13
/// supported locales (audit H48 + H64). Mirrors the web i18n parity
/// suite — adding a string to en.lproj that's missing in ANY other
/// locale fails CI immediately, so production never ships a fallback-
/// to-English surface for an unsupported language.
///
/// Why we don't validate ALL keys exist: pluralisation files
/// (Localizable.stringsdict) and platform-specific overrides legitimately
/// add keys per locale. We assert that the SET of keys defined in en
/// is a subset of every other locale's keys — extras don't fail.
@Suite("Localization Parity")
struct LocalizationParityTests {

    /// Keep in lockstep with the directories under Resources/. Norwegian
    /// uses the Apple-standard `nb` (Bokmål) code; the rest match ISO
    /// 639-1.
    private static let supportedLocales: [String] = [
        "en", "hu", "sk", "cs", "de", "es", "pt", "ro",
        "fr", "it", "pl", "hr", "nb",
    ]

    /// Parses a .strings file into a key set. SwiftUI's parser is
    /// permissive but for this test we only need the keys, not values.
    /// Format: lines like `"key" = "value";` (with optional comments).
    private static func loadKeys(forLocale locale: String) throws -> Set<String> {
        guard let url = Bundle(for: ParityProbe.self)
                .url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: locale)
        else {
            // Fall back to direct path — Bundle.localized lookup can vary
            // between SPM and xcodebuild test runners.
            return try loadKeysViaPath(locale: locale)
        }
        let raw = try String(contentsOf: url, encoding: .utf8)
        return parseKeys(from: raw)
    }

    private static func loadKeysViaPath(locale: String) throws -> Set<String> {
        // Resolve relative to this test file's location at compile-time.
        let testFile = URL(fileURLWithPath: #filePath)
        let appResources = testFile
            .deletingLastPathComponent()           // PetSafetyTests/
            .deletingLastPathComponent()           // PetSafety/
            .appendingPathComponent("PetSafety")
            .appendingPathComponent("Resources")
            .appendingPathComponent("\(locale).lproj")
            .appendingPathComponent("Localizable.strings")
        let raw = try String(contentsOf: appResources, encoding: .utf8)
        return parseKeys(from: raw)
    }

    /// Pull `"key" = "..."` lines, ignoring comments and stringsdict-style
    /// nested keys.
    private static func parseKeys(from raw: String) -> Set<String> {
        var keys = Set<String>()
        // Match `"key"` at start of an assignment line. NSRegularExpression
        // is fine here — strings files are tiny.
        let pattern = #"(?m)^\s*"([^"\\]+(?:\\.[^"\\]*)*)"\s*="#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return keys }
        let ns = raw as NSString
        let matches = regex.matches(in: raw, range: NSRange(location: 0, length: ns.length))
        for m in matches where m.numberOfRanges >= 2 {
            keys.insert(ns.substring(with: m.range(at: 1)))
        }
        return keys
    }

    /// Empty class purely to anchor `Bundle(for:)` in case the test
    /// bundle layout shifts.
    private final class ParityProbe {}

    @Test("English reference file parses and is non-empty")
    func testReferenceLocaleLoads() throws {
        let keys = try Self.loadKeys(forLocale: "en")
        #expect(keys.count > 100)
    }

    @Test("Every supported locale file exists and parses")
    func testEveryLocaleParses() throws {
        for locale in Self.supportedLocales {
            let keys = try Self.loadKeys(forLocale: locale)
            if keys.isEmpty {
                Issue.record(Comment(rawValue: "\(locale).lproj/Localizable.strings yielded zero keys"))
            }
        }
    }

    @Test("Every locale has all keys from en.lproj (no silent English fallback)")
    func testParityAgainstReference() throws {
        let referenceKeys = try Self.loadKeys(forLocale: "en")

        for locale in Self.supportedLocales where locale != "en" {
            let localeKeys = try Self.loadKeys(forLocale: locale)
            let missing = referenceKeys.subtracting(localeKeys).sorted()
            if !missing.isEmpty {
                let firstTen: [String] = Array(missing.prefix(10))
                let preview: String = firstTen.joined(separator: ", ")
                Issue.record(
                    Comment(rawValue: "\(locale).lproj is missing \(missing.count) key(s) from en.lproj. First 10: \(preview)")
                )
            }
        }
    }
}
