import SwiftUI
@preconcurrency import Translation

struct TranslationPreferencesView: View {
    @ObservedObject var settings: TranslationSettings

    @State private var supportedLanguages: [Locale.Language] = []
    private let languageNames = LanguageDisplayNameFormatter()

    var body: some View {
        Section("Translation") {
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
        }
        .task {
            await loadSupportedLanguages()
        }
    }

    private var sourceLanguageOptions: [LanguageOption] {
        guard let sourceLanguageIdentifier = settings.sourceLanguageIdentifier else {
            return supportedLanguages.map {
                LanguageOption(id: $0.minimalIdentifier, language: $0)
            }
        }

        return LanguageOption.make(
            supportedLanguages: supportedLanguages,
            selectedIdentifier: sourceLanguageIdentifier
        )
    }

    private var targetLanguageOptions: [LanguageOption] {
        LanguageOption.make(
            supportedLanguages: supportedLanguages,
            selectedIdentifier: settings.targetLanguageIdentifier
        )
    }

    private func loadSupportedLanguages() async {
        let availableLanguages = await LanguageAvailability().supportedLanguages
        settings.validateSourceLanguage(supportedLanguages: availableLanguages)
        settings.validateTargetLanguage(supportedLanguages: availableLanguages)
        supportedLanguages = availableLanguages.sorted {
            languageNames.name(for: $0.minimalIdentifier)
                .localizedStandardCompare(
                    languageNames.name(for: $1.minimalIdentifier)
                ) == .orderedAscending
        }
    }
}
