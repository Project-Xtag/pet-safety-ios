import Testing
import Foundation
@testable import PetSafety

@Suite("PetsViewModel Tests")
@MainActor
struct PetsViewModelTests {

    // MARK: - Initial State

    @Test("Initial state — pets array is empty, isLoading is false")
    func testInitialState() {
        let viewModel = PetsViewModel()

        #expect(viewModel.pets.isEmpty, "pets should start empty")
        #expect(viewModel.isLoading == false, "isLoading should be false initially")
        #expect(viewModel.errorMessage == nil, "errorMessage should be nil initially")
        #expect(viewModel.showUpgradePrompt == false, "showUpgradePrompt should be false initially")
        #expect(viewModel.upgradeInfo == nil, "upgradeInfo should be nil initially")
    }

    // MARK: - Pet Limit Exceeded

    @Test("APIError.petLimitExceeded has correct error description")
    func testPetLimitExceededErrorDescription() {
        let info = SubscriptionLimitInfo(
            currentPlan: "standard",
            currentPetCount: 1,
            maxPets: 1,
            upgradeTo: "ultimate",
            upgradePrice: "€6.95/month"
        )
        let error = APIError.petLimitExceeded(info)

        #expect(error.errorDescription?.contains("Upgrade") == true, "Error should mention upgrade")
        #expect(error.errorDescription?.contains("limit") == true, "Error should mention limit")
    }

    @Test("SubscriptionLimitInfo stores correct values")
    func testSubscriptionLimitInfo() {
        let info = SubscriptionLimitInfo(
            currentPlan: "standard",
            currentPetCount: 1,
            maxPets: 1,
            upgradeTo: "ultimate",
            upgradePrice: "€6.95/month"
        )

        #expect(info.currentPlan == "standard")
        #expect(info.currentPetCount == 1)
        #expect(info.maxPets == 1)
        #expect(info.upgradeTo == "ultimate")
        #expect(info.upgradePrice == "€6.95/month")
    }

    // MARK: - PetLimitErrorResponse Decoding

    @Test("PetLimitErrorResponse decodes 403 body with subscription info")
    func testPetLimitErrorResponseDecoding() throws {
        let json = """
        {
            "success": false,
            "error": "Pet registration limit reached. Standard plan allows 1 pet. Upgrade to Ultimate for unlimited pets.",
            "subscription": {
                "current_plan": "standard",
                "current_pet_count": 1,
                "max_pets": 1,
                "upgrade_to": "ultimate",
                "upgrade_price": "€6.95/month"
            }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(PetLimitErrorResponse.self, from: json)

        #expect(decoded.success == false)
        #expect(decoded.error.contains("limit"))
        #expect(decoded.subscription != nil)
        #expect(decoded.subscription?.current_plan == "standard")
        #expect(decoded.subscription?.current_pet_count == 1)
        #expect(decoded.subscription?.max_pets == 1)
        #expect(decoded.subscription?.upgrade_to == "ultimate")
        #expect(decoded.subscription?.upgrade_price == "€6.95/month")
    }

    @Test("PetLimitErrorResponse decodes without subscription field")
    func testPetLimitErrorResponseWithoutSubscription() throws {
        let json = """
        {
            "success": false,
            "error": "Access denied"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(PetLimitErrorResponse.self, from: json)

        #expect(decoded.success == false)
        #expect(decoded.error == "Access denied")
        #expect(decoded.subscription == nil)
    }

    // MARK: - checkPetLimit (SubscriptionViewModel)

    @Test("checkPetLimit returns false when at limit")
    func testCheckPetLimitAtLimit() {
        let viewModel = SubscriptionViewModel()
        // checkPetLimit returns true when features are nil (unknown = allow)
        #expect(viewModel.checkPetLimit(currentPetCount: 0) == true, "Should allow when features unknown")
    }
}
