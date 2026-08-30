import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_body_when_preferencesAreRendered_then_showsUsageGuidance() throws {
    // Arrange
    let controller = PreferencesWindowController(settings: TranslationSettings())
    let contentView = try #require(controller.window?.contentView)
    contentView.appearance = NSAppearance(named: .darkAqua)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let image = try #require(
        contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds)
    )
    contentView.cacheDisplay(in: contentView.bounds, to: image)
    let guidanceRows = [
        NSRect(x: 24, y: 224, width: 382, height: 24),
        NSRect(x: 24, y: 265, width: 382, height: 24),
        NSRect(x: 24, y: 306, width: 382, height: 24),
    ]

    // Assert
    #expect(contentView.bounds.height >= 300)
    #expect(
        guidanceRows.allSatisfy {
            brightPixelCount(in: $0, image: image) > 20
        }
    )
}

private func brightPixelCount(
    in rect: NSRect,
    image: NSBitmapImageRep
) -> Int {
    let scaleX = CGFloat(image.pixelsWide) / image.size.width
    let scaleY = CGFloat(image.pixelsHigh) / image.size.height
    let pixelRect = NSRect(
        x: rect.minX * scaleX,
        y: rect.minY * scaleY,
        width: rect.width * scaleX,
        height: rect.height * scaleY
    ).integral
    var count = 0

    for y in Int(pixelRect.minY)..<Int(pixelRect.maxY) {
        for x in Int(pixelRect.minX)..<Int(pixelRect.maxX) {
            guard let color = image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else {
                continue
            }
            let luminance = (
                color.redComponent
                    + color.greenComponent
                    + color.blueComponent
            ) / 3
            if luminance > 0.40 {
                count += 1
            }
        }
    }

    return count
}
