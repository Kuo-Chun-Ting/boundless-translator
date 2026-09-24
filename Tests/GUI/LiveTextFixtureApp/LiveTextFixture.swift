import AppKit
import SwiftUI

/// Uses the production windows and Live Text view. Only translation output is canned.
@MainActor
final class LiveTextFixtureDelegate: NSObject, NSApplicationDelegate {
    private let imageView = LiveTextImageView()
    private let languages = InterfaceLanguageSettings(preferredLanguageIdentifiers: { ["en"] })
    private let coordinator = TranslationCoordinator()
    private lazy var viewer = ImageViewerWindowController(
        content: imageView, interfaceLanguageSettings: languages
    )
    private lazy var translator = TranslationWindowController(
        interfaceLanguageSettings: languages,
        engine: TranslationEngine(
            loadLanguages: { [Locale.Language(identifier: "en"), Locale.Language(identifier: "fr")] },
            makeTaskHost: { request, coordinator in
                AnyView(Color.clear.task {
                    await coordinator.translate(request, using: FixtureTranslationRunner())
                })
            }
        )
    )
    private var timer: Timer?
    private var eventMonitor: Any?
    private var lastMouseEvent: Int64 = 0
    private var reportedWriteError = false
    private let imageSize = NSSize(width: 760, height: 360)

    private var outputDirectory: URL {
        URL(fileURLWithPath: ProcessInfo.processInfo.environment[
            "BOUNDLESS_TRANSLATOR_LIVE_TEXT_FIXTURE_OUTPUT"
        ]!)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        } catch {
            NSLog("Cannot create Live Text test output directory: %@", String(describing: error))
            NSApp.terminate(nil)
            return
        }
        languages.languageIdentifier = "en"
        viewer.present(image: makeImage(), pointerLocation: NSEvent.mouseLocation)
        viewer.window?.setAccessibilityIdentifier("liveText.screenshot")
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDown, .leftMouseDragged, .leftMouseUp, .keyDown]
        ) { [weak self] event in
            if event.type == .keyDown,
               event.charactersIgnoringModifiers?.lowercased() == "t",
               event.modifierFlags.intersection([.command, .shift, .option, .control]) == [.command, .shift] {
                self?.showTranslation()
                return nil
            }
            self?.lastMouseEvent = event.cgEvent?.getIntegerValueField(.eventSourceUserData) ?? 0
            return event
        }
        timer = Timer(timeInterval: 0.02, repeats: true) { _ in
            MainActor.assumeIsolated {
                self.publishState()
            }
        }
        // Keep observing while AppKit is tracking a held mouse button.
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    func applicationWillTerminate(_ notification: Notification) {
        try? FileManager.default.removeItem(at: outputDirectory)
    }

    private func makeImage() -> NSImage {
        let image = NSImage(size: imageSize)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: imageSize).fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 48, weight: .regular),
            .foregroundColor: NSColor.black,
        ]
        ("ORIGINAL" as NSString).draw(at: NSPoint(x: 180, y: 240), withAttributes: attributes)
        ("TARGET" as NSString).draw(at: NSPoint(x: 180, y: 100), withAttributes: attributes)
        image.unlockFocus()
        return image
    }

    private func showTranslation() {
        Task { @MainActor in
            do {
                let selection = try await ImageViewerSelectionReader(provider: viewer).readSelectedText()
                coordinator.submit(selection, sourceLanguageIdentifier: "en", targetLanguageIdentifier: "fr")
                translator.show(
                    coordinator: coordinator,
                    supportedLanguages: [Locale.Language(identifier: "en"), Locale.Language(identifier: "fr")],
                    pointerLocation: NSEvent.mouseLocation
                )
                translationWindow?.setAccessibilityIdentifier("liveText.translation")
            } catch {
                try? String(describing: error).write(
                    to: outputDirectory.appendingPathComponent("error.txt"), atomically: true, encoding: .utf8
                )
            }
        }
    }

    private var translationWindow: NSWindow? {
        NSApp.windows.first { $0 is TranslationWindow && $0.isVisible }
    }

    /// Convert a point in the fixture image to the screen coordinates used by CGEvent.
    private func screenPoint(_ point: CGPoint) -> CGPoint {
        let bounds = imageView.imageView.bounds
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let local = CGPoint(
            x: (bounds.width - imageSize.width * scale) / 2 + point.x * scale,
            y: (bounds.height - imageSize.height * scale) / 2 + point.y * scale
        )
        let windowPoint = imageView.imageView.convert(local, to: nil)
        let screen = viewer.window!.convertPoint(toScreen: windowPoint)
        return CGPoint(x: screen.x, y: NSScreen.screens[0].frame.maxY - screen.y)
    }

    private func publishState() {
        let cursor: String = NSCursor.current === NSCursor.iBeam ? "ibeam"
            : NSCursor.current === NSCursor.arrow ? "arrow" : "other"
        let state = LiveTextFixtureState(
            sampleTime: Date().timeIntervalSince1970,
            recognizedText: imageView.overlayView.text,
            selectedText: imageView.selectedText,
            cursor: cursor,
            lastMouseEvent: lastMouseEvent,
            translationVisible: translationWindow != nil,
            appActive: NSApp.isActive,
            blank: screenPoint(CGPoint(x: 80, y: 127)),
            textStart: screenPoint(CGPoint(x: 190, y: 127)),
            textEnd: screenPoint(CGPoint(x: 346, y: 127)),
            original: screenPoint(CGPoint(x: 270, y: 267))
        )
        if let data = try? JSONEncoder().encode(state) {
            do {
                try data.write(to: outputDirectory.appendingPathComponent("state.json"), options: .atomic)
            } catch {
                if !reportedWriteError {
                    print("Live Text fixture cannot publish state at \(outputDirectory.path): \(error)")
                    reportedWriteError = true
                }
            }
        }
    }
}

private struct FixtureTranslationRunner: TranslationRunning {
    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        TranslationOutput(translatedText: "Texte traduit", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "fr")
    }
}

private struct LiveTextFixtureState: Encodable {
    let sampleTime: TimeInterval
    let recognizedText: String
    let selectedText: String
    let cursor: String
    let lastMouseEvent: Int64
    let translationVisible: Bool
    let appActive: Bool
    let blank: CGPoint
    let textStart: CGPoint
    let textEnd: CGPoint
    let original: CGPoint
}

// The fixture has its own entry point, so it does not compile BoundlessTranslatorApp.swift.
// These auxiliary views only need the app's display name.
enum AppBrand {
    nonisolated static let displayName = "Boundless Translator"
    @MainActor static var iconImage: NSImage { NSApplication.shared.applicationIconImage }
}
