import SwiftUI

enum TranslationLanguageRole {
    case source
    case target
}

struct TranslationLanguageMenu: View {
    @ObservedObject var coordinator: TranslationCoordinator

    let supportedLanguages: [Locale.Language]
    let role: TranslationLanguageRole
    let localization: AppLocalization

    var body: some View {
        TranslationLanguagePicker(
            supportedLanguages: supportedLanguages, role: role, localization: localization,
            selectedIdentifier: role == .source
                ? coordinator.sourceLanguageIdentifier : coordinator.targetLanguageIdentifier,
            sourceLanguageWasDetected: coordinator.request?.sourceLanguageWasDetected == true
        ) { identifier in
            guard let identifier else { return }
            switch role {
            case .source: coordinator.updateSourceLanguage(identifier)
            case .target: coordinator.updateTargetLanguage(identifier)
            }
        }
    }
}

struct TranslationLanguagePicker: View {
    let supportedLanguages: [Locale.Language]
    let role: TranslationLanguageRole
    let localization: AppLocalization
    let selectedIdentifier: String?
    var sourceLanguageWasDetected = false
    var allowsAutomaticSelection = false
    let onSelect: (String?) -> Void

    private var formatter: TranslationLanguagePairFormatter {
        TranslationLanguagePairFormatter(
            locale: Locale(identifier: localization.languageIdentifier),
            localization: localization
        )
    }

    var body: some View {
        if #available(macOS 26, *) {
            languagePicker
                .controlSize(.large)
        } else {
            languagePicker
        }
    }

    private var languagePicker: some View {
        Picker(accessibilityLabel, selection: selection) {
            if role == .source && (allowsAutomaticSelection || selectedIdentifier == nil) {
                Text(verbatim: localization.string("translation.detectAutomatically")).tag("")
            }
            ForEach(options) { option in
                Text(verbatim: optionTitle(option))
                    .tag(option.id)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var selection: Binding<String> {
        Binding(
            get: { selectedIdentifier ?? "" },
            set: { identifier in
                select(identifier)
            }
        )
    }

    private func select(_ identifier: String) {
        let languageIdentifier = identifier.isEmpty ? nil : identifier
        guard languageIdentifier != selectedIdentifier else { return }
        guard languageIdentifier != nil || (role == .source && allowsAutomaticSelection) else { return }
        onSelect(languageIdentifier)
    }

    private func optionTitle(_ option: LanguageOption) -> String {
        let languageName = formatter.languageName(for: option.id)
        guard option.id == selectedIdentifier, badge != nil else {
            return languageName
        }

        return localization.string(
            "panel.language.autoName",
            arguments: languageName
        )
    }

    private var options: [LanguageOption] {
        guard let selectedIdentifier else {
            return supportedLanguages.map { LanguageOption(id: $0.minimalIdentifier, language: $0) }
        }

        return LanguageOption.make(
            supportedLanguages: supportedLanguages,
            selectedIdentifier: selectedIdentifier
        )
    }

    private var title: String {
        if role == .source && selectedIdentifier == nil {
            return localization.string("translation.detectAutomatically")
        }
        guard let selectedIdentifier else {
            return localization.string(
                role == .source
                    ? "panel.language.source"
                    : "panel.language.target"
            )
        }

        return formatter.languageName(for: selectedIdentifier)
    }

    private var badge: String? {
        guard role == .source, sourceLanguageWasDetected else {
            return nil
        }

        return localization.string("panel.language.auto")
    }

    private var accessibilityLabel: String {
        localization.string(
            role == .source
                ? "panel.language.sourceAccessibility"
                : "panel.language.targetAccessibility"
        )
    }

    private var accessibilityValue: String {
        guard let selectedIdentifier else { return title }

        switch role {
        case .source:
            return formatter.sourceDescription(
                languageIdentifier: selectedIdentifier,
                wasDetected: sourceLanguageWasDetected
            )
        case .target:
            return formatter.languageName(
                for: selectedIdentifier
            )
        }
    }

    private var accessibilityIdentifier: String {
        role == .source ? "sourceLanguageMenu" : "targetLanguageMenu"
    }
}
