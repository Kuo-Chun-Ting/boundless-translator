import AppKit
import SwiftUI
import TipKit

/// Production screenshot, translation and Settings windows; only translation output is stubbed.
@MainActor
final class ImageTextFixtureDelegate: NSObject, NSApplicationDelegate {
    private lazy var imageView = ImageTextView(analysisProvider: Self.analyzeImage)
    private let languages = InterfaceLanguageSettings(preferredLanguageIdentifiers: { ["en"] })
    private let coordinator = TranslationCoordinator()
    private lazy var viewer = ImageViewerWindowController(
        content: imageView, interfaceLanguageSettings: languages)
    private lazy var translator = TranslationWindowController(
        interfaceLanguageSettings: languages,
        engine: TranslationEngine(
            loadLanguages: { [Locale.Language(identifier: "en"), Locale.Language(identifier: "fr")] },
            makeTaskHost: { request, coordinator in
                AnyView(
                    Color.clear.task {
                        await coordinator.translate(request, using: FixtureTranslationRunner())
                    })
            }
        )
    )
    private lazy var preferences = PreferencesWindowController(
        settings: TranslationSettings(), interfaceLanguageSettings: languages,
        translationShortcutController: GlobalShortcutController(handler: {}),
        supportedLanguageCatalog: SupportedLanguageCatalog(loadLanguages: { [] })
    )
    private var timer: Timer?
    private var reportedWriteError = false
    private var outputDirectory: URL {
        URL(
            fileURLWithPath: ProcessInfo.processInfo.environment[
                "BOUNDLESS_TRANSLATOR_IMAGE_TEXT_FIXTURE_OUTPUT"]!)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try FileManager.default.createDirectory(
                at: outputDirectory, withIntermediateDirectories: true)
            try Tips.configure([.datastoreLocation(.url(outputDirectory.appendingPathComponent("tips")))])
            configureMenu()
            languages.languageIdentifier = "en"
            let filename = ProcessInfo.processInfo.environment["IMAGE_TEXT_FIXTURE"] ?? "basic-text.png"
            let image = NSImage(
                contentsOf: Bundle.main.url(
                    forResource: filename, withExtension: nil, subdirectory: "ImageText")!)!
            viewer.present(image: image, pointerLocation: NSEvent.mouseLocation)
            viewer.window?.setAccessibilityIdentifier("imageText.screenshot")
            // A taller window leaves actual workspace margins above and below the image.
            viewer.window?.setContentSize(NSSize(width: 900, height: 680))
            viewer.window?.center()
            let timer = Timer(timeInterval: 0.03, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.publishState() }
            }
            self.timer = timer
            RunLoop.main.add(timer, forMode: .common)
        } catch {
            NSLog("Image text fixture failed: %@", String(describing: error))
            NSApp.terminate(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
    {
        showSettings()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        try? FileManager.default.removeItem(at: outputDirectory)
    }

    private static func analyzeImage(_ image: NSImage) async throws -> ImageTextDocument? {
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let size = image.size
        let result = try await Task.detached {
            try ImageTextRecognizer.recognize(cgImage, size: size)
        }.value
        // Test the delivery of a real OCR result while another app is active.
        if ProcessInfo.processInfo.environment["IMAGE_TEXT_HOLD_UNTIL_INACTIVE"] == "1" {
            while NSApp.isActive { try await Task.sleep(nanoseconds: 20_000_000) }
        }
        return result
    }

    private func configureMenu() {
        let menu = NSMenu()
        let item = NSMenuItem()
        let actions = NSMenu()
        for (title, selector, key) in [
            ("Translate", #selector(showTranslation), "\r"),
            ("Settings", #selector(showSettings), ","),
            ("Close", #selector(NSWindow.performClose(_:)), "w"),
            ("Quit", #selector(NSApplication.terminate(_:)), "q"),
        ] {
            actions.addItem(withTitle: title, action: selector, keyEquivalent: key)
        }
        item.submenu = actions
        menu.addItem(item)
        NSApp.mainMenu = menu
    }

    @objc private func showSettings() { preferences.present() }

    @objc private func showTranslation() {
        Task { @MainActor in
            do {
                let selection = try await ImageViewerSelectionReader(provider: viewer).readSelectedText()
                coordinator.submit(
                    selection, sourceLanguageIdentifier: "en", targetLanguageIdentifier: "fr")
                translator.show(
                    coordinator: coordinator,
                    supportedLanguages: [
                        Locale.Language(identifier: "en"), Locale.Language(identifier: "fr"),
                    ],
                    pointerLocation: NSEvent.mouseLocation)
                translationWindow?.setAccessibilityIdentifier("imageText.translation")
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

    private var keyWindowName: String {
        guard let keyWindow = NSApp.keyWindow else { return "none" }
        if keyWindow === viewer.window { return "screenshot" }
        if keyWindow === translationWindow { return "translation" }
        if keyWindow === preferences.window { return "settings" }
        return "other"
    }

    private func screenPoint(_ point: CGPoint) -> [Double] {
        let rect = imageView.viewRect(for: CGRect(origin: point, size: .zero))
        let screen = viewer.window!.convertPoint(toScreen: imageView.convert(rect.origin, to: nil))
        return [screen.x, NSScreen.screens[0].frame.maxY - screen.y]
    }

    private func publishState() {
        let frame = viewer.window!.convertToScreen(imageView.convert(imageView.imageRect, to: nil))
        let state: [String: Any] = [
            "token": ProcessInfo.processInfo.environment["IMAGE_TEXT_TOKEN"] ?? "",
            "active": NSApp.isActive,
            "keyWindow": keyWindowName,
            "selectionResponder": viewer.window?.firstResponder === imageView,
            "selectionActive": imageView.isSelectionEmphasized,
            "selected": imageView.selectedText,
            "translationSource": coordinator.request?.text ?? "",
            "translationVisible": translationWindow != nil,
            "ocrPending": imageView.accessibilityIdentifier() == "imageWorkspace.loading",
            "recognizedText": imageView.document.text,
            "imageFrame": [
                frame.minX, NSScreen.screens[0].frame.maxY - frame.maxY, frame.width, frame.height,
            ],
            "blank": screenPoint(CGPoint(x: 35, y: 220)),
            "margin": screenPoint(CGPoint(x: 35, y: -35)),
            "words": imageView.document.words.map { word in
                [
                    "text": imageView.document.text(in: word.range),
                    "start": screenPoint(CGPoint(x: word.bounds.minX + 1, y: word.bounds.midY)),
                    "end": screenPoint(CGPoint(x: word.bounds.maxX - 1, y: word.bounds.midY)),
                    "center": screenPoint(CGPoint(x: word.bounds.midX, y: word.bounds.midY)),
                    "lineText": imageView.document.text.components(separatedBy: "\n")[word.line],
                ] as [String: Any]
            },
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: state)
            try data.write(to: outputDirectory.appendingPathComponent("state.json"), options: .atomic)
        } catch {
            if !reportedWriteError {
                NSLog("Cannot publish image selection test state: %@", String(describing: error))
                reportedWriteError = true
            }
        }
    }
}

private struct FixtureTranslationRunner: TranslationRunning {
    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        TranslationOutput(
            translatedText: "Texte traduit", sourceLanguageIdentifier: "en",
            targetLanguageIdentifier: "fr")
    }
}
