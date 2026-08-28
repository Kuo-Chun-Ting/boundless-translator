import Combine

@MainActor
final class TranslationPanelState: ObservableObject {
    @Published private(set) var isPinned = false
    @Published private(set) var mode = TranslationPanelMode.translate

    func togglePin() {
        isPinned.toggle()
    }

    func select(_ mode: TranslationPanelMode) {
        self.mode = mode
    }

    func reset() {
        isPinned = false
        mode = .translate
    }
}
