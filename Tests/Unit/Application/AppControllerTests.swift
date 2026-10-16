import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_handleTranslationShortcut_when_no_text_is_selected_then_does_not_capture_screenshot() async {
    // Arrange
    let mock_capture = ScreenshotCaptureMock()
    let suite = "ReadySelectionTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let settings = TranslationSettings(defaults: defaults)
    settings.sourceLanguageIdentifier = "en"
    settings.targetLanguageIdentifier = "ja"
    let controller = AppController(
        settings: settings,
        selectedTextReader: SelectedTextReaderStub(result: .failure(SelectedTextReadError.noSelection)),
        screenshotCapture: mock_capture,
        requestSelectionPermission: { true },
        imageViewerController: ImageViewerControllerStub(),
        subscriptionAccess: makeUnrestrictedTestAccess(),
        onLanguageSetupRequired: {}
    )

    // Act
    controller.handleTranslationShortcut()
    for _ in 0..<5 {
        await Task.yield()
    }

    // Assert
    #expect(mock_capture.captureCount == 0)
}

@Test @MainActor
func test_handleTranslationShortcut_when_selection_is_cancelled_then_does_not_capture_screenshot() async {
    // Arrange
    let mock_capture = ScreenshotCaptureMock()
    let suite = "ReadySelectionTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let settings = TranslationSettings(defaults: defaults)
    settings.sourceLanguageIdentifier = "en"
    settings.targetLanguageIdentifier = "ja"
    let controller = AppController(
        settings: settings,
        selectedTextReader: SelectedTextReaderStub(result: .failure(CancellationError())),
        screenshotCapture: mock_capture,
        requestSelectionPermission: { true },
        imageViewerController: ImageViewerControllerStub(),
        subscriptionAccess: makeUnrestrictedTestAccess(),
        onLanguageSetupRequired: {}
    )

    // Act
    controller.handleTranslationShortcut()
    for _ in 0..<5 {
        await Task.yield()
    }

    // Assert
    #expect(mock_capture.captureCount == 0)
}

@Test(arguments: ["ja", nil]) @MainActor
func test_translationLanguagesForSelection_when_screenshotSelectionIsActive_then_usesLocalPair(source: String?) {
    // Arrange
    let viewer = ImageViewerControllerStub()
    viewer.isSelectionActive = true
    viewer.translationLanguages = (source, "fr")
    let controller = AppController(imageViewerController: viewer,
                                   subscriptionAccess: makeUnrestrictedTestAccess())

    // Act
    let languages = controller.translationLanguagesForSelection()

    // Assert
    #expect(languages.source == source)
    #expect(languages.target == "fr")
}

@Test @MainActor
func test_translationLanguagesForSelection_when_screenshotIsInactive_then_usesSettings() {
    // Arrange
    let viewer = ImageViewerControllerStub()
    viewer.translationLanguages = ("ja", "fr")
    let controller = AppController(imageViewerController: viewer,
                                   subscriptionAccess: makeUnrestrictedTestAccess())

    // Act
    let languages = controller.translationLanguagesForSelection()

    // Assert
    #expect(languages.source == controller.settings.sourceLanguageIdentifier)
    #expect(languages.target == controller.settings.targetLanguageIdentifier)
}

@MainActor
private final class SelectedTextReaderStub: SelectedTextReading {
    let result: Result<SelectedText, Error>
    init(result: Result<SelectedText, Error>) { self.result = result }
    func readSelectedText() async throws -> SelectedText { try result.get() }
}

@MainActor
private final class ScreenshotCaptureMock: ScreenshotCapturing {
    private(set) var captureCount = 0

    func ensurePermission() throws {}

    func captureRegion() async throws -> NSImage? {
        captureCount += 1
        return nil
    }
}

@MainActor
private final class ImageViewerControllerStub: ImageViewerControlling {
    var isSelectionActive = false
    var selectedText = ""
    var translationLanguages: (source: String?, target: String)?
    var presentationCount = 0
    func present(image: NSImage, pointerLocation: CGPoint) { presentationCount += 1 }
}

@Test(arguments: [("", "ja"), ("en", ""), ("", "")]) @MainActor
func test_translate_when_language_is_missing_then_opens_setup_without_calling_engine(source: String, target: String) async throws {
    // Arrange
    let suite = "TranslationSetupTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let settings = TranslationSettings(defaults: defaults)
    settings.sourceLanguageIdentifier = source
    settings.targetLanguageIdentifier = target
    var setupCount = 0
    let controller = AppController(
        settings: settings,
        translationEngine: TranslationEngine(loadLanguages: {
            Issue.record("An incomplete language pair must not reach the engine")
            return []
        }, makeTaskHost: { _, _ in fatalError("Unexpected translation") }),
        requestSelectionPermission: { true },
        imageViewerController: ImageViewerControllerStub(),
        subscriptionAccess: makeUnrestrictedTestAccess(),
        onLanguageSetupRequired: { setupCount += 1 }
    )

    // Act
    await controller.translate(try SelectedText("Hello"), sourceLanguageIdentifier: source)

    // Assert
    #expect(setupCount == 1)
}

@Test @MainActor
func test_handleTranslationShortcut_when_languages_are_missing_then_opens_setup_without_reading_selection() async throws {
    // Arrange
    let suite = "SelectionSetupTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    var events: [String] = []
    let controller = AppController(
        settings: TranslationSettings(defaults: defaults),
        selectedTextReader: SetupSelectionReaderMock { events.append("readSelection") },
        requestSelectionPermission: { true },
        imageViewerController: ImageViewerControllerStub(),
        subscriptionAccess: makeUnrestrictedTestAccess(),
        onLanguageSetupRequired: { events.append("showSettings") }
    )

    // Act
    controller.handleTranslationShortcut()
    let deadline = ContinuousClock.now.advanced(by: .seconds(2))
    while !events.contains("showSettings") && ContinuousClock.now < deadline { await Task.yield() }

    // Assert
    #expect(events == ["showSettings"])
}

@MainActor
private final class SetupSelectionReaderMock: SelectedTextReading {
    let onRead: () -> Void
    init(onRead: @escaping () -> Void) { self.onRead = onRead }
    func readSelectedText() async throws -> SelectedText {
        onRead()
        return try SelectedText("Hello")
    }
}

@Test(arguments: [false, true]) @MainActor
func test_handleTranslationShortcut_when_setup_is_missing_then_requires_accessibility_only_for_external_selection(isScreenshotActive: Bool) async throws {
    // Arrange
    let suite = "SelectionPermissionSetupTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let viewer = ImageViewerControllerStub()
    viewer.isSelectionActive = isScreenshotActive
    var events: [String] = []
    let controller = AppController(
        settings: TranslationSettings(defaults: defaults),
        selectedTextReader: SetupSelectionReaderMock { events.append("readSelection") },
        requestSelectionPermission: { events.append("permissionDenied"); return false },
        imageViewerController: viewer,
        subscriptionAccess: makeUnrestrictedTestAccess(),
        onLanguageSetupRequired: { events.append("showSettings") }
    )

    // Act
    controller.handleTranslationShortcut()
    let deadline = ContinuousClock.now.advanced(by: .seconds(2))
    while events.isEmpty && ContinuousClock.now < deadline { await Task.yield() }

    // Assert
    #expect(events == (isScreenshotActive ? ["showSettings"] : ["permissionDenied"]))
}
