import Combine

@MainActor
final class TranslationWindowState: ObservableObject {
    @Published private(set) var isPinned = false

    func togglePin() {
        isPinned.toggle()
    }

    func reset() {
        isPinned = false
    }
}
