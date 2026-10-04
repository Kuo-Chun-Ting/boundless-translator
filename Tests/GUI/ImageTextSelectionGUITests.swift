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
        XCTAssertEqual(state()["selected"] as? String, "ORIGINAL")
        XCTAssertEqual(state()["selectionResponder"] as? Bool, true)
    }

    func test_selection_when_dragStartsInBlank_then_selectsText() throws {
        // Arrange
        let target = try word("TARGET")
        // Act
        drag(point("blank"), coordinate(target, "end"))
        // Assert
        XCTAssertTrue(waitFor { self.state()["selected"] as? String == "TARGET" })
        capture("blank-origin-selection")
    }

    func test_selection_when_dragCrossesLines_then_preservesTextOrder() throws {
        // Arrange
        let first = try word("ORIGINAL")
        let last = try word("WORDS")
        // Act
        drag(coordinate(first, "start"), coordinate(last, "end"))
        // Assert
        XCTAssertTrue(waitFor { self.state()["selected"] as? String == "ORIGINAL TEXT\nTARGET WORDS" })
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
            waitFor { self.state()["selected"] as? String == "TARGET" },
            "Reverse selection must keep both endpoint letters, got \(state()["selected"] ?? "nil")")
        capture("reverse-english-endpoints")
    }

    func
        test_selection_when_dragReversesAcrossChineseLine_then_keepsFirstCharacterAndFinalPunctuation()
        throws
    {
        // Arrange
        let row = words().filter { ($0["lineText"] as? String)?.contains("中文") == true }
        let first = try XCTUnwrap(row.first)
        let last = try XCTUnwrap(row.last)
        // Act
        drag(coordinate(last, "end"), coordinate(first, "start"))
        // Assert
        XCTAssertTrue(
            waitFor { self.state()["selected"] as? String == "中文也能選取文字。" },
            "Reverse selection must include 中 and the final 。, got \(state()["selected"] ?? "nil")")
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
            waitFor { self.state()["selected"] as? String == "ORIGINAL TEXT\nTARGET WORDS" },
            "Reverse selection must include the initial O and final S, got \(state()["selected"] ?? "nil")"
        )
        capture("reverse-cross-line-endpoints")
    }

    func test_selection_when_selectingChineseLine_then_returnsRecognizedChinese() throws {
        // Arrange: line boundaries come from OCR; expected text is hand-authored.
        let row = words().filter { ($0["lineText"] as? String)?.contains("中文") == true }
        let first = try XCTUnwrap(row.first)
        let last = try XCTUnwrap(row.last)
        // Act
        drag(coordinate(first, "start"), coordinate(last, "end"))
        // Assert
        XCTAssertTrue(waitFor { self.state()["selected"] as? String == "中文也能選取文字。" })
        capture("chinese-selection")
    }

    func test_selection_when_usingRealScreenshot_then_selectsBatteryHeading() throws {
        // Arrange: actual screenshot asset, recognized by Vision without test geometry.
        try loadFixture("battery-settings.jpeg")
        XCTAssertTrue(words().contains { $0["text"] as? String == "Energy" })
        let first = try word("Energy")
        let last = try XCTUnwrap(
            words().first {
                $0["lineText"] as? String == first["lineText"] as? String && $0["text"] as? String == "Mode"
            })
        // Act
        drag(coordinate(first, "start"), coordinate(last, "end"))
        // Assert
        XCTAssertTrue(
            waitFor { self.state()["selected"] as? String == "Energy Mode" },
            "Selected: \(state()["selected"] ?? "nil")")
        capture("real-screenshot-selection")
    }

    func test_focus_when_translationCloses_then_sourceAcceptsSelectionAndCursor() throws {
        // Arrange
        try select("TARGET")
        key(36, .maskCommand)
        XCTAssertTrue(waitFor { self.state()["keyWindow"] as? String == "translation" })
        XCTAssertEqual(state()["translationSource"] as? String, "TARGET")
        // Act
        key(53)
        // Assert
        XCTAssertTrue(waitFor { self.state()["keyWindow"] as? String == "screenshot" })
        XCTAssertEqual(state()["selectionResponder"] as? Bool, true)
        move(coordinate(try word("TARGET"), "center"))
        XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
        try select("ORIGINAL")
        capture("translation-closed")
    }

    func test_focus_when_translationDismissesByOtherApp_then_doesNotStealFocus() throws {
        // Arrange
        try select("TARGET")
        key(36, .maskCommand)
        XCTAssertTrue(waitFor { self.state()["translationVisible"] as? Bool == true })
        // Act
        switchAway()
        // Assert
        XCTAssertTrue(waitFor { self.state()["translationVisible"] as? Bool == false })
        XCTAssertEqual(state()["active"] as? Bool, false)
        XCTAssertEqual(state()["selected"] as? String, "TARGET")
    }

    func test_selection_when_losingFocus_then_keepsRangeWithInactiveHighlight() throws {
        // Arrange
        try select("TARGET")
        // Act
        switchAway()
        // Assert
        XCTAssertEqual(state()["selected"] as? String, "TARGET")
        XCTAssertEqual(state()["selectionActive"] as? Bool, false)
        capture("inactive-selection")
    }

}
