import AppKit
import XCTest

@MainActor
final class ImageTextFocusGUITests: ImageTextGUITestCase {
    func test_cursor_when_movingFromTextToBlank_then_changesFromIBeamToArrow() throws {
        // Arrange
        let text = coordinate(try word("TARGET"), "center")
        // Act / Assert
        move(text)
        XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
        move(point("blank"))
        XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 5, y: 5))
    }

    func test_focus_when_hoveringInactiveScreenshot_then_doesNotActivateOrClearSelection() throws {
        // Arrange
        try select("TARGET")
        switchAway()
        // Act
        move(coordinate(try word("TARGET"), "center"))
        // Assert
        XCTAssertEqual(app.state == .runningForeground, false)
        assertSelected("TARGET")
    }

    func test_focus_when_recognitionCompletesInBackground_then_doesNotStealFocus() throws {
        // Arrange: delay delivery of the real OCR result until the app loses focus.
        try loadFixture("recognition-completion.png", holdCompletionUntilInactive: true)
        XCTAssertEqual(recognitionPending, true)
        // Act
        switchAway()
        // Assert
        XCTAssertTrue(waitFor { self.recognitionPending == false })
        XCTAssertFalse(words().isEmpty)
        XCTAssertEqual(app.state == .runningForeground, false)
        XCTAssertEqual(
            NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            "com.boundless-translator.e2e-test-host")
    }

    func test_focus_when_keysArePressedInAnotherApp_then_doesNotChangeSelectionOrOpenTranslation()
        throws
    {
        // Arrange
        try select("TARGET")
        switchAway()
        // Act
        key(0, .maskCommand)
        key(36, .maskCommand)
        // Assert
        assertSelected("TARGET")
        XCTAssertEqual(translationWindow.exists, false)
        XCTAssertEqual(app.state == .runningForeground, false)
    }

    func test_focus_when_translationCloseButtonIsClicked_then_sourceCanSelectImmediately() throws {
        // Arrange
        try select("TARGET")
        pressTranslate()
        // Act: click the actual close button without activating through XCTest.
        let close = app.windows["imageText.translation"].buttons[XCUIIdentifierCloseWindow].frame
        click(CGPoint(x: close.midX, y: close.midY))
        // Assert
        XCTAssertTrue(waitFor { self.translationWindow.exists == false })
        move(coordinate(try word("TARGET"), "center"))
        XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
        try select("ORIGINAL")
    }

    func test_focus_when_clickingSourceWhileTranslationIsOpen_then_clickIsDeliveredAndCursorRecovers()
        throws
    {
        // Arrange
        try select("TARGET")
        pressTranslate()
        // Act
        click(point("blank"))
        // Assert
        XCTAssertTrue(waitFor { self.translationWindow.exists == false })
        assertSelected("")
        move(coordinate(try word("TARGET"), "center"))
        XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
        try select("TARGET")
    }

    func test_focus_when_reopeningAppFromBackground_then_settingsReceivesKeyboardImmediately()
        async throws
    {
        // Arrange
        try select("TARGET")
        switchAway()
        // Act: normal application reopening, equivalent to opening the running app in Finder/Dock.
        let configuration = NSWorkspace.OpenConfiguration()
        _ = try await NSWorkspace.shared.openApplication(at: fixtureURL, configuration: configuration)
        // Assert
        XCTAssertTrue(waitFor { self.settingsWindow.exists })
        capture("settings-reopen-background", window: app.windows.containing(.staticText, identifier: "preferencesTitle").firstMatch)
        key(13, .maskCommand)
        XCTAssertTrue(
            waitFor { self.settingsWindow.exists == false },
            "Settings must receive Command-W without another click")
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
            click(point("blank"))
            move(coordinate(try word("TARGET"), "center"))
            // Assert
            XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
            try select("ORIGINAL")
            pressTranslate()
            XCTAssertEqual(translationSource, "ORIGINAL")
            key(53)
        }
    }
}
