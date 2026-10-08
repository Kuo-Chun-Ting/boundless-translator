import AppKit
import XCTest

@MainActor
final class ImageTextFocusGUITests: ImageTextGUITestCase {
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

    func test_focus_when_repeatingTranslationAndAppSwitches_then_everyReturnCanSelectAndTranslate()
        throws
    {
        for _ in 0..<3 {
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
            XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
            // Clear the old preview before selecting the source it covers.
            click(imageBlankPoint)
            XCTAssertTrue(waitFor { !self.app.dialogs["screenshotPreview"].exists })
            try select("ORIGINAL")
            pressTranslate()
            XCTAssertEqual(translationSource, "ORIGINAL")
            key(53)
        }
    }
}
