import Foundation

struct Pet: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let species: String
    let breed: String?
    let color: String?
    let dateOfBirth: String?
    let weight: Double?
    let microchipNumber: String?
    let medicalInfo: String?
    let behaviorNotes: String?
    let photoUrl: String?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String

    // Computed property for displaying age
    var age: String? {
        guard let dobString = dateOfBirth,
              let dob = ISO8601DateFormatter().date(from: dobString) else {
            return nil
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: dob, to: Date())

        if let years = components.year, years > 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        } else if let months = components.month {
            return "\(months) month\(months == 1 ? "" : "s")"
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case id, name, species, breed, color, weight
        case userId = "user_id"
        case dateOfBirth = "date_of_birth"
        case microchipNumber = "microchip_number"
        case medicalInfo = "medical_info"
        case behaviorNotes = "behavior_notes"
        case photoUrl = "photo_url"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreatePetRequest: Codable {
    let name: String
    let species: String
    let breed: String?
    let color: String?
    let dateOfBirth: String?
    let weight: Double?
    let microchipNumber: String?
    let medicalInfo: String?
    let behaviorNotes: String?

    enum CodingKeys: String, CodingKey {
        case name, species, breed, color, weight
        case dateOfBirth = "date_of_birth"
        case microchipNumber = "microchip_number"
        case medicalInfo = "medical_info"
        case behaviorNotes = "behavior_notes"
    }
}

struct UpdatePetRequest: Codable {
    let name: String?
    let species: String?
    let breed: String?
    let color: String?
    let dateOfBirth: String?
    let weight: Double?
    let microchipNumber: String?
    let medicalInfo: String?
    let behaviorNotes: String?

    enum CodingKeys: String, CodingKey {
        case name, species, breed, color, weight
        case dateOfBirth = "date_of_birth"
        case microchipNumber = "microchip_number"
        case medicalInfo = "medical_info"
        case behaviorNotes = "behavior_notes"
    }
}
