import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_readSelectedText_when_primary_reader_succeeds_then_skips_fallback() async throws {
    // Arrange
    let expectedSelection = try SelectedText("Hello")
    let stub_primary = SelectedTextReaderStub(result: .success(expectedSelection))
    let mock_fallback = SelectedTextReaderMock(
        result: .failure(SelectedTextReaderTestError.unavailable)
    )
    let resolver = SelectedTextResolver(
        primaryReader: stub_primary,
        fallbackReader: mock_fallback
    )

    // Act
    let selection = try await resolver.readSelectedText()

    // Assert
    #expect(selection == expectedSelection)
    #expect(mock_fallback.invocationCount == 0)
}

@Test @MainActor
func test_readSelectedText_when_primary_has_no_selection_then_uses_fallback() async throws {
    // Arrange
    let expectedSelection = try SelectedText("Fallback")
    let stub_primary = SelectedTextReaderStub(
        result: .failure(SelectedTextReadError.noSelection)
    )
    let mock_fallback = SelectedTextReaderMock(result: .success(expectedSelection))
    let resolver = SelectedTextResolver(
        primaryReader: stub_primary,
        fallbackReader: mock_fallback
    )

    // Act
    let selection = try await resolver.readSelectedText()

    // Assert
    #expect(selection == expectedSelection)
    #expect(mock_fallback.invocationCount == 1)
}

@Test @MainActor
func test_readSelectedText_when_primary_is_cancelled_then_stops_without_fallback() async throws {
    // Arrange
    let mock_fallback = SelectedTextReaderMock(result: .success(try SelectedText("Fallback")))
    let resolver = SelectedTextResolver(
        primaryReader: SelectedTextReaderStub(result: .failure(CancellationError())),
        fallbackReader: mock_fallback
    )

    // Act & Assert
    await #expect(throws: CancellationError.self) { try await resolver.readSelectedText() }
    #expect(mock_fallback.invocationCount == 0)
}

@Test @MainActor
func test_readSelectedText_when_primary_has_unexpected_error_then_preserves_error_without_fallback() async throws {
    // Arrange
    let mock_fallback = SelectedTextReaderMock(result: .success(try SelectedText("Fallback")))
    let resolver = SelectedTextResolver(
        primaryReader: SelectedTextReaderStub(result: .failure(SelectedTextReaderTestError.unavailable)),
        fallbackReader: mock_fallback
    )

    // Act & Assert
    await #expect(throws: SelectedTextReaderTestError.self) { try await resolver.readSelectedText() }
    #expect(mock_fallback.invocationCount == 0)
}

@MainActor
private final class SelectedTextReaderStub: SelectedTextReading {
    private let result: Result<SelectedText, Error>

    init(result: Result<SelectedText, Error>) {
        self.result = result
    }

    func readSelectedText() async throws -> SelectedText {
        try result.get()
    }
}

@MainActor
private final class SelectedTextReaderMock: SelectedTextReading {
    private(set) var invocationCount = 0

    private let result: Result<SelectedText, Error>

    init(result: Result<SelectedText, Error>) {
        self.result = result
    }

    func readSelectedText() async throws -> SelectedText {
        invocationCount += 1
        return try result.get()
    }
}

private enum SelectedTextReaderTestError: Error {
    case unavailable
}
