import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test(arguments: ["en", "zh-Hant", "de", "ar", "ja"], [NSAppearance.Name.aqua, .darkAqua])
@MainActor
func test_failureView_when_longMessageWraps_then_preservesWidthAndExpandsVertically(
    language: String, appearance: NSAppearance.Name
) {
    // Arrange
    let localization = AppLocalization(languageIdentifier: language)
    func measure(_ failure: TranslationFailure) -> CGSize {
        let view = NSHostingView(rootView: TranslationFailureView(
            failure: failure, localization: localization, onRetry: {}
        ).frame(width: 244))
        view.appearance = NSAppearance(named: appearance)
        return view.fittingSize
    }

    // Act
    let short = measure(.unexpected("Unavailable."))
    let long = measure(.unexpected(String(repeating: "Service unavailable. ", count: 80)))

    // Assert
    #expect(short.width == 244)
    #expect(long.width == 244)
    #expect(long.height > short.height)
    #expect(long.height > 440)
}
