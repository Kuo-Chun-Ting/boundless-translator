import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_captureScreenshot_when_region_is_captured_then_presents_image() async throws {
    // Arrange
    let image = NSImage(size: NSSize(width: 100, height: 50))
    let mock_viewer = ScreenshotViewerMock()
    let controller = AppController(
        screenshotCapture: ScreenshotCaptureStub(result: .success(image)),
        imageViewerController: mock_viewer
    )

    // Act
    try await controller.captureScreenshot()

    // Assert
    #expect(mock_viewer.images.count == 1)
    #expect(mock_viewer.images.first === image)
}

@Test @MainActor
func test_captureScreenshot_when_cancelled_then_preserves_existing_image() async throws {
    // Arrange
    let mock_viewer = ScreenshotViewerMock()
    let controller = AppController(
        screenshotCapture: ScreenshotCaptureStub(result: .success(nil)),
        imageViewerController: mock_viewer
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
    let controller = AppController(
        screenshotCapture: ScreenshotCaptureStub(result: .failure(ScreenshotCaptureError.permissionRequired)),
        imageViewerController: mock_viewer
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
    let controller = AppController(screenshotCapture: stub_capture, imageViewerController: mock_viewer)
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
    func captureRegion() async throws -> NSImage? { try result.get() }
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
