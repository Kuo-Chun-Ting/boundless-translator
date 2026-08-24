import Combine

@MainActor
final class TranslationPanelState: ObservableObject {
    @Published private(set) var isPinned = false

    func togglePin() {
        isPinned.toggle()
    }

    func reset() {
        isPinned = false
    }
}
