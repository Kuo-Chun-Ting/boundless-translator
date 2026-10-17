import AppKit
import Combine
import SwiftUI

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
    var translationLanguages: (source: String?, target: String)? { get }
    func present(image: NSImage, pointerLocation: CGPoint)
}

extension ImageViewerControlling {
    var translationLanguages: (source: String?, target: String)? { nil }
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

    var translationLanguages: (source: String?, target: String)? {
        guard let translation = (content as? ImageTextView)?.quickTranslation else { return nil }
        return (translation.sourceLanguageIdentifier, translation.targetLanguageIdentifier)
    }

    var sourceLanguageIdentifier: @MainActor () -> String? = { nil }

    private let screenshotTipController = ScreenshotTipController()
    private let content: any ImageViewerContent
    private let visibleFrameForPointer: VisibleFrameProvider
    private let windowPresenter: any ForegroundWindowPresenting
    private let interfaceLanguageSettings: InterfaceLanguageSettings
    private let recognitionLanguages: @MainActor () -> [String]?
    private var languageCancellable: AnyCancellable?
    private var screenshotHintHeight: CGFloat = 0
    private var languageToolbar: NSHostingView<ScreenshotLanguageToolbar>?

    private var languageToolbarHeight: CGFloat {
        languageToolbar == nil ? 0 : ScreenshotLanguageToolbar.height
    }

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
        WindowBranding.install(on: window, identifier: "screenshotWindow")
        let container = ScreenshotWorkspaceView(frame: window.contentLayoutRect)
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
        updateScreenshotHints(languageIdentifier: interfaceLanguageSettings.languageIdentifier)
        languageCancellable = interfaceLanguageSettings.$languageIdentifier
            .sink { [weak self] languageIdentifier in
                self?.updateScreenshotHints(languageIdentifier: languageIdentifier)
            }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(image: NSImage, pointerLocation: CGPoint) {
        screenshotTipController.close()
        (content as? ImageTextView)?.quickTranslation?.resetLanguages()
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
                                supportedLanguageCatalog: SupportedLanguageCatalog? = nil,
                                authorize: @escaping @MainActor () -> Bool = { true }) {
        guard let imageView = content as? ImageTextView else { return }
        let translation = ScreenshotTranslationController(
            imageView: imageView, settings: settings, interfaceLanguageSettings: interfaceLanguageSettings,
            engine: engine, coordinator: TranslationCoordinator(authorize: authorize))
        imageView.quickTranslation = translation
        (window?.contentView as? ScreenshotWorkspaceView)?.onPointerExited = { [weak translation] in
            translation?.scheduleDismissal()
        }
        sourceLanguageIdentifier = { [weak translation] in translation?.sourceLanguageIdentifier }
        translation.onSourceLanguageChange = { [weak self] in
            guard let self else { return }
            updateScreenshotHints(languageIdentifier: interfaceLanguageSettings.languageIdentifier)
        }
        languageToolbar?.removeFromSuperview()
        let toolbar = NSHostingView(rootView: ScreenshotLanguageToolbar(
            translation: translation,
            supportedLanguageCatalog: supportedLanguageCatalog
                ?? SupportedLanguageCatalog(loadLanguages: engine.loadLanguages),
            interfaceLanguageSettings: interfaceLanguageSettings))
        toolbar.sizingOptions = []
        toolbar.autoresizingMask = [.width, .minYMargin]
        languageToolbar = toolbar
        window?.contentView?.addSubview(toolbar)
        screenshotTipController.topInset = languageToolbarHeight
        window?.contentMinSize = CGSize(width: 420, height: 300 + languageToolbarHeight + screenshotHintHeight)
        layoutScreenshotContent()
    }

    func windowWillClose(_ notification: Notification) {
        screenshotTipController.close()
        (content as? ImageTextView)?.cancelAnalysis()
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
        window.contentMinSize = CGSize(width: 420, height: 300 + languageToolbarHeight + height)
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
            height: max(0, bounds.height - screenshotHintHeight - languageToolbarHeight)
        )
        languageToolbar?.frame = CGRect(
            x: 0, y: bounds.height - languageToolbarHeight,
            width: bounds.width, height: languageToolbarHeight
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
        hints.append(ScreenshotHint(id: "hint.translationLanguages", tip: TranslationLanguageTip(
            localization: localization)))
        hints.append(ScreenshotHint(id: "hint.screenshot", tip: ScreenshotTip(
            localization: localization)))
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
        window.setContentSize(CGSize(width: contentSize.width,
                                     height: contentSize.height + languageToolbarHeight))
        layoutScreenshotContent()
        window.setFrameOrigin(
            CGPoint(
                x: visibleFrame.midX - window.frame.width / 2,
                y: visibleFrame.midY - window.frame.height / 2
            )
        )
    }

    private func updateScreenshotHints(languageIdentifier: String?) {
        let resolvedIdentifier = interfaceLanguageSettings
            .resolvedLanguageIdentifier(for: languageIdentifier)
        (content as? ImageTextView)?.recognitionProgressMessage = AppLocalization(
            languageIdentifier: resolvedIdentifier).string("screenshot.recognizing")
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

private final class ScreenshotWorkspaceView: NSView {
    var onPointerExited: () -> Void = {}
    private var pointerTrackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let pointerTrackingArea { removeTrackingArea(pointerTrackingArea) }
        let area = NSTrackingArea(rect: .zero,
                                  options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                                  owner: self)
        pointerTrackingArea = area
        addTrackingArea(area)
    }

    override func mouseExited(with event: NSEvent) {
        guard let window else { return }
        let pointer = convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        // A native menu can obscure this view without the pointer leaving the workspace.
        guard !bounds.contains(pointer) else { return }
        onPointerExited()
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

private struct ScreenshotLanguageToolbar: View {
    private static let labelHeight: CGFloat = 16
    private static let labelSpacing: CGFloat = 6
    static let height = labelHeight + labelSpacing + TranslationWindowStyle.languageRowHeight
        + TranslationWindowStyle.controlsVerticalPadding * 2

    @ObservedObject var translation: ScreenshotTranslationController
    @ObservedObject var supportedLanguageCatalog: SupportedLanguageCatalog
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            languageField(role: .source)
            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
                .frame(width: 16, height: TranslationWindowStyle.languageRowHeight)
                .accessibilityHidden(true)
            languageField(role: .target)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, TranslationWindowStyle.contentPadding)
        .padding(.vertical, TranslationWindowStyle.controlsVerticalPadding)
        .appControlSurface()
        .overlay(alignment: .bottom) { Divider().allowsHitTesting(false) }
        .onHover { isInside in
            if isInside { translation.cancelPendingHoverAndDismissal() }
        }
        .interfaceLanguage(interfaceLanguageSettings)
        .task { _ = await supportedLanguageCatalog.load() }
    }

    private var localization: AppLocalization {
        AppLocalization(languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier)
    }

    private func languageField(role: TranslationLanguageRole) -> some View {
        VStack(alignment: .leading, spacing: Self.labelSpacing) {
            Text(verbatim: localization.string(
                role == .source ? "preferences.translateFrom" : "preferences.translateTo"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(height: Self.labelHeight, alignment: .leading)
            languagePicker(role: role)
                .frame(minHeight: TranslationWindowStyle.languageRowHeight, alignment: .leading)
        }
        .frame(maxWidth: 190, alignment: .leading)
    }

    private func languagePicker(role: TranslationLanguageRole) -> some View {
        TranslationLanguagePicker(
            supportedLanguages: supportedLanguageCatalog.languages,
            role: role,
            localization: localization,
            selectedIdentifier: role == .source
                ? translation.sourceLanguageIdentifier : translation.targetLanguageIdentifier,
            allowsAutomaticSelection: true
        ) { identifier in
            switch role {
            case .source: translation.updateSourceLanguage(identifier)
            case .target:
                if let identifier { translation.updateTargetLanguage(identifier) }
            }
        }
    }
}
