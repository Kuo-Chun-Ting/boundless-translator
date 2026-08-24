import AppKit

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
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeKey: Bool {
        true
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
        case .error, .sourceLanguageSelection:
            styleMask = [
                .titled,
                .closable,
                .fullSizeContentView,
                .nonactivatingPanel,
            ]
        }
        isOpaque = true
        backgroundColor = .windowBackgroundColor
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
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
