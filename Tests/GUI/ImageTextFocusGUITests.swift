import AppKit
import XCTest

@MainActor
final class ImageTextFocusGUITests: ImageTextGUITestCase {
    func test_translationLookup_when_opened_then_keepsWindowAndRestoresDismissal() throws {
        // Arrange
        try select("TARGET")
        pressTranslate()
        translationWindow.textViews["translation.sourceText"].doubleClick()
        let lookup = translationWindow.buttons["Look Up"]
        XCTAssertTrue(lookup.waitForExistence(timeout: 5), app.debugDescription)
        // Act
        lookup.click()
        continueLookupIfNeeded()
        // Assert
        XCTAssertTrue(translationWindow.exists)
        XCTAssertEqual(translationSource, "TARGET")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "translation-lookup-after-continue"
        attachment.lifetime = .keepAlways
        add(attachment)
        // Act: closing Apple's UI restores the original outside-click dismissal.
        key(53)
        XCTAssertTrue(waitFor { !self.app.popovers.firstMatch.exists })
        click(imageBlankPoint)
        XCTAssertTrue(waitFor { !self.translationWindow.exists })
    }

    func test_focus_when_translationCloses_then_sourceCanSelectImmediately() throws {
        for closeWithEscape in [false, true] {
            // Arrange
            try select("TARGET")
            pressTranslate()
            // Act: both supported ways of closing the same translation window.
            if closeWithEscape {
                key(53)
            } else {
                let close = translationWindow.buttons[XCUIIdentifierCloseWindow].frame
                click(CGPoint(x: close.midX, y: close.midY))
            }
            // Assert
            XCTAssertTrue(waitFor { self.translationWindow.exists == false })
            move(coordinate(try word("TARGET"), "center"))
            XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
            move(imageBlankPoint)
            XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 5, y: 5))
            // Clear the old preview before selecting the source it covers.
            click(imageBlankPoint)
            XCTAssertTrue(waitFor { !self.app.dialogs["screenshotPreview"].exists })
            try select("ORIGINAL")
        }
    }

    func test_focus_when_clickingSourceWhileTranslationIsOpen_then_clickIsDeliveredAndCursorRecovers()
        throws
    {
        // Arrange
        try select("TARGET")
        pressTranslate()
        // Act
        click(imageBlankPoint)
        // Assert
        XCTAssertTrue(waitFor { self.translationWindow.exists == false })
        assertSelected("")
        move(coordinate(try word("TARGET"), "center"))
        XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
        try select("TARGET")
    }

    func test_focus_when_returningFromAnotherApp_then_canSelectAndTranslate()
        throws
    {
        // Arrange
        try select("TARGET")
        pressTranslate()
        XCTAssertEqual(translationSource, "TARGET")
        switchAway()
        XCTAssertTrue(waitFor { self.translationWindow.exists == false })
        // Act
        click(imageBlankPoint)
        move(coordinate(try word("TARGET"), "center"))
        // Assert
        XCTAssertTrue(waitFor { NSCursor.currentSystem?.hotSpot == NSPoint(x: 12, y: 11) })
        // Clear the old preview before selecting the source it covers.
        click(imageBlankPoint)
        XCTAssertTrue(waitFor { !self.app.dialogs["screenshotPreview"].exists })
        try select("ORIGINAL")
        pressTranslate()
        XCTAssertEqual(translationSource, "ORIGINAL")
        key(53)
    }
}
