import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController: NSWindowController {
    private let presentationCoordinator = PreferencesPresentationCoordinator()
    private let activeScreenVisibleFrame: @MainActor () -> CGRect?

    init(
        settings: TranslationSettings,
        shortcutController: GlobalShortcutController,
        activeScreenVisibleFrame: (@MainActor () -> CGRect?)? = nil
    ) {
        self.activeScreenVisibleFrame = activeScreenVisibleFrame ?? {
            NSScreen.main?.visibleFrame
        }
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: CGSize(width: 430, height: 440)),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.collectionBehavior = [.moveToActiveSpace]
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: PreferencesView(
                settings: settings,
                shortcutController: shortcutController
            )
        )
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        centerWindowOnActiveScreen()
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

    private func centerWindowOnActiveScreen() {
        guard let window, let visibleFrame = activeScreenVisibleFrame() else {
            return
        }

        window.setFrameOrigin(
            CGPoint(
                x: visibleFrame.midX - window.frame.width / 2,
                y: visibleFrame.midY - window.frame.height / 2
            )
        )
    }
}
