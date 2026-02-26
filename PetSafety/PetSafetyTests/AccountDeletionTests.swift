import Testing
import Foundation
@testable import PetSafety

@Suite("Account Deletion")
struct AccountDeletionTests {

    // MARK: - CanDeleteAccountResponse

    @Test("Decode CanDeleteAccountResponse when eligible to delete")
    func testCanDeleteEligible() throws {
        let json = """
        {
            "canDelete": true,
            "reason": null,
            "message": "Account can be deleted",
            "missingPets": null
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CanDeleteAccountResponse.self, from: json)
        #expect(response.canDelete == true)
        #expect(response.reason == nil)
        #expect(response.message == "Account can be deleted")
        #expect(response.missingPets == nil)
    }

    @Test("Decode CanDeleteAccountResponse when blocked by missing pets")
    func testCanDeleteBlocked() throws {
        let json = """
        {
            "canDelete": false,
            "reason": "missing_pets",
            "message": "You have pets with active missing alerts",
            "missingPets": [
                {
                    "id": "p1",
                    "name": "Buddy"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CanDeleteAccountResponse.self, from: json)
        #expect(response.canDelete == false)
        #expect(response.reason == "missing_pets")
        #expect(response.missingPets?.count == 1)
        #expect(response.missingPets?[0].id == "p1")
        #expect(response.missingPets?[0].name == "Buddy")
    }

    // MARK: - DeleteAccountRequest

    @Test("Encode DeleteAccountRequest with confirmDelete true")
    func testEncodeDeleteAccountRequest() throws {
        let request = DeleteAccountRequest(confirmDelete: true)
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(dict["confirmDelete"] as? Bool == true)
    }

    // MARK: - DeleteAccountResponse

    @Test("Decode DeleteAccountResponse with success message")
    func testDecodeDeleteAccountResponse() throws {
        let json = """
        {
            "message": "Account deleted successfully"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(DeleteAccountResponse.self, from: json)
        #expect(response.message == "Account deleted successfully")
    }

    // MARK: - MissingPetInfo

    @Test("MissingPetInfo encode and decode round-trip")
    func testMissingPetInfoRoundTrip() throws {
        let original = MissingPetInfo(id: "pet_42", name: "Luna")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MissingPetInfo.self, from: data)
        #expect(decoded.id == "pet_42")
        #expect(decoded.name == "Luna")
    }

    @Test("CanDeleteAccountResponse with empty missingPets array")
    func testEmptyMissingPetsArray() throws {
        let json = """
        {
            "canDelete": false,
            "reason": "other_reason",
            "message": null,
            "missingPets": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CanDeleteAccountResponse.self, from: json)
        #expect(response.canDelete == false)
        #expect(response.missingPets != nil)
        #expect(response.missingPets?.isEmpty == true)
    }
}
