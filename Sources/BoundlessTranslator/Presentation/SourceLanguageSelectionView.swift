import SwiftUI

struct SourceLanguageSelectionView: View {
    let selectedText: SelectedText
    let supportedLanguages: [Locale.Language]
    let onCancel: @MainActor () -> Void
    let onSelect: @MainActor (String) -> Void

    @State private var selectedLanguageIdentifier: String
    private let languageNames = LanguageDisplayNameFormatter()

    init(
        selectedText: SelectedText,
        selection: SourceLanguageSelection,
        supportedLanguages: [Locale.Language],
        onCancel: @escaping @MainActor () -> Void,
        onSelect: @escaping @MainActor (String) -> Void
    ) {
        self.selectedText = selectedText
        self.supportedLanguages = supportedLanguages
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
            Text("Original")
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
            Text("Choose Source Language")
                .font(.headline)
            Text("This text could not be identified confidently.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Picker("From", selection: $selectedLanguageIdentifier) {
                    ForEach(languageOptions) { option in
                        Text(languageNames.name(for: option))
                            .tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Translate") {
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
}
