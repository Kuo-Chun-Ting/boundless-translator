import SwiftUI

struct HowToUsePreferencesView: View {
    let shortcut: GlobalShortcutDefinition

    var body: some View {
        Section("How to Use") {
            Text(
                "Select text in any app and press \(shortcut.displayName) to translate."
            )
            Text("Select text in the translation result and click 📖 to look it up.")
            Text("Click the pin to keep the translation window open.")
        }
        .foregroundStyle(.secondary)
    }
}
