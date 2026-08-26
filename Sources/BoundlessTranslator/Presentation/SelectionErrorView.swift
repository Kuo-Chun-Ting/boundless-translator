import SwiftUI

struct SelectionErrorView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(AppBrand.displayName, systemImage: "character.book.closed")
                .font(.headline)
            Divider()
            Label("Could not read the selected text", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
            Text(message)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Spacer(minLength: 0)
            Text("Shortcut: Command-Shift-T")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(minWidth: 420, minHeight: 260, alignment: .topLeading)
    }
}
