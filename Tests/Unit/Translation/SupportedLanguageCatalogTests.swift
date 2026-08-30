import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_load_when_languages_are_available_then_sorts_by_display_name() async {
    // Arrange
    let catalog = SupportedLanguageCatalog(
        loadLanguages: {
            [
                Locale.Language(identifier: "fr"),
                Locale.Language(identifier: "en"),
            ]
        },
        displayName: { identifier in
            ["en": "Alpha", "fr": "Zulu"][identifier] ?? identifier
        }
    )

    // Act
    let languages = await catalog.load()

    // Assert
    #expect(languages.map(\.minimalIdentifier) == ["en", "fr"])
    #expect(catalog.languages.map(\.minimalIdentifier) == ["en", "fr"])
}

@Test @MainActor
func test_load_when_loader_returns_empty_list_then_loads_only_once() async {
    // Arrange
    var loadCount = 0
    let catalog = SupportedLanguageCatalog(
        loadLanguages: {
            loadCount += 1
            return []
        }
    )

    // Act
    _ = await catalog.load()
    _ = await catalog.load()

    // Assert
    #expect(loadCount == 1)
}

@Test @MainActor
func test_load_when_requests_overlap_then_each_receives_same_sorted_languages() async {
    // Arrange
    var loadCount = 0
    let catalog = SupportedLanguageCatalog(
        loadLanguages: {
            loadCount += 1
            await Task.yield()
            return [
                Locale.Language(identifier: "fr"),
                Locale.Language(identifier: "en"),
            ]
        },
        displayName: { identifier in
            ["en": "Alpha", "fr": "Zulu"][identifier] ?? identifier
        }
    )

    // Act
    let firstTask = Task { await catalog.load() }
    await Task.yield()
    let secondTask = Task { await catalog.load() }
    let firstLanguages = await firstTask.value
    let secondLanguages = await secondTask.value

    // Assert
    #expect(loadCount == 1)
    #expect(firstLanguages.map(\.minimalIdentifier) == ["en", "fr"])
    #expect(secondLanguages.map(\.minimalIdentifier) == ["en", "fr"])
}
