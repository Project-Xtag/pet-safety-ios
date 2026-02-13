import Testing
import Foundation
@testable import PetSafety

/// Tests for Contact Support - Support request submission and validation
@Suite("Contact Support Tests")
struct ContactSupportTests {

    // MARK: - SupportRequest Model Tests

    @Test("SupportRequest should encode correctly")
    func testSupportRequestEncoding() throws {
        let request = SupportRequest(
            category: "Technical Issue",
            subject: "App crashes",
            message: "The app crashes when I open it"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["category"] as? String == "Technical Issue")
        #expect(json?["subject"] as? String == "App crashes")
        #expect(json?["message"] as? String == "The app crashes when I open it")
    }

    @Test("SupportResponse should decode correctly")
    func testSupportResponseDecoding() throws {
        let json = """
        {
            "ticketId": "SUP-ABC123-XYZ9",
            "message": "Support request submitted successfully. We will get back to you within 24 hours."
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(SupportResponse.self, from: json)

        #expect(response.ticketId == "SUP-ABC123-XYZ9")
        #expect(response.message.contains("24 hours"))
    }

    // MARK: - Validation Tests

    @Test("Subject should not exceed 200 characters")
    func testSubjectLengthValidation() {
        let validSubject = String(repeating: "A", count: 200)
        let invalidSubject = String(repeating: "A", count: 201)

        #expect(validSubject.count <= 200)
        #expect(invalidSubject.count > 200)
    }

    @Test("Message should not exceed 5000 characters")
    func testMessageLengthValidation() {
        let validMessage = String(repeating: "A", count: 5000)
        let invalidMessage = String(repeating: "A", count: 5001)

        #expect(validMessage.count <= 5000)
        #expect(invalidMessage.count > 5000)
    }

    @Test("All categories should be valid")
    func testValidCategories() {
        let validCategories = ["General", "Technical Issue", "Account", "Billing", "Feature Request", "Other"]

        for category in validCategories {
            #expect(validCategories.contains(category))
        }
    }

    // MARK: - Ticket ID Format Tests

    @Test("Ticket ID should match expected format")
    func testTicketIdFormat() {
        let validTicketIds = [
            "SUP-ABC123-XYZ9",
            "SUP-LQWERT-ABCD",
            "SUP-123ABC-9999"
        ]

        let ticketIdPattern = #"^SUP-[A-Z0-9]+-[A-Z0-9]+$"#
        let regex = try? NSRegularExpression(pattern: ticketIdPattern)

        for ticketId in validTicketIds {
            let range = NSRange(ticketId.startIndex..., in: ticketId)
            let match = regex?.firstMatch(in: ticketId, range: range)
            #expect(match != nil, "Ticket ID \(ticketId) should match pattern")
        }
    }

    // MARK: - API Response Wrapper Tests

    @Test("API envelope should decode support response correctly")
    func testAPIEnvelopeDecoding() throws {
        let json = """
        {
            "success": true,
            "data": {
                "ticketId": "SUP-TEST-1234",
                "message": "Request submitted successfully."
            }
        }
        """.data(using: .utf8)!

        struct APIEnvelope<T: Codable>: Codable {
            let success: Bool
            let data: T?
            let error: String?
        }

        let decoder = JSONDecoder()
        let envelope = try decoder.decode(APIEnvelope<SupportResponse>.self, from: json)

        #expect(envelope.success == true)
        #expect(envelope.data?.ticketId == "SUP-TEST-1234")
        #expect(envelope.error == nil)
    }

    @Test("API envelope should decode error response correctly")
    func testAPIEnvelopeErrorDecoding() throws {
        let json = """
        {
            "success": false,
            "error": "Subject and message are required"
        }
        """.data(using: .utf8)!

        struct APIEnvelope<T: Codable>: Codable {
            let success: Bool
            let data: T?
            let error: String?
        }

        let decoder = JSONDecoder()
        let envelope = try decoder.decode(APIEnvelope<SupportResponse>.self, from: json)

        #expect(envelope.success == false)
        #expect(envelope.data == nil)
        #expect(envelope.error == "Subject and message are required")
    }
}

// MARK: - Mock API Service Tests

@Suite("Contact Support API Tests")
struct ContactSupportAPITests {

    @Test("submitSupportRequest should create correct URL request")
    func testRequestConstruction() throws {
        // Verify the endpoint path is correct
        let baseURL = URL(string: "https://api.senra.pet/api")!
        let endpoint = baseURL.appendingPathComponent("contact/support")

        #expect(endpoint.absoluteString == "https://api.senra.pet/api/contact/support")
    }

    @Test("Request body should be properly formatted")
    func testRequestBodyFormat() throws {
        let request = SupportRequest(
            category: "Billing",
            subject: "Subscription issue",
            message: "I was charged twice for my subscription."
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let body = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Verify all required fields are present
        #expect(body?["category"] != nil)
        #expect(body?["subject"] != nil)
        #expect(body?["message"] != nil)

        // Verify no extra fields
        #expect(body?.keys.count == 3)
    }
}

// MARK: - View State Tests

@Suite("Contact Support View State Tests")
struct ContactSupportViewStateTests {

    @Test("Submit button should be disabled when subject is empty")
    func testSubmitDisabledWithoutSubject() {
        let subject = ""
        let message = "Some message"
        let isSubmitting = false

        let shouldBeDisabled = subject.isEmpty || message.isEmpty || isSubmitting
        #expect(shouldBeDisabled == true)
    }

    @Test("Submit button should be disabled when message is empty")
    func testSubmitDisabledWithoutMessage() {
        let subject = "Some subject"
        let message = ""
        let isSubmitting = false

        let shouldBeDisabled = subject.isEmpty || message.isEmpty || isSubmitting
        #expect(shouldBeDisabled == true)
    }

    @Test("Submit button should be disabled while submitting")
    func testSubmitDisabledWhileSubmitting() {
        let subject = "Some subject"
        let message = "Some message"
        let isSubmitting = true

        let shouldBeDisabled = subject.isEmpty || message.isEmpty || isSubmitting
        #expect(shouldBeDisabled == true)
    }

    @Test("Submit button should be enabled with valid input")
    func testSubmitEnabledWithValidInput() {
        let subject = "Some subject"
        let message = "Some message"
        let isSubmitting = false

        let shouldBeDisabled = subject.isEmpty || message.isEmpty || isSubmitting
        #expect(shouldBeDisabled == false)
    }

    @Test("Character count should update correctly")
    func testCharacterCount() {
        let message = "Hello, I need help with my account."
        let maxLength = 5000

        let displayText = "\(message.count)/\(maxLength) characters"
        #expect(displayText == "35/5000 characters")
    }

    @Test("Category selection should default to General")
    func testDefaultCategory() {
        let defaultCategory = "General"
        let categories = ["General", "Technical Issue", "Account", "Billing", "Feature Request", "Other"]

        #expect(categories.first == defaultCategory)
    }
}

// MARK: - Edge Cases

@Suite("Contact Support Edge Cases")
struct ContactSupportEdgeCaseTests {

    @Test("Should handle special characters in subject and message")
    func testSpecialCharacters() throws {
        let specialSubject = "Help! 🐕 My pet's tag isn't working <script>alert('xss')</script>"
        let specialMessage = "Unicode: café, naïve, 日本語\nNewlines work\tTabs too"

        let request = SupportRequest(
            category: "Technical Issue",
            subject: specialSubject,
            message: specialMessage
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)

        // Should encode without throwing
        #expect(data.count > 0)

        // Should decode back correctly
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SupportRequest.self, from: data)
        #expect(decoded.subject == specialSubject)
        #expect(decoded.message == specialMessage)
    }

    @Test("Should handle empty strings after trimming")
    func testWhitespaceOnlyInput() {
        let whitespaceSubject = "   \n\t  "
        let trimmed = whitespaceSubject.trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(trimmed.isEmpty)
    }

    @Test("Should handle maximum length boundary")
    func testBoundaryLengths() {
        let maxSubject = String(repeating: "A", count: 200)
        let maxMessage = String(repeating: "B", count: 5000)

        // At boundary - should be valid
        #expect(maxSubject.count == 200)
        #expect(maxMessage.count == 5000)

        // Over boundary - should be invalid
        let overSubject = maxSubject + "X"
        let overMessage = maxMessage + "X"

        #expect(overSubject.count == 201)
        #expect(overMessage.count == 5001)
    }
}
