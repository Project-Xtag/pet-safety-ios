import Foundation

struct Pet: Codable, Identifiable, Hashable {
    let id: String
    let ownerId: String
    let name: String
    let species: String
    let breed: String?
    let color: String?
    let weight: Double?
    let microchipNumber: String?
    let medicalNotes: String?
    let notes: String?
    let profileImage: String?
    let isMissing: Bool
    let createdAt: String
    let updatedAt: String

    // Age-related fields from database
    let ageYears: Int?
    let ageMonths: Int?
    let ageText: String?
    let ageIsApproximate: Bool?

    // Additional fields from database
    let allergies: String?
    let medications: String?
    let uniqueFeatures: String?
    let sex: String?
    let isNeutered: Bool?
    let qrCode: String?
    let dateOfBirth: String?

    // Public profile fields (only present when scanning QR code)
    let ownerName: String?
    let ownerPhone: String?
    let ownerEmail: String?

    // Computed property for displaying age
    var age: String? {
        if let text = ageText, !text.isEmpty {
            return text
        }

        if let years = ageYears, years > 0 {
            if let months = ageMonths, months > 0 {
                return "\(years)y \(months)m"
            }
            return "\(years) year\(years == 1 ? "" : "s")"
        } else if let months = ageMonths, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s")"
        }
        return nil
    }

    // Computed properties for backward compatibility
    var photoUrl: String? { profileImage }
    var userId: String { ownerId }
    var isActive: Bool { !isMissing }
    var medicalInfo: String? { medicalNotes }
    var behaviorNotes: String? { notes }
    var isSterilized: Bool? { isNeutered }

    enum CodingKeys: String, CodingKey {
        case id, name, species, breed, color, weight
        case ownerId = "owner_id"
        case microchipNumber = "microchip_number"
        case medicalNotes = "medical_notes"
        case notes
        case profileImage = "profile_image"
        case photoUrl = "photo_url"
        case isMissing = "is_missing"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case ageYears = "age_years"
        case ageMonths = "age_months"
        case ageText = "age_text"
        case ageIsApproximate = "age_is_approximate"
        case allergies, medications
        case uniqueFeatures = "unique_features"
        case sex
        case isNeutered = "is_neutered"
        case qrCode = "qr_code"
        case dateOfBirth = "date_of_birth"
        case ownerName = "owner_name"
        case ownerPhone = "owner_phone"
        case ownerEmail = "owner_email"
    }

    // Memberwise initializer for creating Pet instances (e.g., in previews)
    init(
        id: String,
        ownerId: String,
        name: String,
        species: String,
        breed: String? = nil,
        color: String? = nil,
        weight: Double? = nil,
        microchipNumber: String? = nil,
        medicalNotes: String? = nil,
        notes: String? = nil,
        profileImage: String? = nil,
        isMissing: Bool,
        createdAt: String,
        updatedAt: String,
        ageYears: Int? = nil,
        ageMonths: Int? = nil,
        ageText: String? = nil,
        ageIsApproximate: Bool? = nil,
        allergies: String? = nil,
        medications: String? = nil,
        uniqueFeatures: String? = nil,
        sex: String? = nil,
        isNeutered: Bool? = nil,
        qrCode: String? = nil,
        dateOfBirth: String? = nil,
        ownerName: String? = nil,
        ownerPhone: String? = nil,
        ownerEmail: String? = nil
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.species = species
        self.breed = breed
        self.color = color
        self.weight = weight
        self.microchipNumber = microchipNumber
        self.medicalNotes = medicalNotes
        self.notes = notes
        self.profileImage = profileImage
        self.isMissing = isMissing
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ageYears = ageYears
        self.ageMonths = ageMonths
        self.ageText = ageText
        self.ageIsApproximate = ageIsApproximate
        self.allergies = allergies
        self.medications = medications
        self.uniqueFeatures = uniqueFeatures
        self.sex = sex
        self.isNeutered = isNeutered
        self.qrCode = qrCode
        self.dateOfBirth = dateOfBirth
        self.ownerName = ownerName
        self.ownerPhone = ownerPhone
        self.ownerEmail = ownerEmail
    }

    // Custom decoder to handle weight as either String or Double
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        name = try container.decode(String.self, forKey: .name)
        species = try container.decode(String.self, forKey: .species)
        breed = try container.decodeIfPresent(String.self, forKey: .breed)
        color = try container.decodeIfPresent(String.self, forKey: .color)

        // Handle weight as either String or Double
        if let weightDouble = try? container.decodeIfPresent(Double.self, forKey: .weight) {
            weight = weightDouble
        } else if let weightString = try? container.decodeIfPresent(String.self, forKey: .weight) {
            weight = Double(weightString)
        } else {
            weight = nil
        }

        microchipNumber = try container.decodeIfPresent(String.self, forKey: .microchipNumber)
        medicalNotes = try container.decodeIfPresent(String.self, forKey: .medicalNotes)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        let profileImageValue = try container.decodeIfPresent(String.self, forKey: .profileImage)
        let photoUrlValue = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        profileImage = profileImageValue ?? photoUrlValue
        isMissing = try container.decode(Bool.self, forKey: .isMissing)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        ageYears = try container.decodeIfPresent(Int.self, forKey: .ageYears)
        ageMonths = try container.decodeIfPresent(Int.self, forKey: .ageMonths)
        ageText = try container.decodeIfPresent(String.self, forKey: .ageText)
        ageIsApproximate = try container.decodeIfPresent(Bool.self, forKey: .ageIsApproximate)
        allergies = try container.decodeIfPresent(String.self, forKey: .allergies)
        medications = try container.decodeIfPresent(String.self, forKey: .medications)
        uniqueFeatures = try container.decodeIfPresent(String.self, forKey: .uniqueFeatures)
        sex = try container.decodeIfPresent(String.self, forKey: .sex)
        isNeutered = try container.decodeIfPresent(Bool.self, forKey: .isNeutered)
        qrCode = try container.decodeIfPresent(String.self, forKey: .qrCode)
        dateOfBirth = try container.decodeIfPresent(String.self, forKey: .dateOfBirth)
        ownerName = try container.decodeIfPresent(String.self, forKey: .ownerName)
        ownerPhone = try container.decodeIfPresent(String.self, forKey: .ownerPhone)
        ownerEmail = try container.decodeIfPresent(String.self, forKey: .ownerEmail)
    }

    // Custom encoder to handle photoUrl key (only used for decoding legacy API responses)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(name, forKey: .name)
        try container.encode(species, forKey: .species)
        try container.encodeIfPresent(breed, forKey: .breed)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(microchipNumber, forKey: .microchipNumber)
        try container.encodeIfPresent(medicalNotes, forKey: .medicalNotes)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(profileImage, forKey: .profileImage)
        try container.encode(isMissing, forKey: .isMissing)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(ageYears, forKey: .ageYears)
        try container.encodeIfPresent(ageMonths, forKey: .ageMonths)
        try container.encodeIfPresent(ageText, forKey: .ageText)
        try container.encodeIfPresent(ageIsApproximate, forKey: .ageIsApproximate)
        try container.encodeIfPresent(allergies, forKey: .allergies)
        try container.encodeIfPresent(medications, forKey: .medications)
        try container.encodeIfPresent(uniqueFeatures, forKey: .uniqueFeatures)
        try container.encodeIfPresent(sex, forKey: .sex)
        try container.encodeIfPresent(isNeutered, forKey: .isNeutered)
        try container.encodeIfPresent(qrCode, forKey: .qrCode)
        try container.encodeIfPresent(dateOfBirth, forKey: .dateOfBirth)
        try container.encodeIfPresent(ownerName, forKey: .ownerName)
        try container.encodeIfPresent(ownerPhone, forKey: .ownerPhone)
        try container.encodeIfPresent(ownerEmail, forKey: .ownerEmail)
    }
}

struct CreatePetRequest: Codable {
    let name: String
    let species: String
    let breed: String?
    let color: String?
    let age: String? // Backend accepts flexible age string
    let weight: Double?
    let microchipNumber: String?
    let medicalNotes: String?
    let allergies: String?
    let medications: String?
    let notes: String?
    let uniqueFeatures: String?
    let sex: String?
    let isNeutered: Bool?

    enum CodingKeys: String, CodingKey {
        case name, species, breed, color, weight, age
        case microchipNumber = "microchip_number"
        case medicalNotes = "medical_notes"
        case allergies, medications, notes
        case uniqueFeatures = "unique_features"
        case sex
        case isNeutered = "is_neutered"
    }
}

struct UpdatePetRequest: Codable {
    let name: String?
    let species: String?
    let breed: String?
    let color: String?
    let age: String?
    let weight: Double?
    let microchipNumber: String?
    let medicalNotes: String?
    let allergies: String?
    let medications: String?
    let notes: String?
    let uniqueFeatures: String?
    let sex: String?
    let isNeutered: Bool?
    let isMissing: Bool?

    enum CodingKeys: String, CodingKey {
        case name, species, breed, color, weight, age
        case microchipNumber = "microchip_number"
        case medicalNotes = "medical_notes"
        case allergies, medications, notes
        case uniqueFeatures = "unique_features"
        case sex
        case isNeutered = "is_neutered"
        case isMissing = "is_missing"
    }
}
