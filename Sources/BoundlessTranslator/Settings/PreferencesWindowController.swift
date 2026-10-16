import AppKit
import Combine
import SwiftUI

@MainActor
final class PreferencesWindowController: NSWindowController {
    private let settings: TranslationSettings
    private let interfaceLanguageSettings: InterfaceLanguageSettings
    private let pointerScreenVisibleFrame: @MainActor () -> CGRect?
    private let windowPresenter: any ForegroundWindowPresenting
    private var languageCancellable: AnyCancellable?
    private let tipController = SettingsTipController()
    private let languageSetupHintController = LanguageSetupHintController()
    private var settingsCancellable: AnyCancellable?

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
        self.settings = settings
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
        let tipController = self.tipController
        let languageSetupHintController = self.languageSetupHintController
        window.contentView = NSHostingView(
            rootView: PreferencesView(
                settings: settings,
                interfaceLanguageSettings: interfaceLanguageSettings,
                translationShortcutController: translationShortcutController,
                screenshotShortcutController: screenshotShortcutController,
                supportedLanguageCatalog: supportedLanguageCatalog,
                quitApplication: quitApplication,
                onShowSubscription: onShowSubscription,
                onLanguageSettingsAnchorReady: { languageSetupHintController.setAnchor($0) },
                onHelpButtonReady: { button in
                    tipController.setAnchor(button, localization: AppLocalization(
                        languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier
                    ))
                }
            )
        )
        super.init(window: window)
        WindowBranding.install(on: window, identifier: "settingsWindow")
        resizeWindowForLanguage()
        languageCancellable = interfaceLanguageSettings.$languageIdentifier
            .sink { [weak self] _ in
                // Published sends before the value is stored. Resize after SwiftUI
                // can read the new language, avoiding layout with the old value.
                Task { @MainActor [weak self] in
                    self?.resizeWindowForLanguage()
                    self?.updateLanguageSetupHint()
                }
            }
        settingsCancellable = settings.$sourceLanguageIdentifier
            .combineLatest(settings.$targetLanguageIdentifier)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.updateLanguageSetupHint() }
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
            window.contentView?.layoutSubtreeIfNeeded()
            tipController.present(in: window)
            updateLanguageSetupHint()
        }
    }

    func presentForLanguageSetup() {
        present()
        guard let contentView = window?.contentView as? NSHostingView<PreferencesView> else { return }
        contentView.rootView.languageSetupReminderCount += 1
    }

    private func updateLanguageSetupHint() {
        guard let window, window.isVisible else { return }
        if !settings.hasSelectedLanguages {
            languageSetupHintController.present(in: window, localization: AppLocalization(
                languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier
            ))
        } else {
            languageSetupHintController.close()
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

    private func resizeWindowForLanguage() {
        window?.setContentSize(PreferencesWindowStyle.contentSize(
            settings: interfaceLanguageSettings,
            languageIdentifier: interfaceLanguageSettings.languageIdentifier
        ))
    }
}
