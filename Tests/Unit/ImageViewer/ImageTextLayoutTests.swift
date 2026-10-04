import CoreGraphics
import Foundation
import Testing

@testable import BoundlessTranslator

private func fragmentDocument(_ fragments: [(String, CGRect)]) -> ImageTextDocument {
    var text = ""
    var words: [ImageTextRegion] = []
    var characters: [ImageTextRegion] = []
    for (line, fragment) in fragments.enumerated() {
        if !text.isEmpty { text += "\n" }
        let offset = (text as NSString).length
        text += fragment.0
        words.append(
            ImageTextRegion(
                range: NSRange(location: offset, length: (fragment.0 as NSString).length),
                bounds: fragment.1, line: line))
        for (index, character) in fragment.0.enumerated() {
            let width = fragment.1.width / CGFloat(fragment.0.count)
            let x = fragment.1.minX + CGFloat(index) * width
            characters.append(
                ImageTextRegion(
                    range: NSRange(location: offset + index, length: String(character).utf16.count),
                    bounds: CGRect(x: x, y: fragment.1.minY, width: width, height: fragment.1.height),
                    line: line))
        }
    }
    return ImageTextDocument(text: text, words: words, characters: characters)
}

private func scatteredDocument() -> ImageTextDocument {
    fragmentDocument([
        ("開啟", CGRect(x: 500, y: 20, width: 40, height: 20)),
        ("正常", CGRect(x: 500, y: 200, width: 40, height: 20)),
        ("自動調整亮度", CGRect(x: 150, y: 110, width: 120, height: 20)),
        ("低耗電模式", CGRect(x: 20, y: 20, width: 100, height: 20)),
        ("電池健康度", CGRect(x: 20, y: 200, width: 100, height: 20)),
    ])
}

@Test func test_layout_when_paragraphWrapsAcrossNearbyAlignedRows_then_joinsSoftLineBreaks() {
    // Arrange
    let fragments = [
        ("People live under different economic, social,", CGRect(x: 20, y: 200, width: 420, height: 20)),
        ("and physical conditions. Some have access", CGRect(x: 21, y: 168, width: 390, height: 20)),
        ("to time, money, education, and support.", CGRect(x: 20, y: 136, width: 360, height: 20)),
        ("A new paragraph starts here.", CGRect(x: 20, y: 80, width: 260, height: 20)),
    ]

    // Act
    let subject = fragmentDocument(fragments)

    // Assert
    #expect(subject.text == "People live under different economic, social, and physical conditions. Some have access to time, money, education, and support.\nA new paragraph starts here.")
}

@Test func test_layout_when_adjacentRowsContainSeparateLabels_then_preservesLineBreaks() {
    // Arrange
    let fragments = [
        ("Battery Health", CGRect(x: 20, y: 200, width: 120, height: 20)),
        ("Normal", CGRect(x: 400, y: 200, width: 60, height: 20)),
        ("Low Power Mode", CGRect(x: 20, y: 168, width: 130, height: 20)),
        ("On", CGRect(x: 400, y: 168, width: 30, height: 20)),
    ]

    // Act
    let subject = fragmentDocument(fragments)

    // Assert
    #expect(subject.text == "Battery Health Normal\nLow Power Mode On")
}

@Test func test_layout_when_chineseParagraphWraps_then_joinsWithoutInsertedSpaces() {
    // Arrange
    let fragments = [
        ("人們生活在不同的經濟、社會", CGRect(x: 20, y: 200, width: 260, height: 20)),
        ("和身體狀況。", CGRect(x: 20, y: 168, width: 120, height: 20)),
    ]

    // Act
    let subject = fragmentDocument(fragments)

    // Assert
    #expect(subject.text == "人們生活在不同的經濟、社會和身體狀況。")
}

@Test func test_layout_when_fragmentsArriveUnordered_then_ordersVisualRowsLeftToRight() {
    // Arrange / Act
    let subject = scatteredDocument()
    // Assert
    #expect(subject.text == "電池健康度 正常\n自動調整亮度\n低耗電模式 開啟")
}

@Test func test_range_when_dragCrossesScatteredRows_then_includesMiddleAndExcludesLastRightLabel() {
    // Arrange
    let subject = scatteredDocument()
    // Act
    let range = subject.range(from: CGPoint(x: 25, y: 210), to: CGPoint(x: 115, y: 30))
    // Assert
    #expect(subject.text(in: range) == "電池健康度 正常\n自動調整亮度\n低耗電模式")
}

@Test func test_range_when_dragReversesAcrossScatteredRows_then_preservesBothEndpoints() {
    // Arrange
    let subject = scatteredDocument()
    // Act
    let range = subject.range(from: CGPoint(x: 115, y: 30), to: CGPoint(x: 25, y: 210))
    // Assert
    #expect(subject.text(in: range) == "電池健康度 正常\n自動調整亮度\n低耗電模式")
}

@Test
func test_layout_when_sameRowHasDifferentFontHeights_then_keepsLabelsTogetherAndNextRowSeparate() {
    // Arrange / Act: shared lower edge, different glyph heights; next row is close but separate.
    let subject = fragmentDocument([
        ("small", CGRect(x: 300, y: 200, width: 50, height: 16)),
        ("next", CGRect(x: 20, y: 167, width: 40, height: 20)),
        ("LARGE", CGRect(x: 20, y: 198, width: 150, height: 40)),
    ])
    // Assert
    #expect(subject.text == "LARGE small\nnext")
}

@Test func test_layout_when_twoColumnsHaveSmallVerticalOffsets_then_readsAcrossEachRow() {
    // Arrange / Act
    let subject = fragmentDocument([
        ("RIGHT1", CGRect(x: 300, y: 202, width: 60, height: 20)),
        ("LEFT2", CGRect(x: 20, y: 100, width: 50, height: 20)),
        ("RIGHT2", CGRect(x: 300, y: 99, width: 60, height: 20)),
        ("LEFT1", CGRect(x: 20, y: 200, width: 50, height: 20)),
    ])
    // Assert
    #expect(subject.text == "LEFT1 RIGHT1\nLEFT2 RIGHT2")
    #expect(
        subject.text(in: subject.range(from: CGPoint(x: 25, y: 210), to: CGPoint(x: 65, y: 110)))
            == "LEFT1 RIGHT1\nLEFT2")
}

@Test func test_range_when_dragCrossesThreeRaggedRows_then_selectsFullMiddleRowAndPartialEnds() {
    // Arrange
    let subject = fragmentDocument([
        ("ABC", CGRect(x: 20, y: 200, width: 60, height: 20)),
        ("MIDDLE", CGRect(x: 150, y: 110, width: 180, height: 30)),
        ("XYZ", CGRect(x: 50, y: 20, width: 60, height: 20)),
    ])
    // Act
    let range = subject.range(from: CGPoint(x: 50, y: 210), to: CGPoint(x: 80, y: 30))
    // Assert
    #expect(subject.text(in: range) == "BC\nMIDDLE\nXY")
}

@Test func test_range_when_reverseDragCrossesThreeRaggedRows_then_selectsSameCompleteRange() {
    // Arrange
    let subject = fragmentDocument([
        ("ABC", CGRect(x: 20, y: 200, width: 60, height: 20)),
        ("MIDDLE", CGRect(x: 150, y: 110, width: 180, height: 30)),
        ("XYZ", CGRect(x: 50, y: 20, width: 60, height: 20)),
    ])
    // Act
    let range = subject.range(from: CGPoint(x: 80, y: 30), to: CGPoint(x: 50, y: 210))
    // Assert
    #expect(subject.text(in: range) == "BC\nMIDDLE\nXY")
}

@Test func test_range_when_blankOriginCrossesScatteredRows_then_includesFirstReachedRow() {
    // Arrange
    let subject = scatteredDocument()
    // Act
    let range = subject.range(from: CGPoint(x: 0, y: 210), to: CGPoint(x: 115, y: 30))
    // Assert
    #expect(subject.text(in: range) == "電池健康度 正常\n自動調整亮度\n低耗電模式")
}

@Test
func test_range_when_smallTextSharesRowWithTallText_then_selectsTheTextUnderThePointer() {
    // Arrange
    let subject = fragmentDocument([
        ("LARGE", CGRect(x: 20, y: 198, width: 150, height: 100)),
        ("small", CGRect(x: 300, y: 200, width: 50, height: 16)),
        ("next", CGRect(x: 20, y: 167, width: 40, height: 20)),
    ])
    // Act
    let range = subject.range(from: CGPoint(x: 301, y: 208), to: CGPoint(x: 349, y: 208))
    // Assert
    #expect(subject.text(in: range) == "small")
}
