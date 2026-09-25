import AppKit
import Combine

@MainActor
protocol ImageViewerContent: AnyObject {
    var view: NSView { get }
    var selectedText: String { get }
    var hasActiveTextSelection: Bool { get }

    func display(_ image: NSImage)
    func clearSelection()
}

@MainActor
protocol ImageViewerControlling: ImageViewerSelectionProviding {
    func present(image: NSImage, pointerLocation: CGPoint)
}

extension LiveTextImageView: ImageViewerContent {
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

    private let content: any ImageViewerContent
    private let visibleFrameForPointer: VisibleFrameProvider
    private let windowPresenter: any ForegroundWindowPresenting
    private let interfaceLanguageSettings: InterfaceLanguageSettings
    private var languageCancellable: AnyCancellable?

    init(
        content: any ImageViewerContent = LiveTextImageView(),
        visibleFrameForPointer: @escaping VisibleFrameProvider = { pointerLocation in
            NSScreen.screens.first {
                $0.frame.contains(pointerLocation)
            }?.visibleFrame ?? NSScreen.main?.visibleFrame
        },
        windowPresenter: any ForegroundWindowPresenting = ForegroundWindowPresenter.shared,
        interfaceLanguageSettings: InterfaceLanguageSettings
    ) {
        self.content = content
        self.visibleFrameForPointer = visibleFrameForPointer
        self.windowPresenter = windowPresenter
        self.interfaceLanguageSettings = interfaceLanguageSettings

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
        window.acceptsMouseMovedEvents = true
        window.contentMinSize = CGSize(width: 420, height: 300)
        window.contentView = content.view

        super.init(window: window)
        window.delegate = self
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
        content.display(image)
        if let visibleFrame = visibleFrameForPointer(pointerLocation) {
            fitWindow(to: image.size, inside: visibleFrame)
        }
        if let window {
            windowPresenter.present(window)
        }
    }

    func windowWillClose(_ notification: Notification) {
        content.clearSelection()
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
    private var pendingTextDrag = false

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, event.keyCode == 53,
           event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty {
            cancelOperation(nil)
            return
        }
        defer { updateTextCursor(for: event) }
        if handlePendingTextDrag(event) { return }
        super.sendEvent(event)
    }

    override func cancelOperation(_ sender: Any?) {
        performClose(sender)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.intersection([.command, .option, .control, .shift]) == .command,
           event.charactersIgnoringModifiers?.lowercased() == "w" {
            performClose(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    private func handlePendingTextDrag(_ event: NSEvent) -> Bool {
        guard let textView = contentView as? LiveTextImageView else { return false }
        switch event.type {
        case .leftMouseDown:
            pendingTextDrag = textView.canBeginSelection(at: event.locationInWindow)
                && !textView.containsText(at: event.locationInWindow)
            guard pendingTextDrag else { return false }
            makeKeyAndOrderFront(nil)
            textView.clearSelection()
            // Own the blank-space gesture until it reaches text. Sending this
            // down to VisionKit would start a competing native tracking loop.
            return true
        case .leftMouseDragged:
            guard pendingTextDrag else { return false }
            guard textView.containsText(at: event.locationInWindow) else { return true }
            pendingTextDrag = false
            beginNativeTextDrag(with: event)
            return false
        case .leftMouseUp:
            let wasPending = pendingTextDrag
            pendingTextDrag = false
            return wasPending
        default:
            return false
        }
    }

    private func beginNativeTextDrag(with event: NSEvent) {
        // Hand off once, at the first text hit. Subsequent drag/up events follow
        // normal AppKit dispatch; nothing is posted to the system event queue.
        guard let start = NSEvent.mouseEvent(
            with: .leftMouseDown, location: event.locationInWindow,
            modifierFlags: event.modifierFlags, timestamp: event.timestamp,
            windowNumber: windowNumber, context: nil,
            eventNumber: event.eventNumber, clickCount: 1, pressure: 1
        ) else { return }
        super.sendEvent(start)
    }

    private func updateTextCursor(for event: NSEvent) {
        switch event.type {
        case .mouseMoved, .leftMouseDown, .leftMouseDragged, .leftMouseUp, .cursorUpdate:
            (contentView as? LiveTextImageView)?.updateCursor(at: event.locationInWindow)
        default:
            break
        }
    }


}
