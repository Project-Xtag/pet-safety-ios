import Foundation

/// A single vaccination ("health record") entry for a pet.
///
/// **Date fields are intentionally `String`, not `Date`.** `administered_at`
/// and `expires_at` arrive as DATE-only values ("2026-06-12"), and the shared
/// `JSONDecoder.DateDecodingStrategy.flexibleISO8601` used by `APIService`
/// only parses full ISO-8601 *datetimes* — decoding a date-only string as
/// `Date` would throw. We therefore keep the raw strings (matching `Pet` /
/// `PetPhoto`) and derive `status` / `daysUntilExpiry` on the client.
///
/// `vaccine_code` is opaque: store/submit it verbatim, render
/// `vaccine_name_snapshot`, and never parse the code (Stage B decision #3).
struct Vaccination: Codable, Identifiable, Hashable {
    let id: String
    let petId: String
    let vaccineCode: String
    let vaccineNameSnapshot: String
    let administeredAt: String          // "YYYY-MM-DD"
    let expiresAt: String?              // "YYYY-MM-DD"; nil = no expiry / unknown
    let batchNumber: String?
    let vetName: String?
    let vetClinic: String?
    let certificateUrl: String?
    let certificateMime: String?
    let notes: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case petId = "pet_id"
        case vaccineCode = "vaccine_code"
        case vaccineNameSnapshot = "vaccine_name_snapshot"
        case administeredAt = "administered_at"
        case expiresAt = "expires_at"
        case batchNumber = "batch_number"
        case vetName = "vet_name"
        case vetClinic = "vet_clinic"
        case certificateUrl = "certificate_url"
        case certificateMime = "certificate_mime"
        case notes
        case createdAt = "created_at"
    }

    /// Parsed expiry as a UTC calendar-day instant (midnight UTC), or nil.
    /// The single place a view should get a `Date` from `expiresAt` — never
    /// call `DateFormatter` at a call site (keeps the UTC/POSIX parse in one
    /// spot so a date can't shift a day across time zones).
    var expiresDay: Date? { VaccinationDate.parse(expiresAt) }

    /// Parsed administered date as a UTC calendar-day instant, or nil.
    var administeredDay: Date? { VaccinationDate.parse(administeredAt) }

    /// Client-derived status from `expiresAt`. nil expiry → always `.valid`.
    /// The home-summary endpoint computes its own server-side `status` (which
    /// we consume verbatim on `UrgentVaccination`); this derivation is ONLY for
    /// the per-pet CRUD list, whose rows carry raw dates and no `status`.
    var status: VaccinationStatus {
        VaccinationStatus.derive(expiresAt: expiresAt)
    }

    /// Signed days until expiry; negative = overdue. nil when no expiry date.
    var daysUntilExpiry: Int? {
        VaccinationDate.daysUntil(expiresAt)
    }

    /// A copy with the certificate fields replaced. Used after a successful cert
    /// upload/removal so the row reflects it immediately (in the list / detail)
    /// without a re-fetch — `VaccinationsViewModel.uploadCertificate`. Uses the
    /// synthesized memberwise init; keep the argument order in sync with the
    /// stored properties above.
    func withCertificate(url: String?, mime: String?) -> Vaccination {
        Vaccination(
            id: id, petId: petId, vaccineCode: vaccineCode,
            vaccineNameSnapshot: vaccineNameSnapshot, administeredAt: administeredAt,
            expiresAt: expiresAt, batchNumber: batchNumber, vetName: vetName,
            vetClinic: vetClinic, certificateUrl: url, certificateMime: mime,
            notes: notes, createdAt: createdAt
        )
    }
}

/// Status of a vaccination record. Raw values match the server's strings on
/// both the home-summary (`'expired' | 'expiring'`) and public-QR
/// (`'valid' | 'expiring' | 'expired'`) surfaces, so the same type decodes
/// the server's `status` field AND backs the client-derived value above.
enum VaccinationStatus: String, Codable, Hashable {
    case valid
    case expiring
    case expired

    /// Derive a status from a "YYYY-MM-DD" expiry string.
    ///
    /// Boundary mirrors the backend SQL (`expires_at < CURRENT_DATE` → expired;
    /// `expires_at < CURRENT_DATE + 30 days` → expiring): days in `0..<30` are
    /// `.expiring`, `>= 30` are `.valid`, `< 0` are `.expired`. nil → `.valid`.
    static func derive(expiresAt: String?, now: Date = Date()) -> VaccinationStatus {
        guard let days = VaccinationDate.daysUntil(expiresAt, now: now) else { return .valid }
        if days < 0 { return .expired }
        if days < 30 { return .expiring }
        return .valid
    }
}

/// Date helpers for the DATE-only vaccination fields. Kept separate from the
/// model so both `Vaccination` and `VaccinationHomeSummary.UrgentVaccination`
/// can reuse the same parsing (and so it's unit-testable in isolation).
enum VaccinationDate {
    /// Fixed UTC + Gregorian calendar. The server stores/compares these fields
    /// as plain calendar dates (`CURRENT_DATE`), so the client treats them the
    /// same — pinning to UTC means a date-only value never shifts a day with
    /// the device's time zone (the footgun of decoding date-only as `Date`).
    static let utcCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    /// Parser/formatter for the "YYYY-MM-DD" wire format. POSIX locale + UTC so
    /// parse AND display are both timezone-stable. Use this for any rendering
    /// too — don't spin up a second `DateFormatter` at a call site.
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = utcCalendar
        f.timeZone = TimeZone(identifier: "UTC")!
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func parse(_ string: String?) -> Date? {
        guard let string else { return nil }
        return formatter.date(from: string)
    }

    /// Localized, medium-style display string ("12 Jun 2026") for a "YYYY-MM-DD"
    /// wire value. Formatted in UTC so the day shown matches the stored calendar
    /// day regardless of device time zone (same reasoning as `formatter`). Falls
    /// back to the raw string if it can't be parsed, and to "" if absent. The one
    /// place a call site should turn an `administered_at` / `expires_at` into
    /// user-facing text — don't build a `DateFormatter` at the row.
    static func displayString(_ string: String?, locale: Locale = .current) -> String {
        guard let string else { return "" }
        guard let date = parse(string) else { return string }
        let f = DateFormatter()
        f.locale = locale
        f.calendar = utcCalendar
        f.timeZone = TimeZone(identifier: "UTC")!
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    /// Signed whole-day delta from today to the given expiry, computed in UTC
    /// to match the server. Negative = already past. nil when the string is
    /// absent / unparseable. Mirrors the backend's date arithmetic so a record
    /// never shows one status here and another on the server-rendered surfaces.
    static func daysUntil(_ expiresAt: String?, now: Date = Date()) -> Int? {
        guard let expiry = parse(expiresAt) else { return nil }
        let from = utcCalendar.startOfDay(for: now)
        let to = utcCalendar.startOfDay(for: expiry)
        return utcCalendar.dateComponents([.day], from: from, to: to).day
    }
}

// MARK: - Request payloads

/// POST body for creating a record. `vaccine_code` is required; omit
/// `expires_at` (leave nil) to let the server derive it from the catalog's
/// `default_validity_months`. Synthesized `Codable` omits nil optionals, so an
/// absent field is sent as "not provided" (undefined) rather than explicit null.
struct CreateVaccinationRequest: Codable {
    let vaccineCode: String
    let administeredAt: String
    let expiresAt: String?
    let batchNumber: String?
    let vetName: String?
    let vetClinic: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case vaccineCode = "vaccine_code"
        case administeredAt = "administered_at"
        case expiresAt = "expires_at"
        case batchNumber = "batch_number"
        case vetName = "vet_name"
        case vetClinic = "vet_clinic"
        case notes
    }
}

/// PUT body for editing a record. **Deliberately omits `vaccine_code`** — it's
/// immutable server-side (to change the vaccine, delete and re-add). All fields
/// optional; only non-nil fields are encoded, so this is a partial update.
struct UpdateVaccinationRequest: Codable {
    let administeredAt: String?
    let expiresAt: String?
    let batchNumber: String?
    let vetName: String?
    let vetClinic: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case administeredAt = "administered_at"
        case expiresAt = "expires_at"
        case batchNumber = "batch_number"
        case vetName = "vet_name"
        case vetClinic = "vet_clinic"
        case notes
    }
}

// MARK: - Response envelopes
//
// `APIService.performRequest` already unwraps the outer `{success, data}`
// envelope, so these decode the *contents* of `data`.

struct VaccinationsResponse: Codable {
    let vaccinations: [Vaccination]
}

struct VaccinationResponse: Codable {
    let vaccination: Vaccination
}

struct CertificateUploadResponse: Codable {
    let certificateUrl: String

    enum CodingKeys: String, CodingKey {
        case certificateUrl = "certificate_url"
    }
}
