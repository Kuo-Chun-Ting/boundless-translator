enum TranslationPanelKind {
    case translation
    case error
    case sourceLanguageSelection
}

struct PanelInteractionPolicy {
    let kind: TranslationPanelKind

    func shouldDismissForOutsideClick(isPinned: Bool) -> Bool {
        switch kind {
        case .translation:
            !isPinned
        case .error:
            true
        case .sourceLanguageSelection:
            false
        }
    }
}
