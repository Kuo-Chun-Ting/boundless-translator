import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_readSelectedText_when_workspace_selection_is_active_then_returns_selection() async throws {
    // Arrange
    let provider = ImageViewerSelectionProviderStub(
        isSelectionActive: true,
        selectedText: "Image selection"
    )
    let reader = ImageViewerSelectionReader(provider: provider)

    // Act
    let selectedText = try await reader.readSelectedText()

    // Assert
    #expect(selectedText == (try SelectedText("Image selection")))
}

@Test @MainActor
func test_readSelectedText_when_workspace_selection_is_inactive_then_reports_reader_unavailable() async {
    // Arrange
    let provider = ImageViewerSelectionProviderStub(
        isSelectionActive: false,
        selectedText: "Stale selection"
    )
    let reader = ImageViewerSelectionReader(provider: provider)

    // Act & Assert
    await #expect(throws: SelectedTextReadError.readerUnavailable) {
        try await reader.readSelectedText()
    }
}

@Test @MainActor
func test_readSelectedText_when_workspace_selection_is_empty_then_reports_reader_unavailable() async {
    // Arrange
    let provider = ImageViewerSelectionProviderStub(
        isSelectionActive: true,
        selectedText: "  \n"
    )
    let reader = ImageViewerSelectionReader(provider: provider)

    // Act & Assert
    await #expect(throws: SelectedTextReadError.readerUnavailable) {
        try await reader.readSelectedText()
    }
}

@MainActor
private final class ImageViewerSelectionProviderStub: ImageViewerSelectionProviding {
    let isSelectionActive: Bool
    let selectedText: String

    init(isSelectionActive: Bool, selectedText: String) {
        self.isSelectionActive = isSelectionActive
        self.selectedText = selectedText
    }
}
