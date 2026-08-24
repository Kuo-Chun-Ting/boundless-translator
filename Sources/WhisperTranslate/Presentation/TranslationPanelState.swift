import Combine

@MainActor
final class TranslationPanelState: ObservableObject {
    @Published private(set) var isPinned = false

    var pinRotationDegrees: Double {
        isPinned ? 0 : 45
    }

    func togglePin() {
        isPinned.toggle()
    }

    func reset() {
        isPinned = false
    }
}
