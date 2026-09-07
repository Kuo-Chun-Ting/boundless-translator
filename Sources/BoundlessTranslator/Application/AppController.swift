import AppKit

@MainActor
final class AppController {
    let settings = TranslationSettings()
    let interfaceLanguageSettings: InterfaceLanguageSettings

    private let coordinator = TranslationCoordinator()
    private lazy var panelController = TranslationPanelController(
        interfaceLanguageSettings: interfaceLanguageSettings,
        engine: translationEngine
    )
    private let translationEngine: TranslationEngine
    private let supportedLanguageCatalog: SupportedLanguageCatalog
    private lazy var shortcutController = GlobalShortcutController { [weak self] in
        self?.handleShortcut()
    }
    private lazy var preferencesWindowController = PreferencesWindowController(
        settings: settings,
        interfaceLanguageSettings: interfaceLanguageSettings,
        shortcutController: shortcutController,
        supportedLanguageCatalog: supportedLanguageCatalog
    )
    private let selectedTextReader: any SelectedTextReading
    private let clipboardImageReader: any ClipboardImageReading
    private let imageViewerController: any ImageViewerControlling
    private let sourceLanguageResolver: SourceLanguageResolver
    private var selectionTask: Task<Void, Never>?

    init(
        translationEngine: TranslationEngine = .apple,
        selectedTextReader: any SelectedTextReading = SelectedTextResolver(
            primaryReader: AccessibilitySelectedTextReader(),
            fallbackReader: ClipboardSelectedTextReader()
        ),
        clipboardImageReader: any ClipboardImageReading = PasteboardClipboardImageReader(),
        imageViewerController: (any ImageViewerControlling)? = nil,
        interfaceLanguageSettings: InterfaceLanguageSettings = InterfaceLanguageSettings(),
        sourceLanguageResolver: SourceLanguageResolver = SourceLanguageResolver(
            minimumConfidence: 0.60,
            languageIdentifier: NaturalLanguageIdentifier()
        )
    ) {
        self.translationEngine = translationEngine
        self.supportedLanguageCatalog = SupportedLanguageCatalog(
            loadLanguages: translationEngine.loadLanguages
        )
        self.interfaceLanguageSettings = interfaceLanguageSettings
        self.clipboardImageReader = clipboardImageReader
        let resolvedImageViewerController = imageViewerController
            ?? ImageViewerWindowController(
                interfaceLanguageSettings: interfaceLanguageSettings
            )
        self.imageViewerController = resolvedImageViewerController
        self.selectedTextReader = SelectedTextResolver(
            primaryReader: ImageViewerSelectionReader(
                provider: resolvedImageViewerController
            ),
            fallbackReader: selectedTextReader
        )
        self.sourceLanguageResolver = sourceLanguageResolver
    }

    func prepare() {
        do {
            try shortcutController.start()
        } catch {
            if let shortcutError = error as? GlobalShortcutError {
                showError(.globalShortcut(shortcutError))
            } else {
                showError(.verbatim(error.localizedDescription))
            }
        }

        Task {
            let supportedLanguages = await supportedLanguageCatalog.load()
            settings.validateSourceLanguage(
                supportedLanguages: supportedLanguages
            )
            settings.validateTargetLanguage(
                supportedLanguages: supportedLanguages
            )
        }
    }

    func showPreferences() {
        preferencesWindowController.present()
    }

    func translate(
        _ selectedText: SelectedText,
        sourceLanguageIdentifier: String,
        sourceLanguageWasDetected: Bool = false
    ) {
        coordinator.submit(
            selectedText,
            sourceLanguageIdentifier: sourceLanguageIdentifier,
            targetLanguageIdentifier: settings.targetLanguageIdentifier,
            sourceLanguageWasDetected: sourceLanguageWasDetected
        )
        panelController.show(
            coordinator: coordinator,
            supportedLanguages: supportedLanguageCatalog.languages,
            pointerLocation: NSEvent.mouseLocation
        )
    }

    func handleShortcut() {
        guard selectionTask == nil else {
            return
        }

        selectionTask = Task {
            defer {
                selectionTask = nil
            }

            switch await resolveShortcutAction() {
            case .translate(let selectedText):
                await resolveSourceLanguage(for: selectedText)
            case .openImage(let image):
                imageViewerController.present(
                    image: image,
                    pointerLocation: NSEvent.mouseLocation
                )
            case .none:
                return
            }
        }
    }

    func resolveShortcutAction() async -> ShortcutAction {
        if let selectedText = try? await selectedTextReader.readSelectedText() {
            return .translate(selectedText)
        }

        if let image = clipboardImageReader.readImage() {
            return .openImage(image)
        }

        return .none
    }

    private func showError(_ message: SelectionErrorMessage) {
        panelController.showError(
            message: message,
            pointerLocation: NSEvent.mouseLocation
        )
    }

    private func resolveSourceLanguage(for selectedText: SelectedText) async {
        let supportedLanguages = await supportedLanguageCatalog.load()
        let resolution = sourceLanguageResolver.resolve(
            text: selectedText.value,
            configuredSource: settings.sourceLanguageIdentifier
        )

        switch resolution {
        case .resolved(let languageIdentifier):
            translate(
                selectedText,
                sourceLanguageIdentifier: languageIdentifier,
                sourceLanguageWasDetected: settings.sourceLanguageIdentifier == nil
            )
        case .needsSelection(let suggestedLanguageIdentifier):
            guard let selection = SourceLanguageSelection.make(
                supportedLanguages: supportedLanguages,
                suggestedLanguageIdentifier: suggestedLanguageIdentifier
            ) else {
                showError(.translationLanguagesUnavailable)
                return
            }

            panelController.showSourceLanguageSelection(
                selectedText: selectedText,
                selection: selection,
                supportedLanguages: supportedLanguages,
                pointerLocation: NSEvent.mouseLocation
            ) { [weak self] languageIdentifier in
                self?.translate(
                    selectedText,
                    sourceLanguageIdentifier: languageIdentifier
                )
            }
        }
    }

}

enum ShortcutAction {
    case translate(SelectedText)
    case openImage(NSImage)
    case none
}
