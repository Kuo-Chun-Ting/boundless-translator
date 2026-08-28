import AppKit
import SwiftUI

@MainActor
final class TranslationPanelController: NSObject, NSWindowDelegate {
    private let auxiliaryPanelSize = CGSize(width: 420, height: 260)
    private let translationLayout = TranslationPanelLayout()
    private let positioner = PanelPositioner(pointerOffset: 12)
    private let panelState: TranslationPanelState
    private let dictionaryCoordinator: DictionaryLookupCoordinator
    private let panel: TranslationPanel
    private lazy var workflowCoordinator = PanelWorkflowCoordinator(
        translation: PanelTranslationWorkflow(panelState: panelState),
        dictionary: PanelDictionaryWorkflow(
            panelState: panelState,
            coordinator: dictionaryCoordinator
        )
    )
    private lazy var toolbarController = TranslationPanelToolbarController(
        panelState: panelState,
        onSelectMode: { [weak self] mode in
            self?.selectMode(mode)
        }
    )
    private var interactionPolicy = PanelInteractionPolicy(kind: .translation)
    private var presentedKind = TranslationPanelKind.translation
    private var presentedPointerLocation = CGPoint.zero
    private var selectedText: SelectedText?

    init(
        dictionaryService: any DictionaryLookupServicing = DictionaryServicesLookupService()
    ) {
        panelState = TranslationPanelState()
        dictionaryCoordinator = DictionaryLookupCoordinator(service: dictionaryService)
        panel = TranslationPanel(contentSize: auxiliaryPanelSize)
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
    }

    func show(
        selectedText: SelectedText,
        coordinator: TranslationCoordinator,
        supportedLanguages: [Locale.Language],
        pointerLocation: CGPoint
    ) {
        self.selectedText = selectedText
        dictionaryCoordinator.reset()
        let initialSize = translationLayout.metrics(
            sourceText: coordinator.request?.text ?? "",
            status: coordinator.status
        ).size
        present(
            TranslationPanelView(
                coordinator: coordinator,
                dictionaryCoordinator: dictionaryCoordinator,
                panelState: panelState,
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
        presentedPointerLocation = pointerLocation
        panel.contentView = NSHostingView(rootView: content)
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

        panel.setContentSize(size)
        positionPanel(
            size: size,
            pointerLocation: presentedPointerLocation
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

    private func selectMode(_ mode: TranslationPanelMode) {
        guard let selectedText else {
            return
        }

        workflowCoordinator.select(mode, text: selectedText)
    }

    private func dismissForCancelOperation(_ sender: Any?) {
        guard interactionPolicy.shouldDismissForCancelOperation(
            isPinned: panelState.isPinned
        ) else {
            return
        }

        panel.orderOut(sender)
    }

    func windowDidResignKey(_ notification: Notification) {
        guard interactionPolicy.shouldDismissForOutsideClick(
            isPinned: panelState.isPinned
        ) else {
            return
        }

        panel.orderOut(nil)
    }
}

@MainActor
private final class PanelTranslationWorkflow: TranslationWorkflowing {
    private let panelState: TranslationPanelState

    init(panelState: TranslationPanelState) {
        self.panelState = panelState
    }

    func translate() {
        panelState.select(.translate)
    }
}

@MainActor
private final class PanelDictionaryWorkflow: DictionaryWorkflowing {
    private let panelState: TranslationPanelState
    private let coordinator: DictionaryLookupCoordinator

    init(
        panelState: TranslationPanelState,
        coordinator: DictionaryLookupCoordinator
    ) {
        self.panelState = panelState
        self.coordinator = coordinator
    }

    func lookUp(_ selectedText: SelectedText) {
        panelState.select(.dictionary)
        coordinator.lookUp(selectedText)
    }
}
