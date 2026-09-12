import AppKit

@MainActor
protocol ScreenshotCapturing {
    func captureRegion() async throws -> NSImage?
}

enum ScreenshotCaptureError: Error, Equatable {
    case permissionRequired
    case captureFailed

    func message(localization: AppLocalization) -> String {
        localization.string(self == .permissionRequired ? "screenshot.permissionRequired" : "screenshot.failed")
    }
}

@MainActor
struct SystemScreenshotCapture: ScreenshotCapturing {
    let requestPermission: @MainActor () -> Bool
    let runCapture: @MainActor (URL) async throws -> Int32

    init(
        requestPermission: @escaping @MainActor () -> Bool = {
            ScreenRecordingPermission.requestIfNeeded()
        },
        runCapture: @escaping @MainActor (URL) async throws -> Int32 = Self.runSystemCapture
    ) {
        self.requestPermission = requestPermission
        self.runCapture = runCapture
    }

    func captureRegion() async throws -> NSImage? {
        guard requestPermission() else { throw ScreenshotCaptureError.permissionRequired }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoundlessScreenshot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("capture.png")
        let status = try await runCapture(output)
        if (status == 0 || status == 1) && !FileManager.default.fileExists(atPath: output.path) {
            return nil
        }
        guard status == 0, let image = NSImage(contentsOf: output) else {
            throw ScreenshotCaptureError.captureFailed
        }
        return image
    }

    private static func runSystemCapture(output: URL) async throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-s", "-x", "-t", "png", output.path]
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                continuation.resume(returning: process.terminationStatus)
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
