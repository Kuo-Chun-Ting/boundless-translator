import AppKit
import XCTest

@MainActor
final class ImageTextSelectionGUITests: ImageTextGUITestCase {
    func test_selection_when_selectAllImmediatelyAfterOpening_then_selectsRecognizedText() {
        // Arrange: the screenshot has opened and recognition has completed; no extra click.
        // Act
        key(0, .maskCommand)
        // Assert
        assertSelected("ORIGINAL TEXT\nTARGET WORDS\n中文也能選取文字。\nSelect text, then press Command-Return.")
    }

    func test_selection_when_returningThroughImageBlank_then_firstDragAndCursorWork() throws {
        try checkReturn("blank")
    }
    func test_selection_when_returningThroughOuterMargin_then_firstDragAndCursorWork() throws {
        try checkReturn("margin")
    }
    func test_selection_when_returningThroughText_then_firstDragAndCursorWork() throws {
        try checkReturn("text")
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

    func test_selection_when_dragStartsInBlank_then_selectsText() throws {
        // Arrange
        let target = try word("TARGET")
        // Act
        drag(point("blank"), coordinate(target, "end"))
        // Assert
        XCTAssertTrue(waitFor { self.selectedText == "TARGET" })
        capture("blank-origin-selection")
    }

    func test_selection_when_dragCrossesLines_then_preservesTextOrder() throws {
        // Arrange
        let first = try word("ORIGINAL")
        let last = try word("WORDS")
        // Act
        drag(coordinate(first, "start"), coordinate(last, "end"))
        // Assert
        XCTAssertTrue(waitFor { self.selectedText == "ORIGINAL TEXT\nTARGET WORDS" })
        capture("cross-line-selection")
    }

    func test_selection_when_dragCoversMiddleLetters_then_selectsWholeWord() throws {
        // Arrange: drag only through the middle of TARGET, whose letters share a word box.
        let target = try word("TARGET")
        let start = coordinate(target, "start")
        let end = coordinate(target, "end")
        // Act
        drag(
            CGPoint(x: start.x + (end.x - start.x) * 0.22, y: start.y),
            CGPoint(x: start.x + (end.x - start.x) * 0.61, y: start.y))
        // Assert
        assertSelected("TARGET")
        capture("whole-word-from-partial-drag")
    }

    func test_selection_when_dragReversesAcrossEnglishWord_then_keepsFirstAndLastLetters() throws {
        // Arrange: reverse from the final T to the first T; expected text is literal.
        let target = try word("TARGET")
        // Act
        drag(coordinate(target, "end"), coordinate(target, "start"))
        // Assert
        XCTAssertTrue(
            waitFor { self.selectedText == "TARGET" },
            "Reverse selection must keep both endpoint letters, got \(selectedText)")
        capture("reverse-english-endpoints")
    }

    func
        test_selection_when_dragReversesAcrossChineseLine_then_keepsFirstCharacterAndFinalPunctuation()
        throws
    {
        // Arrange
        let row = try wordsInLine(containing: "中文")
        let first = try XCTUnwrap(row.first)
        let last = try XCTUnwrap(row.last)
        // Act
        drag(coordinate(last, "end"), coordinate(first, "start"))
        // Assert
        XCTAssertTrue(
            waitFor { self.selectedText == "中文也能選取文字。" },
            "Reverse selection must include 中 and the final 。, got \(selectedText)")
        capture("reverse-chinese-endpoints")
    }

    func test_selection_when_dragReversesAcrossLines_then_keepsBothEndpointCharacters() throws {
        // Arrange
        let first = try word("ORIGINAL")
        let last = try word("WORDS")
        // Act
        drag(coordinate(last, "end"), coordinate(first, "start"))
        // Assert
        XCTAssertTrue(
            waitFor { self.selectedText == "ORIGINAL TEXT\nTARGET WORDS" },
            "Reverse selection must include the initial O and final S, got \(selectedText)"
        )
        capture("reverse-cross-line-endpoints")
    }

    func test_selection_when_selectingChineseLine_then_returnsRecognizedChinese() throws {
        // Arrange: line boundaries come from OCR; expected text is hand-authored.
        let row = try wordsInLine(containing: "中文")
        let first = try XCTUnwrap(row.first)
        let last = try XCTUnwrap(row.last)
        // Act
        drag(coordinate(first, "start"), coordinate(last, "end"))
        // Assert
        XCTAssertTrue(waitFor { self.selectedText == "中文也能選取文字。" })
        capture("chinese-selection")
    }

    func test_selection_when_usingRealScreenshot_then_selectsBatteryHeading() throws {
        // Arrange: actual screenshot asset, recognized by Vision without test geometry.
        try loadFixture("battery-settings.jpeg")
        XCTAssertTrue(words().contains { $0.text == "Energy" })
        let first = try word("Energy")
        let last = try XCTUnwrap(
            words().first {
                $0.line == first.line && $0.text == "Mode"
            })
        // Act
        drag(coordinate(first, "start"), coordinate(last, "end"))
        // Assert
        XCTAssertTrue(
            waitFor { self.selectedText == "Energy Mode" },
            "Selected: \(selectedText)")
        capture("real-screenshot-selection")
    }

    func test_focus_when_translationCloses_then_sourceAcceptsSelectionAndCursor() throws {
        // Arrange
        try select("TARGET")
        key(36, .maskCommand)
        XCTAssertTrue(waitFor { self.translationWindow.exists })
        XCTAssertEqual(translationSource, "TARGET")
        // Act
        key(53)
        // Assert
        XCTAssertTrue(waitFor { self.translationWindow.exists == false })
        move(coordinate(try word("TARGET"), "center"))
        XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
        try select("ORIGINAL")
        capture("translation-closed")
    }

    func test_focus_when_translationDismissesByOtherApp_then_doesNotStealFocus() throws {
        // Arrange
        try select("TARGET")
        key(36, .maskCommand)
        XCTAssertTrue(waitFor { self.translationWindow.exists })
        // Act
        switchAway()
        // Assert
        XCTAssertTrue(waitFor { self.translationWindow.exists == false })
        XCTAssertEqual(app.state == .runningForeground, false)
        XCTAssertEqual(selectedText, "TARGET")
    }

    func test_selection_when_losingFocus_then_keepsRange() throws {
        // Arrange
        try select("TARGET")
        // Act
        switchAway()
        // Assert
        XCTAssertEqual(selectedText, "TARGET")
        XCTAssertNotEqual(app.state, .runningForeground)
        capture("inactive-selection")
    }

}
