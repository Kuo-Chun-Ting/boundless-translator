import XCTest

final class HintPresentationGUITests: XCTestCase {
    private var app: XCUIApplication!
    private var datastore: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        datastore = FileManager.default.temporaryDirectory.appendingPathComponent("hint-tests-\(UUID().uuidString)")
        app = XCUIApplication()
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_DATASTORE"] = datastore.path
        app.launchEnvironment["BOUNDLESS_HINT_OBSERVATIONS"] = datastore.appendingPathExtension("json").path
    }

    override func tearDownWithError() throws {
        app.terminate()
        try? FileManager.default.removeItem(at: datastore)
        try? FileManager.default.removeItem(at: datastore.appendingPathExtension("json"))
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

    func test_settingsHint_when_firstOpened_then_appearsAtRightUntilPermanentlyDismissed() {
        // Arrange
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] = "settings"
        let hint = app.groups["hint.settings"].firstMatch

        // Act & Assert
        checkHintLifecycle(hint: hint, readyElement: app.buttons["usageHelpButton"]) {
            self.assertSettingsHintPosition()
        }
    }

    private func assertSettingsHintPosition() {
        let hint = app.groups["hint.settings"].firstMatch
        let settings = app.windows["Boundless Translator Settings"]
        let help = settings.buttons["usageHelpButton"]
        XCTAssertGreaterThan(hint.frame.minX, settings.frame.maxX)
        XCTAssertEqual(hint.frame.maxY - 28, help.frame.midY, accuracy: 3)
        XCTAssertTrue(hint.staticTexts["How to Use"].exists)
        XCTAssertTrue(hint.staticTexts["Click ? to see how to translate selected text and screenshots."].exists)
    }

    func test_settingsHint_when_settingsMoves_then_followsAtRightAndHelpStillOpens() {
        // Arrange
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] = "settings"
        app.launch()
        app.activate()
        let hint = app.groups["hint.settings"].firstMatch
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        let settings = app.windows["Boundless Translator Settings"]
        let before = hint.frame
        let titlebar = settings.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 180, dy: 12))

        // Act
        titlebar.press(forDuration: 0.1, thenDragTo: titlebar.withOffset(CGVector(dx: -60, dy: 40)))

        // Assert
        XCTAssertEqual(hint.frame.minX, before.minX - 60, accuracy: 3)
        XCTAssertEqual(hint.frame.minY, before.minY + 40, accuracy: 3)
        assertSettingsHintPosition()
        settings.buttons["usageHelpButton"].click()
        XCTAssertTrue(app.staticTexts["For selectable text, select it in another app and press ⇧⌘1 to translate."].waitForExistence(timeout: 5))
        captureHint()
    }

    func test_settingsHint_when_localizedInLightAndDark_then_textAndControlsFitInCard() {
        for appearance in ["light", "dark"] {
            for language in ["en", "zh-Hant", "de", "ar"] {
                // Arrange
                app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] = "settings"
                app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_LANGUAGE"] = language
                app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_APPEARANCE"] = appearance

                // Act
                app.launch()
                let hint = app.groups["hint.settings"].firstMatch
                XCTAssertTrue(hint.waitForExistence(timeout: 5))

                // Assert
                let titles = ["en": "How to Use", "zh-Hant": "使用方式", "de": "Verwendung", "ar": "الاستخدام"]
                XCTAssertTrue(hint.staticTexts[titles[language]!].waitForExistence(timeout: 5))
                let texts = hint.staticTexts.allElementsBoundByIndex
                XCTAssertGreaterThanOrEqual(texts.count, 2)
                for text in texts {
                    XCTAssertTrue(hint.frame.insetBy(dx: -1, dy: -1).contains(text.frame), text.label)
                }
                XCTAssertTrue(hint.checkBoxes.firstMatch.isHittable)
                XCTAssertTrue(hint.buttons.firstMatch.isHittable)
                XCTAssertFalse(hint.checkBoxes.firstMatch.frame.intersects(hint.buttons.firstMatch.frame))
                if language == "ar" {
                    XCTAssertLessThan(hint.buttons.firstMatch.frame.midX, hint.checkBoxes.firstMatch.frame.midX)
                } else {
                    XCTAssertGreaterThan(hint.buttons.firstMatch.frame.midX, hint.checkBoxes.firstMatch.frame.midX)
                }
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "Settings hint \(language) \(appearance)"
                attachment.lifetime = .keepAlways
                add(attachment)
                let card = XCTAttachment(screenshot: hint.screenshot())
                card.name = "Settings card \(language) \(appearance)"
                card.lifetime = .keepAlways
                add(card)
                app.terminate()
            }
        }
    }

    func test_usageGuide_when_opened_then_usesConsistentFeatureSpacing() {
        for appearance in ["light", "dark"] {
            for language in ["en", "zh-Hant"] {
                // Arrange
                app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] = "settings"
                app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_LANGUAGE"] = language
                app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_APPEARANCE"] = appearance
                app.launch()
                app.activate()

                // Act
                app.buttons["usageHelpButton"].click()
                let guide = app.groups["usageGuide"].firstMatch
                XCTAssertTrue(guide.waitForExistence(timeout: 5))

                // Assert
                let dictionary = guide.groups["usageItem.lookUp"].firstMatch
                let reading = guide.groups["usageItem.listen"].firstMatch
                XCTAssertTrue(dictionary.staticTexts[language == "en" ? "Dictionary" : "字典"].exists)
                XCTAssertTrue(reading.staticTexts[language == "en" ? "Read Aloud" : "朗讀"].exists)
                let identifiers = ["translateText", "translateImageText", "lookUp", "listen", "pinWindow", "languageSupport"]
                let rows = identifiers.map { guide.groups["usageItem.\($0)"].firstMatch }
                let gaps = zip(rows, rows.dropFirst()).map { previous, next in
                    next.staticTexts.element(boundBy: 0).frame.minY
                        - previous.staticTexts.element(boundBy: 1).frame.maxY
                }
                for gap in gaps {
                    XCTAssertEqual(gap, gaps[0], accuracy: 1)
                }
                let attachment = XCTAttachment(screenshot: guide.screenshot())
                attachment.name = "Usage guide \(language) \(appearance)"
                attachment.lifetime = .keepAlways
                add(attachment)
                app.terminate()
            }
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

    func test_screenshotHint_whenDisplayed_then_reservesSpaceAndKeepsImageSizeAfterClosing() throws {
        // Arrange
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_HINT_KIND"] = "screenshot"
        app.launch()
        let hint = app.groups["hint.screenshot"].firstMatch
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        waitForObservation { $0.recognizedText.contains("TARGET") }
        let window = app.windows["Screenshot Translation"]
        let before = try screenshotObservation()
        let windowHeight = window.frame.height

        // Act & Assert
        XCTAssertLessThanOrEqual(hint.frame.maxY, before.imageFrame[1], "The hint must occupy its own row above the image.")
        movePointer(to: before.textStart, in: window)
        waitForObservation { $0.cursor == "ibeam" }
        for element in [hint.staticTexts["Translate Selected Text"], hint.staticTexts["Select text and press ⌥T to translate."]] {
            element.hover()
            waitForObservation { $0.cursor == "arrow" }
        }
        captureHint()
        coordinate(at: before.textStart, in: window).press(
            forDuration: 0.1, thenDragTo: coordinate(at: before.textEnd, in: window)
        )
        waitForObservation { $0.selectedText.contains("TARGET") }
        let selectedText = try screenshotObservation().selectedText
        app.buttons["Close"].firstMatch.click()
        XCTAssertTrue(hint.waitForNonExistence(timeout: 5))
        waitForObservation { $0.imageFrame[1] < before.imageFrame[1] }
        let after = try screenshotObservation()
        XCTAssertEqual(after.imageFrame[2], before.imageFrame[2], accuracy: 1)
        XCTAssertEqual(after.imageFrame[3], before.imageFrame[3], accuracy: 1)
        XCTAssertEqual(after.selectedText, selectedText)
        XCTAssertLessThan(window.frame.height, windowHeight)
    }

    private struct ScreenshotObservation: Decodable {
        let cursor: String
        let recognizedText: String
        let selectedText: String
        let imageFrame: [Double]
        let textStart: [Double]
        let textEnd: [Double]
    }

    private func screenshotObservation() throws -> ScreenshotObservation {
        let data = try Data(contentsOf: datastore.appendingPathExtension("json"))
        return try JSONDecoder().decode(ScreenshotObservation.self, from: data)
    }

    private func waitForObservation(_ matches: @escaping (ScreenshotObservation) -> Bool) {
        let condition = NSPredicate { _, _ in
            guard let state = try? self.screenshotObservation() else { return false }
            return matches(state)
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: condition, object: nil)], timeout: 8), .completed)
    }

    private func movePointer(to point: [Double], in window: XCUIElement) {
        coordinate(at: point, in: window).hover()
    }

    private func coordinate(at point: [Double], in window: XCUIElement) -> XCUICoordinate {
        window.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point[0] - window.frame.minX, dy: point[1] - window.frame.minY))
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
        XCTAssertGreaterThan(hintFrame.height, 24)
        XCTAssertTrue(windowFrame.contains(hintFrame), "Keep the whole hint inside the screenshot window.")
        XCTAssertEqual(hintFrame.midX, windowFrame.midX, accuracy: 2, "The hint row spans the screenshot window.")
        XCTAssertGreaterThan(hintFrame.width, windowFrame.width - 40)
        XCTAssertGreaterThan(hintFrame.minY, windowFrame.minY + 20, "Leave space below the title bar.")
        XCTAssertLessThan(hintFrame.midY, windowFrame.midY, "Keep the hint near the upper side.")
    }

    private func hintSurfaceFrame(_ hint: XCUIElement) -> CGRect {
        hint.frame
    }

    private func captureHint() {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Hint before dismissal"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
