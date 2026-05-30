import Testing
import Foundation
@testable import PetSafety

/// Decode + logic coverage for the Stage-B vaccination models.
///
/// The catalog and empty-summary fixtures are **verbatim production
/// responses** (api.senra.pet, 2026-05-30) so this suite is the concrete
/// "model decode vs. real prod response" check. Each decode runs through the
/// same `ApiEnvelope<…>` + `.flexibleISO8601` pipeline `APIService` uses — the
/// key property being that DATE-only fields ("2026-06-12") decode fine because
/// they're typed `String`, not `Date` (a `Date` would throw under that
/// strategy, which is exactly why the model keeps raw strings).
@Suite("Vaccination Models")
struct VaccinationModelTests {

    /// Mirror of the decoder configured in `APIService.performRequest`.
    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .flexibleISO8601
        return decoder
    }

    // MARK: - Catalog (real prod response)

    @Test("Catalog decodes verbatim prod response")
    func catalogDecodesProdResponse() throws {
        // GET /api/vaccines/catalog?species=dog&country=HU  (Accept-Language: hu)
        let json = """
        {"success":true,"data":{"vaccines":[
          {"code":"rabies_dog_hu","display_name":"Veszettség elleni oltás","description":"Kötelező veszettség elleni védőoltás kutyák és macskák számára.","is_core":true,"default_validity_months":36,"min_age_weeks":12,"rabies_specific":true,"sort_order":10},
          {"code":"dhpp_dog_hu","display_name":"DHPP kombinált oltás","description":"Kombinált oltás szopornyica, fertőző májgyulladás, parvovírus és parainfluenza ellen.","is_core":true,"default_validity_months":36,"min_age_weeks":6,"rabies_specific":false,"sort_order":20},
          {"code":"dhppi_l4_dog_hu","display_name":"DHPPi + L4 oltás","description":"DHPP kombináció leptospirózis (4 törzs) elleni védelemmel; éves emlékeztető.","is_core":true,"default_validity_months":12,"min_age_weeks":6,"rabies_specific":false,"sort_order":30},
          {"code":"bordetella_dog_hu","display_name":"Bordetella (kennelköhögés) elleni oltás","description":"Kennelköhögés elleni oltás; panzió vagy kutyaiskola előtt ajánlott.","is_core":false,"default_validity_months":12,"min_age_weeks":6,"rabies_specific":false,"sort_order":110},
          {"code":"babesiosis_dog_hu","display_name":"Babéziózis elleni oltás","description":"Kullancs által terjesztett babéziózis (Babesia canis) elleni oltás.","is_core":false,"default_validity_months":12,"min_age_weeks":24,"rabies_specific":false,"sort_order":120}
        ]}}
        """.data(using: .utf8)!

        let envelope = try makeDecoder().decode(ApiEnvelope<VaccineCatalogResponse>.self, from: json)
        let vaccines = try #require(envelope.data?.vaccines)

        #expect(vaccines.count == 5)
        let rabies = vaccines[0]
        #expect(rabies.code == "rabies_dog_hu")
        #expect(rabies.displayName == "Veszettség elleni oltás")
        #expect(rabies.isCore == true)
        #expect(rabies.rabiesSpecific == true)
        #expect(rabies.defaultValidityMonths == 36)
        #expect(rabies.minAgeWeeks == 12)
        #expect(rabies.sortOrder == 10)
        #expect(rabies.id == rabies.code)        // Identifiable bridges to code
    }

    // MARK: - Summary (real prod empty-state response)

    @Test("Empty-state summary decodes verbatim prod response")
    func emptySummaryDecodesProdResponse() throws {
        // GET /api/users/me/vaccinations/summary — feature ON, no records yet
        let json = """
        {"success":true,"data":{"summary":{"total_pets_with_vaccinations":0,"expired_count":0,"expiring_30d_count":0,"valid_count":0,"urgent":[]}}}
        """.data(using: .utf8)!

        let envelope = try makeDecoder().decode(ApiEnvelope<VaccinationSummaryResponse>.self, from: json)
        let summary = try #require(envelope.data?.summary)

        #expect(summary.totalPetsWithVaccinations == 0)
        #expect(summary.urgent.isEmpty)
        #expect(summary.isEmpty == true)   // → hide home card, keep pet-detail section
    }

    @Test("Populated summary decodes signed days + status (synthetic: null image)")
    func populatedSummaryDecodes() throws {
        // Synthetic companion to the real-prod fixture below: the prod test pet
        // (Max) HAS a profile image, so this is the only case that exercises
        // `pet_profile_image: null` and a larger overdue magnitude.
        let json = """
        {"success":true,"data":{"summary":{
          "total_pets_with_vaccinations":2,
          "expired_count":1,"expiring_30d_count":1,"valid_count":4,
          "urgent":[
            {"pet_id":"p1","pet_name":"Bela","pet_profile_image":"https://cdn/x.webp","vaccination_id":"v1","vaccine_name":"Veszettség","expires_at":"2026-05-20","days_until_expiry":-10,"status":"expired"},
            {"pet_id":"p2","pet_name":"Cica","pet_profile_image":null,"vaccination_id":"v2","vaccine_name":"DHPP","expires_at":"2026-06-12","days_until_expiry":13,"status":"expiring"}
          ]
        }}}
        """.data(using: .utf8)!

        let summary = try #require(
            try makeDecoder().decode(ApiEnvelope<VaccinationSummaryResponse>.self, from: json).data?.summary
        )
        #expect(summary.urgent.count == 2)

        let overdue = summary.urgent[0]
        #expect(overdue.status == .expired)
        #expect(overdue.daysUntilExpiry == -10)
        #expect(overdue.petProfileImage == "https://cdn/x.webp")
        #expect(overdue.id == "v1")

        let soon = summary.urgent[1]
        #expect(soon.status == .expiring)
        #expect(soon.daysUntilExpiry == 13)
        #expect(soon.petProfileImage == nil)   // null tolerated
    }

    // MARK: - Real prod fixtures (captured 2026-05-30, account szasz_viktor@yahoo, pet "Max")
    //
    // These are VERBATIM production responses for a pet carrying three records
    // (expired / expiring / valid) with a cert on one. They close the decode
    // gate the empty-state fixtures left open: the urgent[] element with a
    // present pet_profile_image, server-computed signed days + status, a list
    // row with certificate_url both present and null, and date-only fields
    // decoded in real context (not synthetic strings).

    @Test("Real-prod populated summary decodes verbatim")
    func realProdSummaryDecodes() throws {
        let json = """
        {"success":true,"data":{"summary":{"total_pets_with_vaccinations":1,"expired_count":1,"expiring_30d_count":1,"valid_count":1,"urgent":[{"pet_id":"67cbc6ff-ee15-47f0-bdba-17448b4f979f","pet_name":"Max","pet_profile_image":"https://pet-safety-eu-images-7dbbf5fa.s3.eu-north-1.amazonaws.com/public/pets/67cbc6ff-ee15-47f0-bdba-17448b4f979f/1779112020625.webp","vaccination_id":"644f6b0f-970b-4c60-8b1a-6d2d4203adb7","vaccine_name":"Macska kombinált alapoltás (FPV/FHV/FCV)","expires_at":"2026-05-28","days_until_expiry":-2,"status":"expired"},{"pet_id":"67cbc6ff-ee15-47f0-bdba-17448b4f979f","pet_name":"Max","pet_profile_image":"https://pet-safety-eu-images-7dbbf5fa.s3.eu-north-1.amazonaws.com/public/pets/67cbc6ff-ee15-47f0-bdba-17448b4f979f/1779112020625.webp","vaccination_id":"69e0b423-1ba5-489a-b30a-9b162b2ef6bb","vaccine_name":"Macska kombinált alapoltás (FPV/FHV/FCV)","expires_at":"2026-06-06","days_until_expiry":7,"status":"expiring"}]}}}
        """.data(using: .utf8)!

        let summary = try #require(
            try makeDecoder().decode(ApiEnvelope<VaccinationSummaryResponse>.self, from: json).data?.summary
        )
        #expect(summary.totalPetsWithVaccinations == 1)
        #expect(summary.expiredCount == 1)
        #expect(summary.expiring30dCount == 1)
        #expect(summary.validCount == 1)
        #expect(summary.isEmpty == false)
        // Two urgent rows; the far-future "valid" record is correctly absent.
        #expect(summary.urgent.count == 2)
        // Expired-first ordering (server: most overdue first).
        #expect(summary.urgent[0].status == .expired)
        #expect(summary.urgent[0].daysUntilExpiry == -2)         // signed
        #expect(summary.urgent[0].petName == "Max")
        #expect(summary.urgent[0].petProfileImage != nil)        // present on real data
        #expect(summary.urgent[1].status == .expiring)
        #expect(summary.urgent[1].daysUntilExpiry == 7)
    }

    @Test("Real-prod populated list decodes; rows carry no status (client derives)")
    func realProdListDecodes() throws {
        let json = """
        {"success":true,"data":{"vaccinations":[{"id":"98982a38-24d4-4159-b376-9d366b38ad0c","pet_id":"67cbc6ff-ee15-47f0-bdba-17448b4f979f","vaccine_code":"feline_core_trio_cat_hu","vaccine_name_snapshot":"Macska kombinált alapoltás (FPV/FHV/FCV)","administered_at":"2026-05-30","expires_at":"2027-06-01","batch_number":null,"vet_name":null,"vet_clinic":null,"certificate_url":null,"certificate_mime":null,"notes":null,"created_at":"2026-05-30T14:03:26.674Z","updated_at":"2026-05-30T14:03:26.674Z"},{"id":"69e0b423-1ba5-489a-b30a-9b162b2ef6bb","pet_id":"67cbc6ff-ee15-47f0-bdba-17448b4f979f","vaccine_code":"feline_core_trio_cat_hu","vaccine_name_snapshot":"Macska kombinált alapoltás (FPV/FHV/FCV)","administered_at":"2026-05-30","expires_at":"2026-06-06","batch_number":"LOT-EXPIRING","vet_name":"Dr. Teszt","vet_clinic":"Teszt Klinika","certificate_url":"https://pet-safety-eu-images-7dbbf5fa.s3.eu-north-1.amazonaws.com/public/vaccinations/67cbc6ff-ee15-47f0-bdba-17448b4f979f/69e0b423-1ba5-489a-b30a-9b162b2ef6bb/1780149806865.webp","certificate_mime":"image/webp","notes":"expiring row","created_at":"2026-05-30T14:03:26.313Z","updated_at":"2026-05-30T14:03:26.952Z"},{"id":"644f6b0f-970b-4c60-8b1a-6d2d4203adb7","pet_id":"67cbc6ff-ee15-47f0-bdba-17448b4f979f","vaccine_code":"feline_core_trio_cat_hu","vaccine_name_snapshot":"Macska kombinált alapoltás (FPV/FHV/FCV)","administered_at":"2025-05-01","expires_at":"2026-05-28","batch_number":null,"vet_name":null,"vet_clinic":null,"certificate_url":null,"certificate_mime":null,"notes":null,"created_at":"2026-05-30T14:03:26.519Z","updated_at":"2026-05-30T14:03:26.519Z"}]}}
        """.data(using: .utf8)!

        let rows = try #require(
            try makeDecoder().decode(ApiEnvelope<VaccinationsResponse>.self, from: json).data?.vaccinations
        )
        #expect(rows.count == 3)

        // Cert present on exactly one row, decoded both ways from real bytes.
        let withCert = try #require(rows.first { $0.id == "69e0b423-1ba5-489a-b30a-9b162b2ef6bb" })
        #expect(withCert.certificateMime == "image/webp")
        #expect(withCert.certificateUrl?.hasSuffix(".webp") == true)
        #expect(withCert.batchNumber == "LOT-EXPIRING")
        #expect(withCert.vetName == "Dr. Teszt")

        let noCert = try #require(rows.first { $0.id == "644f6b0f-970b-4c60-8b1a-6d2d4203adb7" })
        #expect(noCert.certificateUrl == nil)
        #expect(noCert.certificateMime == nil)
        #expect(noCert.batchNumber == nil)

        // Dates decode in real context; expiresDay parses (centralized UTC).
        #expect(withCert.administeredDay != nil)
        #expect(withCert.expiresDay != nil)

        // Rows carry no server status → client derivation, pinned to capture
        // day (2026-05-30) so it matches what the server returned that day.
        let captureDay: Date = {
            var c = DateComponents(); c.year = 2026; c.month = 5; c.day = 30; c.hour = 12
            return VaccinationDate.utcCalendar.date(from: c)!
        }()
        let valid   = try #require(rows.first { $0.expiresAt == "2027-06-01" })
        let expiring = try #require(rows.first { $0.expiresAt == "2026-06-06" })
        let expired = try #require(rows.first { $0.expiresAt == "2026-05-28" })
        #expect(VaccinationStatus.derive(expiresAt: valid.expiresAt,    now: captureDay) == .valid)
        #expect(VaccinationStatus.derive(expiresAt: expiring.expiresAt, now: captureDay) == .expiring)
        #expect(VaccinationStatus.derive(expiresAt: expired.expiresAt,  now: captureDay) == .expired)
        // And the derived signed-days match the server's summary values exactly.
        #expect(VaccinationDate.daysUntil(expiring.expiresAt, now: captureDay) == 7)
        #expect(VaccinationDate.daysUntil(expired.expiresAt,  now: captureDay) == -2)
    }

    // MARK: - Vaccination CRUD object

    @Test("Full vaccination record decodes (contract shape)")
    func fullVaccinationDecodes() throws {
        let json = """
        {"success":true,"data":{"vaccination":{
          "id":"vac-1","pet_id":"pet-1","vaccine_code":"rabies_dog_hu",
          "vaccine_name_snapshot":"Veszettség elleni oltás",
          "administered_at":"2026-01-15","expires_at":"2029-01-15",
          "batch_number":"LOT-42","vet_name":"Dr. Kovács","vet_clinic":"Állatklinika",
          "certificate_url":"https://cdn/cert.webp","certificate_mime":"image/webp",
          "notes":"OK","created_at":"2026-05-30T08:03:00.000Z"
        }}}
        """.data(using: .utf8)!

        let vac = try #require(
            try makeDecoder().decode(ApiEnvelope<VaccinationResponse>.self, from: json).data?.vaccination
        )
        #expect(vac.id == "vac-1")
        #expect(vac.vaccineCode == "rabies_dog_hu")
        #expect(vac.vaccineNameSnapshot == "Veszettség elleni oltás")
        #expect(vac.administeredAt == "2026-01-15")   // DATE-only string, not Date
        #expect(vac.expiresAt == "2029-01-15")
        #expect(vac.certificateMime == "image/webp")
    }

    @Test("Minimal vaccination record decodes with nulls; nil expiry → valid")
    func minimalVaccinationDecodes() throws {
        let json = """
        {"success":true,"data":{"vaccination":{
          "id":"vac-2","pet_id":"pet-1","vaccine_code":"dhpp_dog_hu",
          "vaccine_name_snapshot":"DHPP","administered_at":"2026-03-01",
          "expires_at":null,"batch_number":null,"vet_name":null,"vet_clinic":null,
          "certificate_url":null,"certificate_mime":null,"notes":null,
          "created_at":"2026-05-30T08:03:00.000Z"
        }}}
        """.data(using: .utf8)!

        let vac = try #require(
            try makeDecoder().decode(ApiEnvelope<VaccinationResponse>.self, from: json).data?.vaccination
        )
        #expect(vac.expiresAt == nil)
        #expect(vac.daysUntilExpiry == nil)
        #expect(vac.status == .valid)         // no expiry → always valid
    }

    // MARK: - Status / date derivation (deterministic clock)

    /// Fixed "today" (UTC) so the boundary assertions don't drift with
    /// wall-clock OR with the machine's time zone. Built with the same UTC
    /// calendar the production code uses.
    private var fixedNow: Date {
        var c = DateComponents()
        c.year = 2026; c.month = 6; c.day = 1; c.hour = 12
        return VaccinationDate.utcCalendar.date(from: c)!
    }

    private func expiry(daysFromNow days: Int) -> String {
        let date = VaccinationDate.utcCalendar.date(byAdding: .day, value: days, to: fixedNow)!
        return VaccinationDate.formatter.string(from: date)
    }

    @Test("Status case-set mirrors backend exactly")
    func statusBoundaries() {
        // days < 0 → expired (server: expires_at < CURRENT_DATE).
        #expect(VaccinationStatus.derive(expiresAt: expiry(daysFromNow: -1), now: fixedNow) == .expired)
        // days == 0 (expires today) → expiring, NOT expired (server test is < 0).
        #expect(VaccinationStatus.derive(expiresAt: expiry(daysFromNow: 0),  now: fixedNow) == .expiring)
        #expect(VaccinationStatus.derive(expiresAt: expiry(daysFromNow: 29), now: fixedNow) == .expiring)
        // Day 30 is the boundary: backend uses `< CURRENT_DATE + 30 days`.
        #expect(VaccinationStatus.derive(expiresAt: expiry(daysFromNow: 30), now: fixedNow) == .valid)
        #expect(VaccinationStatus.derive(expiresAt: expiry(daysFromNow: 365), now: fixedNow) == .valid)
        // null expires_at → valid (server's NULL rule; never appears in urgent).
        #expect(VaccinationStatus.derive(expiresAt: nil, now: fixedNow) == .valid)
    }

    @Test("Date-only string is timezone-stable (no day shift)")
    func dateParseIsUTCStable() throws {
        // A record dated 2026-06-12 must read back as 2026-06-12 regardless of
        // the device time zone — the whole reason these fields stay String.
        let day = try #require(VaccinationDate.parse("2026-06-12"))
        #expect(VaccinationDate.formatter.string(from: day) == "2026-06-12")
    }

    @Test("daysUntil is signed and parseable")
    func daysUntilSigned() {
        #expect(VaccinationDate.daysUntil(expiry(daysFromNow: 16), now: fixedNow) == 16)
        #expect(VaccinationDate.daysUntil(expiry(daysFromNow: -3), now: fixedNow) == -3)
        #expect(VaccinationDate.daysUntil(nil, now: fixedNow) == nil)
        #expect(VaccinationDate.daysUntil("not-a-date", now: fixedNow) == nil)
    }

    // MARK: - Request encoding

    @Test("CreateVaccinationRequest omits nil expires_at (server derives it)")
    func createRequestOmitsNilExpiry() throws {
        let req = CreateVaccinationRequest(
            vaccineCode: "rabies_dog_hu", administeredAt: "2026-01-15",
            expiresAt: nil, batchNumber: nil, vetName: nil, vetClinic: nil, notes: nil
        )
        let obj = try encodeToObject(req)
        #expect(obj["vaccine_code"] as? String == "rabies_dog_hu")
        #expect(obj["administered_at"] as? String == "2026-01-15")
        #expect(obj["expires_at"] == nil)        // omitted, not null
        #expect(obj["batch_number"] == nil)
    }

    @Test("UpdateVaccinationRequest never carries vaccine_code; omits nil fields")
    func updateRequestExcludesImmutableCode() throws {
        let req = UpdateVaccinationRequest(
            administeredAt: nil, expiresAt: "2030-01-01",
            batchNumber: nil, vetName: "Dr. Nagy", vetClinic: nil, notes: nil
        )
        let obj = try encodeToObject(req)
        #expect(obj["vaccine_code"] == nil)      // immutable — delete + re-add to change
        #expect(obj["expires_at"] as? String == "2030-01-01")
        #expect(obj["vet_name"] as? String == "Dr. Nagy")
        #expect(obj["administered_at"] == nil)   // nil → omitted (partial update)
        #expect(obj["notes"] == nil)
    }

    private func encodeToObject<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
