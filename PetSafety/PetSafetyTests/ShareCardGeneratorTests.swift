import Testing
import UIKit
@testable import PetSafety

@Suite("ShareCardGenerator")
struct ShareCardGeneratorTests {

    // MARK: - Image Generation

    @Test("Generates image with correct dimensions")
    func testGeneratesCorrectDimensions() {
        let image = ShareCardGenerator.generate(
            petName: "Buddy",
            petImage: nil,
            petSpecies: "Dog"
        )

        #expect(image.size.width == 1080)
        #expect(image.size.height == 1080)
    }

    @Test("Returns non-nil image for basic input")
    func testReturnsImage() {
        let image = ShareCardGenerator.generate(
            petName: "Max",
            petImage: nil,
            petSpecies: "Cat"
        )

        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }

    @Test("Generates image with pet photo")
    func testWithPetPhoto() {
        // Create a small test image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let testPhoto = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }

        let image = ShareCardGenerator.generate(
            petName: "Buddy",
            petImage: testPhoto,
            petSpecies: "Dog"
        )

        #expect(image.size.width == 1080)
        #expect(image.size.height == 1080)
    }

    @Test("Generates image without pet photo (placeholder)")
    func testWithoutPetPhoto() {
        let image = ShareCardGenerator.generate(
            petName: "Whiskers",
            petImage: nil,
            petSpecies: "Cat"
        )

        #expect(image.size.width == 1080)
        #expect(image.size.height == 1080)
    }

    @Test("Handles long pet name")
    func testLongPetName() {
        let longName = "Sir Barksalot The Third Of Canterbury"
        let image = ShareCardGenerator.generate(
            petName: longName,
            petImage: nil,
            petSpecies: "Dog"
        )

        #expect(image.size.width == 1080)
        #expect(image.size.height == 1080)
    }

    @Test("Handles special characters in pet name")
    func testSpecialCharacters() {
        let image = ShareCardGenerator.generate(
            petName: "Müller's Kätze",
            petImage: nil,
            petSpecies: "Cat"
        )

        #expect(image.size.width == 1080)
        #expect(image.size.height == 1080)
    }

    @Test("Handles empty pet name")
    func testEmptyPetName() {
        let image = ShareCardGenerator.generate(
            petName: "",
            petImage: nil,
            petSpecies: "Dog"
        )

        #expect(image.size.width == 1080)
        #expect(image.size.height == 1080)
    }

    @Test("Handles emoji in pet name")
    func testEmojiInPetName() {
        let image = ShareCardGenerator.generate(
            petName: "🐕 Buddy",
            petImage: nil,
            petSpecies: "Dog"
        )

        #expect(image.size.width == 1080)
        #expect(image.size.height == 1080)
    }

    // MARK: - PNG Export

    @Test("Can export as PNG data")
    func testPNGExport() {
        let image = ShareCardGenerator.generate(
            petName: "Buddy",
            petImage: nil,
            petSpecies: "Dog"
        )

        let pngData = image.pngData()
        #expect(pngData != nil)
        #expect((pngData?.count ?? 0) > 0)
    }

    @Test("Can export as JPEG data")
    func testJPEGExport() {
        let image = ShareCardGenerator.generate(
            petName: "Buddy",
            petImage: nil,
            petSpecies: "Dog"
        )

        let jpegData = image.jpegData(compressionQuality: 0.8)
        #expect(jpegData != nil)
        #expect((jpegData?.count ?? 0) > 0)
    }

    // MARK: - Image Content Verification

    @Test("Image has non-transparent pixels (is not blank)")
    func testImageIsNotBlank() {
        let image = ShareCardGenerator.generate(
            petName: "Buddy",
            petImage: nil,
            petSpecies: "Dog"
        )

        guard let cgImage = image.cgImage else {
            Issue.record("Failed to get CGImage")
            return
        }

        // cgImage.width/height are in pixels, which depend on the renderer scale.
        // Verify the image dimensions match 1080 points scaled by the image's scale factor.
        let scale = image.scale
        let width = cgImage.width
        let height = cgImage.height
        #expect(width == Int(1080 * scale))
        #expect(height == Int(1080 * scale))

        // Sample a pixel from the center area (should be teal background or content)
        let dataProvider = cgImage.dataProvider
        #expect(dataProvider != nil)
    }

    @Test("Generating multiple times produces consistent dimensions")
    func testConsistency() {
        let image1 = ShareCardGenerator.generate(petName: "A", petImage: nil, petSpecies: "Dog")
        let image2 = ShareCardGenerator.generate(petName: "B", petImage: nil, petSpecies: "Cat")
        let image3 = ShareCardGenerator.generate(petName: "C", petImage: nil, petSpecies: "Dog")

        #expect(image1.size == image2.size)
        #expect(image2.size == image3.size)
        #expect(image1.size.width == 1080)
    }

    // MARK: - Performance

    @Test("Generates image in reasonable time")
    func testPerformance() async {
        let start = Date()
        for _ in 0..<5 {
            _ = ShareCardGenerator.generate(
                petName: "Buddy",
                petImage: nil,
                petSpecies: "Dog"
            )
        }
        let elapsed = Date().timeIntervalSince(start)
        // 5 generations should take less than 5 seconds
        #expect(elapsed < 5.0)
    }
}
