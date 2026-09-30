import AppKit
import SwiftUI
import TipKit

@MainActor
final class HintFixtureDelegate: NSObject, NSApplicationDelegate {
    private let languages = InterfaceLanguageSettings(preferredLanguageIdentifiers: { ["en"] })
    private let coordinator = TranslationCoordinator()
    private lazy var translator = TranslationWindowController(
        interfaceLanguageSettings: languages,
        engine: TranslationEngine(loadLanguages: { [] }, makeTaskHost: { _, _ in AnyView(EmptyView()) })
    )
    private let imageView = LiveTextImageView()
    private lazy var viewer = ImageViewerWindowController(content: imageView, interfaceLanguageSettings: languages)
    private var observationTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let environment = ProcessInfo.processInfo.environment
            NSApp.appearance = NSAppearance(named: environment["BOUNDLESS_TRANSLATOR_HINT_APPEARANCE"] == "dark" ? .darkAqua : .aqua)
            let datastore = URL(fileURLWithPath: environment["BOUNDLESS_TRANSLATOR_HINT_DATASTORE"]!)
            try Tips.configure([.datastoreLocation(.url(datastore))])
            languages.languageIdentifier = "en"
            if environment["BOUNDLESS_TRANSLATOR_HINT_KIND"] == "dictionary" {
                try presentTranslation()
            } else {
                presentScreenshot()
            }
        } catch {
            NSLog("Hint fixture failed: %@", String(describing: error))
            NSApp.terminate(nil)
        }
    }

    private func presentTranslation() throws {
        coordinator.submit(try SelectedText("Hello"), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
        translator.show(coordinator: coordinator, supportedLanguages: [], pointerLocation: presentationPoint)
    }

    private func presentScreenshot() {
        viewer.translationShortcutName = { "⌥T" }
        viewer.present(image: makeImage(), pointerLocation: presentationPoint)
        startObservingScreenshot()
    }

    private func startObservingScreenshot() {
        guard let path = ProcessInfo.processInfo.environment["BOUNDLESS_HINT_OBSERVATIONS"] else { return }
        let timer = Timer(timeInterval: 0.02, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.publishScreenshotState(to: URL(fileURLWithPath: path)) }
        }
        observationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func publishScreenshotState(to url: URL) {
        guard let window = viewer.window else { return }
        let screenRect = window.convertToScreen(imageView.convert(imageView.bounds, to: nil))
        let state: [String: Any] = [
            "cursor": NSCursor.current === NSCursor.iBeam ? "ibeam"
                : NSCursor.current === NSCursor.arrow ? "arrow" : "other",
            "recognizedText": imageView.overlayView.text,
            "selectedText": imageView.selectedText,
            "imageFrame": [screenRect.minX, NSScreen.screens[0].frame.maxY - screenRect.maxY,
                           screenRect.width, screenRect.height],
            "textStart": screenPoint(NSPoint(x: 48, y: 150), window: window),
            "textEnd": screenPoint(NSPoint(x: 186, y: 150), window: window)
        ]
        if let data = try? JSONSerialization.data(withJSONObject: state) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func screenPoint(_ point: NSPoint, window: NSWindow) -> [Double] {
        let scale = min(imageView.bounds.width / 760, imageView.bounds.height / 420)
        let local = NSPoint(
            x: (imageView.bounds.width - 760 * scale) / 2 + point.x * scale,
            y: (imageView.bounds.height - 420 * scale) / 2 + point.y * scale
        )
        let screen = window.convertPoint(toScreen: imageView.convert(local, to: nil))
        return [screen.x, NSScreen.screens[0].frame.maxY - screen.y]
    }

    private var presentationPoint: CGPoint {
        let screen = NSScreen.screens[0].visibleFrame
        return CGPoint(x: screen.midX, y: screen.midY)
    }

    private func makeImage() -> NSImage {
        let size = NSSize(width: 760, height: 420)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.textBackgroundColor.setFill()
        NSRect(origin: .zero, size: size).fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 40, weight: .regular),
            .foregroundColor: NSColor.labelColor
        ]
        ("COVERED WORDS" as NSString).draw(at: NSPoint(x: 32, y: 340), withAttributes: attributes)
        ("TARGET" as NSString).draw(at: NSPoint(x: 40, y: 130), withAttributes: attributes)
        image.unlockFocus()
        return image
    }
}
