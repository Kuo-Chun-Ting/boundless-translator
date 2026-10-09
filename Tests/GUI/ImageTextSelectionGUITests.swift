import AppKit
import XCTest

@MainActor
final class ImageTextSelectionGUITests: ImageTextGUITestCase {
    func test_preview_when_lightAndDark_then_keepsTextAndActionsUsable() throws {
        try checkPreview(appearance: "light", background: "white", length: "short", translation: "金色的")
        try checkPreview(appearance: "dark", background: "color", length: "long",
                         translation: "系統設計面試著重於架構取捨，以及解決複雜問題的能力。")
    }

    func test_previewCursor_when_leavingButtonsAndText_then_returnsToArrow() throws {
        // Arrange
        let fixtureApp = try XCTUnwrap(NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.boundless-translator.cursor-test-host").first)
        click(imageBlankPoint)
        XCTAssertTrue(waitFor { fixtureApp.isActive }, "Setup: the screenshot app must be active before hovering")
        move(coordinate(try word("TARGET"), "middle"))
        let text = app.textViews["screenshotPreview.translation"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        let card = app.dialogs["screenshotPreview"]
        let blank = CGPoint(x: card.frame.maxX - 8, y: card.frame.maxY - 12)
        let regions = [app.buttons["screenshotPreview.speech"],
                       app.buttons["screenshotPreview.lookup"], text]
        // Act & Assert
        for region in regions {
            move(CGPoint(x: region.frame.midX, y: region.frame.midY))
            pause(0.2)
            XCTAssertNotEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 5, y: 5))
            move(blank)
            XCTAssertTrue(waitFor { NSCursor.currentSystem?.hotSpot == NSPoint(x: 5, y: 5) })
        }
        attachPreview("cursor-restored-on-card-background")
        move(imageBlankPoint)
        XCTAssertTrue(waitFor { NSCursor.currentSystem?.hotSpot == NSPoint(x: 5, y: 5) })
    }

    func test_preview_when_movingFromWordToCard_then_actionsRemainClickable() throws {
        // Arrange: distinct outputs make an accidental source change observable.
        app.terminate()
        app.launchEnvironment["IMAGE_TEXT_ECHO_SOURCE"] = "1"
        app.launch()
        XCTAssertTrue(waitFor { self.words().contains { $0.text == "TARGET" } })
        let target = try word("TARGET")
        let original = try word("ORIGINAL")
        let result = app.textViews["screenshotPreview.translation"]
        let card = app.dialogs["screenshotPreview"]
        let speech = app.buttons["screenshotPreview.speech"]

        for selected in [false, true] {
            // Act: open the same card by hovering or selecting text.
            if selected { try select("TARGET") }
            else {
                move(CGPoint(x: target.frame.minX + 1, y: target.frame.midY))
                move(coordinate(target, "middle"))
            }
            XCTAssertTrue(waitFor { result.exists && result.value as? String == "TARGET" })
            let frame = card.frame
            let coveredText = original.frame.intersection(frame).insetBy(dx: 2, dy: 2)
            XCTAssertFalse(coveredText.isNull, "The card must cover another OCR word")
            XCTAssertGreaterThan(coveredText.height, 2)
            // Move inside the card repeatedly, over a different word underneath it.
            move(CGPoint(x: coveredText.midX - 1, y: coveredText.midY))
            move(CGPoint(x: coveredText.midX + 1, y: coveredText.midY))
            pause(0.6)
            // Assert: the upper card owns these events, preserving source and position.
            XCTAssertEqual(result.value as? String, "TARGET")
            XCTAssertEqual(card.frame, frame)
            XCTAssertEqual(selectedText, selected ? "TARGET" : "")
            move(CGPoint(x: speech.frame.midX, y: speech.frame.midY))
            pause(0.5)
            speech.click()
            XCTAssertEqual(result.value as? String, "TARGET")
            XCTAssertTrue(speech.isEnabled)
            let attachment = XCTAttachment(screenshot: app.windows["imageText.screenshot"].screenshot())
            attachment.name = selected ? "selected-card-over-text" : "hover-card-over-text"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        // Act: clearing selection and leaving the card restores ordinary source hover.
        click(imageBlankPoint)
        move(CGPoint(x: original.frame.minX + 1, y: original.frame.midY))
        move(coordinate(original, "middle"))
        // Assert
        XCTAssertTrue(waitFor { result.exists && result.value as? String == "ORIGINAL" })
        let window = app.windows["imageText.screenshot"]
        move(CGPoint(x: window.frame.minX + 150, y: window.frame.minY + 12))
        XCTAssertTrue(waitFor { !result.exists })
    }

    func test_preview_when_dragSelectsText_then_cardShowsSelectionWithoutBlockingDrag() throws {
        // Arrange
        move(coordinate(try word("TARGET"), "middle"))
        XCTAssertTrue(app.buttons["screenshotPreview.lookup"].waitForExistence(timeout: 5))
        // Act: leave the hover card before selecting the source it covers.
        move(imageBlankPoint)
        XCTAssertTrue(waitFor { !self.app.dialogs["screenshotPreview"].exists })
        try select("ORIGINAL")
        // Assert
        XCTAssertEqual(selectedText, "ORIGINAL")
        XCTAssertTrue(waitFor { self.app.textViews["screenshotPreview.translation"].value as? String == "Texte traduit" })
        attachPreview("selected-preview")
    }

    func test_previewLookup_when_closed_then_hoverCanContinue() throws {
        // Arrange
        app.terminate()
        app.launchEnvironment["IMAGE_TEXT_ECHO_SOURCE"] = "1"
        app.launch()
        XCTAssertTrue(waitFor { self.words().contains { $0.text == "TARGET" } })
        move(coordinate(try word("TARGET"), "middle"))
        let lookup = app.buttons["screenshotPreview.lookup"]
        XCTAssertTrue(lookup.waitForExistence(timeout: 5))
        // Act
        lookup.click()
        continueLookupIfNeeded()
        // Assert
        XCTAssertTrue(app.dialogs["screenshotPreview"].exists)
        XCTAssertEqual(app.textViews["screenshotPreview.translation"].value as? String, "TARGET")
        XCTAssertEqual(selectedText, "")
        attachPreview("lookup-after-continue")
        // Act: dismiss Apple's lookup and continue using the screenshot.
        key(53)
        XCTAssertTrue(waitFor { !self.app.popovers.firstMatch.exists })
        // TEXT is not covered by the card that remains above TARGET.
        move(coordinate(try word("TEXT"), "middle"))
        // Assert
        XCTAssertTrue(waitFor {
            self.app.textViews["screenshotPreview.translation"].value as? String == "TEXT"
        })
        let preview = app.dialogs["screenshotPreview"]
        let nextWord = try word("TEXT")
        XCTAssertTrue(waitFor { preview.frame.maxY < nextWord.frame.minY })
    }

    func test_selection_when_draggingDirectlyIntoInactiveWindow_then_firstDragWorks() throws {
        // Arrange
        try select("TARGET")
        switchAway()
        // Act: WORDS remains uncovered when the existing preview returns with the app.
        try select("WORDS")
        // Assert
        XCTAssertEqual(selectedText, "WORDS")
    }

    private func checkPreview(appearance: String, background: String, length: String, translation: String) throws {
        // Arrange
        app.terminate()
        app.launchEnvironment["IMAGE_TEXT_APPEARANCE"] = appearance
        app.launchEnvironment["IMAGE_TEXT_BACKGROUND"] = background
        app.launchEnvironment["IMAGE_TEXT_TRANSLATION"] = translation
        app.launch()
        XCTAssertTrue(waitFor { self.words().contains { $0.text == "TARGET" } })
        // Act
        move(coordinate(try word("TARGET"), "middle"))
        let result = app.textViews["screenshotPreview.translation"]
        // Assert
        XCTAssertTrue(waitFor { result.exists && result.value as? String == translation })
        XCTAssertTrue(app.buttons["screenshotPreview.speech"].isEnabled)
        XCTAssertTrue(app.buttons["screenshotPreview.lookup"].isEnabled)
        pause(0.5)
        let screenshot = XCTAttachment(screenshot: app.dialogs["screenshotPreview"].screenshot())
        screenshot.name = "glass-\(appearance)-\(background)-\(length)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        move(imageBlankPoint)
        XCTAssertTrue(waitFor { !result.exists })
    }

    private func attachPreview(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

}
