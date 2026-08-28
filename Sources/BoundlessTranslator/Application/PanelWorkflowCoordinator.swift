enum TranslationPanelMode: Int, Equatable, Sendable {
    case translate
    case dictionary
}

@MainActor
protocol TranslationWorkflowing {
    func translate()
}

@MainActor
protocol DictionaryWorkflowing {
    func lookUp(_ selectedText: SelectedText)
}

@MainActor
final class PanelWorkflowCoordinator {
    private let translation: any TranslationWorkflowing
    private let dictionary: any DictionaryWorkflowing

    init(
        translation: any TranslationWorkflowing,
        dictionary: any DictionaryWorkflowing
    ) {
        self.translation = translation
        self.dictionary = dictionary
    }

    func select(_ mode: TranslationPanelMode, text: SelectedText) {
        switch mode {
        case .translate:
            translation.translate()
        case .dictionary:
            dictionary.lookUp(text)
        }
    }
}
