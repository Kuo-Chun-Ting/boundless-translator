import AppKit
import SwiftUI

@main
struct BoundlessTranslatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                interfaceLanguageSettings: appDelegate.controller
                    .interfaceLanguageSettings,
                onShowPreferences: {
                    appDelegate.controller.showPreferences()
                },
                onShowSubscription: appDelegate.controller.subscriptionAction
            )
        } label: {
            Image(nsImage: AppBrand.menuBarIconImage)
                .renderingMode(AppBrand.menuBarIconRenderingMode)
                .accessibilityLabel(AppBrand.displayName)
        }
        .menuBarExtraStyle(.menu)
    }
}


private struct MenuBarView: View {
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings
    let onShowPreferences: @MainActor () -> Void
    let onShowSubscription: (@MainActor () -> Void)?

    var body: some View {
        Group {
            Button(action: onShowPreferences) {
                Text(verbatim: localization.string("menu.preferences"))
            }
            .keyboardShortcut(",", modifiers: .command)

            if let onShowSubscription {
                Button(action: onShowSubscription) {
                    Text(verbatim: localization.string("subscription.title"))
                }
            }

            Divider()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Text(
                    verbatim: localization.string(
                        "menu.quitApplication",
                        arguments: AppBrand.displayName
                    )
                )
            }
            .keyboardShortcut("q")
        }
        .interfaceLanguage(interfaceLanguageSettings)
    }

    private var localization: AppLocalization {
        AppLocalization(
            languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier
        )
    }
}
