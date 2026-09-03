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
                }
            )
        } label: {
            Image(nsImage: AppBrand.menuBarIconImage)
                .renderingMode(AppBrand.menuBarIconRenderingMode)
                .accessibilityLabel(AppBrand.displayName)
        }
        .menuBarExtraStyle(.menu)
    }
}

enum AppBrand {
    static let displayName = "Boundless Translator"
    static let iconFileName = "AppIcon.icns"
    static let menuBarIconRenderingMode: Image.TemplateRenderingMode = .original

    @MainActor
    static var iconImage: NSImage {
        NSApplication.shared.applicationIconImage
    }

    @MainActor
    static var menuBarIconImage: NSImage {
        let size = NSSize(width: 24, height: 24)
        let sourceImage = iconImage
        let image = NSImage(size: size, flipped: false) { rect in
            sourceImage.draw(in: rect)
            return true
        }
        image.isTemplate = false
        return image
    }
}

private struct MenuBarView: View {
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings
    let onShowPreferences: @MainActor () -> Void

    var body: some View {
        Group {
            Button(action: onShowPreferences) {
                Text(verbatim: localization.string("menu.preferences"))
            }
            .keyboardShortcut(",", modifiers: .command)

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
