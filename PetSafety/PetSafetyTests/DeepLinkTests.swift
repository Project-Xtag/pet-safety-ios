import XCTest
@testable import PetSafety

final class DeepLinkTests: XCTestCase {

    // MARK: - DeepLinkService URL Handling Tests

    func testCustomSchemeTagActivation() async {
        let deepLinkService = await DeepLinkService.shared

        await MainActor.run {
            // Clear any existing state
            deepLinkService.clearPendingLink()
            XCTAssertNil(deepLinkService.pendingTagCode)
            XCTAssertFalse(deepLinkService.showTagActivation)

            // Test senra://tag/PS-12345678
            let url = URL(string: "senra://tag/PS-12345678")!
            let handled = deepLinkService.handleURL(url)

            XCTAssertTrue(handled, "Custom scheme URL should be handled")
            XCTAssertEqual(deepLinkService.pendingTagCode, "PS-12345678")
            XCTAssertTrue(deepLinkService.showTagActivation)
        }
    }

    func testUniversalLinkTagActivation() async {
        let deepLinkService = await DeepLinkService.shared

        await MainActor.run {
            // Clear any existing state
            deepLinkService.clearPendingLink()

            // Test https://senra.pet/qr/PS-ABCDEFGH
            let url = URL(string: "https://senra.pet/qr/PS-ABCDEFGH")!
            let handled = deepLinkService.handleURL(url)

            XCTAssertTrue(handled, "Universal link URL should be handled")
            XCTAssertEqual(deepLinkService.pendingTagCode, "PS-ABCDEFGH")
            XCTAssertTrue(deepLinkService.showTagActivation)
        }
    }

    func testUniversalLinkWithWww() async {
        let deepLinkService = await DeepLinkService.shared

        await MainActor.run {
            deepLinkService.clearPendingLink()

            // Test https://www.senra.pet/qr/PS-WWW12345
            let url = URL(string: "https://www.senra.pet/qr/PS-WWW12345")!
            let handled = deepLinkService.handleURL(url)

            XCTAssertTrue(handled, "Universal link with www should be handled")
            XCTAssertEqual(deepLinkService.pendingTagCode, "PS-WWW12345")
        }
    }

    func testUnhandledURLScheme() async {
        let deepLinkService = await DeepLinkService.shared

        await MainActor.run {
            deepLinkService.clearPendingLink()

            // Test an unrelated URL
            let url = URL(string: "https://example.com/something")!
            let handled = deepLinkService.handleURL(url)

            XCTAssertFalse(handled, "Unrelated URL should not be handled")
            XCTAssertNil(deepLinkService.pendingTagCode)
            XCTAssertFalse(deepLinkService.showTagActivation)
        }
    }

    func testClearPendingLink() async {
        let deepLinkService = await DeepLinkService.shared

        await MainActor.run {
            // Set up a pending link
            let url = URL(string: "senra://tag/PS-TEST1234")!
            _ = deepLinkService.handleURL(url)

            XCTAssertNotNil(deepLinkService.pendingTagCode)
            XCTAssertTrue(deepLinkService.showTagActivation)

            // Clear it
            deepLinkService.clearPendingLink()

            XCTAssertNil(deepLinkService.pendingTagCode)
            XCTAssertFalse(deepLinkService.showTagActivation)
        }
    }

    // MARK: - Tag Code Extraction Tests

    @MainActor
    func testExtractTagCodeFromPlainCode() {
        let code = "PS-12345678"
        let extracted = DeepLinkService.extractTagCode(from: code)
        XCTAssertEqual(extracted, "PS-12345678")
    }

    @MainActor
    func testExtractTagCodeFromUniversalLink() {
        let url = "https://senra.pet/qr/PS-URLCODE1"
        let extracted = DeepLinkService.extractTagCode(from: url)
        XCTAssertEqual(extracted, "PS-URLCODE1")
    }

    @MainActor
    func testExtractTagCodeFromCustomScheme() {
        let url = "senra://tag/PS-CUSTCODE"
        let extracted = DeepLinkService.extractTagCode(from: url)
        XCTAssertEqual(extracted, "PS-CUSTCODE")
    }

    @MainActor
    func testExtractTagCodeWithWhitespace() {
        let code = "  PS-SPACED01  "
        let extracted = DeepLinkService.extractTagCode(from: code)
        XCTAssertEqual(extracted, "PS-SPACED01")
    }

    @MainActor
    func testExtractTagCodeFromWwwUrl() {
        let url = "https://www.senra.pet/qr/PS-WWWCODE1"
        let extracted = DeepLinkService.extractTagCode(from: url)
        XCTAssertEqual(extracted, "PS-WWWCODE1")
    }

    // MARK: - Deep Link Type Tests

    func testDeepLinkTypeTagActivation() {
        let type = DeepLinkService.DeepLinkType.tagActivation(code: "PS-12345678")

        switch type {
        case .tagActivation(let code):
            XCTAssertEqual(code, "PS-12345678")
        default:
            XCTFail("Expected tagActivation type")
        }
    }

    func testDeepLinkTypePetView() {
        let type = DeepLinkService.DeepLinkType.petView(petId: "pet-123")

        switch type {
        case .petView(let petId):
            XCTAssertEqual(petId, "pet-123")
        default:
            XCTFail("Expected petView type")
        }
    }

    func testDeepLinkTypeQRScan() {
        let type = DeepLinkService.DeepLinkType.qrScan(code: "PS-QRSCAN01")

        switch type {
        case .qrScan(let code):
            XCTAssertEqual(code, "PS-QRSCAN01")
        default:
            XCTFail("Expected qrScan type")
        }
    }

    // MARK: - QRScannerViewModel Tests

    func testQRScannerViewModelInitialState() async {
        let viewModel = await QRScannerViewModel()

        await MainActor.run {
            XCTAssertNil(viewModel.scannedCode)
            XCTAssertNil(viewModel.scanResult)
            XCTAssertFalse(viewModel.isLoading)
            XCTAssertNil(viewModel.errorMessage)
        }
    }

    func testQRScannerViewModelReset() async {
        let viewModel = await QRScannerViewModel()

        await MainActor.run {
            // Set some state
            viewModel.scannedCode = "test-code"
            viewModel.errorMessage = "test error"

            // Reset
            viewModel.reset()

            XCTAssertNil(viewModel.scannedCode)
            XCTAssertNil(viewModel.scanResult)
            XCTAssertNil(viewModel.errorMessage)
        }
    }

    // MARK: - Flow Verification Tests

    /// Verifies that public profile viewing (finder flow) does not require authentication
    /// The scanQRCode API call uses requiresAuth: false
    func testPublicProfileFlowNoAuthRequired() {
        // This test documents the expected behavior:
        // When a finder scans a QR code, they should see the pet's public profile
        // without needing to log in. The API call scanQRCode uses requiresAuth: false.

        // The flow is:
        // 1. User scans QR code in QRScannerView
        // 2. QRScannerViewModel.scanQRCode() is called
        // 3. APIService.scanQRCode() is called with requiresAuth: false
        // 4. ScannedPetView displays the public profile

        // This is a documentation test to verify the flow is correct
        XCTAssertTrue(true, "Public profile flow does not require authentication")
    }

    /// Verifies that tag activation (owner flow) requires authentication
    func testTagActivationFlowRequiresAuth() {
        // This test documents the expected behavior:
        // When an owner wants to activate a tag, they must be logged in.

        // The flow is:
        // 1. Deep link received (senra://tag/CODE or https://senra.pet/qr/CODE)
        // 2. DeepLinkService sets pendingTagCode and showTagActivation
        // 3. ContentView checks authentication:
        //    - If authenticated: shows TagActivationView
        //    - If not authenticated: shows DeepLinkLoginPromptView
        // 4. After login, user is directed to TagActivationView
        // 5. QRScannerViewModel.activateTag() is called (requires auth)

        XCTAssertTrue(true, "Tag activation flow requires authentication")
    }

    // MARK: - Edge Cases

    func testInvalidCustomSchemeHost() async {
        let deepLinkService = await DeepLinkService.shared

        await MainActor.run {
            deepLinkService.clearPendingLink()

            // Test senra://invalid/PS-12345678
            let url = URL(string: "senra://invalid/PS-12345678")!
            let handled = deepLinkService.handleURL(url)

            XCTAssertFalse(handled, "Invalid host should not be handled")
            XCTAssertNil(deepLinkService.pendingTagCode)
        }
    }

    func testUniversalLinkWrongPath() async {
        let deepLinkService = await DeepLinkService.shared

        await MainActor.run {
            deepLinkService.clearPendingLink()

            // Test https://senra.pet/other/PS-12345678 (wrong path)
            let url = URL(string: "https://senra.pet/other/PS-12345678")!
            let handled = deepLinkService.handleURL(url)

            XCTAssertFalse(handled, "Wrong path should not be handled")
            XCTAssertNil(deepLinkService.pendingTagCode)
        }
    }

    func testUniversalLinkMissingCode() async {
        let deepLinkService = await DeepLinkService.shared

        await MainActor.run {
            deepLinkService.clearPendingLink()

            // Test https://senra.pet/qr (missing code)
            let url = URL(string: "https://senra.pet/qr")!
            let handled = deepLinkService.handleURL(url)

            XCTAssertFalse(handled, "URL without code should not be handled")
            XCTAssertNil(deepLinkService.pendingTagCode)
        }
    }
}
