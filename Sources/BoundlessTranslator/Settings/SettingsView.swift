import SwiftUI
@preconcurrency import Translation

struct SettingsView: View {
    @ObservedObject var settings: TranslationSettings

    @State private var supportedLanguages: [Locale.Language] = []
    private let languageNames = LanguageDisplayNameFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(nsImage: AppBrand.iconImage)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .accessibilityHidden(true)

                Text("Translation")
                    .font(.headline)
            }
            .padding(.horizontal, 20)

            Form {
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
                }

                Section("How to Use") {
                    Text("Select text in any app and press ⌘⇧T to translate.")
                    Text("Select text in the translation result and click 📖 to look it up.")
                    Text("Click the pin to keep the translation window open.")
                }
                .foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
        }
        .padding(.top, 18)
        .frame(width: 430, height: 340)
        .task {
            let availableLanguages = await LanguageAvailability().supportedLanguages
            settings.validateSourceLanguage(
                supportedLanguages: availableLanguages
            )
            settings.validateTargetLanguage(
                supportedLanguages: availableLanguages
            )
            supportedLanguages = availableLanguages
                .sorted {
                    languageNames.name(for: $0.minimalIdentifier)
                        .localizedStandardCompare(
                            languageNames.name(for: $1.minimalIdentifier)
                        ) == .orderedAscending
                }
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
}
