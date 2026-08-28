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
        Menu {
            ForEach(options) { option in
                languageButton(option)
            }
        } label: {
            LanguageMenuLabel(title: title, badge: badge)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    @ViewBuilder
    private func languageButton(_ option: LanguageOption) -> some View {
        Button {
            select(option)
        } label: {
            if option.id == selectedIdentifier {
                Label(
                    formatter.languageName(for: option.id),
                    systemImage: "checkmark"
                )
            } else {
                Text(formatter.languageName(for: option.id))
            }
        }
    }

    private func select(_ option: LanguageOption) {
        guard option.id != selectedIdentifier else {
            return
        }

        switch role {
        case .source:
            coordinator.updateSourceLanguage(option.id)
        case .target:
            coordinator.updateTargetLanguage(option.id)
        }
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
}

private struct LanguageMenuLabel: View {
    let title: String
    let badge: String?

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
            if let badge {
                Text(badge)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
