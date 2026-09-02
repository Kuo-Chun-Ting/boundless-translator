import SwiftUI

enum TranslationLanguageRole {
    case source
    case target
}

struct TranslationLanguageMenu: View {
    @ObservedObject var coordinator: TranslationCoordinator

    let supportedLanguages: [Locale.Language]
    let role: TranslationLanguageRole

    private let formatter = TranslationLanguagePairFormatter(locale: .current)

    var body: some View {
        Picker(accessibilityLabel, selection: selection) {
            ForEach(options) { option in
                Text(optionTitle(option))
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
        guard identifier != selectedIdentifier else {
            return
        }

        switch role {
        case .source:
            coordinator.updateSourceLanguage(identifier)
        case .target:
            coordinator.updateTargetLanguage(identifier)
        }
    }

    private func optionTitle(_ option: LanguageOption) -> String {
        let languageName = formatter.languageName(for: option.id)
        guard option.id == selectedIdentifier, badge != nil else {
            return languageName
        }

        return "\(languageName) (Auto)"
    }

    private var request: TranslationRequest? {
        coordinator.request
    }

    private var options: [LanguageOption] {
        guard let selectedIdentifier else {
            return []
        }

        return LanguageOption.make(
            supportedLanguages: supportedLanguages,
            selectedIdentifier: selectedIdentifier
        )
    }

    private var selectedIdentifier: String? {
        switch role {
        case .source:
            request?.sourceLanguageIdentifier
        case .target:
            request?.targetLanguageIdentifier
        }
    }

    private var title: String {
        guard let selectedIdentifier else {
            return role == .source ? "Source" : "Target"
        }

        return formatter.languageName(for: selectedIdentifier)
    }

    private var badge: String? {
        guard role == .source, request?.sourceLanguageWasDetected == true else {
            return nil
        }

        return "Auto"
    }

    private var accessibilityLabel: String {
        role == .source ? "Source Language" : "Target Language"
    }

    private var accessibilityValue: String {
        guard let request else {
            return title
        }

        switch role {
        case .source:
            return formatter.sourceDescription(
                languageIdentifier: request.sourceLanguageIdentifier,
                wasDetected: request.sourceLanguageWasDetected
            )
        case .target:
            return formatter.languageName(
                for: request.targetLanguageIdentifier
            )
        }
    }

    private var accessibilityIdentifier: String {
        role == .source ? "sourceLanguageMenu" : "targetLanguageMenu"
    }
}
