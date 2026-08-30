import AppKit
import SwiftUI

@MainActor
final class TranslationPanelController: NSObject, NSWindowDelegate {
    private let auxiliaryPanelSize = CGSize(width: 420, height: 260)
    private let translationLayout = TranslationPanelLayout()
    private let positioner = PanelPositioner(pointerOffset: 12)
    private let panelState: TranslationPanelState
    private let panel: TranslationPanel
    private let applicationNotificationCenter: NotificationCenter
    private lazy var toolbarController = TranslationPanelToolbarController(
        panelState: panelState
    )
    private var interactionPolicy = PanelInteractionPolicy(kind: .translation)
    private var presentedKind = TranslationPanelKind.translation
    private var mouseDownMonitor: MouseDownMonitor?

    override convenience init() {
        self.init(
            applicationNotificationCenter: NSWorkspace.shared.notificationCenter
        )
    }

    init(applicationNotificationCenter: NotificationCenter) {
        panelState = TranslationPanelState()
        panel = TranslationPanel(contentSize: auxiliaryPanelSize)
        self.applicationNotificationCenter = applicationNotificationCenter
        super.init()
        panel.delegate = self
        panel.toolbar = toolbarController.toolbar
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.cancelOperationHandler = { [weak self] sender in
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
            status: coordinator.status
        ).size
        present(
            TranslationPanelView(
                coordinator: coordinator,
                supportedLanguages: supportedLanguages,
                layout: translationLayout,
                onPreferredSizeChange: { [weak self] size in
                    self?.resizeTranslationPanel(to: size)
                }
            ),
            kind: .translation,
            pointerLocation: pointerLocation,
            panelSize: initialSize
        )
    }

    func showError(message: String, pointerLocation: CGPoint) {
        present(
            SelectionErrorView(message: message),
            kind: .error,
            pointerLocation: pointerLocation,
            panelSize: auxiliaryPanelSize
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
                onCancel: { [weak self] in
                    self?.panel.orderOut(nil)
                },
                onSelect: onSelect
            ),
            kind: .sourceLanguageSelection,
            pointerLocation: pointerLocation,
            panelSize: auxiliaryPanelSize
        )
    }

    private func present<Content: View>(
        _ content: Content,
        kind: TranslationPanelKind,
        pointerLocation: CGPoint,
        panelSize: CGSize
    ) {
        panelState.reset()
        toolbarController.synchronize()
        interactionPolicy = PanelInteractionPolicy(kind: kind)
        presentedKind = kind
        panel.contentView = TranslationPanelContentView(rootView: content)
        panel.setContentSize(panelSize)
        configureWindowControls(for: kind)

        positionPanel(size: panelSize, pointerLocation: pointerLocation)

        panel.orderFrontRegardless()
        panel.makeKey()
    }

    private func resizeTranslationPanel(to size: CGSize) {
        guard case .translation = presentedKind else {
            return
        }
        guard panel.contentLayoutRect.size != size else {
            return
        }

        let currentFrame = panel.frame
        panel.setContentSize(size)
        preservePanelPosition(from: currentFrame)
    }

    private func preservePanelPosition(from currentFrame: CGRect) {
        guard let visibleFrame = (panel.screen ?? NSScreen.main)?.visibleFrame else {
            panel.setFrameTopLeftPoint(
                CGPoint(x: currentFrame.minX, y: currentFrame.maxY)
            )
            return
        }

        panel.setFrameOrigin(
            positioner.resizedOrigin(
                currentFrame: currentFrame,
                newPanelSize: panel.frame.size,
                visibleFrame: visibleFrame
            )
        )
    }

    private func positionPanel(size: CGSize, pointerLocation: CGPoint) {
        let screen = NSScreen.screens.first {
            $0.frame.contains(pointerLocation)
        } ?? NSScreen.main
        if let visibleFrame = screen?.visibleFrame {
            panel.setFrameOrigin(
                positioner.origin(
                    pointer: pointerLocation,
                    panelSize: size,
                    visibleFrame: visibleFrame
                )
            )
        }
    }

    private func configureWindowControls(for kind: TranslationPanelKind) {
        panel.configureChrome(for: kind)

        switch kind {
        case .translation:
            panel.standardWindowButton(.closeButton)?.isHidden = false
            panel.standardWindowButton(.miniaturizeButton)?.isHidden = false
            panel.standardWindowButton(.zoomButton)?.isHidden = false
        case .error, .sourceLanguageSelection:
            panel.standardWindowButton(.closeButton)?.isHidden = false
            panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
            panel.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }

    private func dismissForCancelOperation(_ sender: Any?) {
        guard interactionPolicy.shouldDismissForCancelOperation(
            isPinned: panelState.isPinned
        ) else {
            return
        }

        panel.orderOut(sender)
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
        guard panel.isVisible else {
            return
        }
        guard !panel.frame.contains(screenLocation) else {
            return
        }
        guard interactionPolicy.shouldDismissForOutsideClick(
            isPinned: panelState.isPinned
        ) else {
            return
        }

        panel.orderOut(nil)
    }

    func dismissForApplicationActivation(processIdentifier: pid_t) {
        guard processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            return
        }
        guard panel.isVisible else {
            return
        }
        guard interactionPolicy.shouldDismissForOutsideClick(
            isPinned: panelState.isPinned
        ) else {
            return
        }

        panel.orderOut(nil)
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
