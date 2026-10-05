import Foundation
import Testing
@testable import BoundlessTranslator

@Test(.enabled(if: LanguageSupportFixture.isEnabled, "Run Scripts/run_language_support_tests.sh")) @MainActor
func test_language_support_when_runtime_capabilities_change_then_reports_fixture_gaps() async throws {
    // Arrange
    let fixtures = try LanguageSupportFixture.load()

    // Act
    let capabilities = try await LanguageSupportCapabilities.load()
    let translationGroups = capabilities.translationGroups
    let ocrGroups = capabilities.ocrGroups
    let screenshotGroups = capabilities.screenshotGroups
    let fixtureGroups = Set(fixtures.map(\.id))
    let imageGroups = Set(fixtures.filter { $0.ocrImage != nil }.map(\.id))

    // Assert
    #expect(!translationGroups.isEmpty)
    #expect(!ocrGroups.isEmpty)
    #expect(fixtureGroups.count == fixtures.count, "Fixture language identifiers must be unique.")
    #expect(translationGroups.subtracting(fixtureGroups).isEmpty, "New translation languages need fixtures: \(translationGroups.subtracting(fixtureGroups).sorted())")
    #expect(screenshotGroups.subtracting(imageGroups).isEmpty, "New screenshot source languages need images: \(screenshotGroups.subtracting(imageGroups).sorted())")
    print("ENVIRONMENT: \(ProcessInfo.processInfo.operatingSystemVersionString); Vision revision \(capabilities.ocrRevision), accurate, automatic language detection")
    print("Translation: \(translationGroups.sorted())")
    print("Translation (raw API identifiers): \(capabilities.translation.sorted())")
    print("OCR (raw API identifiers): \(capabilities.ocr.sorted())")
    print("Screenshot sources: \(screenshotGroups.sorted())")
    print("Translation without OCR: \(translationGroups.subtracting(ocrGroups).sorted())")
    print("OCR without translation: \(ocrGroups.subtracting(translationGroups).sorted())")
    let interfaceGroups = Set(capabilities.interface.map(LanguageSupportFixture.languageGroup))
    print("Interface without translation: \(interfaceGroups.subtracting(translationGroups).sorted())")
    print("Translation without interface: \(translationGroups.subtracting(interfaceGroups).sorted())")
    print("Fixture languages unsupported on this Mac (not exercised): \(fixtureGroups.subtracting(translationGroups).sorted())")
    print("Interface (bundle identifiers): \(capabilities.interface.sorted())")
}
