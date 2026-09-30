import XCTest

final class HintPresentationGUITests: XCTestCase {
    private var app: XCUIApplication!
    private var datastore: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        datastore = FileManager.default.temporaryDirectory.appendingPathComponent("hint-tests-\(UUID().uuidString)")
        app = XCUIApplication()
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_DATASTORE"] = datastore.path
    }

    override func tearDownWithError() throws {
        app.terminate()
        try? FileManager.default.removeItem(at: datastore)
    }

    func test_dictionaryHint_whenFirstUsed_then_appearsUntilUserDismisses() {
        // Arrange
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] = "dictionary"
        let hint = app.staticTexts["Dictionary"]

        // Act & Assert
        checkHintLifecycle(hint: hint, readyElement: app.textViews["translation.sourceText"]) {
            self.assertDictionaryHintPosition()
        }
    }

    func test_screenshotHint_whenFirstUsed_then_appearsUntilUserDismisses() {
        // Arrange
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] = "screenshot"
        let hint = app.staticTexts["Select text and press ⌥T to translate."]

        // Act & Assert
        let screenshotWindow = app.windows["Screenshot Translation"]
        checkHintLifecycle(hint: hint, readyElement: screenshotWindow) {
            self.assertScreenshotHintPosition(relativeTo: screenshotWindow)
        }
    }

    private func checkHintLifecycle(
        hint: XCUIElement,
        readyElement: XCUIElement,
        checkPosition: () -> Void = {}
    ) {
        app.launch()
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        XCTAssertTrue(hint.isHittable)
        captureHint()

        app.terminate()
        app.launch()
        XCTAssertTrue(hint.waitForExistence(timeout: 5), "Reopening without dismissing must preserve the hint.")
        app.buttons["Close"].firstMatch.click()
        XCTAssertTrue(hint.waitForNonExistence(timeout: 5))

        app.terminate()
        app.launch()
        XCTAssertTrue(readyElement.waitForExistence(timeout: 5))
        XCTAssertTrue(hint.waitForExistence(timeout: 5), "Closing without the checkbox must allow the hint next time.")
        checkPosition()
        app.checkBoxes["Don’t show again"].firstMatch.click()
        XCTAssertTrue(hint.exists, "Checking the option must not close the hint.")
        app.buttons["Close"].firstMatch.click()
        XCTAssertTrue(hint.waitForNonExistence(timeout: 5))

        app.terminate()
        app.launch()
        XCTAssertTrue(readyElement.waitForExistence(timeout: 5))
        XCTAssertFalse(hint.waitForExistence(timeout: 2), "Only closing with the checkbox selected hides the hint permanently.")

        app.terminate()
        let otherKind = app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] == "dictionary" ? "screenshot" : "dictionary"
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] = otherKind
        app.launch()
        XCTAssertTrue(app.checkBoxes["Don’t show again"].firstMatch.waitForExistence(timeout: 5),
                      "Permanently dismissing one hint must not hide the other.")
    }

    func test_hints_whenDarkAppearance_then_appearInTheirWindows() {
        // Arrange
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_APPEARANCE"] = "dark"

        // Act & Assert
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] = "dictionary"
        app.launch()
        XCTAssertTrue(app.staticTexts["Dictionary"].waitForExistence(timeout: 5))
        assertDictionaryHintPosition()
        captureHint()
        app.terminate()

        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] = "screenshot"
        app.launch()
        XCTAssertTrue(app.staticTexts["Select text and press ⌥T to translate."].waitForExistence(timeout: 5))
        assertScreenshotHintPosition(relativeTo: app.windows["Screenshot Translation"])
        captureHint()
    }

    private func assertDictionaryHintPosition() {
        let hint = app.groups["hint.dictionary"].firstMatch
        XCTAssertTrue(hint.exists)
        let hintFrame = hintSurfaceFrame(hint)
        let sourceFrame = app.textViews["translation.sourceText"].frame
        let windowFrame = app.windows.firstMatch.frame
        XCTAssertGreaterThan(hintFrame.height, 50, "Measure the whole hint, including its message and close button.")
        XCTAssertTrue(windowFrame.contains(hintFrame), "Keep the whole hint inside the translation window.")
        XCTAssertLessThanOrEqual(hintFrame.maxX, windowFrame.midX + 2, "Keep the hint in the source column.")
        XCTAssertGreaterThanOrEqual(hintFrame.minY, sourceFrame.maxY - 2, "Place the hint below the source text.")
    }

    private func assertScreenshotHintPosition(relativeTo window: XCUIElement) {
        let hint = app.groups["hint.screenshot"].firstMatch
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        XCTAssertTrue(hint.staticTexts["Translate Selected Text"].exists)
        XCTAssertTrue(hint.staticTexts["Select text and press ⌥T to translate."].exists)
        let hintFrame = hintSurfaceFrame(hint)
        let windowFrame = window.frame
        XCTAssertGreaterThan(hintFrame.height, 50)
        XCTAssertTrue(windowFrame.contains(hintFrame), "Keep the whole hint inside the screenshot window.")
        XCTAssertLessThan(hintFrame.midX, windowFrame.midX, "Keep the hint near the left side.")
        XCTAssertGreaterThan(hintFrame.minY, windowFrame.minY + 30, "Leave space below the title bar.")
        XCTAssertLessThan(hintFrame.midY, windowFrame.midY, "Keep the hint near the upper side.")
    }

    private func hintSurfaceFrame(_ hint: XCUIElement) -> CGRect {
        // SwiftUI exposes the group's content bounds; the shared card adds 12pt padding.
        hint.frame.insetBy(dx: -12, dy: -12)
    }

    private func captureHint() {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = "Hint before dismissal"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
