import SwiftUI

enum PreferencesWindowStyle {
    static let contentSize = CGSize(width: 430, height: 330)
}

struct PreferencesView: View {
    @ObservedObject var settings: TranslationSettings
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings
    @ObservedObject var shortcutController: GlobalShortcutController
    @ObservedObject var screenshotShortcutController: GlobalShortcutController
    @ObservedObject var supportedLanguageCatalog: SupportedLanguageCatalog
    let quitApplication: @MainActor @Sendable () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TranslationPreferencesView(
                    settings: settings,
                    supportedLanguageCatalog: supportedLanguageCatalog,
                    localization: localization
                )

                Section {
                    ShortcutPreferencesView(
                        controller: shortcutController,
                        otherController: screenshotShortcutController,
                        titleKey: "shortcut.section",
                        accessibilityIdentifier: "shortcutRecorder",
                        localization: localization
                    )
                    ShortcutPreferencesView(
                        controller: screenshotShortcutController,
                        otherController: shortcutController,
                        titleKey: "screenshot.shortcut",
                        accessibilityIdentifier: "screenshotShortcutRecorder",
                        localization: localization
                    )
                    InterfaceLanguagePreferencesView(
                        settings: interfaceLanguageSettings
                    )
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            HStack {
                PreferencesActionButton(
                    style: .standard(
                        title: localization.string(
                            "menu.quitApplication",
                            arguments: AppBrand.displayName
                        )
                    ),
                    accessibilityIdentifier: "quitButton",
                    action: quitApplication
                )
                .fixedSize()

                Spacer()

                UsagePreferencesView(
                    shortcut: shortcutController.definition,
                    screenshotShortcut: screenshotShortcutController.definition,
                    localization: localization
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(
            width: PreferencesWindowStyle.contentSize.width,
            height: PreferencesWindowStyle.contentSize.height
        )
        .interfaceLanguage(interfaceLanguageSettings)
    }

    private var localization: AppLocalization {
        AppLocalization(
            languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier
        )
    }
}
