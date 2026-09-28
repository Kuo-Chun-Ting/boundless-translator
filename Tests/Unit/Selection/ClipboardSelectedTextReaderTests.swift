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
func test_readSelectedText_when_copySucceeds_then_returnsSelectionAndRestoresOriginal() async throws {
    // Arrange
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    pasteboard.setString("Original", forType: .string)
    let reader = ClipboardSelectedTextReader(pasteboard: pasteboard, hasAccessibilityPermission: { true }, copier: TestSelectedTextCopier(copy: {
        pasteboard.clearContents()
        pasteboard.setString("Selection", forType: .string)
    }))

    // Act
    let selection = try await reader.readSelectedText()

    // Assert
    #expect(selection.value == "Selection")
    #expect(pasteboard.string(forType: .string) == "Original")
}

@Test @MainActor
func test_readSelectedText_when_originalIsEmpty_then_restoresEmptyClipboard() async throws {
    // Arrange
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    let reader = ClipboardSelectedTextReader(pasteboard: pasteboard, hasAccessibilityPermission: { true }, copier: TestSelectedTextCopier(copy: {
        pasteboard.clearContents()
        pasteboard.setString("Selection", forType: .string)
    }))

    // Act
    _ = try await reader.readSelectedText()

    // Assert
    #expect(pasteboard.pasteboardItems?.isEmpty != false)
}

@Test @MainActor
func test_readSelectedText_when_copyReturnsEmptyText_then_restoresOriginalAndReportsNoSelection() async {
    // Arrange
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    pasteboard.setString("Original", forType: .string)
    let reader = ClipboardSelectedTextReader(pasteboard: pasteboard, hasAccessibilityPermission: { true }, copier: TestSelectedTextCopier(copy: {
        pasteboard.clearContents()
        pasteboard.setString("", forType: .string)
    }))

    // Act & Assert
    await #expect(throws: SelectedTextReadError.noSelection) { try await reader.readSelectedText() }
    #expect(pasteboard.string(forType: .string) == "Original")
}

@Test @MainActor
func test_readSelectedText_when_copyTimesOut_then_keepsOriginal() async {
    // Arrange
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    pasteboard.setString("Original", forType: .string)
    let reader = ClipboardSelectedTextReader(copyTimeout: .zero, pasteboard: pasteboard,
                                            hasAccessibilityPermission: { true }, copier: TestSelectedTextCopier(copy: {}))

    // Act & Assert
    await #expect(throws: SelectedTextReadError.noSelection) { try await reader.readSelectedText() }
    #expect(pasteboard.string(forType: .string) == "Original")
}

@Test @MainActor
func test_readSelectedText_when_copyThrows_then_keepsOriginal() async {
    // Arrange
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    pasteboard.setString("Original", forType: .string)
    let reader = ClipboardSelectedTextReader(pasteboard: pasteboard, hasAccessibilityPermission: { true }, copier: TestSelectedTextCopier(copy: {
        throw SelectedTextReadError.readerUnavailable
    }))

    // Act & Assert
    await #expect(throws: SelectedTextReadError.readerUnavailable) { try await reader.readSelectedText() }
    #expect(pasteboard.string(forType: .string) == "Original")
}

@Test @MainActor
func test_readSelectedText_when_cancelledWhileWaiting_then_keepsOriginal() async {
    // Arrange
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    pasteboard.setString("Original", forType: .string)
    let started = AsyncStream<Void>.makeStream()
    let reader = ClipboardSelectedTextReader(pollInterval: .seconds(120), copyTimeout: .seconds(120),
                                            pasteboard: pasteboard, hasAccessibilityPermission: { true }, copier: TestSelectedTextCopier(copy: {
        started.continuation.yield(())
    }))
    let task = Task { try await reader.readSelectedText() }
    for await _ in started.stream { break }

    // Act
    task.cancel()
    let result = await task.result

    // Assert
    guard case .failure(let error) = result else {
        Issue.record("Expected cancellation")
        return
    }
    #expect(error is CancellationError)
    #expect(pasteboard.string(forType: .string) == "Original")
}

@Test @MainActor
func test_readSelectedText_when_multipleItemsAndFormats_then_restoresEveryRepresentation() async throws {
    // Arrange
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    let textItem = NSPasteboardItem()
    textItem.setString("Original", forType: .string)
    let richText = Data("{\\rtf1 Original}".utf8)
    textItem.setData(richText, forType: .rtf)
    let imageItem = NSPasteboardItem()
    let imageData = Data([1, 2, 3, 4])
    imageItem.setData(imageData, forType: .png)
    pasteboard.writeObjects([textItem, imageItem])
    let reader = ClipboardSelectedTextReader(pasteboard: pasteboard, hasAccessibilityPermission: { true }, copier: TestSelectedTextCopier(copy: {
        pasteboard.clearContents()
        pasteboard.setString("Selection", forType: .string)
    }))

    // Act
    _ = try await reader.readSelectedText()

    // Assert
    let items = try #require(pasteboard.pasteboardItems)
    #expect(items.count == 2)
    #expect(items[0].string(forType: .string) == "Original")
    #expect(items[0].data(forType: .rtf) == richText)
    #expect(items[1].data(forType: .png) == imageData)
}

@Test @MainActor
func test_restore_when_userCopiesNewContent_then_preservesNewCopy() throws {
    // Arrange
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    pasteboard.setString("Original", forType: .string)
    let snapshot = try PasteboardSnapshot(pasteboard: pasteboard)
    pasteboard.clearContents()
    pasteboard.setString("Selection", forType: .string)
    let copiedChangeCount = pasteboard.changeCount
    pasteboard.clearContents()
    pasteboard.setString("New user copy", forType: .string)

    // Act
    snapshot.restore(to: pasteboard, ifUnchangedSince: copiedChangeCount)

    // Assert
    #expect(pasteboard.string(forType: .string) == "New user copy")
}

@Test @MainActor
func test_readSelectedText_when_cancelledAfterNonTextCopy_then_restoresOriginal() async {
    // Arrange
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    pasteboard.setString("Original", forType: .string)
    let started = AsyncStream<Void>.makeStream()
    let reader = ClipboardSelectedTextReader(pollInterval: .seconds(120), copyTimeout: .seconds(120),
                                            pasteboard: pasteboard, hasAccessibilityPermission: { true }, copier: TestSelectedTextCopier(copy: {
        pasteboard.clearContents()
        pasteboard.setData(Data([1]), forType: .png)
        started.continuation.yield(())
    }))
    let task = Task { try await reader.readSelectedText() }
    for await _ in started.stream { break }

    // Act
    task.cancel()
    let result = await task.result

    // Assert
    guard case .failure(let error) = result else {
        Issue.record("Expected cancellation")
        return
    }
    #expect(error is CancellationError)
    #expect(pasteboard.string(forType: .string) == "Original")
}

@Test @MainActor
func test_readSelectedText_when_userCopiesWhileWaitingForText_then_keepsNewCopy() async {
    // Arrange
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    pasteboard.setString("Original", forType: .string)
    let started = AsyncStream<Void>.makeStream()
    let reader = ClipboardSelectedTextReader(pasteboard: pasteboard, hasAccessibilityPermission: { true }, copier: TestSelectedTextCopier(copy: {
        pasteboard.clearContents()
        pasteboard.setData(Data([1]), forType: .png)
        started.continuation.yield(())
    }))
    let task = Task { try await reader.readSelectedText() }
    for await _ in started.stream { break }

    // Act
    pasteboard.clearContents()
    pasteboard.setString("New user copy", forType: .string)
    let result = await task.result

    // Assert
    guard case .failure(let error) = result else {
        Issue.record("A later clipboard update must not be mistaken for the selection")
        return
    }
    #expect(error as? SelectedTextReadError == .noSelection)
    #expect(pasteboard.string(forType: .string) == "New user copy")
}
