import AppKit

@MainActor
final class AppController {
    let settings = TranslationSettings()

    private let coordinator = TranslationCoordinator()
    private let panelController = TranslationPanelController()
    private let supportedLanguageCatalog = SupportedLanguageCatalog()
    private lazy var shortcutController = GlobalShortcutController { [weak self] in
        self?.translateCurrentSelection()
    }
    private lazy var preferencesWindowController = PreferencesWindowController(
        settings: settings,
        shortcutController: shortcutController,
        supportedLanguageCatalog: supportedLanguageCatalog
    )
    private let selectedTextReader: any SelectedTextReading
    private let sourceLanguageResolver: SourceLanguageResolver
    private var selectionTask: Task<Void, Never>?

    init(
        selectedTextReader: any SelectedTextReading = SelectedTextResolver(
            primaryReader: AccessibilitySelectedTextReader(),
            fallbackReader: ClipboardSelectedTextReader()
        ),
        sourceLanguageResolver: SourceLanguageResolver = SourceLanguageResolver(
            minimumConfidence: 0.60,
            languageIdentifier: NaturalLanguageIdentifier()
        )
    ) {
        self.selectedTextReader = selectedTextReader
        self.sourceLanguageResolver = sourceLanguageResolver
    }

    func prepare() {
        do {
            try shortcutController.start()
        } catch {
            showError(error.localizedDescription)
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

    func translateCurrentSelection() {
        guard selectionTask == nil else {
            return
        }

        selectionTask = Task {
            defer {
                selectionTask = nil
            }
            do {
                let selectedText = try await selectedTextReader.readSelectedText()
                await resolveSourceLanguage(for: selectedText)
            } catch {
                panelController.showError(
                    message: error.localizedDescription,
                    pointerLocation: NSEvent.mouseLocation
                )
            }
        }
    }

    func showError(_ message: String) {
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
                showError(
                    "No translation languages are available. Check your macOS language settings and try again."
                )
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
