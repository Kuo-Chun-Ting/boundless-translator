import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_captureRegion_when_permission_denied_then_does_not_start_capture() async {
    // Arrange
    var invoked = false
    let capture = SystemScreenshotCapture(requestPermission: { false }, runCapture: { _ in
        invoked = true
        return 0
    })

    // Act & Assert
    await #expect(throws: ScreenshotCaptureError.permissionRequired) {
        try await capture.captureRegion()
    }
    #expect(!invoked)
}

@Test @MainActor
func test_captureRegion_when_capture_completes_then_loads_image_and_removes_temporary_file() async throws {
    // Arrange
    var outputURL: URL?
    let bitmap = try #require(NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: 10, pixelsHigh: 20, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ))
    let png = try #require(bitmap.representation(using: .png, properties: [:]))
    let capture = SystemScreenshotCapture(requestPermission: { true }, runCapture: { url in
        outputURL = url
        try png.write(to: url)
        return 0
    })

    // Act
    let image = try await capture.captureRegion()

    // Assert
    #expect(image?.size == NSSize(width: 10, height: 20))
    #expect(image?.tiffRepresentation != nil)
    let directory = try #require(outputURL).deletingLastPathComponent()
    #expect(!FileManager.default.fileExists(atPath: directory.path))
}

@Test @MainActor
func test_captureRegion_when_user_cancels_then_returns_nil_and_removes_temporary_directory() async throws {
    // Arrange
    var outputURL: URL?
    let capture = SystemScreenshotCapture(requestPermission: { true }, runCapture: { url in
        outputURL = url
        return 1
    })

    // Act
    let image = try await capture.captureRegion()

    // Assert
    #expect(image == nil)
    let directory = try #require(outputURL).deletingLastPathComponent()
    #expect(!FileManager.default.fileExists(atPath: directory.path))
}

@Test(arguments: [Int32(0), Int32(2)]) @MainActor
func test_captureRegion_when_output_is_missing_or_command_fails_then_reports_failure(status: Int32) async {
    // Arrange
    let capture = SystemScreenshotCapture(requestPermission: { true }, runCapture: { _ in status })

    // Act & Assert
    await #expect(throws: ScreenshotCaptureError.captureFailed) {
        try await capture.captureRegion()
    }
}

@Test @MainActor
func test_captureRegion_when_output_is_invalid_then_reports_failure_and_cleans_up() async throws {
    // Arrange
    var outputURL: URL?
    let capture = SystemScreenshotCapture(requestPermission: { true }, runCapture: { url in
        outputURL = url
        try Data("Not an image".utf8).write(to: url)
        return 0
    })

    // Act & Assert
    await #expect(throws: ScreenshotCaptureError.captureFailed) {
        try await capture.captureRegion()
    }
    let directory = try #require(outputURL).deletingLastPathComponent()
    #expect(!FileManager.default.fileExists(atPath: directory.path))
}
