import Testing
import Foundation
@testable import PetSafety

/**
 * M12 — pin the iOS Privacy Mode + Secondary Contacts seam. The views and
 * the User model fields shipped before this audit; what was missing was
 * any test that the model fields round-trip correctly and that the views
 * stay wired into the Profile menu.
 *
 * Coverage:
 *   1. User Codable round-trip for all six privacy flags + the two
 *      secondary contact fields. A snake_case rename or a missing CodingKey
 *      would silently null the field on every login.
 *   2. Source-regression: ProfileView still navigates to ContactsView and
 *      PrivacyModeView, and PrivacyModeView still calls updateProfile with
 *      the exact backend keys (snake_case, e.g. "show_name_publicly").
 */
@Suite("Privacy Mode + Secondary Contacts (M12)")
struct PrivacyAndContactsTests {

    // MARK: - Round-trip via Codable

    @Test("User decodes all privacy + secondary contact fields from snake_case JSON")
    func decodesAllPrivacyAndSecondaryFields() throws {
        let json = """
        {
            "id": "user-1",
            "email": "owner@senra.pet",
            "first_name": "Anna",
            "last_name": "Toth",
            "phone": "+36301234567",
            "secondary_phone": "+36309876543",
            "secondary_email": "anna.work@senra.pet",
            "address": "1 Petofi utca",
            "city": "Budapest",
            "postal_code": "1011",
            "country": "HU",
            "show_name_publicly": true,
            "show_phone_publicly": false,
            "show_email_publicly": true,
            "show_address_publicly": false,
            "show_secondary_phone_publicly": true,
            "show_secondary_email_publicly": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: json)

        #expect(user.secondaryPhone == "+36309876543")
        #expect(user.secondaryEmail == "anna.work@senra.pet")
        #expect(user.showNamePublicly == true)
        #expect(user.showPhonePublicly == false)
        #expect(user.showEmailPublicly == true)
        #expect(user.showAddressPublicly == false)
        #expect(user.showSecondaryPhonePublicly == true)
        #expect(user.showSecondaryEmailPublicly == false)
    }

    @Test("User leaves privacy fields nil when absent (legacy backend response)")
    func acceptsMissingPrivacyFields() throws {
        // Older backend builds (or shelter / vet accounts that don't carry
        // privacy state yet) omit these fields entirely. The decoder must
        // not throw or default-true them.
        let json = """
        { "id": "user-1", "email": "anon@senra.pet" }
        """.data(using: .utf8)!

        let user = try JSONDecoder().decode(User.self, from: json)
        #expect(user.secondaryPhone == nil)
        #expect(user.secondaryEmail == nil)
        #expect(user.showNamePublicly == nil)
        #expect(user.showSecondaryEmailPublicly == nil)
    }

    // MARK: - Source-regression — keep the wiring in place

    @Test("source — ProfileView still routes to ContactsView and PrivacyModeView")
    func profileViewRoutesToBothScreens() throws {
        let source = try sourceContents("Views/Profile/ProfileView.swift")
        #expect(source.contains("destination: ContactsView()"),
                "ProfileView must keep the navigation link into ContactsView")
        #expect(source.contains("destination: PrivacyModeView()"),
                "ProfileView must keep the navigation link into PrivacyModeView")
    }

    @Test("source — PrivacyModeView writes through the exact snake_case backend keys")
    func privacyModeViewUsesBackendFieldNames() throws {
        let source = try sourceContents("Views/Profile/PrivacyModeView.swift")
        // Each toggle must call updateProfile with the matching server field.
        // Renaming any of these silently breaks the toggle without a compile
        // error since updateProfile takes [String: Any].
        for key in [
            "show_name_publicly",
            "show_phone_publicly",
            "show_email_publicly",
            "show_address_publicly",
            "show_secondary_phone_publicly",
            "show_secondary_email_publicly",
        ] {
            #expect(source.contains("\"\(key)\""),
                    "PrivacyModeView must persist \(key) via updateProfile")
        }
    }

    @Test("source — ContactsView reads + writes secondaryPhone and secondaryEmail")
    func contactsViewUsesSecondaryFields() throws {
        let source = try sourceContents("Views/Profile/ContactsView.swift")
        #expect(source.contains("secondaryEmail"))
        #expect(source.contains("secondaryPhone"))
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        let prefixCandidates = [
            "PetSafety/PetSafety",
            "PetSafety",
            ".",
        ]
        var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        for _ in 0..<6 {
            for prefix in prefixCandidates {
                let candidate = dir.appendingPathComponent("\(prefix)/\(relativePath)")
                if FileManager.default.fileExists(atPath: candidate.path) {
                    return try String(contentsOf: candidate, encoding: .utf8)
                }
            }
            dir.deleteLastPathComponent()
        }
        throw NSError(
            domain: "PrivacyAndContactsTests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not locate \(relativePath)"]
        )
    }
}
