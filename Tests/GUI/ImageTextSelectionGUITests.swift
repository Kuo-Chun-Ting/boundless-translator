import AppKit
import XCTest

@MainActor
final class ImageTextSelectionGUITests: ImageTextGUITestCase {
    func test_selection_when_draggingDirectlyIntoInactiveWindow_then_firstDragWorks() throws {
        // Arrange
        try select("TARGET")
        switchAway()
        // Act
        try select("ORIGINAL")
        // Assert
        XCTAssertEqual(selectedText, "ORIGINAL")
    }

}
