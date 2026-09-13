import AppKit
import SwiftUI

@MainActor
final class SubscriptionWindowController: NSWindowController {
    private let windowPresenter: any ForegroundWindowPresenting

    init(
        access: SubscriptionAccessController,
        interfaceLanguageSettings: InterfaceLanguageSettings,
        windowPresenter: any ForegroundWindowPresenting = ForegroundWindowPresenter.shared
    ) {
        self.windowPresenter = windowPresenter
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 500, height: 650),
            styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false
        )
        window.title = AppBrand.displayName
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        window.contentMinSize = NSSize(width: 460, height: 540)
        window.contentView = NSHostingView(rootView: SubscriptionView(
            access: access,
            interfaceLanguageSettings: interfaceLanguageSettings,
            configuration: .current
        ))
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present() {
        window?.center()
        if let window {
            windowPresenter.present(window)
        }
    }
}
