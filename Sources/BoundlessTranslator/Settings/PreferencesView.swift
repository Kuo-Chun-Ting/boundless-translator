import SwiftUI

enum PreferencesWindowStyle {
    static let contentSize = CGSize(width: 430, height: 304)

    @MainActor
    static func contentSize(
        settings: InterfaceLanguageSettings,
        languageIdentifier: String?
    ) -> CGSize {
        let resolved = settings.resolvedLanguageIdentifier(for: languageIdentifier)
        let localization = AppLocalization(languageIdentifier: resolved)
        let names = InterfaceLanguageDisplayNameFormatter(displayLocale: Locale(identifier: resolved))
        let value = languageIdentifier.map { names.name(for: $0) }
            ?? names.systemDefaultName(
                label: localization.string("interfaceLanguage.followMacOS"),
                languageIdentifier: resolved
            )
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let labelWidth = (localization.string("interfaceLanguage.label") as NSString)
            .size(withAttributes: [.font: font]).width
        let valueWidth = (value as NSString).size(withAttributes: [.font: font]).width
        // Grouped Form insets and spacing (80), plus native popup chrome (48).
        let width = max(contentSize.width, ceil(labelWidth + valueWidth + 128))
        return CGSize(width: width, height: contentSize.height)
    }
}

struct PreferencesView: View {
    @ObservedObject var settings: TranslationSettings
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings
    @ObservedObject var translationShortcutController: GlobalShortcutController
    @ObservedObject var screenshotShortcutController: GlobalShortcutController
    @ObservedObject var supportedLanguageCatalog: SupportedLanguageCatalog
    let quitApplication: @MainActor @Sendable () -> Void
    var onShowSubscription: (@MainActor () -> Void)? = nil

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
                        controller: translationShortcutController,
                        titleKey: "shortcut.selectedTextTranslation",
                        accessibilityIdentifier: "shortcutRecorder",
                        localization: localization
                    )
                    ShortcutPreferencesView(
                        controller: screenshotShortcutController,
                        titleKey: "shortcut.screenshotTranslation",
                        accessibilityIdentifier: "screenshotShortcutRecorder",
                        localization: localization
                    )
                }
                Section {
                    InterfaceLanguagePreferencesView(
                        settings: interfaceLanguageSettings
                    )
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            HStack(spacing: 8) {
                PreferencesActionButton(
                    style: .standard(
                        title: localization.string("preferences.quit")
                    ),
                    accessibilityIdentifier: "quitButton",
                    action: quitApplication
                )
                .fixedSize()
                Spacer(minLength: 8)
                if let onShowSubscription {
                    PreferencesActionButton(
                        style: .standard(title: localization.string("subscription.title")),
                        accessibilityIdentifier: "subscriptionButton",
                        action: onShowSubscription
                    )
                    .fixedSize()
                }
                UsagePreferencesView(
                    translationShortcut: translationShortcutController.definition,
                    screenshotShortcut: screenshotShortcutController.definition,
                    localization: localization
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .appControlSurface()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(
            width: PreferencesWindowStyle.contentSize(
                settings: interfaceLanguageSettings,
                languageIdentifier: interfaceLanguageSettings.languageIdentifier
            ).width,
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
