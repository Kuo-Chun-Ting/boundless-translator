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
