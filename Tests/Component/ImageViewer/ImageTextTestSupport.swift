import AppKit
@testable import BoundlessTranslator

@MainActor func selectionFixture() async -> (NSWindow, ImageTextView) {
    let view = ImageTextView(analysisProvider: { _ in
        ImageTextDocument(text: "A B", words: [
            ImageTextRegion(range: NSRange(location: 0, length: 1),
                            bounds: CGRect(x: 10, y: 10, width: 20, height: 20), line: 0),
            ImageTextRegion(range: NSRange(location: 2, length: 1),
                            bounds: CGRect(x: 80, y: 10, width: 20, height: 20), line: 0)
        ])
    })
    let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 200, height: 200),
                          styleMask: [.titled], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.contentView = view
    view.display(NSImage(size: NSSize(width: 200, height: 200)))
    await viewAnalysis(view)
    return (window, view)
}

@MainActor func mouseEvent(_ type: NSEvent.EventType, at point: CGPoint, in window: NSWindow) -> NSEvent {
    NSEvent.mouseEvent(with: type, location: point, modifierFlags: [], timestamp: 0,
                      windowNumber: window.windowNumber, context: nil,
                      eventNumber: 0, clickCount: 1, pressure: 1)!
}

@MainActor func viewAnalysis(_ view: ImageTextView) async {
    for _ in 0..<100 where view.accessibilityIdentifier() == "imageWorkspace.loading" {
        await Task.yield()
    }
}
