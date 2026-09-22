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
            contentRect: CGRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable], backing: .buffered, defer: false
        )
        window.title = AppBrand.displayName
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        let configuration = SubscriptionConfiguration.current
        let storeProvider = StoreKitSubscriptionProvider(productID: configuration?.productID ?? "")
        let store = SubscriptionStoreController(access: access, storeProvider: storeProvider)
        window.contentView = NSHostingView(rootView: SubscriptionView(
            access: access,
            store: store,
            interfaceLanguageSettings: interfaceLanguageSettings,
            configuration: configuration,
            onContentSizeChange: { [weak window] size in window?.setContentSize(size) }
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
