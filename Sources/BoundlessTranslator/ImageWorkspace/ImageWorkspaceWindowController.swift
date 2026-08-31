import AppKit

@MainActor
protocol ImageWorkspaceContent: AnyObject {
    var view: NSView { get }
    var selectedText: String { get }
    var hasActiveTextSelection: Bool { get }

    func display(_ image: NSImage)
    func clearSelection()
}

@MainActor
protocol ImageWorkspaceControlling: ImageWorkspaceSelectionProviding {
    func present(image: NSImage, pointerLocation: CGPoint)
}

extension LiveTextImageView: ImageWorkspaceContent {
    var view: NSView {
        self
    }
}

@MainActor
final class ImageWorkspaceWindowController: NSWindowController,
    ImageWorkspaceControlling,
    NSWindowDelegate
{
    typealias VisibleFrameProvider = @MainActor (CGPoint) -> CGRect?

    var selectedText: String {
        content.selectedText
    }

    var isSelectionActive: Bool {
        window?.isKeyWindow == true && content.hasActiveTextSelection
    }

    private let content: any ImageWorkspaceContent
    private let visibleFrameForPointer: VisibleFrameProvider
    private let activateApplication: @MainActor () -> Void

    convenience init() {
        self.init(
            content: LiveTextImageView(),
            visibleFrameForPointer: { pointerLocation in
                NSScreen.screens.first {
                    $0.frame.contains(pointerLocation)
                }?.visibleFrame ?? NSScreen.main?.visibleFrame
            },
            activateApplication: {
                NSApplication.shared.activate()
            }
        )
    }

    init(
        content: any ImageWorkspaceContent,
        visibleFrameForPointer: @escaping VisibleFrameProvider,
        activateApplication: @escaping @MainActor () -> Void
    ) {
        self.content = content
        self.visibleFrameForPointer = visibleFrameForPointer
        self.activateApplication = activateApplication

        let window = NSWindow(
            contentRect: CGRect(
                origin: .zero,
                size: CGSize(width: 760, height: 520)
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Clipboard Image"
        window.collectionBehavior = [.moveToActiveSpace]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.contentMinSize = CGSize(width: 420, height: 300)
        window.contentView = content.view

        super.init(window: window)
        window.delegate = self
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
        activateApplication()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
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
