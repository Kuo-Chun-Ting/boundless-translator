@MainActor
protocol ImageWorkspaceSelectionProviding: AnyObject {
    var isSelectionActive: Bool { get }
    var selectedText: String { get }
}

@MainActor
final class ImageWorkspaceSelectionReader: SelectedTextReading {
    private weak var provider: (any ImageWorkspaceSelectionProviding)?

    init(provider: any ImageWorkspaceSelectionProviding) {
        self.provider = provider
    }

    func readSelectedText() async throws -> SelectedText {
        guard
            let provider,
            provider.isSelectionActive
        else {
            throw SelectedTextReadError.noSelection
        }

        do {
            return try SelectedText(provider.selectedText)
        } catch SelectedTextError.empty {
            throw SelectedTextReadError.noSelection
        }
    }
}
