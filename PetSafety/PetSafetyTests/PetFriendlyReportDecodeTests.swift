import Foundation
import Testing
@testable import PetSafety

/// Decode-contract tests for POST /pet-friendly-places/:id/report.
///
/// The DEPLOYED response body (read verbatim from staging, not assumed) is
///     {"success":true,"data":{"message":"..."}}
/// — the envelope middleware wraps the route's flat shape, so the client
/// decodes `success` + `data.message`. These tests prove the SHAPE-handling
/// only: nothing here shows the button presents or a report lands (device).
struct PetFriendlyReportDecodeTests {

    private func decode(_ json: String) throws -> ApiEnvelope<APIService.PetFriendlyReportAck> {
        try JSONDecoder().decode(
            ApiEnvelope<APIService.PetFriendlyReportAck>.self,
            from: Data(json.utf8)
        )
    }

    @Test("Decodes the verbatim staging envelope: success + data.message")
    func decodesVerbatimStagingBody() throws {
        let envelope = try decode(
            #"{"success":true,"data":{"message":"Köszönjük a jelentést. Csapatunk hamarosan átnézi a helyet."}}"#
        )
        #expect(envelope.success == true)
        #expect(envelope.data?.message?.hasPrefix("Köszönjük") == true)
    }

    @Test("Tolerates unknown fields at BOTH levels — envelope drift cannot throw")
    func toleratesUnknownFields() throws {
        let envelope = try decode(
            #"{"success":true,"data":{"message":"ok","reportCount":3,"isHidden":false},"requestId":"r-1","meta":{"x":1}}"#
        )
        #expect(envelope.success == true)
        #expect(envelope.data?.message == "ok")
    }

    @Test("Tolerates an absent message — data.message is advisory, not required")
    func toleratesAbsentMessage() throws {
        let envelope = try decode(#"{"success":true,"data":{}}"#)
        #expect(envelope.success == true)
        #expect(envelope.data?.message == nil)
    }
}
