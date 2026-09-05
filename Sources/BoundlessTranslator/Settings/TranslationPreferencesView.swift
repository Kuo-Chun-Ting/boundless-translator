import SwiftUI

struct TranslationPreferencesView: View {
    @ObservedObject var settings: TranslationSettings
    @ObservedObject var supportedLanguageCatalog: SupportedLanguageCatalog
    let localization: AppLocalization

    private var languageNames: LanguageDisplayNameFormatter {
        LanguageDisplayNameFormatter(
            locale: Locale(identifier: localization.languageIdentifier)
        )
    }

    var body: some View {
        Section {
            Picker(
                localization.string("preferences.translateFrom"),
                selection: $settings.sourceLanguageIdentifier
            ) {
                Text(verbatim: localization.string("translation.detectAutomatically"))
                    .tag(nil as String?)

                ForEach(sourceLanguageOptions) { option in
                    Text(verbatim: languageNames.name(for: option))
                        .tag(Optional(option.id))
                }
            }
            .pickerStyle(.menu)

            Picker(
                localization.string("preferences.translateTo"),
                selection: $settings.targetLanguageIdentifier
            ) {
                ForEach(targetLanguageOptions) { option in
                    Text(verbatim: languageNames.name(for: option))
                        .tag(option.id)
                }
            }
            .pickerStyle(.menu)

        }
        .task {
            _ = await supportedLanguageCatalog.load()
        }
    }

    private var sourceLanguageOptions: [LanguageOption] {
        guard let sourceLanguageIdentifier = settings.sourceLanguageIdentifier else {
            return supportedLanguageCatalog.languages.map {
                LanguageOption(id: $0.minimalIdentifier, language: $0)
            }
        }

        return LanguageOption.make(
            supportedLanguages: supportedLanguageCatalog.languages,
            selectedIdentifier: sourceLanguageIdentifier
        )
    }

    private var targetLanguageOptions: [LanguageOption] {
        LanguageOption.make(
            supportedLanguages: supportedLanguageCatalog.languages,
            selectedIdentifier: settings.targetLanguageIdentifier
        )
    }
}
