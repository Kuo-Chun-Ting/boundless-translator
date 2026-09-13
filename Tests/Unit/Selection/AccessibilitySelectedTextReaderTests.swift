import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_readSelectedText_when_accessibility_returns_empty_text_then_reports_no_selection() async {
    // Arrange
    let reader = AccessibilitySelectedTextReader(
        isProcessTrusted: { true },
        readRawSelectedText: { "" }
    )

    // Act & Assert
    do {
        _ = try await reader.readSelectedText()
        Issue.record("Expected no selection")
    } catch SelectedTextReadError.noSelection {
        // Expected.
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}
