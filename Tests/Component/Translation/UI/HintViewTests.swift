import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test(arguments: ["en", "zh-Hant", "de", "ar"], [false, true])
@MainActor
func test_hintView_when_measuredBeforePresentation_then_hasContentSize(language: String, screenshot: Bool) {
    // Arrange
    let localization = AppLocalization(languageIdentifier: language)
    let lookupTip = LookupTip(localization: localization)
    let screenshotTip = ScreenshotTip(localization: localization, shortcut: "⇧⌘1")
    let controller = NSHostingController(rootView: HintView(
        title: screenshot ? screenshotTip.title : lookupTip.title,
        message: screenshot ? screenshotTip.message : lookupTip.message,
        icon: Image(nsImage: AppBrand.spriteImage), width: 256, localization: localization,
        identifier: screenshot ? "hint.screenshot" : "hint.dictionary", onClose: { _ in }
    ))

    // Act
    let size = controller.view.fittingSize

    // Assert
    #expect(size.width == 256)
    #expect(size.height > 24)
    #expect(size.height < 200)
}

@Test @MainActor
func test_hintView_whenWidthIsReduced_then_wrapsControlsWithoutClippingText() {
    // Arrange
    let localization = AppLocalization(languageIdentifier: "de")
    let tip = ScreenshotTip(localization: localization, shortcut: "⇧⌘1")
    func measure(width: CGFloat) -> CGSize {
        NSHostingController(rootView: HintView(
            title: tip.title, message: tip.message,
            icon: Image(nsImage: AppBrand.spriteImage), width: width,
            localization: localization, identifier: "hint.screenshot", onClose: { _ in }
        )).view.fittingSize
    }

    // Act
    let wide = measure(width: 1_000)
    let narrow = measure(width: 256)

    // Assert
    #expect(narrow.width == 256)
    #expect(narrow.height > wide.height)
}

@Test(arguments: InterfaceLanguageCatalog.languageIdentifiers) @MainActor
func test_settingsHint_when_localized_then_wrapsWithinFixedCardWidth(language: String) {
    // Arrange
    let localization = AppLocalization(languageIdentifier: language)
    let tip = SettingsTip(localization: localization)
    func measure(width: CGFloat) -> CGSize {
        NSHostingController(rootView: HintView(
            title: tip.title, message: tip.message, icon: Image(nsImage: AppBrand.spriteImage),
            width: width, localization: localization, identifier: "hint.settings",
            onClose: { _ in }, presentation: .callout
        )).view.fittingSize
    }

    // Act
    let card = measure(width: 248)
    let wide = measure(width: 1_000)

    // Assert
    #expect(card.width == 248)
    #expect(card.height > wide.height)
    #expect(card.height < 360)
}

@Test @MainActor
func test_hintSurface_when_appearanceChanges_then_cardAndInlineShareAdaptiveBackground() throws {
    // Arrange
    var brightness: [CGFloat] = []
    for appearance in [NSAppearance.Name.aqua, .darkAqua] {
        var samples: [NSColor] = []
        for presentation in [HintPresentation.inline, .callout] {
            let view = NSHostingView(rootView: HintView(
                title: Text("Title"), message: Text("Message"), icon: Image(nsImage: AppBrand.spriteImage),
                width: 248, localization: AppLocalization(languageIdentifier: "en"),
                identifier: "hint.test", onClose: { _ in }, presentation: presentation
            ))
            let window = NSWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
            window.colorSpace = .sRGB
            window.appearance = NSAppearance(named: appearance)
            window.contentView = view
            window.setContentSize(view.fittingSize)

            // Act
            view.layoutSubtreeIfNeeded()
            let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
            view.cacheDisplay(in: view.bounds, to: bitmap)
            let sample = try #require(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: 5))
            samples.append(sample)
        }

        // Assert
        #expect(abs(samples[0].redComponent - samples[1].redComponent) < 0.02)
        #expect(abs(samples[0].greenComponent - samples[1].greenComponent) < 0.02)
        #expect(abs(samples[0].blueComponent - samples[1].blueComponent) < 0.02)
        #expect(samples.allSatisfy { $0.alphaComponent > 0.99 })
        brightness.append(samples[0].redComponent)
    }
    #expect(brightness[0] > brightness[1] + 0.3)
}
