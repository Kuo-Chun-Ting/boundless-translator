import AppKit
import SwiftUI

@main
struct BoundlessTranslatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView {
                appDelegate.controller.showPreferences()
            }
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
        let size = NSSize(width: 18, height: 18)
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
    let onShowPreferences: @MainActor () -> Void

    var body: some View {
        Button("Preferences…") {
            onShowPreferences()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit \(AppBrand.displayName)") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
