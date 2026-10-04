import CoreGraphics
import Foundation
import Testing

@testable import BoundlessTranslator

private func document() -> ImageTextDocument {
    ImageTextDocument(
        text: "one two\n三 四",
        words: [
            ImageTextRegion(
                range: NSRange(location: 0, length: 3), bounds: CGRect(x: 30, y: 60, width: 30, height: 20),
                line: 0),
            ImageTextRegion(
                range: NSRange(location: 4, length: 3), bounds: CGRect(x: 75, y: 60, width: 30, height: 20),
                line: 0),
            ImageTextRegion(
                range: NSRange(location: 8, length: 1), bounds: CGRect(x: 30, y: 20, width: 20, height: 20),
                line: 1),
            ImageTextRegion(
                range: NSRange(location: 10, length: 1),
                bounds: CGRect(x: 65, y: 20, width: 20, height: 20), line: 1),
        ])
}

@Test func test_range_when_dragStartsInBlank_then_selectsFirstReachedWords() {
    // Arrange
    let subject = document()
    // Act
    let selected = subject.range(from: CGPoint(x: 2, y: 70), to: CGPoint(x: 90, y: 70))
    // Assert
    #expect(subject.text(in: selected) == "one two")
}

@Test func test_range_when_dragCrossesLines_then_preservesReadingOrderAndLineBreak() {
    // Arrange
    let subject = document()
    // Act
    let selected = subject.range(from: CGPoint(x: 85, y: 70), to: CGPoint(x: 40, y: 30))
    // Assert
    #expect(subject.text(in: selected) == "two\n三")
}

@Test func test_range_when_dragReverses_then_preservesReadingOrder() {
    // Arrange
    let subject = document()
    // Act
    let selected = subject.range(from: CGPoint(x: 40, y: 30), to: CGPoint(x: 85, y: 70))
    // Assert
    #expect(subject.text(in: selected) == "two\n三")
}

private func characterDocument() -> ImageTextDocument {
    ImageTextDocument(
        text: "ABC\n甲乙丙", words: [],
        characters: [
            ImageTextRegion(
                range: NSRange(location: 0, length: 1), bounds: CGRect(x: 30, y: 60, width: 10, height: 20),
                line: 0),
            ImageTextRegion(
                range: NSRange(location: 1, length: 1), bounds: CGRect(x: 40, y: 60, width: 10, height: 20),
                line: 0),
            ImageTextRegion(
                range: NSRange(location: 2, length: 1), bounds: CGRect(x: 50, y: 60, width: 10, height: 20),
                line: 0),
            ImageTextRegion(
                range: NSRange(location: 4, length: 1), bounds: CGRect(x: 30, y: 20, width: 10, height: 20),
                line: 1),
            ImageTextRegion(
                range: NSRange(location: 5, length: 1), bounds: CGRect(x: 40, y: 20, width: 10, height: 20),
                line: 1),
            ImageTextRegion(
                range: NSRange(location: 6, length: 1), bounds: CGRect(x: 50, y: 20, width: 10, height: 20),
                line: 1),
        ])
}

@Test func test_range_when_dragReversesAcrossEnglishWord_then_includesBothEndpointCharacters() {
    // Arrange
    let subject = characterDocument()
    // Act
    let selected = subject.range(from: CGPoint(x: 55, y: 70), to: CGPoint(x: 35, y: 70))
    // Assert
    #expect(subject.text(in: selected) == "ABC")
}

@Test func test_range_when_dragReversesAcrossChineseWord_then_includesBothEndpointCharacters() {
    // Arrange
    let subject = characterDocument()
    // Act
    let selected = subject.range(from: CGPoint(x: 55, y: 30), to: CGPoint(x: 35, y: 30))
    // Assert
    #expect(subject.text(in: selected) == "甲乙丙")
}

@Test func test_range_when_dragReversesAcrossLines_then_includesEndpointsWithoutAdjacentCharacters()
{
    // Arrange
    let subject = characterDocument()
    // Act
    let selected = subject.range(from: CGPoint(x: 45, y: 30), to: CGPoint(x: 45, y: 70))
    // Assert
    #expect(subject.text(in: selected) == "BC\n甲乙")
}

@Test func test_range_when_dragStartsInOuterMargin_then_reachesText() {
    // Arrange
    let subject = document()
    // Act
    let selected = subject.range(from: CGPoint(x: -50, y: 120), to: CGPoint(x: 45, y: 70))
    // Assert
    #expect(subject.text(in: selected) == "one")
}

@Test func test_range_when_imageHasNoText_then_returnsNoSelection() {
    // Arrange
    let subject = ImageTextDocument(text: "", words: [])
    // Act
    let selected = subject.range(from: .zero, to: CGPoint(x: 100, y: 100))
    // Assert
    #expect(selected == nil)
}

@Test func test_intersectsText_when_dragStaysInBlank_then_doesNotReachNearbyText() {
    // Arrange
    let subject = document()
    // Act
    let reachesText = subject.intersectsText(from: CGPoint(x: 2, y: 70), to: CGPoint(x: 10, y: 70))
    // Assert
    #expect(!reachesText)
}

@Test
func test_range_when_partialDragInsideSharedWordBox_then_selectsWholeWord() {
    // Arrange: accurate OCR may return the same word rectangle for every character.
    let bounds = CGRect(x: 10, y: 20, width: 60, height: 20)
    let subject = ImageTextDocument(text: "ABC", words: [], characters: (0..<3).map {
        ImageTextRegion(range: NSRange(location: $0, length: 1), bounds: bounds, line: 0)
    })
    // Act
    let selected = subject.range(from: CGPoint(x: 31, y: 30), to: CGPoint(x: 49, y: 30))
    // Assert
    #expect(subject.text(in: selected) == "ABC")
}

@Test func test_range_when_oneWordHasNoCharacterBounds_then_keepsThatWordSelectable() {
    // Arrange
    let first = ImageTextRegion(range: NSRange(location: 0, length: 1),
                                bounds: CGRect(x: 10, y: 10, width: 20, height: 20), line: 0)
    let second = ImageTextRegion(range: NSRange(location: 2, length: 1),
                                 bounds: CGRect(x: 80, y: 10, width: 20, height: 20), line: 0)
    let subject = ImageTextDocument(text: "A B", words: [first, second], characters: [first])
    // Act
    let selected = subject.range(from: CGPoint(x: 81, y: 20), to: CGPoint(x: 99, y: 20))
    // Assert
    #expect(subject.text(in: selected) == "B")
    #expect(subject.selectionRegions.contains(second))
}

@Test func test_range_when_wordHasOnlySomeCharacterBounds_then_doesNotDropOtherLetters() {
    // Arrange
    let word = ImageTextRegion(range: NSRange(location: 0, length: 3),
                               bounds: CGRect(x: 10, y: 10, width: 60, height: 20), line: 0)
    let middle = ImageTextRegion(range: NSRange(location: 1, length: 1),
                                 bounds: CGRect(x: 30, y: 10, width: 20, height: 20), line: 0)
    let subject = ImageTextDocument(text: "ABC", words: [word], characters: [middle])
    // Act
    let selected = subject.range(from: CGPoint(x: 11, y: 20), to: CGPoint(x: 69, y: 20))
    // Assert
    #expect(subject.text(in: selected) == "ABC")
}
