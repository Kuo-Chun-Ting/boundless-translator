import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_captureScreenshot_when_region_is_captured_then_presents_image() async throws {
    // Arrange
    let image = NSImage(size: NSSize(width: 100, height: 50))
    let mock_viewer = ScreenshotViewerMock()
    let fixture_defaults = UserDefaults(suiteName: UUID().uuidString)!
    let settings = TranslationSettings(defaults: fixture_defaults)
    settings.sourceLanguageIdentifier = "en"
    settings.targetLanguageIdentifier = "ja"
    defer { fixture_defaults.removeObject(forKey: "sourceLanguageIdentifier"); fixture_defaults.removeObject(forKey: "targetLanguageIdentifier") }
    let controller = AppController(
        settings: settings,
        screenshotCapture: ScreenshotCaptureStub(result: .success(image)),
        imageViewerController: mock_viewer,
        subscriptionAccess: makeUnrestrictedTestAccess()
    )

    // Act
    try await controller.captureScreenshot()

    // Assert
    #expect(mock_viewer.images.count == 1)
    #expect(mock_viewer.images.first === image)
}

@Test @MainActor
func test_handleScreenshotShortcut_when_triggered_then_captures_without_reading_selection() async throws {
    // Arrange
    let image = NSImage(size: NSSize(width: 100, height: 50))
    let mock_reader = ScreenshotSelectedTextReaderMock()
    let mock_viewer = ScreenshotViewerMock()
    let fixture_defaults = UserDefaults(suiteName: UUID().uuidString)!
    let settings = TranslationSettings(defaults: fixture_defaults)
    settings.sourceLanguageIdentifier = "en"
    settings.targetLanguageIdentifier = "ja"
    defer { fixture_defaults.removeObject(forKey: "sourceLanguageIdentifier"); fixture_defaults.removeObject(forKey: "targetLanguageIdentifier") }
    let controller = AppController(
        settings: settings,
        selectedTextReader: mock_reader,
        screenshotCapture: ScreenshotCaptureStub(result: .success(image)),
        imageViewerController: mock_viewer,
        subscriptionAccess: makeUnrestrictedTestAccess()
    )

    // Act
    controller.handleScreenshotShortcut()
    for _ in 0..<10 {
        await Task.yield()
    }

    // Assert
    #expect(mock_reader.invocationCount == 0)
    #expect(mock_viewer.images.count == 1)
}

@Test @MainActor
func test_captureScreenshot_when_cancelled_then_preserves_existing_image() async throws {
    // Arrange
    let mock_viewer = ScreenshotViewerMock()
    let fixture_defaults = UserDefaults(suiteName: UUID().uuidString)!
    let settings = TranslationSettings(defaults: fixture_defaults)
    settings.sourceLanguageIdentifier = "en"
    settings.targetLanguageIdentifier = "ja"
    defer { fixture_defaults.removeObject(forKey: "sourceLanguageIdentifier"); fixture_defaults.removeObject(forKey: "targetLanguageIdentifier") }
    let controller = AppController(
        settings: settings,
        screenshotCapture: ScreenshotCaptureStub(result: .success(nil)),
        imageViewerController: mock_viewer,
        subscriptionAccess: makeUnrestrictedTestAccess()
    )

    // Act
    try await controller.captureScreenshot()

    // Assert
    #expect(mock_viewer.images.isEmpty)
}

@Test @MainActor
func test_captureScreenshot_when_permission_is_denied_then_reports_error_without_opening_image() async {
    // Arrange
    let mock_viewer = ScreenshotViewerMock()
    let fixture_defaults = UserDefaults(suiteName: UUID().uuidString)!
    let settings = TranslationSettings(defaults: fixture_defaults)
    settings.sourceLanguageIdentifier = "en"
    settings.targetLanguageIdentifier = "ja"
    defer { fixture_defaults.removeObject(forKey: "sourceLanguageIdentifier"); fixture_defaults.removeObject(forKey: "targetLanguageIdentifier") }
    let controller = AppController(
        settings: settings,
        screenshotCapture: ScreenshotCaptureStub(result: .failure(ScreenshotCaptureError.permissionRequired)),
        imageViewerController: mock_viewer,
        subscriptionAccess: makeUnrestrictedTestAccess()
    )

    // Act & Assert
    await #expect(throws: ScreenshotCaptureError.permissionRequired) {
        try await controller.captureScreenshot()
    }
    #expect(mock_viewer.images.isEmpty)
}

@Test @MainActor
func test_captureScreenshot_when_already_capturing_then_ignores_duplicate_and_allows_next_capture() async throws {
    // Arrange
    let stub_capture = SuspendedScreenshotCapture()
    let mock_viewer = ScreenshotViewerMock()
    let fixture_defaults = UserDefaults(suiteName: UUID().uuidString)!
    let settings = TranslationSettings(defaults: fixture_defaults)
    settings.sourceLanguageIdentifier = "en"
    settings.targetLanguageIdentifier = "ja"
    defer { fixture_defaults.removeObject(forKey: "sourceLanguageIdentifier"); fixture_defaults.removeObject(forKey: "targetLanguageIdentifier") }
    let controller = AppController(
        settings: settings,
        screenshotCapture: stub_capture,
        imageViewerController: mock_viewer,
        subscriptionAccess: makeUnrestrictedTestAccess()
    )
    let first = Task { try await controller.captureScreenshot() }
    await stub_capture.waitUntilStarted()

    // Act
    try await controller.captureScreenshot()
    stub_capture.finish()
    try await first.value
    let next = Task { try await controller.captureScreenshot() }
    await stub_capture.waitUntilStarted()
    stub_capture.finish()
    try await next.value

    // Assert
    #expect(stub_capture.callCount == 2)
    #expect(mock_viewer.images.isEmpty)
}

@MainActor
private struct ScreenshotCaptureStub: ScreenshotCapturing {
    let result: Result<NSImage?, Error>
    func ensurePermission() throws {}

    func captureRegion() async throws -> NSImage? { try result.get() }
}

@MainActor
private final class ScreenshotSelectedTextReaderMock: SelectedTextReading {
    private(set) var invocationCount = 0

    func readSelectedText() async throws -> SelectedText {
        invocationCount += 1
        return try SelectedText("Selected text")
    }
}

@MainActor
private final class ScreenshotViewerMock: ImageViewerControlling {
    var isSelectionActive = false
    var selectedText = ""
    var images: [NSImage] = []
    func present(image: NSImage, pointerLocation: CGPoint) { images.append(image) }
}

@MainActor
private final class SuspendedScreenshotCapture: ScreenshotCapturing {
    var callCount = 0
    private var completion: CheckedContinuation<NSImage?, Never>?
    private var started: CheckedContinuation<Void, Never>?

    func ensurePermission() throws {}

    func captureRegion() async throws -> NSImage? {
        callCount += 1
        return await withCheckedContinuation { continuation in
            completion = continuation
            started?.resume()
            started = nil
        }
    }

    func waitUntilStarted() async {
        if completion != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func finish() {
        completion?.resume(returning: nil)
        completion = nil
    }
}

@Test @MainActor
func test_captureScreenshot_when_languages_are_missing_then_checks_permission_before_opening_setup() async throws {
    // Arrange
    let suite = "ScreenshotSetupTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let settings = TranslationSettings(defaults: defaults)
    var events: [String] = []
    let mock_capture = SetupScreenshotCaptureMock { events.append($0) }
    let mock_viewer = ScreenshotViewerMock()
    let controller = AppController(
        settings: settings, screenshotCapture: mock_capture, imageViewerController: mock_viewer,
        subscriptionAccess: makeUnrestrictedTestAccess(),
        onLanguageSetupRequired: { events.append("showSettings") }
    )

    // Act
    try await controller.captureScreenshot()

    // Assert
    #expect(events == ["permission", "showSettings"])
    #expect(mock_viewer.images.isEmpty)

    // Completing setup does not resume an old request; the next invocation can capture.
    settings.sourceLanguageIdentifier = "en"
    settings.targetLanguageIdentifier = "ja"
    #expect(mock_viewer.images.isEmpty)
    try await controller.captureScreenshot()
    #expect(events == ["permission", "showSettings", "permission", "capture"])
    #expect(mock_viewer.images.count == 1)
}

@Test @MainActor
func test_captureScreenshot_when_permission_is_missing_then_does_not_open_language_setup() async {
    // Arrange
    let suite = "ScreenshotPermissionSetupTests.\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    var events: [String] = []
    let mock_capture = SetupScreenshotCaptureMock(permissionGranted: false) { events.append($0) }
    let controller = AppController(
        settings: TranslationSettings(defaults: defaults), screenshotCapture: mock_capture,
        imageViewerController: ScreenshotViewerMock(), subscriptionAccess: makeUnrestrictedTestAccess(),
        onLanguageSetupRequired: { events.append("showSettings") }
    )

    // Act & Assert
    await #expect(throws: ScreenshotCaptureError.permissionRequired) {
        try await controller.captureScreenshot()
    }
    #expect(events == ["permission"])
}

@MainActor
private struct SetupScreenshotCaptureMock: ScreenshotCapturing {
    var permissionGranted = true
    let record: (String) -> Void
    func ensurePermission() throws {
        record("permission")
        if !permissionGranted { throw ScreenshotCaptureError.permissionRequired }
    }
    func captureRegion() async throws -> NSImage? {
        record("capture")
        return NSImage(size: NSSize(width: 100, height: 50))
    }
}
