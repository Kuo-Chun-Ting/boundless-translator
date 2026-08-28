import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_lookUp_when_selection_has_outer_whitespace_then_forwards_complete_trimmed_term() throws {
    // Arrange
    let mock_service = DictionaryLookupServiceMock(definition: "Definition")
    let coordinator = DictionaryLookupCoordinator(service: mock_service)

    // Act
    coordinator.lookUp(try SelectedText("  San Francisco  \n"))

    // Assert
    #expect(mock_service.receivedTerms == ["San Francisco"])
}

@Test @MainActor
func test_lookUp_when_definition_exists_then_publishes_found_status() throws {
    // Arrange
    let stub_service = DictionaryLookupServiceMock(definition: "A greeting.")
    let coordinator = DictionaryLookupCoordinator(service: stub_service)

    // Act
    coordinator.lookUp(try SelectedText("hello"))

    // Assert
    #expect(
        coordinator.status == .found(
            DictionaryDefinition(term: "hello", text: "A greeting.")
        )
    )
}

@Test @MainActor
func test_lookUp_when_definition_is_missing_then_publishes_notFound_status() throws {
    // Arrange
    let stub_service = DictionaryLookupServiceMock(definition: nil)
    let coordinator = DictionaryLookupCoordinator(service: stub_service)

    // Act
    coordinator.lookUp(try SelectedText("unknown term"))

    // Assert
    #expect(coordinator.status == .notFound("unknown term"))
}

@Test @MainActor
func test_lookUp_when_normalized_term_is_unchanged_then_reuses_cached_result() throws {
    // Arrange
    let mock_service = DictionaryLookupServiceMock(definition: "A greeting.")
    let coordinator = DictionaryLookupCoordinator(service: mock_service)

    // Act
    coordinator.lookUp(try SelectedText("hello"))
    coordinator.lookUp(try SelectedText("  hello\n"))

    // Assert
    #expect(mock_service.receivedTerms == ["hello"])
}

@Test @MainActor
func test_reset_when_lookup_has_completed_then_publishes_idle_status() throws {
    // Arrange
    let stub_service = DictionaryLookupServiceMock(definition: "A greeting.")
    let coordinator = DictionaryLookupCoordinator(service: stub_service)
    coordinator.lookUp(try SelectedText("hello"))

    // Act
    coordinator.reset()

    // Assert
    #expect(coordinator.status == .idle)
}

@Test @MainActor
func test_reset_when_same_term_is_lookedUp_again_then_clears_cached_term() throws {
    // Arrange
    let mock_service = DictionaryLookupServiceMock(definition: "A greeting.")
    let coordinator = DictionaryLookupCoordinator(service: mock_service)
    let selectedText = try SelectedText("hello")
    coordinator.lookUp(selectedText)

    // Act
    coordinator.reset()
    coordinator.lookUp(selectedText)

    // Assert
    #expect(mock_service.receivedTerms == ["hello", "hello"])
}

private final class DictionaryLookupServiceMock: DictionaryLookupServicing {
    private(set) var receivedTerms: [String] = []

    private let definition: String?

    init(definition: String?) {
        self.definition = definition
    }

    func lookUp(_ term: String) -> String? {
        receivedTerms.append(term)
        return definition
    }
}
