import SwiftUI

struct SourceLanguageSelectionView: View {
    let selectedText: SelectedText
    let supportedLanguages: [Locale.Language]
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings
    let onCancel: @MainActor () -> Void
    let onSelect: @MainActor (String) -> Void

    @State private var selectedLanguageIdentifier: String
    private var languageNames: LanguageDisplayNameFormatter {
        LanguageDisplayNameFormatter(locale: interfaceLanguageSettings.locale)
    }

    init(
        selectedText: SelectedText,
        selection: SourceLanguageSelection,
        supportedLanguages: [Locale.Language],
        interfaceLanguageSettings: InterfaceLanguageSettings,
        onCancel: @escaping @MainActor () -> Void,
        onSelect: @escaping @MainActor (String) -> Void
    ) {
        self.selectedText = selectedText
        self.supportedLanguages = supportedLanguages
        self.interfaceLanguageSettings = interfaceLanguageSettings
        self.onCancel = onCancel
        self.onSelect = onSelect
        _selectedLanguageIdentifier = State(
            initialValue: selection.selectedLanguageIdentifier
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            originalText
            Divider()
            languageSelection
        }
        .padding(18)
        .frame(minWidth: 420, minHeight: 260, alignment: .topLeading)
        .interfaceLanguage(interfaceLanguageSettings)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "character.book.closed")
                .foregroundStyle(.tint)
            Text(AppBrand.displayName)
                .font(.headline)
        }
    }

    private var originalText: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(verbatim: localization.string("sourceSelection.original"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(selectedText.value)
                .lineLimit(3)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var languageSelection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: localization.string("sourceSelection.title"))
                .font(.headline)
            Text(verbatim: localization.string("sourceSelection.message"))
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Picker(
                    localization.string("translation.from"),
                    selection: $selectedLanguageIdentifier
                ) {
                    ForEach(languageOptions) { option in
                        Text(verbatim: languageNames.name(for: option))
                            .tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Button(localization.string("common.cancel")) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button(localization.string("common.translate")) {
                    onSelect(selectedLanguageIdentifier)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedLanguageIdentifier.isEmpty)
            }
        }
    }

    private var languageOptions: [LanguageOption] {
        guard !selectedLanguageIdentifier.isEmpty else {
            return supportedLanguages.map {
                LanguageOption(id: $0.minimalIdentifier, language: $0)
            }
        }

        return LanguageOption.make(
            supportedLanguages: supportedLanguages,
            selectedIdentifier: selectedLanguageIdentifier
        )
    }

    private var localization: AppLocalization {
        AppLocalization(
            languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier
        )
    }
}
