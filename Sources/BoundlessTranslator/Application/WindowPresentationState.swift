import AppKit

@MainActor
struct WindowPresentationState {
    let window: NSWindow
    var contentWindow: NSWindow? = nil

    var isPresenting: Bool {
        if window.attachedSheet != nil { return true }
        return window.childWindows?.contains { child in
            if child === contentWindow {
                return WindowPresentationState(window: child).isPresenting
            }
            return child.isVisible
        } ?? false
    }
}
