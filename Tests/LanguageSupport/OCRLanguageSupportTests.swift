import Foundation
import ImageIO
import Testing
@testable import BoundlessTranslator

@Test(
    .enabled(if: LanguageSupportFixture.isEnabled, "Run Tests/Runners/run_language_support_tests.sh"),
    .serialized,
    arguments: try await LanguageSupportFixture.ocrFixtures()
)
func test_recognize_when_image_contains_supported_language_then_returns_fixture_text(
    fixture: LanguageSupportFixture
) throws {
    // Arrange
    let name = try #require(fixture.ocrImage)
    let url = try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures/OCR"))
    let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
    let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))

    // Act
    let result = try ImageTextRecognizer.recognize(image, size: CGSize(width: image.width, height: image.height))

    // Assert
    #expect(result.text.precomposedStringWithCanonicalMapping == fixture.text.precomposedStringWithCanonicalMapping)
}
