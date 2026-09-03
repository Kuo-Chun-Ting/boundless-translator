import SwiftUI

struct InterfaceLanguagePreferencesView: View {
    @ObservedObject var settings: InterfaceLanguageSettings

    var body: some View {
        Picker(
            localization.string("interfaceLanguage.label"),
            selection: $settings.languageIdentifier
        ) {
            Text(
                verbatim: languageNames.systemDefaultName(
                    label: localization.string("interfaceLanguage.followMacOS"),
                    languageIdentifier: settings.resolvedLanguageIdentifier(
                        for: nil
                    )
                )
            )
                .tag(nil as String?)

            ForEach(languageIdentifiers, id: \.self) { identifier in
                Text(verbatim: languageNames.name(for: identifier))
                    .tag(Optional(identifier))
            }
        }
        .pickerStyle(.menu)
        .accessibilityIdentifier("interfaceLanguagePicker")
    }

    private var localization: AppLocalization {
        AppLocalization(languageIdentifier: settings.resolvedLanguageIdentifier)
    }

    private var languageNames: InterfaceLanguageDisplayNameFormatter {
        InterfaceLanguageDisplayNameFormatter(displayLocale: settings.locale)
    }

    private var languageIdentifiers: [String] {
        InterfaceLanguageCatalog.languageIdentifiers.sorted {
            languageNames.localizedName(for: $0).compare(
                languageNames.localizedName(for: $1),
                options: .caseInsensitive,
                range: nil,
                locale: settings.locale
            ) == .orderedAscending
        }
    }
}
