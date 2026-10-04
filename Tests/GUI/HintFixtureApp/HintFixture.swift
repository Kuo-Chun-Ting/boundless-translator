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
    private let imageView = ImageTextView()
    private lazy var viewer = ImageViewerWindowController(content: imageView, interfaceLanguageSettings: languages)
    private lazy var preferences = PreferencesWindowController(
        settings: TranslationSettings(), interfaceLanguageSettings: languages,
        translationShortcutController: GlobalShortcutController(handler: {}),
        supportedLanguageCatalog: SupportedLanguageCatalog(loadLanguages: { [] }), onShowSubscription: {},
        pointerScreenVisibleFrame: { NSScreen.screens[0].visibleFrame }
    )
    private var observationTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let environment = ProcessInfo.processInfo.environment
            NSApp.appearance = NSAppearance(named: environment["BOUNDLESS_TRANSLATOR_HINT_APPEARANCE"] == "dark" ? .darkAqua : .aqua)
            let datastore = URL(fileURLWithPath: environment["BOUNDLESS_TRANSLATOR_HINT_DATASTORE"]!)
            try Tips.configure([.datastoreLocation(.url(datastore))])
            languages.languageIdentifier = environment["BOUNDLESS_TRANSLATOR_HINT_LANGUAGE"] ?? "en"
            if environment["BOUNDLESS_TRANSLATOR_HINT_KIND"] == "settings" {
                preferences.present()
            } else if environment["BOUNDLESS_TRANSLATOR_HINT_KIND"] == "dictionary" {
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
        let longText = ProcessInfo.processInfo.environment["BOUNDLESS_TRANSLATOR_HINT_LONG_TEXT"] == "1"
        let source = longText
            ? String(repeating: "People live under different economic, social, and physical conditions. Small decisions can create opportunities. ", count: 6)
            : "Hello"
        coordinator.submit(try SelectedText(source), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
        translator.show(coordinator: coordinator, supportedLanguages: [], pointerLocation: presentationPoint)
        if longText, let request = coordinator.request {
            Task { await coordinator.translate(request, using: HintTranslationStub()) }
        }
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
            "recognizedText": imageView.document.text,
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

private struct HintTranslationStub: TranslationRunning {
    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        TranslationOutput(
            translatedText: String(repeating: "人們生活在不同的經濟、社會與身體狀況之下。小小的選擇也能創造機會。", count: 6),
            sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant"
        )
    }
}
