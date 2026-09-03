import SwiftUI

struct TranslationPreferencesView: View {
    @ObservedObject var settings: TranslationSettings
    @ObservedObject var supportedLanguageCatalog: SupportedLanguageCatalog

    private let languageNames = LanguageDisplayNameFormatter()

    var body: some View {
        Section {
            Picker("From", selection: $settings.sourceLanguageIdentifier) {
                Text("Detect Automatically")
                    .tag(nil as String?)

                ForEach(sourceLanguageOptions) { option in
                    Text(languageNames.name(for: option))
                        .tag(Optional(option.id))
                }
            }
            .pickerStyle(.menu)

            Picker("To", selection: $settings.targetLanguageIdentifier) {
                ForEach(targetLanguageOptions) { option in
                    Text(languageNames.name(for: option))
                        .tag(option.id)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Translation")
                .font(.headline)
                .foregroundStyle(.primary)
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
