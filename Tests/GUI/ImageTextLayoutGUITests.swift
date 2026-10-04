import AppKit
import XCTest

@MainActor
final class ImageTextLayoutGUITests: ImageTextGUITestCase {
    let expectedScattered = "電池健康度 正常\n自動調整亮度\n低耗電模式"

    func test_selection_when_scatteredLabels_then_matchesApprovedExample() throws {
        // Arrange
        try loadFixture("scattered-labels.png")
        // Act
        drag(fixturePoint(42, 287), fixturePoint(178, 87))
        // Assert
        assertSelected(expectedScattered)
        capture("scattered-approved-selection")
    }

    func test_selection_when_reversingScatteredSelection_then_keepsBothEndCharacters() throws {
        // Arrange
        try loadFixture("scattered-labels.png")
        // Act
        drag(fixturePoint(178, 87), fixturePoint(42, 287))
        // Assert
        assertSelected(expectedScattered)
        capture("scattered-reverse-selection")
    }

    func test_selection_when_dragStartsInScatteredImageBlank_then_selectsApprovedRange() throws {
        // Arrange
        try loadFixture("scattered-labels.png")
        // Act
        drag(fixturePoint(10, 287), fixturePoint(178, 87))
        // Assert
        assertSelected(expectedScattered)
    }

    func test_selection_when_dragStartsOutsideScatteredImage_then_selectsApprovedRange() throws {
        // Arrange
        try loadFixture("scattered-labels.png")
        let start = fixturePoint(10, 360)
        // Act
        drag(CGPoint(x: start.x, y: start.y - 30), fixturePoint(178, 87))
        // Assert
        assertSelected(expectedScattered)
    }

    func test_selection_when_scatteredSelectionIsCopied_then_clipboardMatchesHighlightedRange() throws
    {
        // Arrange
        try loadFixture("scattered-labels.png")
        drag(fixturePoint(42, 287), fixturePoint(178, 87))
        assertSelected(expectedScattered)
        // Act
        let copied = try copyPreservingClipboard()
        // Assert
        XCTAssertEqual(copied, expectedScattered)
    }

    func test_selection_when_scatteredSelectionIsTranslated_then_snapshotsExactText() throws {
        // Arrange
        try loadFixture("scattered-labels.png")
        drag(fixturePoint(42, 287), fixturePoint(178, 87))
        assertSelected(expectedScattered)
        // Act
        pressTranslate()
        // Assert
        XCTAssertEqual(state()["translationSource"] as? String, expectedScattered)
        XCTAssertEqual(state()["selected"] as? String, expectedScattered)
    }

    func test_selection_when_threeRaggedRows_then_selectsWholeMiddleAndPartialEnds() throws {
        // Arrange
        try loadFixture("ragged-rows.png")
        let start = coordinate(try word("ALPHA"), "start")
        let end = coordinate(try word("OMEGA"), "end")
        // Act
        drag(start, end)
        // Assert
        assertSelected("ALPHA\nMIDDLE CONTENT\nOMEGA")
        capture("ragged-three-lines")
    }

    func test_selection_when_twoColumns_then_readsAcrossRowsIncludingRightColumn() throws {
        // Arrange
        try loadFixture("two-columns.png")
        // Act
        drag(coordinate(try word("LEFT"), "start"), coordinate(try word("LOWER"), "end"))
        // Assert
        assertSelected("LEFT RIGHT\nLOWER")
    }

    func test_selection_when_sameRowHasMixedFontSizes_then_doesNotSplitVisualRow() throws {
        // Arrange
        try loadFixture("mixed-font-sizes.png")
        // Act
        drag(coordinate(try word("LARGE"), "start"), coordinate(try word("NEXT"), "end"))
        // Assert
        assertSelected("LARGE small\nNEXT")
        capture("mixed-font-row")
    }

    func test_selection_when_clickingImageBlank_then_clearsSelection() throws {
        // Arrange
        try select("TARGET")
        // Act
        click(point("blank"))
        // Assert
        assertSelected("")
    }

    func test_selection_when_clickingOuterMargin_then_clearsSelection() throws {
        // Arrange
        try select("TARGET")
        // Act
        click(point("margin"))
        // Assert
        assertSelected("")
    }

    func test_selection_when_newDragBegins_then_replacesPreviousSelection() throws {
        // Arrange
        try select("TARGET")
        // Act
        let original = try word("ORIGINAL")
        drag(coordinate(original, "start"), coordinate(original, "end"))
        // Assert
        assertSelected("ORIGINAL")
    }

    func test_selection_when_pointerMovesAfterMouseUp_then_doesNotExtendSelection() throws {
        // Arrange
        try select("TARGET")
        // Act
        move(coordinate(try word("ORIGINAL"), "center"))
        // Assert
        assertSelected("TARGET")
    }

    func test_selection_when_dragStaysInBlank_then_doesNotSelectNearbyText() throws {
        // Arrange
        let start = point("blank")
        // Act
        drag(start, CGPoint(x: start.x + 15, y: start.y + 8))
        // Assert
        assertSelected("")
    }

    func test_selection_when_imageContainsNoText_then_dragCreatesNoSelection() throws {
        // Arrange
        try loadFixture("no-text.png")
        // Act
        drag(fixturePoint(20, 300), fixturePoint(700, 50))
        // Assert
        assertSelected("")
        XCTAssertTrue(words().isEmpty)
    }
}
