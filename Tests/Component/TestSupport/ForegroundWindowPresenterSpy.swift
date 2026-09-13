import AppKit
@testable import BoundlessTranslator

@MainActor
final class ForegroundWindowPresenterSpy: ForegroundWindowPresenting {
    private(set) var presentedWindows: [NSWindow] = []

    func present(_ window: NSWindow) {
        presentedWindows.append(window)
        window.orderFront(nil)
    }
}
