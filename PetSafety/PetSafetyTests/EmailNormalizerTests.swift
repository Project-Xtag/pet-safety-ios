import XCTest
@testable import PetSafety

/// Mirrors the backend `normalizeEmail` and Android `EmailNormalizer.normalize`
/// test contracts. Pins the rule that the iOS client always sends the
/// canonical lowercased email — so an account created on iOS resolves to
/// the same user row when the user logs in on Android or web later, and
/// vice versa.
final class EmailNormalizerTests: XCTestCase {

    func testLowercasesMixedCase() {
        XCTAssertEqual(EmailNormalizer.normalize("Foo@Bar.COM"), "foo@bar.com")
    }

    func testTrimsSurroundingWhitespace() {
        XCTAssertEqual(EmailNormalizer.normalize("  foo@bar.com  "), "foo@bar.com")
    }

    func testHandlesTabAndNewline() {
        XCTAssertEqual(EmailNormalizer.normalize("\tfoo@bar.com\n"), "foo@bar.com")
    }

    func testReturnsEmptyStringForNil() {
        XCTAssertEqual(EmailNormalizer.normalize(nil), "")
    }

    func testReturnsEmptyStringForBlank() {
        XCTAssertEqual(EmailNormalizer.normalize("   "), "")
    }

    func testIsIdempotent() {
        let first = EmailNormalizer.normalize("Foo@Bar.COM ")
        let second = EmailNormalizer.normalize(first)
        XCTAssertEqual(first, second)
    }

    func testPreservesPlusTagInLocalPart() {
        XCTAssertEqual(
            EmailNormalizer.normalize("Foo+iOS@Example.com"),
            "foo+ios@example.com"
        )
    }
}
