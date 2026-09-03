import SwiftUI

enum PreferencesWindowStyle {
    static let contentSize = CGSize(width: 430, height: 280)
    static let backgroundColor = Color(nsColor: .underPageBackgroundColor)
    static let cardBackgroundColor = Color(nsColor: .controlBackgroundColor)
}

struct PreferencesView: View {
    @ObservedObject var settings: TranslationSettings
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings
    @ObservedObject var shortcutController: GlobalShortcutController
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
                        localization: localization
                    )
                    InterfaceLanguagePreferencesView(
                        settings: interfaceLanguageSettings
                    )
                }
                .listRowBackground(PreferencesWindowStyle.cardBackgroundColor)
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
                    localization: localization
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .background(PreferencesWindowStyle.backgroundColor)
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
