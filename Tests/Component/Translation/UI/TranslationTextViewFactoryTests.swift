import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_make_when_creating_translation_text_view_then_applies_shared_configuration() throws {
    // Arrange
    let expectedFont = TranslationPanelStyle.contentFont

    // Act
    let textView = TranslationTextViewFactory.make()

    // Assert
    #expect(!textView.isEditable)
    #expect(textView.isSelectable)
    #expect(!textView.isRichText)
    #expect(!textView.drawsBackground)
    #expect(textView.font?.fontName == expectedFont.fontName)
    #expect(textView.textColor == .labelColor)
    #expect(textView.textContainerInset == .zero)
    #expect(textView.textContainer?.widthTracksTextView == true)
    #expect(textView.textContainer?.lineFragmentPadding == 0)
}
