import AppKit
import Testing
@testable import BoundlessTranslator

@MainActor
private struct TestSelectedTextCopier: SelectedTextCopying {
    let copy: @MainActor () throws -> Void

    func copySelection() throws -> Void {
        try copy()
    }
}

@Test @MainActor
func test_readSelectedText_when_accessibility_succeeds_then_preserves_clipboard_without_copy() async throws {
    // Arrange
    let pasteboard = NSPasteboard(name: .init(UUID().uuidString))
    defer { pasteboard.releaseGlobally() }
    pasteboard.setString("Original clipboard", forType: .string)
    let originalChangeCount = pasteboard.changeCount
    var copyCount = 0
    let reader = SelectedTextResolver(
        primaryReader: AccessibilitySelectedTextReader(
            hasAccessibilityPermission: { true },
            readRawSelectedText: { "Selected text" }
        ),
        fallbackReader: ClipboardSelectedTextReader(
            pasteboard: pasteboard,
            hasAccessibilityPermission: { true },
            copier: TestSelectedTextCopier(copy: { copyCount += 1 })
        )
    )

    // Act
    let selection = try await reader.readSelectedText()

    // Assert
    #expect(selection.value == "Selected text")
    #expect(copyCount == 0)
    #expect(pasteboard.changeCount == originalChangeCount)
    #expect(pasteboard.string(forType: .string) == "Original clipboard")
}

@Test @MainActor
func test_readSelectedText_when_accessibility_is_unavailable_then_copies_selection_and_restores_clipboard() async throws {
    // Arrange
    let pasteboard = NSPasteboard(name: .init(UUID().uuidString))
    defer { pasteboard.releaseGlobally() }
    pasteboard.setString("Original clipboard", forType: .string)
    let originalChangeCount = pasteboard.changeCount
    var copyCount = 0
    let reader = SelectedTextResolver(
        primaryReader: AccessibilitySelectedTextReader(
            hasAccessibilityPermission: { true },
            readRawSelectedText: { throw SelectedTextReadError.readerUnavailable }
        ),
        fallbackReader: ClipboardSelectedTextReader(
            pasteboard: pasteboard,
            hasAccessibilityPermission: { true },
            copier: TestSelectedTextCopier(copy: {
                copyCount += 1
                pasteboard.clearContents()
                pasteboard.setString("Selected text", forType: .string)
            })
        )
    )

    // Act
    let selection = try await reader.readSelectedText()

    // Assert
    #expect(selection.value == "Selected text")
    #expect(copyCount == 1)
    #expect(pasteboard.changeCount > originalChangeCount)
    #expect(pasteboard.string(forType: .string) == "Original clipboard")
}
