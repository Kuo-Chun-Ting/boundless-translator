import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController: NSWindowController {
    private let presentationCoordinator = PreferencesPresentationCoordinator()

    init(settings: TranslationSettings) {
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: CGSize(width: 430, height: 190)),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView(settings: settings))
        window.center()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        presentationCoordinator.present(
            deferPresentation: { presentation in
                Task { @MainActor in
                    await Task.yield()
                    presentation()
                }
            },
            activateApplication: {
                NSApplication.shared.activate()
            },
            showWindow: { [weak self] in
                self?.showWindow(nil)
            },
            forceWindowToFront: { [weak self] in
                self?.window?.makeKeyAndOrderFront(nil)
                self?.window?.orderFrontRegardless()
            }
        )
    }
}
