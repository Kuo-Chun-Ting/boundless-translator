import SwiftUI

struct HowToUsePreferencesView: View {
    let shortcut: GlobalShortcutDefinition

    var body: some View {
        Section("How to Use") {
            Text(
                "Select text and press \(shortcut.displayName) to translate."
            )
            Text(
                "With no text selected, copy an image and press \(shortcut.displayName) to select its text."
            )
            Text("Select text in the translation result and click 📖 to look it up.")
            Text("Click the pin to keep the translation window open.")
        }
        .foregroundStyle(.secondary)
    }
}
