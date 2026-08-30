import AppKit

extension Notification.Name {
    static let translationPanelFirstResponderDidChange = Notification.Name(
        "TranslationPanelFirstResponderDidChange"
    )
}

@MainActor
final class TranslationPanel: NSPanel {
    var cancelOperationHandler: ((Any?) -> Void)?

    init(contentSize: CGSize = CGSize(width: 420, height: 260)) {
        super.init(
            contentRect: CGRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        acceptsMouseMovedEvents = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeKey: Bool {
        true
    }

    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        let didChangeFirstResponder = super.makeFirstResponder(responder)
        if didChangeFirstResponder {
            NotificationCenter.default.post(
                name: .translationPanelFirstResponderDidChange,
                object: self
            )
        }
        return didChangeFirstResponder
    }

    override func sendEvent(_ event: NSEvent) {
        super.sendEvent(event)

        guard eventCanChangeCursor(event) else {
            return
        }
        let hitView = contentView?.hitTest(event.locationInWindow)
        guard hitView is PointingHandButton else {
            return
        }
        NSCursor.pointingHand.set()
    }

    private func eventCanChangeCursor(_ event: NSEvent) -> Bool {
        switch event.type {
        case .cursorUpdate, .mouseEntered, .mouseMoved:
            true
        default:
            false
        }
    }

    func configureChrome(for kind: TranslationPanelKind) {
        switch kind {
        case .translation:
            styleMask = [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                .fullSizeContentView,
                .nonactivatingPanel,
            ]
            toolbar?.isVisible = true
        case .error, .sourceLanguageSelection:
            styleMask = [
                .titled,
                .closable,
                .fullSizeContentView,
                .nonactivatingPanel,
            ]
            toolbar?.isVisible = false
        }
        isOpaque = true
        backgroundColor = .windowBackgroundColor
        toolbarStyle = .unifiedCompact
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        titlebarSeparatorStyle = .none
        hasShadow = true
    }

    override func cancelOperation(_ sender: Any?) {
        if let cancelOperationHandler {
            cancelOperationHandler(sender)
        } else {
            orderOut(sender)
        }
    }
}
