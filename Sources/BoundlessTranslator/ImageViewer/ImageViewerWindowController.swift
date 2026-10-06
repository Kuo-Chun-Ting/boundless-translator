import AppKit
import Combine

@MainActor
protocol ImageViewerContent: AnyObject {
    var view: NSView { get }
    var selectedText: String { get }
    var hasActiveTextSelection: Bool { get }
    var onAnalysisCompletion: ((ImageTextDocument?) -> Void)? { get set }

    func display(_ image: NSImage)
    func clearSelection()
}

@MainActor
protocol ImageViewerControlling: ImageViewerSelectionProviding {
    func present(image: NSImage, pointerLocation: CGPoint)
}

extension ImageTextView: ImageViewerContent {
    var view: NSView {
        self
    }
}

@MainActor
final class ImageViewerWindowController: NSWindowController,
    ImageViewerControlling,
    NSWindowDelegate
{
    typealias VisibleFrameProvider = @MainActor (CGPoint) -> CGRect?

    var selectedText: String {
        content.selectedText
    }

    var isSelectionActive: Bool {
        window?.isKeyWindow == true && content.hasActiveTextSelection
    }

    var translationShortcutName: @MainActor () -> String = { "" }
    var sourceLanguageIdentifier: @MainActor () -> String? = { nil }

    private let screenshotTipController = ScreenshotTipController()
    private let content: any ImageViewerContent
    private let visibleFrameForPointer: VisibleFrameProvider
    private let windowPresenter: any ForegroundWindowPresenting
    private let interfaceLanguageSettings: InterfaceLanguageSettings
    private let recognitionLanguages: @MainActor () -> [String]?
    private var languageCancellable: AnyCancellable?
    private var screenshotHintHeight: CGFloat = 0

    init(
        content: any ImageViewerContent = ImageTextView(),
        visibleFrameForPointer: @escaping VisibleFrameProvider = { pointerLocation in
            NSScreen.screens.first {
                $0.frame.contains(pointerLocation)
            }?.visibleFrame ?? NSScreen.main?.visibleFrame
        },
        windowPresenter: any ForegroundWindowPresenting = ForegroundWindowPresenter.shared,
        interfaceLanguageSettings: InterfaceLanguageSettings,
        recognitionLanguages: @escaping @MainActor () -> [String]? = {
            try? ImageTextRecognizer.supportedLanguages()
        }
    ) {
        self.content = content
        self.visibleFrameForPointer = visibleFrameForPointer
        self.windowPresenter = windowPresenter
        self.interfaceLanguageSettings = interfaceLanguageSettings
        self.recognitionLanguages = recognitionLanguages

        let window = ImageViewerWindow(
            contentRect: CGRect(
                origin: .zero,
                size: CGSize(width: 760, height: 520)
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.collectionBehavior = [.moveToActiveSpace]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.contentMinSize = CGSize(width: 420, height: 300)
        let container = NSView(frame: window.contentLayoutRect)
        content.view.frame = container.bounds
        content.view.autoresizingMask = [.width, .height]
        container.addSubview(content.view)
        window.contentView = container

        super.init(window: window)
        window.delegate = self
        content.onAnalysisCompletion = { [weak self] document in
            self?.showEmptyResultAlert(for: document)
        }
        screenshotTipController.onHeightChange = { [weak self] height in
            self?.reserveScreenshotHintSpace(height: height)
        }
        updateWindowTitle(languageIdentifier: interfaceLanguageSettings.languageIdentifier)
        languageCancellable = interfaceLanguageSettings.$languageIdentifier
            .sink { [weak self] languageIdentifier in
                self?.updateWindowTitle(languageIdentifier: languageIdentifier)
            }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(image: NSImage, pointerLocation: CGPoint) {
        screenshotTipController.close()
        content.display(image)
        if let visibleFrame = visibleFrameForPointer(pointerLocation) {
            fitWindow(to: image.size, inside: visibleFrame)
        }
        if let window {
            windowPresenter.present(window)
            showScreenshotTip()
        }
    }

    func enableQuickTranslation(settings: TranslationSettings, engine: TranslationEngine,
                                authorize: @escaping @MainActor () -> Bool = { true }) {
        guard let imageView = content as? ImageTextView else { return }
        imageView.quickTranslation = ScreenshotTranslationController(
            imageView: imageView, settings: settings, interfaceLanguageSettings: interfaceLanguageSettings,
            engine: engine, coordinator: TranslationCoordinator(authorize: authorize))
    }

    func windowWillClose(_ notification: Notification) {
        screenshotTipController.close()
        content.clearSelection()
    }

    func windowDidResize(_ notification: Notification) {
        layoutScreenshotContent()
        if let width = window?.contentView?.bounds.width {
            screenshotTipController.resize(to: width)
        }
    }

    private func reserveScreenshotHintSpace(height: CGFloat) {
        guard height != screenshotHintHeight, let window else { return }
        let difference = height - screenshotHintHeight
        screenshotHintHeight = height
        var frame = window.frame
        frame.size.height += difference
        frame.origin.y -= difference
        if let visibleFrame = window.screen?.visibleFrame {
            frame.origin = WindowPositioner(pointerOffset: 0).resizedOrigin(
                currentFrame: window.frame, newWindowSize: frame.size, visibleFrame: visibleFrame
            )
        }
        window.contentMinSize = CGSize(width: 420, height: 300 + height)
        window.setFrame(frame, display: true)
        layoutScreenshotContent()
    }

    private func showEmptyResultAlert(for document: ImageTextDocument?) {
        guard let document, document.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let window, window.isVisible else { return }
        let localization = AppLocalization(languageIdentifier:
            interfaceLanguageSettings.resolvedLanguageIdentifier(
                for: interfaceLanguageSettings.languageIdentifier))
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = localization.string("screenshot.noTextTitle")
        alert.informativeText = localization.string("screenshot.noTextMessage")
        alert.addButton(withTitle: localization.string("common.ok"))
        alert.beginSheetModal(for: window)
    }

    private func layoutScreenshotContent() {
        guard let bounds = window?.contentView?.bounds else { return }
        content.view.frame = CGRect(
            x: 0, y: 0, width: bounds.width,
            height: max(0, bounds.height - screenshotHintHeight)
        )
    }

    private func showScreenshotTip() {
        guard let window, window.isVisible else { return }
        let localization = AppLocalization(
            languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier(
                for: interfaceLanguageSettings.languageIdentifier
            )
        )
        screenshotTipController.present(
            in: window, localization: localization, hints: makeScreenshotHints(localization: localization)
        )
    }

    private func makeScreenshotHints(localization: AppLocalization) -> [ScreenshotHint] {
        var hints: [ScreenshotHint] = []
        if let source = sourceLanguageIdentifier(), let tip = ScreenshotLanguageTip.make(
            localization: localization, sourceLanguageIdentifier: source,
            recognitionLanguages: recognitionLanguages()
        ) {
            hints.append(ScreenshotHint(id: "hint.screenshotLanguage", tip: tip))
        }
        let shortcut = translationShortcutName()
        if !shortcut.isEmpty {
            hints.append(ScreenshotHint(id: "hint.screenshot", tip: ScreenshotTip(
                localization: localization, shortcut: shortcut)))
        }
        return hints
    }

    private func fitWindow(to imageSize: CGSize, inside visibleFrame: CGRect) {
        guard let window else {
            return
        }

        let maximumSize = CGSize(
            width: min(1_000, visibleFrame.width * 0.82),
            height: min(760, visibleFrame.height * 0.82)
        )
        let contentSize = Self.aspectFitSize(
            imageSize: imageSize,
            maximumSize: maximumSize
        )
        window.setContentSize(contentSize)
        window.setFrameOrigin(
            CGPoint(
                x: visibleFrame.midX - window.frame.width / 2,
                y: visibleFrame.midY - window.frame.height / 2
            )
        )
    }

    private func updateWindowTitle(languageIdentifier: String?) {
        let resolvedIdentifier = interfaceLanguageSettings
            .resolvedLanguageIdentifier(for: languageIdentifier)
        window?.title = AppLocalization(
            languageIdentifier: resolvedIdentifier
        ).string("shortcut.screenshotTranslation")
        screenshotTipController.update(
            localization: AppLocalization(languageIdentifier: resolvedIdentifier),
            hints: makeScreenshotHints(localization: AppLocalization(languageIdentifier: resolvedIdentifier))
        )
    }

    private static func aspectFitSize(
        imageSize: CGSize,
        maximumSize: CGSize
    ) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGSize(width: 760, height: 520)
        }

        let scale = min(
            maximumSize.width / imageSize.width,
            maximumSize.height / imageSize.height
        )
        return CGSize(
            width: max(420, imageSize.width * scale),
            height: max(300, imageSize.height * scale)
        )
    }
}

private final class ImageViewerWindow: NSWindow {
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, event.keyCode == 53,
           event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty {
            cancelOperation(nil)
            return
        }
        super.sendEvent(event)
    }

    override func cancelOperation(_ sender: Any?) {
        performClose(sender)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.intersection([.command, .option, .control, .shift]) == .command,
           event.characters?.lowercased() == "w" {
            performClose(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
