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
    private lazy var imageAccessibility = ImageTextAccessibility(imageView: imageView)

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let datastore = FileManager.default.temporaryDirectory.appendingPathComponent(
                "image-text-tips-" + ProcessInfo.processInfo.environment["IMAGE_TEXT_SESSION"]!)
            try Tips.configure([.datastoreLocation(.url(datastore))])
            configureMenu()
            languages.languageIdentifier = "en"
            let image = NSImage(
                contentsOf: Bundle.main.url(
                    forResource: "basic-text.png", withExtension: nil, subdirectory: "ImageText")!)!
            imageView.setAccessibilityChildren([imageAccessibility])
            viewer.present(image: image, pointerLocation: NSEvent.mouseLocation)
            viewer.window?.setAccessibilityIdentifier("imageText.screenshot")
            // A taller window leaves actual workspace margins above and below the image.
            viewer.window?.setContentSize(NSSize(width: 900, height: 680))
            let window = viewer.window!
            let screen = NSScreen.screens[0].visibleFrame
            window.setFrameOrigin(NSPoint(
                x: screen.midX - window.frame.width / 2,
                y: screen.midY - window.frame.height / 2))
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

    private static func analyzeImage(_ image: NSImage) async throws -> ImageTextDocument? {
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let size = image.size
        let result = try await Task.detached {
            try ImageTextRecognizer.recognize(cgImage, size: size)
        }.value
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

    @objc private func showSettings() {
        preferences.present()
        preferences.window?.setAccessibilityIdentifier("imageText.settings")
    }

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
                NSLog("Image text fixture translation failed: %@", String(describing: error))
            }
        }
    }

    private var translationWindow: NSWindow? {
        NSApp.windows.first { $0 is TranslationWindow && $0.isVisible }
    }

}

// Test-only accessibility for drawn OCR text. These views expose values and bounds, without handling events.
@MainActor
final class ImageTextAccessibility: NSView {
    private unowned let imageView: ImageTextView
    private var cachedText: String?
    private var wordElements: [NSView] = []
    private lazy var selectionElement = ImageTextValueElement(
        role: .textArea, identifier: "imageText.selection", parent: self,
        value: { [unowned self] in imageView.selectedText },
        frame: { [unowned self] in accessibilityFrame() })

    init(imageView: ImageTextView) {
        self.imageView = imageView
        super.init(frame: .zero)
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityIdentifier("imageText.content")
        setAccessibilityParent(imageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func accessibilityFrame() -> NSRect {
        imageView.window?.convertToScreen(imageView.convert(imageView.imageRect, to: nil)) ?? .zero
    }

    override func accessibilityChildren() -> [Any]? {
        updateChildren()
        return super.accessibilityChildren()
    }

    private func updateChildren() {
        if cachedText != imageView.document.text {
            cachedText = imageView.document.text
            wordElements = imageView.document.words.map { word in
                let text = imageView.document.text(in: word.range)
                let element = ImageTextValueElement(
                    role: .staticText,
                    identifier: "imageText.word.\(word.line).\(word.range.location)", parent: self,
                    value: { text },
                    frame: { [unowned self] in
                        imageView.window?.convertToScreen(
                            imageView.convert(imageView.viewRect(for: word.bounds), to: nil)) ?? .zero
                    })
                element.setAccessibilityLabel(text)
                return element
            }
        }
        setAccessibilityChildren([selectionElement] + wordElements)
    }
}

@MainActor
private final class ImageTextValueElement: NSView {
    private let readValue: () -> String
    private let readFrame: () -> NSRect

    init(role: NSAccessibility.Role, identifier: String, parent: Any,
         value: @escaping () -> String, frame: @escaping () -> NSRect) {
        readValue = value
        readFrame = frame
        super.init(frame: .zero)
        setAccessibilityElement(true)
        setAccessibilityRole(role)
        setAccessibilityIdentifier(identifier)
        setAccessibilityParent(parent)
    }

    override func accessibilityValue() -> Any? {
        readValue()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func accessibilityFrame() -> NSRect {
        readFrame()
    }
}

private struct FixtureTranslationRunner: TranslationRunning {
    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        TranslationOutput(
            translatedText: "Texte traduit", sourceLanguageIdentifier: "en",
            targetLanguageIdentifier: "fr")
    }
}
