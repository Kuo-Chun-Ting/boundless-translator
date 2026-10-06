import AppKit
import XCTest

@MainActor
final class ImageTextSelectionGUITests: ImageTextGUITestCase {
    func test_previewGlass_when_backgroundAndAppearanceVary_then_keepsTextAndActionsUsable() throws {
        for appearance in ["light", "dark"] {
            for background in ["white", "dark", "color"] {
                for (length, translation) in [("short", "金色的"),
                    ("long", "系統設計面試著重於架構取捨，以及解決複雜問題的能力。") ] {
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
                    XCTAssertTrue(waitFor { result.exists && result.value as? String == translation })
                    // Assert
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
            }
        }
    }

    func test_previewCursor_when_leavingButtonsAndText_then_returnsToArrow() throws {
        // Arrange
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
        // Arrange
        move(coordinate(try word("TARGET"), "middle"))
        let result = app.textViews["screenshotPreview.translation"]
        XCTAssertTrue(waitFor { result.exists && result.value as? String == "Texte traduit" })
        let speech = app.buttons["screenshotPreview.speech"]
        // Act
        move(CGPoint(x: speech.frame.midX, y: speech.frame.midY))
        pause(0.5)
        speech.click()
        // Assert
        XCTAssertTrue(result.exists)
        XCTAssertTrue(speech.isEnabled)
        XCTAssertEqual(selectedText, "")
        attachPreview("hover-preview")
        // Moving from the card to the title bar should dismiss an unselected preview.
        let window = app.windows["imageText.screenshot"]
        move(CGPoint(x: window.frame.minX + 150, y: window.frame.minY + 12))
        XCTAssertTrue(waitFor { !result.exists })
    }

    func test_preview_when_dragSelectsText_then_cardShowsSelectionWithoutBlockingDrag() throws {
        // Arrange
        move(coordinate(try word("TARGET"), "middle"))
        XCTAssertTrue(app.buttons["screenshotPreview.lookup"].waitForExistence(timeout: 5))
        // Act
        try select("ORIGINAL")
        // Assert
        XCTAssertEqual(selectedText, "ORIGINAL")
        XCTAssertTrue(waitFor { self.app.textViews["screenshotPreview.translation"].value as? String == "Texte traduit" })
        attachPreview("selected-preview")
    }

    func test_previewLookup_when_closed_then_hoverCanContinue() throws {
        // Arrange
        move(coordinate(try word("TARGET"), "middle"))
        let lookup = app.buttons["screenshotPreview.lookup"]
        XCTAssertTrue(lookup.waitForExistence(timeout: 5))
        // Act
        lookup.click()
        pause(1)
        attachPreview("native-dictionary")
        // Assert
        XCTAssertTrue(app.popovers.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(selectedText, "")
        // Act: dismiss Apple's lookup and continue using the screenshot.
        key(53)
        XCTAssertTrue(waitFor { !self.app.popovers.firstMatch.exists })
        // TEXT is not covered by the card that remains above TARGET.
        move(coordinate(try word("TEXT"), "middle"))
        // Assert
        XCTAssertTrue(waitFor { self.app.buttons["screenshotPreview.lookup"].exists })
        let preview = app.dialogs["screenshotPreview"]
        let nextWord = try word("TEXT")
        XCTAssertTrue(waitFor { preview.frame.maxY < nextWord.frame.minY })
    }

    func test_selection_when_draggingDirectlyIntoInactiveWindow_then_firstDragWorks() throws {
        // Arrange
        try select("TARGET")
        switchAway()
        // Act
        try select("ORIGINAL")
        // Assert
        XCTAssertEqual(selectedText, "ORIGINAL")
    }

    private func attachPreview(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

}
