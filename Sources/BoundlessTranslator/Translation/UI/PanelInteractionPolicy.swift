enum TranslationWindowKind {
    case translation
    case error
}

struct WindowInteractionPolicy {
    let kind: TranslationWindowKind

    func shouldDismissForOutsideClick(isPinned: Bool) -> Bool {
        switch kind {
        case .translation:
            !isPinned
        case .error:
            true
        }
    }

    func shouldDismissForCancelOperation(isPinned: Bool) -> Bool {
        switch kind {
        case .translation:
            !isPinned
        case .error:
            true
        }
    }
}
