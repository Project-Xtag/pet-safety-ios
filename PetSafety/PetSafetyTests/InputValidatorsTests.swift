import Testing
import Foundation
@testable import PetSafety

@Suite("InputValidators Tests")
struct InputValidatorsTests {

    // MARK: - Email Validation

    @Test("Valid emails pass validation")
    func testValidEmails() {
        #expect(InputValidators.isValidEmail("user@example.com"))
        #expect(InputValidators.isValidEmail("user.name@example.co.uk"))
        #expect(InputValidators.isValidEmail("user+tag@example.com"))
        #expect(InputValidators.isValidEmail("USER@EXAMPLE.COM"))
        #expect(InputValidators.isValidEmail("  user@example.com  ")) // trimming
    }

    @Test("Invalid emails fail validation")
    func testInvalidEmails() {
        #expect(!InputValidators.isValidEmail(""))
        #expect(!InputValidators.isValidEmail("user"))
        #expect(!InputValidators.isValidEmail("user@"))
        #expect(!InputValidators.isValidEmail("@example.com"))
        #expect(!InputValidators.isValidEmail("user@.com"))
        #expect(!InputValidators.isValidEmail("user@example"))
        #expect(!InputValidators.isValidEmail("   "))
    }

    // MARK: - Phone Validation

    @Test("Valid phones pass validation")
    func testValidPhones() {
        #expect(InputValidators.isValidPhone("+36301234567"))
        #expect(InputValidators.isValidPhone("+442071234567"))
        #expect(InputValidators.isValidPhone("06301234567"))
        #expect(InputValidators.isValidPhone("+1 234 567 8901"))
    }

    @Test("Invalid phones fail validation")
    func testInvalidPhones() {
        #expect(!InputValidators.isValidPhone(""))
        #expect(!InputValidators.isValidPhone("123"))
        #expect(!InputValidators.isValidPhone("abcdefg"))
        #expect(!InputValidators.isValidPhone("   "))
    }

    // MARK: - Microchip Validation

    @Test("Valid microchip numbers pass")
    func testValidMicrochips() {
        #expect(InputValidators.isValidMicrochip("123456789012345")) // 15 digits ISO standard
        #expect(InputValidators.isValidMicrochip("123456789")) // 9 digits minimum
        #expect(InputValidators.isValidMicrochip("")) // optional, empty is ok
    }

    @Test("Invalid microchip numbers fail")
    func testInvalidMicrochips() {
        #expect(!InputValidators.isValidMicrochip("12345")) // too short
        #expect(!InputValidators.isValidMicrochip("123456789012345678")) // too long (18)
        #expect(!InputValidators.isValidMicrochip("12345678901234A")) // contains letter
    }

    // MARK: - OTP Validation

    @Test("Valid OTP codes pass")
    func testValidOTPs() {
        #expect(InputValidators.isValidOTP("123456"))
        #expect(InputValidators.isValidOTP("000000"))
        #expect(InputValidators.isValidOTP(" 123456 ")) // trimming
    }

    @Test("Invalid OTP codes fail")
    func testInvalidOTPs() {
        #expect(!InputValidators.isValidOTP(""))
        #expect(!InputValidators.isValidOTP("12345")) // 5 digits
        #expect(!InputValidators.isValidOTP("1234567")) // 7 digits
        #expect(!InputValidators.isValidOTP("12345a")) // contains letter
        #expect(!InputValidators.isValidOTP("      ")) // spaces
    }

    // MARK: - Weight Validation

    @Test("Valid weights pass")
    func testValidWeights() {
        #expect(InputValidators.isValidWeight("5.5"))
        #expect(InputValidators.isValidWeight("0.1"))
        #expect(InputValidators.isValidWeight("500"))
        #expect(InputValidators.isValidWeight("")) // optional
    }

    @Test("Invalid weights fail")
    func testInvalidWeights() {
        #expect(!InputValidators.isValidWeight("0"))
        #expect(!InputValidators.isValidWeight("-5"))
        #expect(!InputValidators.isValidWeight("501"))
        #expect(!InputValidators.isValidWeight("abc"))
    }

    // MARK: - Reward Amount Validation

    @Test("Valid reward amounts pass")
    func testValidRewards() {
        #expect(InputValidators.isValidRewardAmount("100"))
        #expect(InputValidators.isValidRewardAmount("50.50"))
        #expect(InputValidators.isValidRewardAmount("")) // optional
    }

    @Test("Invalid reward amounts fail")
    func testInvalidRewards() {
        #expect(!InputValidators.isValidRewardAmount("0"))
        #expect(!InputValidators.isValidRewardAmount("-100"))
        #expect(!InputValidators.isValidRewardAmount("abc"))
        #expect(!InputValidators.isValidRewardAmount("1000001"))
    }

    // MARK: - Coordinate Validation

    @Test("Valid coordinates pass")
    func testValidCoordinates() {
        #expect(InputValidators.isValidCoordinate(latitude: 47.4979, longitude: 19.0402)) // Budapest
        #expect(InputValidators.isValidCoordinate(latitude: -33.8688, longitude: 151.2093)) // Sydney
        #expect(InputValidators.isValidCoordinate(latitude: 90, longitude: 180)) // boundary
        #expect(InputValidators.isValidCoordinate(latitude: -90, longitude: -180)) // boundary
    }

    @Test("Invalid coordinates fail")
    func testInvalidCoordinates() {
        #expect(!InputValidators.isValidCoordinate(latitude: 0, longitude: 0)) // null island
        #expect(!InputValidators.isValidCoordinate(latitude: 91, longitude: 19)) // lat out of range
        #expect(!InputValidators.isValidCoordinate(latitude: 47, longitude: 181)) // lng out of range
    }

    // MARK: - Text Length Limits

    @Test("isWithinLimit works correctly")
    func testTextLengthLimits() {
        #expect(InputValidators.isWithinLimit("hello", maxLength: 10))
        #expect(InputValidators.isWithinLimit("", maxLength: 10))
        #expect(!InputValidators.isWithinLimit(String(repeating: "a", count: 101), maxLength: 100))
        #expect(InputValidators.isWithinLimit(String(repeating: "a", count: 100), maxLength: 100))
    }

    @Test("Max length constants are reasonable")
    func testMaxLengthConstants() {
        #expect(InputValidators.maxPetName == 100)
        #expect(InputValidators.maxMicrochip == 17)
        #expect(InputValidators.maxMedicalNotes == 2000)
        #expect(InputValidators.maxEmail == 254)
        #expect(InputValidators.maxPhone == 20)
    }
}
