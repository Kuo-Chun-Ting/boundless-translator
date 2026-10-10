import ApplicationServices
import XCTest

final class SelectionTranslationE2ETests: BoundlessTranslatorE2ETestCase {
    func test_selectionTranslation_when_editorsExposeOrHideSelectedText_then_translatesBothSelections() {
        // Arrange
        launchBoundlessTranslator()
        launchFixture()
        // Act & Assert
        XCTContext.runActivity(named: "Translate from an editor exposing selected text") { _ in
            fixtureElement("fixture.selectAccessibilityText").click()
            XCTAssertEqual(systemSelectedText(), "Accessibility selection sample",
                           "The fixture must expose its selected text through macOS Accessibility.")
            translateAndCheckSelection("Accessibility selection sample")
        }
        XCTContext.runActivity(named: "Translate from a copy-only editor") { _ in
            fixture.activate()
            XCTAssertTrue(fixture.wait(for: .runningForeground, timeout: 5))
            fixtureElement("fixture.selectCopyOnlyText").click()
            XCTAssertTrue((systemSelectedText() ?? "").isEmpty,
                          "The copy-only editor must not expose selected text through Accessibility.")
            translateAndCheckSelection("Clipboard fallback sample")
        }
    }

    private func translateAndCheckSelection(_ expectedSource: String) {
        triggerTranslationAction()
        let sourceText = appElement("translation.sourceText")
        XCTAssertTrue(sourceText.waitForExistence(timeout: 10))
        XCTAssertEqual(stringValue(of: sourceText).trimmingCharacters(in: .whitespacesAndNewlines), expectedSource)
        assertTranslationAppears()
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
