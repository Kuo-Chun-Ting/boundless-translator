import AppKit
import Testing
import VisionKit
@testable import BoundlessTranslator

@Test @MainActor
func test_appearance_when_switchingLightDarkLight_then_updatesBackgroundAndPreservesImage() throws {
    // Arrange
    let view = LiveTextImageView(analysisProvider: { _ in nil })
    let image = NSImage(size: NSSize(width: 400, height: 200))
    view.display(image)
    var backgrounds: [CGColor] = []

    // Act & Assert
    for name in [NSAppearance.Name.aqua, .darkAqua, .aqua] {
        view.appearance = NSAppearance(named: name)
        view.displayIfNeeded()
        let actual = try #require(view.layer?.backgroundColor)
        var expected: CGColor?
        view.effectiveAppearance.performAsCurrentDrawingAppearance {
            expected = NSColor.windowBackgroundColor.cgColor
        }
        #expect(actual == expected)
        #expect(view.imageView.image === image)
        backgrounds.append(actual)
    }
    #expect(backgrounds[0] != backgrounds[1])
    #expect(backgrounds[0] == backgrounds[2])
}

@Test @MainActor
func test_init_whenViewIsCreated_then_composesNativeLiveTextOverlay() {
    // Arrange & Act
    let view = LiveTextImageView(analysisProvider: { _ in nil })

    // Assert
    #expect(view.imageView.superview === view)
    #expect(view.overlayView.superview === view.imageView)
    #expect(view.imageView.imageScaling == .scaleProportionallyUpOrDown)
    #expect(view.overlayView.trackingImageView === view.imageView)
    #expect(view.overlayView.preferredInteractionTypes == .textSelection)
}

@Test @MainActor
func test_contentsRect_whenImageIsAspectFit_then_matchesDisplayedImageBounds() {
    // Arrange
    let view = LiveTextImageView(analysisProvider: { _ in nil })
    view.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
    view.layoutSubtreeIfNeeded()
    view.display(NSImage(size: NSSize(width: 400, height: 200)))

    // Act
    let contentsRect = view.contentsRect(for: view.overlayView)

    // Assert
    #expect(contentsRect == NSRect(x: 0, y: 50, width: 400, height: 200))
}

@Test @MainActor
func test_display_whenImageChanges_then_analyzesLatestImageAndReplacesDisplayedImage() async {
    // Arrange
    var analyzedSizes: [NSSize] = []
    let view = LiveTextImageView { image in
        analyzedSizes.append(image.size)
        return nil
    }
    let firstImage = NSImage(size: NSSize(width: 100, height: 80))
    let secondImage = NSImage(size: NSSize(width: 300, height: 200))

    // Act
    view.display(firstImage)
    await Task.yield()
    view.display(secondImage)
    await Task.yield()

    // Assert
    #expect(view.imageView.image === secondImage)
    #expect(analyzedSizes == [firstImage.size, secondImage.size])
    #expect(!view.hasActiveTextSelection)
    #expect(view.selectedText.isEmpty)
}
