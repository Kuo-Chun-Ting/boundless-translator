import AppKit
import SwiftUI

@MainActor
final class TranslationWindowController: NSObject, NSWindowDelegate {
    private let auxiliaryWindowSize = CGSize(width: 420, height: 260)
    private let translationLayout = TranslationWindowLayout()
    private let positioner = WindowPositioner(pointerOffset: 12)
    private let windowState: TranslationWindowState
    private let window: TranslationWindow
    private let speechController: TranslationSpeechController
    private let interfaceLanguageSettings: InterfaceLanguageSettings
    private let engine: TranslationEngine
    private let windowPresenter: any ForegroundWindowPresenting
    private let applicationNotificationCenter: NotificationCenter
    private lazy var toolbarController = TranslationWindowToolbarController(
        windowState: windowState,
        interfaceLanguageSettings: interfaceLanguageSettings
    )
    private var interactionPolicy = WindowInteractionPolicy(kind: .translation)
    private var presentedKind = TranslationWindowKind.translation
    private var mouseDownMonitor: MouseDownMonitor?

    init(
        applicationNotificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        speechPlayer: any SpeechPlaying = AppleSpeechPlayer(),
        interfaceLanguageSettings: InterfaceLanguageSettings,
        engine: TranslationEngine,
        windowPresenter: any ForegroundWindowPresenting = ForegroundWindowPresenter.shared
    ) {
        windowState = TranslationWindowState()
        window = TranslationWindow(contentSize: auxiliaryWindowSize)
        speechController = TranslationSpeechController(player: speechPlayer)
        self.interfaceLanguageSettings = interfaceLanguageSettings
        self.engine = engine
        self.windowPresenter = windowPresenter
        self.applicationNotificationCenter = applicationNotificationCenter
        super.init()
        window.delegate = self
        window.toolbar = toolbarController.toolbar
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.cancelOperationHandler = { [weak self] sender in
            self?.dismissForCancelOperation(sender)
        }
        configureDismissalTriggers()
    }

    deinit {
        applicationNotificationCenter.removeObserver(self)
    }

    func show(
        coordinator: TranslationCoordinator,
        supportedLanguages: [Locale.Language],
        pointerLocation: CGPoint
    ) {
        let initialSize = translationLayout.metrics(
            sourceText: coordinator.request?.text ?? "",
            status: coordinator.status,
            localization: localization
        ).size
        present(
            TranslationWindowView(
                coordinator: coordinator,
                speechController: speechController,
                interfaceLanguageSettings: interfaceLanguageSettings,
                supportedLanguages: supportedLanguages,
                engine: engine,
                layout: translationLayout,
                onPreferredSizeChange: { [weak self] size in
                    self?.resizeTranslationWindow(to: size)
                }
            ),
            kind: .translation,
            pointerLocation: pointerLocation,
            windowSize: initialSize
        )
    }

    func showError(
        message: SelectionErrorMessage,
        pointerLocation: CGPoint
    ) {
        present(
            SelectionErrorView(
                message: message,
                interfaceLanguageSettings: interfaceLanguageSettings
            ),
            kind: .error,
            pointerLocation: pointerLocation,
            windowSize: auxiliaryWindowSize
        )
    }

    func showSourceLanguageSelection(
        selectedText: SelectedText,
        selection: SourceLanguageSelection,
        supportedLanguages: [Locale.Language],
        pointerLocation: CGPoint,
        onSelect: @escaping @MainActor (String) -> Void
    ) {
        present(
            SourceLanguageSelectionView(
                selectedText: selectedText,
                selection: selection,
                supportedLanguages: supportedLanguages,
                interfaceLanguageSettings: interfaceLanguageSettings,
                onCancel: { [weak self] in
                    self?.dismiss(nil)
                },
                onSelect: onSelect
            ),
            kind: .sourceLanguageSelection,
            pointerLocation: pointerLocation,
            windowSize: auxiliaryWindowSize
        )
    }

    private func present<Content: View>(
        _ content: Content,
        kind: TranslationWindowKind,
        pointerLocation: CGPoint,
        windowSize: CGSize
    ) {
        speechController.stopPlayback()
        windowState.reset()
        toolbarController.synchronize()
        interactionPolicy = WindowInteractionPolicy(kind: kind)
        presentedKind = kind
        window.contentView = TranslationWindowContentView(rootView: content)
        window.setContentSize(windowSize)
        configureWindowControls(for: kind)

        positionWindow(size: windowSize, pointerLocation: pointerLocation)

        windowPresenter.present(window)
    }

    private func resizeTranslationWindow(to size: CGSize) {
        guard case .translation = presentedKind else {
            return
        }
        guard window.contentLayoutRect.size != size else {
            return
        }

        let currentFrame = window.frame
        window.setContentSize(size)
        preserveWindowPosition(from: currentFrame)
    }

    private func preserveWindowPosition(from currentFrame: CGRect) {
        guard let visibleFrame = (window.screen ?? NSScreen.main)?.visibleFrame else {
            window.setFrameTopLeftPoint(
                CGPoint(x: currentFrame.minX, y: currentFrame.maxY)
            )
            return
        }

        window.setFrameOrigin(
            positioner.resizedOrigin(
                currentFrame: currentFrame,
                newWindowSize: window.frame.size,
                visibleFrame: visibleFrame
            )
        )
    }

    private func positionWindow(size: CGSize, pointerLocation: CGPoint) {
        let screen = NSScreen.screens.first {
            $0.frame.contains(pointerLocation)
        } ?? NSScreen.main
        if let visibleFrame = screen?.visibleFrame {
            window.setFrameOrigin(
                positioner.origin(
                    pointer: pointerLocation,
                    windowSize: size,
                    visibleFrame: visibleFrame
                )
            )
        }
    }

    private func configureWindowControls(for kind: TranslationWindowKind) {
        window.configureChrome(for: kind)

        switch kind {
        case .translation:
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window.standardWindowButton(.zoomButton)?.isHidden = false
        case .error, .sourceLanguageSelection:
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }

    private var localization: AppLocalization {
        AppLocalization(
            languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier
        )
    }

    private func dismissForCancelOperation(_ sender: Any?) {
        guard interactionPolicy.shouldDismissForCancelOperation(
            isPinned: windowState.isPinned
        ) else {
            return
        }

        dismiss(sender)
    }

    private func configureDismissalTriggers() {
        applicationNotificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        mouseDownMonitor = MouseDownMonitor { [weak self] screenLocation in
            Task { @MainActor [weak self] in
                self?.dismissForMouseDown(at: screenLocation)
            }
        }
    }

    func dismissForMouseDown(at screenLocation: CGPoint) {
        guard window.isVisible else {
            return
        }
        guard !window.frame.contains(screenLocation) else {
            return
        }
        guard interactionPolicy.shouldDismissForOutsideClick(
            isPinned: windowState.isPinned
        ) else {
            return
        }

        dismiss(nil)
    }

    func dismissForApplicationActivation(processIdentifier: pid_t) {
        guard processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            return
        }
        guard window.isVisible else {
            return
        }
        guard interactionPolicy.shouldDismissForOutsideClick(
            isPinned: windowState.isPinned
        ) else {
            return
        }

        dismiss(nil)
    }

    @objc
    private func applicationDidActivate(_ notification: Notification) {
        guard let application = notification.userInfo?[
            NSWorkspace.applicationUserInfoKey
        ] as? NSRunningApplication else {
            return
        }

        dismissForApplicationActivation(
            processIdentifier: application.processIdentifier
        )
    }

    func windowWillClose(_ notification: Notification) {
        speechController.stopPlayback()
    }

    private func dismiss(_ sender: Any?) {
        speechController.stopPlayback()
        window.orderOut(sender)
    }
}

private final class MouseDownMonitor {
    private let globalToken: Any?
    private let localToken: Any?

    init(onMouseDown: @escaping (CGPoint) -> Void) {
        globalToken = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { _ in
            onMouseDown(NSEvent.mouseLocation)
        }
        localToken = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { event in
            onMouseDown(NSEvent.mouseLocation)
            return event
        }
    }

    deinit {
        if let globalToken {
            NSEvent.removeMonitor(globalToken)
        }
        if let localToken {
            NSEvent.removeMonitor(localToken)
        }
    }
}
