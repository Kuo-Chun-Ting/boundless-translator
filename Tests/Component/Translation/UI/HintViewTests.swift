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
