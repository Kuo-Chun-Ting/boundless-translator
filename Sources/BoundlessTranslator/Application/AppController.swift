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
    private lazy var windowController = TranslationWindowController(
        interfaceLanguageSettings: interfaceLanguageSettings,
        engine: translationEngine
    )
    private let translationEngine: TranslationEngine
    private let supportedLanguageCatalog: SupportedLanguageCatalog
    private lazy var translationShortcutController = GlobalShortcutController { [weak self] in
        self?.handleTranslationShortcut()
    }
    private lazy var screenshotShortcutController = GlobalShortcutController(
        purpose: .screenshot
    ) { [weak self] in
        self?.handleScreenshotShortcut()
    }
    private lazy var preferencesWindowController = PreferencesWindowController(
        settings: settings,
        interfaceLanguageSettings: interfaceLanguageSettings,
        translationShortcutController: translationShortcutController,
        screenshotShortcutController: screenshotShortcutController,
        supportedLanguageCatalog: supportedLanguageCatalog,
        onShowSubscription: subscriptionAction
    )
    private let selectedTextReader: any SelectedTextReading
    private let screenshotCapture: any ScreenshotCapturing
    private let imageViewerController: any ImageViewerControlling
    private var shortcutTask: Task<Void, Never>?
    private var isCapturingScreenshot = false

    var subscriptionAction: (@MainActor () -> Void)? {
        guard subscriptionAccess.requiresSubscription else { return nil }
        return { [weak self] in self?.showSubscription() }
    }

    init(
        translationEngine: TranslationEngine = .apple,
        selectedTextReader: any SelectedTextReading = SelectedTextResolver(
            primaryReader: AccessibilitySelectedTextReader(),
            fallbackReader: ClipboardSelectedTextReader(copier: SystemSelectedTextCopier())
        ),
        screenshotCapture: any ScreenshotCapturing = SystemScreenshotCapture(),
        imageViewerController: (any ImageViewerControlling)? = nil,
        interfaceLanguageSettings: InterfaceLanguageSettings = InterfaceLanguageSettings(),
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
        if let viewer = resolvedImageViewerController as? ImageViewerWindowController {
            viewer.enableQuickTranslation(settings: settings, engine: translationEngine) { [weak self] in
                self?.authorizeFeature() ?? false
            }
            viewer.translationShortcutName = { [weak self] in
                self?.translationShortcutController.definition.displayName ?? ""
            }
            viewer.sourceLanguageIdentifier = { [weak self] in
                self?.settings.sourceLanguageIdentifier
            }
        }
    }

    func prepare() {
        subscriptionAccess.start()
        startShortcut(translationShortcutController)
        startShortcut(screenshotShortcutController)

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
        sourceLanguageIdentifier: String?
    ) async {
        await subscriptionAccess.loadIfNeeded()
        guard !Task.isCancelled else { return }
        guard authorizeFeature() else { return }
        let supportedLanguages = await supportedLanguageCatalog.load()
        guard !Task.isCancelled else { return }
        coordinator.submit(
            selectedText,
            sourceLanguageIdentifier: sourceLanguageIdentifier,
            targetLanguageIdentifier: settings.targetLanguageIdentifier
        )
        windowController.show(
            coordinator: coordinator,
            supportedLanguages: supportedLanguages,
            pointerLocation: NSEvent.mouseLocation
        )
    }

    func handleTranslationShortcut() {
        if subscriptionAccess.hasLoaded, !authorizeFeature() { return }
        guard shortcutTask == nil, !isCapturingScreenshot else {
            return
        }

        shortcutTask = Task {
            defer { shortcutTask = nil }
            await subscriptionAccess.loadIfNeeded()
            guard !Task.isCancelled, authorizeFeature() else { return }
            do {
                let selectedText = try await selectedTextReader.readSelectedText()
                try Task.checkCancellation()
                await translate(selectedText, sourceLanguageIdentifier: settings.sourceLanguageIdentifier)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                handleSelectionError(error)
            }
        }
    }

    private func handleSelectionError(_ error: Error) {
        switch error {
        case SelectedTextReadError.noSelection: break
        case SelectedTextReadError.accessibilityPermissionRequired:
            AccessibilityPermission.requestIfNeeded()
        default: showError(.verbatim(error.localizedDescription))
        }
    }

    func handleScreenshotShortcut() {
        if subscriptionAccess.hasLoaded, !authorizeFeature() { return }
        guard shortcutTask == nil, !isCapturingScreenshot else { return }

        shortcutTask = Task {
            defer { shortcutTask = nil }
            await captureScreenshotFromShortcut()
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

    private func captureScreenshotFromShortcut() async {
        do {
            try await captureScreenshot()
        } catch ScreenshotCaptureError.permissionRequired {
            // The permission flow already explained the next step.
            return
        } catch is CancellationError {
            return
        } catch {
            showError(.screenshot((error as? ScreenshotCaptureError) ?? .captureFailed))
        }
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
        windowController.showError(
            message: message,
            pointerLocation: NSEvent.mouseLocation
        )
    }
}
