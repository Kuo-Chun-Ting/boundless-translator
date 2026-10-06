import Foundation
import Testing
@testable import BoundlessTranslator

@Test
func test_previewTarget_when_selectionExists_then_usesSelectionInsteadOfHoveredWord() throws {
    // Arrange
    let document = previewDocument()
    // Act
    let target = ImageTextPreviewTarget.make(document: document,
        selection: NSRange(location: 0, length: 10), point: CGPoint(x: 15, y: 15))
    // Assert
    #expect(target?.text == "Hello moon")
    #expect(target?.bounds == CGRect(x: 10, y: 10, width: 110, height: 20))
}

@Test
func test_previewTarget_when_hoveringWord_then_usesThatWordAndItsBounds() {
    // Arrange
    let document = previewDocument()
    // Act
    let target = ImageTextPreviewTarget.make(document: document, selection: nil,
                                            point: CGPoint(x: 85, y: 15))
    // Assert
    #expect(target?.text == "moon")
    #expect(target?.bounds == document.words[1].bounds)
    #expect(ImageTextPreviewTarget.make(document: document, selection: nil,
                                       point: CGPoint(x: 150, y: 15)) == nil)
}

@Test(arguments: [CGFloat(150), CGFloat(370)])
func test_previewFrame_when_spaceVaries_then_prefersAboveAndFallsBackBelow(anchorY: CGFloat) {
    // Arrange
    let screen = CGRect(x: -500, y: 0, width: 500, height: 400)
    let anchor = CGRect(x: -20, y: anchorY, width: 15, height: 20)
    // Act
    let frame = ImageTextPreviewPositioner.frame(anchor: anchor,
        size: CGSize(width: 180, height: 100), visibleFrame: screen)
    // Assert
    #expect(screen.contains(frame))
    #expect(anchorY == 150 ? frame.minY > anchor.maxY : frame.maxY < anchor.minY)
}

private func previewDocument() -> ImageTextDocument {
    ImageTextDocument(text: "Hello moon", words: [
        ImageTextRegion(range: NSRange(location: 0, length: 5),
            bounds: CGRect(x: 10, y: 10, width: 50, height: 20), line: 0),
        ImageTextRegion(range: NSRange(location: 6, length: 4),
            bounds: CGRect(x: 80, y: 10, width: 40, height: 20), line: 0)
    ])
}
