import AppKit

@MainActor
final class AppController {
    let settings = TranslationSettings()
    let interfaceLanguageSettings: InterfaceLanguageSettings

    let subscriptionAccess: SubscriptionAccessController
    private let onSubscriptionRequired: (@MainActor () -> Void)?
    private lazy var subscriptionWindowController = SubscriptionWindowController(
        access: subscriptionAccess, interfaceLanguageSettings: interfaceLanguageSettings
    )
    private lazy var coordinator = TranslationCoordinator { [weak self] in
        self?.authorizeFeature() ?? false
    }
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
        supportedLanguageCatalog: supportedLanguageCatalog,
        onShowSubscription: subscriptionAction
    )
    private let selectedTextReader: any SelectedTextReading
    private let screenshotCapture: any ScreenshotCapturing
    private let imageViewerController: any ImageViewerControlling
    private let sourceLanguageResolver: SourceLanguageResolver
    private var selectionTask: Task<Void, Never>?
    private var isCapturingScreenshot = false

    var subscriptionAction: (@MainActor () -> Void)? {
        guard subscriptionAccess.requiresSubscription else { return nil }
        return { [weak self] in self?.showSubscription() }
    }

    init(
        translationEngine: TranslationEngine = .apple,
        selectedTextReader: any SelectedTextReading = SelectedTextResolver(
            primaryReader: AccessibilitySelectedTextReader(),
            fallbackReader: ClipboardSelectedTextReader()
        ),
        screenshotCapture: any ScreenshotCapturing = SystemScreenshotCapture(),
        imageViewerController: (any ImageViewerControlling)? = nil,
        interfaceLanguageSettings: InterfaceLanguageSettings = InterfaceLanguageSettings(),
        sourceLanguageResolver: SourceLanguageResolver = SourceLanguageResolver(
            minimumConfidence: 0.60,
            languageIdentifier: NaturalLanguageIdentifier()
        ),
        subscriptionAccess: SubscriptionAccessController? = nil,
        onSubscriptionRequired: (@MainActor () -> Void)? = nil
    ) {
        self.translationEngine = translationEngine
        self.subscriptionAccess = subscriptionAccess ?? SubscriptionConfiguration.makeAccessController()
        self.onSubscriptionRequired = onSubscriptionRequired
        self.supportedLanguageCatalog = SupportedLanguageCatalog(
            loadLanguages: translationEngine.loadLanguages
        )
        self.interfaceLanguageSettings = interfaceLanguageSettings
        self.screenshotCapture = screenshotCapture
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
        subscriptionAccess.start()
        startShortcut(shortcutController)

        Task {
            let supportedLanguages = await supportedLanguageCatalog.load()
            settings.validateSourceLanguage(supportedLanguages: supportedLanguages)
            settings.validateTargetLanguage(supportedLanguages: supportedLanguages)
        }
    }

    func showPreferences() {
        preferencesWindowController.present()
    }

    func showSubscription() {
        guard subscriptionAccess.requiresSubscription else { return }
        subscriptionWindowController.present()
    }

    func translate(
        _ selectedText: SelectedText,
        sourceLanguageIdentifier: String,
        sourceLanguageWasDetected: Bool = false
    ) async {
        await subscriptionAccess.loadIfNeeded()
        guard !Task.isCancelled else { return }
        guard authorizeFeature() else { return }
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
        if subscriptionAccess.hasLoaded, !authorizeFeature() { return }
        guard selectionTask == nil, !isCapturingScreenshot else {
            return
        }

        selectionTask = Task {
            defer {
                selectionTask = nil
            }

            await subscriptionAccess.loadIfNeeded()
            guard !Task.isCancelled, authorizeFeature() else { return }

            do {
                switch try await resolveShortcutAction() {
                case .translate(let selectedText):
                    await resolveSourceLanguage(for: selectedText)
                case .captureScreenRegion:
                    do {
                        try await captureScreenshot()
                    } catch ScreenshotCaptureError.permissionRequired {
                        // The permission flow already explained the next step.
                        return
                    } catch {
                        showError(.screenshot((error as? ScreenshotCaptureError) ?? .captureFailed))
                    }
                }
            } catch SelectedTextReadError.accessibilityPermissionRequired {
                AccessibilityPermission.requestIfNeeded()
            } catch is CancellationError {
                return
            } catch {
                showError(.verbatim(error.localizedDescription))
            }
        }
    }

    func resolveShortcutAction() async throws -> ShortcutAction {
        do {
            return .translate(try await selectedTextReader.readSelectedText())
        } catch SelectedTextReadError.noSelection, SelectedTextReadError.copyFailed {
            return .captureScreenRegion
        }
    }

    func captureScreenshot() async throws {
        await subscriptionAccess.loadIfNeeded()
        try Task.checkCancellation()
        guard authorizeFeature() else { return }
        guard !isCapturingScreenshot else { return }
        isCapturingScreenshot = true
        defer { isCapturingScreenshot = false }
        guard let image = try await screenshotCapture.captureRegion() else { return }
        imageViewerController.present(image: image, pointerLocation: NSEvent.mouseLocation)
    }

    private func authorizeFeature() -> Bool {
        guard subscriptionAccess.hasAccess else {
            if let onSubscriptionRequired { onSubscriptionRequired() } else { showSubscription() }
            return false
        }
        return true
    }

    private func startShortcut(_ controller: GlobalShortcutController) {
        do {
            try controller.start()
        } catch {
            if let shortcutError = error as? GlobalShortcutError {
                showError(.globalShortcut(shortcutError))
            } else {
                showError(.verbatim(error.localizedDescription))
            }
        }
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
            await translate(
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
                Task { [weak self] in
                    await self?.translate(
                        selectedText,
                        sourceLanguageIdentifier: languageIdentifier
                    )
                }
            }
        }
    }

}

enum ShortcutAction {
    case translate(SelectedText)
    case captureScreenRegion
}
