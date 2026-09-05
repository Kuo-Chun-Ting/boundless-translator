import AppKit
import Combine
import SwiftUI

@MainActor
final class PreferencesWindowController: NSWindowController {
    private let presentationCoordinator = PreferencesPresentationCoordinator()
    private let interfaceLanguageSettings: InterfaceLanguageSettings
    private let activeScreenVisibleFrame: @MainActor () -> CGRect?
    private var languageCancellable: AnyCancellable?

    init(
        settings: TranslationSettings,
        interfaceLanguageSettings: InterfaceLanguageSettings,
        shortcutController: GlobalShortcutController,
        supportedLanguageCatalog: SupportedLanguageCatalog = SupportedLanguageCatalog(),
        activeScreenVisibleFrame: (@MainActor () -> CGRect?)? = nil,
        quitApplication: @escaping @MainActor @Sendable () -> Void = {
            NSApplication.shared.terminate(nil)
        }
    ) {
        self.interfaceLanguageSettings = interfaceLanguageSettings
        self.activeScreenVisibleFrame = activeScreenVisibleFrame ?? {
            NSScreen.main?.visibleFrame
        }
        let window = NSWindow(
            contentRect: CGRect(
                origin: .zero,
                size: PreferencesWindowStyle.contentSize
            ),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .windowBackgroundColor
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.collectionBehavior = [.moveToActiveSpace]
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: PreferencesView(
                settings: settings,
                interfaceLanguageSettings: interfaceLanguageSettings,
                shortcutController: shortcutController,
                supportedLanguageCatalog: supportedLanguageCatalog,
                quitApplication: quitApplication
            )
        )
        super.init(window: window)
        updateWindowTitle(languageIdentifier: interfaceLanguageSettings.languageIdentifier)
        languageCancellable = interfaceLanguageSettings.$languageIdentifier
            .sink { [weak self] languageIdentifier in
                self?.updateWindowTitle(languageIdentifier: languageIdentifier)
            }
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

    private func updateWindowTitle(languageIdentifier: String?) {
        let resolvedIdentifier = interfaceLanguageSettings
            .resolvedLanguageIdentifier(for: languageIdentifier)
        window?.title = AppLocalization(
            languageIdentifier: resolvedIdentifier
        ).string("preferences.windowTitle")
    }
}
