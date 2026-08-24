import Foundation
import Testing
@testable import WhisperTranslate

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
func test_readSelectedText_when_primary_reader_fails_then_uses_fallback() async throws {
    // Arrange
    let expectedSelection = try SelectedText("Fallback")
    let stub_primary = SelectedTextReaderStub(
        result: .failure(SelectedTextReaderTestError.unavailable)
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
