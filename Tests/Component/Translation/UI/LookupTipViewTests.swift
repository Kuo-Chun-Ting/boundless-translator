import SwiftUI
import Testing
import TipKit
@testable import BoundlessTranslator

@Test(arguments: ["en", "zh-Hant", "de", "ar"])
@MainActor
func test_lookupTip_when_measuredBeforePresentation_then_hasContentSize(language: String) {
    // Arrange
    let localization = AppLocalization(languageIdentifier: language)
    let controller = NSHostingController(rootView: LookupTipView(
        tip: LookupTip(localization: localization), width: 256, localization: localization
    ))

    // Act
    let size = controller.view.fittingSize

    // Assert
    #expect(size.width == 256)
    #expect(size.height > 24)
    #expect(size.height < 200)
}
