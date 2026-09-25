import AppKit
import Combine
import SwiftUI

@MainActor
final class PreferencesWindowController: NSWindowController {
    private let interfaceLanguageSettings: InterfaceLanguageSettings
    private let pointerScreenVisibleFrame: @MainActor () -> CGRect?
    private let windowPresenter: any ForegroundWindowPresenting
    private var languageCancellable: AnyCancellable?
    private let titleLabel = NSTextField(labelWithString: "")

    init(
        settings: TranslationSettings,
        interfaceLanguageSettings: InterfaceLanguageSettings,
        translationShortcutController: GlobalShortcutController,
        screenshotShortcutController: GlobalShortcutController = GlobalShortcutController(
            purpose: .screenshot,
            handler: {}
        ),
        supportedLanguageCatalog: SupportedLanguageCatalog,
        onShowSubscription: (@MainActor () -> Void)? = nil,
        pointerScreenVisibleFrame: (@MainActor () -> CGRect?)? = nil,
        windowPresenter: any ForegroundWindowPresenting = ForegroundWindowPresenter.shared,
        quitApplication: @escaping @MainActor @Sendable () -> Void = {
            NSApplication.shared.terminate(nil)
        }
    ) {
        self.interfaceLanguageSettings = interfaceLanguageSettings
        self.pointerScreenVisibleFrame = pointerScreenVisibleFrame ?? {
            let pointerLocation = NSEvent.mouseLocation
            return NSScreen.screens.first {
                $0.frame.contains(pointerLocation)
            }?.visibleFrame ?? NSScreen.main?.visibleFrame
        }
        self.windowPresenter = windowPresenter
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
        window.hidesOnDeactivate = false
        window.contentView = NSHostingView(
            rootView: PreferencesView(
                settings: settings,
                interfaceLanguageSettings: interfaceLanguageSettings,
                translationShortcutController: translationShortcutController,
                screenshotShortcutController: screenshotShortcutController,
                supportedLanguageCatalog: supportedLanguageCatalog,
                quitApplication: quitApplication,
                onShowSubscription: onShowSubscription
            )
        )
        super.init(window: window)
        configureTitlebar(window)
        updateWindowTitle(languageIdentifier: interfaceLanguageSettings.languageIdentifier)
        resizeWindowForLanguage()
        languageCancellable = interfaceLanguageSettings.$languageIdentifier
            .sink { [weak self] languageIdentifier in
                self?.updateWindowTitle(languageIdentifier: languageIdentifier)
                // Published sends before the value is stored. Resize after SwiftUI
                // can read the new language, avoiding layout with the old value.
                Task { @MainActor [weak self] in
                    self?.resizeWindowForLanguage()
                }
            }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        centerWindowOnPointerScreen()
        if let window {
            windowPresenter.present(window)
        }
    }

    private func centerWindowOnPointerScreen() {
        guard let window, let visibleFrame = pointerScreenVisibleFrame() else {
            return
        }

        window.setFrameOrigin(
            CGPoint(
                x: visibleFrame.midX - window.frame.width / 2,
                y: visibleFrame.midY - window.frame.height / 2
            )
        )
    }

    private func configureTitlebar(_ window: NSWindow) {
        window.titleVisibility = .hidden
        let icon = NSImageView(image: AppBrand.iconImage)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.setAccessibilityElement(false)
        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        titleLabel.setAccessibilityIdentifier("preferencesTitle")
        let stack = NSStackView(views: [icon, titleLabel])
        stack.spacing = 6
        stack.alignment = .centerY
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
        ])
        let accessory = NSTitlebarAccessoryViewController()
        accessory.layoutAttribute = .left
        accessory.view = stack
        window.addTitlebarAccessoryViewController(accessory)
    }

    private func updateWindowTitle(languageIdentifier: String?) {
        let resolvedIdentifier = interfaceLanguageSettings
            .resolvedLanguageIdentifier(for: languageIdentifier)
        window?.title = AppLocalization(
            languageIdentifier: resolvedIdentifier
        ).string("preferences.windowTitle")
        titleLabel.stringValue = window?.title ?? ""
        if let window, let titleView = window.titlebarAccessoryViewControllers.first?.view {
            let titlebarHeight = window.frame.height - window.contentLayoutRect.height
            titleView.setFrameSize(NSSize(width: titleView.fittingSize.width, height: titlebarHeight))
        }
    }

    private func resizeWindowForLanguage() {
        window?.setContentSize(PreferencesWindowStyle.contentSize(
            settings: interfaceLanguageSettings,
            languageIdentifier: interfaceLanguageSettings.languageIdentifier
        ))
    }
}
