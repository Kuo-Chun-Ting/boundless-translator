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
    private lazy var viewer = ImageViewerWindowController(interfaceLanguageSettings: languages)

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
        let text = "A little curiosity goes a long way.\n\nSelect text from a screenshot to explore new ideas.\n\nSmall discoveries can become something new."
        (text as NSString).draw(
            in: NSRect(x: 32, y: 60, width: 696, height: 320),
            withAttributes: [.font: NSFont.systemFont(ofSize: 26), .foregroundColor: NSColor.labelColor]
        )
        image.unlockFocus()
        return image
    }
}
