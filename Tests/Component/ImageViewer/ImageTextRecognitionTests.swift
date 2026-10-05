import AppKit
import Testing
@testable import BoundlessTranslator

private struct RecognitionCase: Sendable {
    let image: String
    let first: String
    let last: String
    let expected: String
}

@Test(arguments: [
    RecognitionCase(image: "basic-text.png", first: "ORIGINAL", last: "WORDS", expected: "ORIGINAL TEXT\nTARGET WORDS"),
    RecognitionCase(image: "basic-text.png", first: "中文", last: "。", expected: "中文也能選取文字。"),
    RecognitionCase(image: "battery-settings.jpeg", first: "Energy", last: "Mode", expected: "Energy Mode"),
    RecognitionCase(image: "scattered-labels.png", first: "電池", last: "模式", expected: "電池健康度 正常\n自動調整亮度\n低耗電模式"),
    RecognitionCase(image: "ragged-rows.png", first: "ALPHA", last: "OMEGA", expected: "ALPHA\nMIDDLE CONTENT\nOMEGA"),
    RecognitionCase(image: "two-columns.png", first: "LEFT", last: "LOWER", expected: "LEFT RIGHT\nLOWER"),
    RecognitionCase(image: "mixed-font-sizes.png", first: "LARGE", last: "NEXT", expected: "LARGE small\nNEXT")
]) @MainActor
private func test_recognition_when_fixedImageIsSelectedInEitherDirection_then_preservesLiteralText(
    input: RecognitionCase
) async throws {
    // Arrange: real Vision recognition and the production selection view, without another App.
    let image = try loadImageTextFixture(input.image)
    let cgImage = try #require(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
    let document = try ImageTextRecognizer.recognize(cgImage, size: image.size)
    let view = ImageTextView(analysisProvider: { _ in document })
    let window = NSWindow(contentRect: CGRect(origin: .zero, size: image.size),
                          styleMask: [.titled], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.contentView = view
    defer { window.close() }
    view.display(image)
    await viewAnalysis(view)
    let first = try #require(view.document.words.first { view.document.text(in: $0.range).contains(input.first) })
    let last = try #require(view.document.words.first { $0.line >= first.line && view.document.text(in: $0.range).contains(input.last) })
    let a = view.viewRect(for: first.bounds)
    let b = view.viewRect(for: last.bounds)
    let start = CGPoint(x: a.minX + 1, y: a.midY)
    let end = CGPoint(x: b.maxX - 1, y: b.midY)
    // Act & Assert: both directions represent the same reading range.
    for (from, to) in [(start, end), (end, start)] {
        dragImageText(view, in: window, from: from, to: to)
        #expect(view.selectedText == input.expected)
    }
}

@Test @MainActor
func test_recognition_when_imageHasNoText_then_dragCreatesNoSelection() async throws {
    // Arrange
    let image = try loadImageTextFixture("no-text.png")
    let cgImage = try #require(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
    let document = try ImageTextRecognizer.recognize(cgImage, size: image.size)
    let view = ImageTextView(analysisProvider: { _ in document })
    let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 760, height: 360),
                          styleMask: [.titled], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.contentView = view
    defer { window.close() }
    view.display(image)
    await viewAnalysis(view)
    // Act
    dragImageText(view, in: window, from: CGPoint(x: 20, y: 300), to: CGPoint(x: 700, y: 50))
    // Assert
    #expect(view.document.words.isEmpty)
    #expect(view.selectedText.isEmpty)
}

@MainActor func loadImageTextFixture(_ name: String) throws -> NSImage {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
    return try #require(NSImage(contentsOf: root.appendingPathComponent("Fixtures/ImageText/\(name)")))
}
