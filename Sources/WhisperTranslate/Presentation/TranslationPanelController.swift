import AppKit
import SwiftUI

@MainActor
final class TranslationPanelController: NSObject, NSWindowDelegate {
    private let panelSize = CGSize(width: 420, height: 260)
    private let positioner = PanelPositioner(pointerOffset: 12)
    private let panelState = TranslationPanelState()
    private let panel: TranslationPanel
    private var interactionPolicy = PanelInteractionPolicy(kind: .translation)

    override init() {
        panel = TranslationPanel(contentSize: panelSize)
        super.init()
        panel.delegate = self
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.backgroundColor = .windowBackgroundColor
    }

    func show(
        coordinator: TranslationCoordinator,
        pointerLocation: CGPoint
    ) {
        present(
            TranslationPanelView(
                coordinator: coordinator,
                panelState: panelState
            ),
            kind: .translation,
            pointerLocation: pointerLocation
        )
    }

    func showError(message: String, pointerLocation: CGPoint) {
        present(
            SelectionErrorView(message: message),
            kind: .error,
            pointerLocation: pointerLocation
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
            pointerLocation: pointerLocation
        )
    }

    private func present<Content: View>(
        _ content: Content,
        kind: TranslationPanelKind,
        pointerLocation: CGPoint
    ) {
        panelState.reset()
        interactionPolicy = PanelInteractionPolicy(kind: kind)
        panel.contentView = NSHostingView(rootView: content)
        panel.setContentSize(panelSize)

        let screen = NSScreen.screens.first {
            $0.frame.contains(pointerLocation)
        } ?? NSScreen.main
        if let visibleFrame = screen?.visibleFrame {
            panel.setFrameOrigin(
                positioner.origin(
                    pointer: pointerLocation,
                    panelSize: panelSize,
                    visibleFrame: visibleFrame
                )
            )
        }

        panel.orderFrontRegardless()
        panel.makeKey()
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
