import Foundation

enum InputValidators {

    // MARK: - Email (RFC 5322 simplified)

    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: trimmed)
    }

    // MARK: - Phone (E.164: +countrycode followed by digits, 7-15 total digits)

    static func isValidPhone(_ phone: String) -> Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let digits = trimmed.filter { $0.isNumber }
        // Allow with or without +, 7-15 digits
        let pattern = "^\\+?[0-9]{7,15}$"
        let stripped = trimmed.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: stripped) && digits.count >= 7
    }

    // MARK: - Microchip (ISO 11784/11785: 15 digits)

    static func isValidMicrochip(_ chip: String) -> Bool {
        let trimmed = chip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true } // optional field
        return trimmed.count >= 9 && trimmed.count <= 17 && trimmed.allSatisfy(\.isNumber)
    }

    // MARK: - OTP (exactly 6 digits)

    static func isValidOTP(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count == 6 && trimmed.allSatisfy(\.isNumber)
    }

    // MARK: - Weight (positive number, max 500 kg)

    static func isValidWeight(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true } // optional field
        guard let value = Double(trimmed) else { return false }
        return value > 0 && value <= 500
    }

    // MARK: - Reward amount (positive number)

    static func isValidRewardAmount(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true } // optional field
        guard let value = Double(trimmed) else { return false }
        return value > 0 && value <= 1_000_000
    }

    // MARK: - Coordinates

    static func isValidLatitude(_ lat: Double) -> Bool {
        lat >= -90 && lat <= 90
    }

    static func isValidLongitude(_ lng: Double) -> Bool {
        lng >= -180 && lng <= 180
    }

    static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        isValidLatitude(latitude) && isValidLongitude(longitude) &&
        !(latitude == 0 && longitude == 0) // reject null island
    }

    // MARK: - Text length limits

    static let maxPetName = 100
    static let maxBreed = 100
    static let maxColor = 100
    static let maxMicrochip = 17
    static let maxMedicalNotes = 2000
    static let maxNotes = 2000
    static let maxUniqueFeatures = 1000
    static let maxAllergies = 1000
    static let maxMedications = 1000
    static let maxAlertDescription = 2000
    static let maxRewardAmount = 20
    static let maxLocationText = 500
    static let maxPostalCode = 20
    static let maxPersonName = 100
    static let maxEmail = 254
    static let maxPhone = 20

    static func isWithinLimit(_ text: String, maxLength: Int) -> Bool {
        text.count <= maxLength
    }
}
