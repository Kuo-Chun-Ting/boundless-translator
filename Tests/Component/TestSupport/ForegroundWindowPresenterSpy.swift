import AppKit
@testable import BoundlessTranslator

@MainActor
final class ForegroundWindowPresenterSpy: ForegroundWindowPresenting {
    private(set) var presentedWindows: [NSWindow] = []
    private(set) var framesBeforePresentation: [NSRect] = []

    func present(_ window: NSWindow) {
        presentedWindows.append(window)
        framesBeforePresentation.append(window.frame)
        window.makeKeyAndOrderFront(nil)
        window.makeMain()
    }
}
