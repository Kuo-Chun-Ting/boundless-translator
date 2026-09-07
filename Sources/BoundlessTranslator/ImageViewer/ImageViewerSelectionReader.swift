@MainActor
protocol ImageViewerSelectionProviding: AnyObject {
    var isSelectionActive: Bool { get }
    var selectedText: String { get }
}

@MainActor
final class ImageViewerSelectionReader: SelectedTextReading {
    private weak var provider: (any ImageViewerSelectionProviding)?

    init(provider: any ImageViewerSelectionProviding) {
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
