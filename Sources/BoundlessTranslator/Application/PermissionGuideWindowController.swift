import AppKit
import SwiftUI

@MainActor
final class PermissionGuideWindowController: NSWindowController, NSWindowDelegate {
    private var didContinue = false

    init(configuration: PermissionGuideConfiguration, localization: AppLocalization) {
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 520, height: 410),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = AppBrand.displayName
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        super.init(window: window)
        window.delegate = self
        window.contentView = NSHostingView(rootView: PermissionGuideView(
            configuration: configuration,
            localization: localization,
            onContinue: { [weak self] in self?.finish(continuing: true) }
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func present() -> Bool {
        guard let window else { return false }
        didContinue = false
        window.center()
        NSApplication.shared.activate()
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.runModal(for: window)
        window.orderOut(nil)
        return didContinue
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        finish(continuing: false)
        return false
    }

    private func finish(continuing: Bool) {
        didContinue = continuing
        NSApplication.shared.stopModal()
    }
}
