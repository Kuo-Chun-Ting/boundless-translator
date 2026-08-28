import SwiftUI

struct DictionaryPanelView: View {
    let status: DictionaryLookupStatus

    @ViewBuilder
    var body: some View {
        switch status {
        case .idle:
            Color.clear
                .accessibilityHidden(true)
        case .found(let definition):
            definitionView(definition)
        case .notFound:
            ContentUnavailableView {
                Label("No definition found", systemImage: "book.closed")
            } description: {
                Text("Try a different selection or return to Translate.")
            }
        }
    }

    private func definitionView(
        _ definition: DictionaryDefinition
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(definition.term)
                    .font(.title3.weight(.semibold))
                Text(definition.text)
                    .font(.body)
            }
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
