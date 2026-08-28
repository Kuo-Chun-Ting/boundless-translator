import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_select_when_mode_is_translate_then_only_runs_translation_workflow() throws {
    // Arrange
    let mock_translation = TranslationWorkflowMock()
    let mock_dictionary = DictionaryWorkflowMock()
    let coordinator = PanelWorkflowCoordinator(
        translation: mock_translation,
        dictionary: mock_dictionary
    )

    // Act
    coordinator.select(.translate, text: try SelectedText("mockup"))

    // Assert
    #expect(mock_translation.invocationCount == 1)
    #expect(mock_dictionary.receivedTexts.isEmpty)
}

@Test @MainActor
func test_select_when_mode_is_dictionary_then_only_looksUp_selected_text() throws {
    // Arrange
    let mock_translation = TranslationWorkflowMock()
    let mock_dictionary = DictionaryWorkflowMock()
    let coordinator = PanelWorkflowCoordinator(
        translation: mock_translation,
        dictionary: mock_dictionary
    )
    let selectedText = try SelectedText("mockup")

    // Act
    coordinator.select(.dictionary, text: selectedText)

    // Assert
    #expect(mock_translation.invocationCount == 0)
    #expect(mock_dictionary.receivedTexts == [selectedText])
}

@MainActor
private final class TranslationWorkflowMock: TranslationWorkflowing {
    private(set) var invocationCount = 0

    func translate() {
        invocationCount += 1
    }
}

@MainActor
private final class DictionaryWorkflowMock: DictionaryWorkflowing {
    private(set) var receivedTexts: [SelectedText] = []

    func lookUp(_ selectedText: SelectedText) {
        receivedTexts.append(selectedText)
    }
}
