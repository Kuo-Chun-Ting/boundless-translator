import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: TranslationSettings
    @ObservedObject var shortcutController: GlobalShortcutController
    @ObservedObject var supportedLanguageCatalog: SupportedLanguageCatalog

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Form {
                TranslationPreferencesView(
                    settings: settings,
                    supportedLanguageCatalog: supportedLanguageCatalog
                )
                ShortcutPreferencesView(controller: shortcutController)
                HowToUsePreferencesView(
                    shortcut: shortcutController.definition
                )
            }
            .formStyle(.grouped)
        }
        .padding(.top, 18)
        .frame(width: 430, height: 440)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: AppBrand.iconImage)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)

            Text("Boundless Translator")
                .font(.headline)
        }
        .padding(.horizontal, 20)
    }
}
