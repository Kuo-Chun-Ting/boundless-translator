import ApplicationServices
import XCTest

final class SelectionTranslationE2ETests: BoundlessTranslatorE2ETestCase {
    func test_accessibilitySelection_whenTranslationActionRuns_thenPresentsSelectedSourceText() {
        // Arrange
        launchBoundlessTranslator()
        launchFixture()
        fixtureElement("fixture.selectAccessibilityText").click()
        XCTAssertEqual(
            systemSelectedText(),
            "Accessibility selection sample",
            "The fixture did not expose its selected text through macOS Accessibility."
        )

        // Act
        triggerTranslationAction()

        // Assert
        let sourceText = appElement("translation.sourceText")
        XCTAssertTrue(sourceText.waitForExistence(timeout: 10))
        XCTAssertTrue(stringValue(of: sourceText).contains("Accessibility selection sample"))
    }

    func test_copyOnlySelection_whenTranslationActionRuns_thenUsesClipboardFallback() {
        // Arrange
        launchBoundlessTranslator()
        launchFixture()
        fixtureElement("fixture.selectCopyOnlyText").click()
        XCTAssertTrue(
            (systemSelectedText() ?? "").isEmpty,
            "The copy-only editor unexpectedly exposed its selected text through Accessibility."
        )

        // Act
        triggerTranslationAction()

        // Assert
        let sourceText = appElement("translation.sourceText")
        XCTAssertTrue(sourceText.waitForExistence(timeout: 10))
        XCTAssertTrue(stringValue(of: sourceText).contains("Clipboard fallback sample"))
    }

    private func systemSelectedText() -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElementValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementValue
        ) == .success,
        let focusedElementValue
        else {
            return nil
        }

        let focusedElement = focusedElementValue as! AXUIElement
        var selectedTextValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        ) == .success
        else {
            return nil
        }
        return selectedTextValue as? String
    }
}
