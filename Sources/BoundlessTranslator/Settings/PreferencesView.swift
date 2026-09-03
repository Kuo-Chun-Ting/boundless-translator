import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: TranslationSettings
    @ObservedObject var shortcutController: GlobalShortcutController
    @ObservedObject var supportedLanguageCatalog: SupportedLanguageCatalog
    let quitApplication: @MainActor @Sendable () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TranslationPreferencesView(
                    settings: settings,
                    supportedLanguageCatalog: supportedLanguageCatalog
                )
                ShortcutPreferencesView(controller: shortcutController)
                UsagePreferencesView(
                    shortcut: shortcutController.definition
                )
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                PreferencesActionButton(
                    style: .standard(title: "Quit"),
                    accessibilityIdentifier: "quitButton",
                    action: quitApplication
                )
                .fixedSize()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 430, height: 350)
    }
}
