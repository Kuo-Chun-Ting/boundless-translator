import SwiftUI

enum SelectionErrorMessage {
    case globalShortcut(GlobalShortcutError)
    case translationLanguagesUnavailable
    case verbatim(String)

    func localizedText(using localization: AppLocalization) -> String {
        switch self {
        case .globalShortcut(let error):
            error.message(localization: localization)
        case .translationLanguagesUnavailable:
            localization.string("translation.noLanguages")
        case .verbatim(let message):
            message
        }
    }
}

struct SelectionErrorView: View {
    let message: SelectionErrorMessage
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings

    init(
        message: SelectionErrorMessage,
        interfaceLanguageSettings: InterfaceLanguageSettings
    ) {
        self.message = message
        self.interfaceLanguageSettings = interfaceLanguageSettings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(AppBrand.displayName, systemImage: "character.book.closed")
                .font(.headline)
            Divider()
            Label(
                localization.string("selectionError.title"),
                systemImage: "exclamationmark.triangle"
            )
                .foregroundStyle(.red)
            Text(verbatim: localizedMessage)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Spacer(minLength: 0)
            Text(verbatim: localization.string("selectionError.guidance"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(minWidth: 420, minHeight: 260, alignment: .topLeading)
        .interfaceLanguage(interfaceLanguageSettings)
    }

    var localizedMessage: String {
        message.localizedText(using: localization)
    }

    private var localization: AppLocalization {
        AppLocalization(
            languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier
        )
    }
}
