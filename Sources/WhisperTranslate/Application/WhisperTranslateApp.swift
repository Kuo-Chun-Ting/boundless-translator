import AppKit
import SwiftUI

@main
struct WhisperTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra(
            "Whisper Translate",
            systemImage: WhisperTranslateBrand.systemImageName
        ) {
            MenuBarView {
                appDelegate.controller.showPreferences()
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

enum WhisperTranslateBrand {
    static let systemImageName = "w.square.fill"
}

private struct MenuBarView: View {
    let onShowPreferences: @MainActor () -> Void

    var body: some View {
        Button("Preferences…") {
            onShowPreferences()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Whisper Translate") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
